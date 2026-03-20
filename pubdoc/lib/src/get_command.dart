import 'dart:convert';

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'cache.dart';
import 'config.dart';
import 'doc_generator.dart';
import 'environment.dart';
import 'exceptions.dart';
import 'project.dart';
import 'version_resolution.dart';

/// Cache status for a single package after `pubdoc get`.
enum CacheStatus {
  /// The cached documentation was valid and reused as-is.
  hit,

  /// No cache existed; documentation was generated fresh.
  miss,

  /// Cache existed but was not compatible with the given package version,
  /// so documentation was regenerated.
  refreshed,
}

/// Per-package result from [GetCommand.run].
class PackageGetResult {
  /// Absolute path to the symlink in the project's `.pubdoc/` directory.
  final String documentation;

  /// Absolute path to the package source directory that the documentation was
  /// generated from.
  final String source;

  /// The resolved documentation version string (e.g. `5.3.x`).
  final String version;

  /// Whether documentation was served from cache, generated fresh, or refreshed.
  final CacheStatus cacheStatus;

  const PackageGetResult({
    required this.documentation,
    required this.source,
    required this.version,
    required this.cacheStatus,
  });

  Map<String, dynamic> toJson() => {
    'documentation': documentation,
    'version': version,
    'source': source,
    'cache': cacheStatus.name,
  };
}

/// Aggregated result from [GetCommand.run], keyed by package name.
class GetResult {
  /// Results indexed by package name.
  final Map<String, PackageGetResult> packages;

  const GetResult({required this.packages});

  Map<String, dynamic> toJson() => {
    'packages': {for (final e in packages.entries) e.key: e.value.toJson()},
  };

  /// Returns a human-readable summary suitable for printing to stdout.
  ///
  /// Each package is rendered as:
  /// ```
  /// <packageName>
  ///   documentation: <path>
  ///   source:        <path>
  ///   cache:         <hit|miss|refreshed>
  /// ```
  /// Packages are separated by a blank line.
  String format() {
    final buffer = StringBuffer();
    var first = true;
    for (final entry in packages.entries) {
      if (!first) buffer.write('\n');
      first = false;
      final r = entry.value;
      buffer.write('${entry.key}\n');
      buffer.write('  documentation: ${r.documentation}\n');
      buffer.write('  version:       ${r.version}\n');
      buffer.write('  source:        ${r.source}\n');
      buffer.write('  cache:         ${r.cacheStatus.name}\n');
    }
    return buffer.toString();
  }
}

/// Creates a package_config.json for [package] from the project-level
/// [projectPackageConfig] and the dependency graph [projectPackageGraph].
///
/// The result contains only the packages that [package] transitively
/// depends on, so the analyzer doesn't index unrelated packages.
///
/// [projectPackageConfig] is the parsed `.dart_tool/package_config.json`:
/// ```json
/// {
///   "configVersion": 2,
///   "packages": [
///     {"name": "foo", "rootUri": "...", "packageUri": "lib/"},
///     ...
///   ]
/// }
/// ```
///
/// [projectPackageGraph] is the parsed `.dart_tool/package_graph.json`:
/// ```json
/// {
///   "configVersion": 1,
///   "packages": [
///     {"name": "foo", "dependencies": ["bar", "baz"]},
///     ...
///   ]
/// }
/// ```
///
/// All top-level fields other than `packages` are preserved.
/// Returns a new map; the originals are not modified.
@visibleForTesting
Map<String, dynamic> buildPackageConfigFor({
  required String package,
  required Map<String, dynamic> projectPackageConfig,
  required Map<String, dynamic> projectPackageGraph,
}) {
  // Build adjacency map from the graph.
  final graphPackages = projectPackageGraph['packages'] as List<dynamic>;
  final graph = <String, List<String>>{};
  for (final pkg in graphPackages) {
    final map = pkg as Map<String, dynamic>;
    final name = map['name'] as String;
    final deps = (map['dependencies'] as List<dynamic>).cast<String>();
    graph[name] = deps;
  }

  // BFS from package to find transitive closure.
  final visited = <String>{};
  final queue = [package];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (!visited.add(current)) continue;
    final deps = graph[current];
    if (deps != null) queue.addAll(deps);
  }

  // Filter package_config packages to only those in the transitive closure.
  final configPackages = projectPackageConfig['packages'] as List<dynamic>;
  final result = Map<String, dynamic>.of(projectPackageConfig);
  result['packages'] = [
    for (final pkg in configPackages)
      if (visited.contains((pkg as Map<String, dynamic>)['name'])) pkg,
  ];
  return result;
}

/// Recursively copies the contents of [src] into [dst].
void _copyDirectory(Directory src, Directory dst) {
  for (final entity in src.listSync()) {
    final name = p.basename(entity.path);
    if (entity is File) {
      entity.copySync(p.join(dst.path, name));
    } else if (entity is Directory) {
      final sub = dst.childDirectory(name);
      sub.createSync();
      _copyDirectory(entity, sub);
    }
  }
}

class GetCommand {
  final ProjectContext project;
  final PubdocConfig config;
  final Environment env;
  final ResolutionStrategy strategy;
  final bool useCache;
  final DocGenerator? _generator;

  GetCommand({
    required this.project,
    required this.config,
    required this.env,
    this.strategy = ResolutionStrategy.loosePatch,
    this.useCache = true,
    DocGenerator? generator,
  }) : _generator = generator;

  /// Runs the get command for the given [packageNames] and returns a
  /// [GetResult] containing per-package metadata.
  Future<GetResult> run({required List<String> packageNames}) async {
    if (packageNames.isEmpty) {
      throw PubdocException(
        'No packages specified. Usage: pubdoc get <package1> [package2 ...]',
      );
    }

    project.validate();

    final cacheManager = CacheManager(config, env: env);
    final generator = _generator ?? DocGenerator(env: env);

    final results = <String, PackageGetResult>{};
    for (final packageName in packageNames) {
      results[packageName] = await _processPackage(
        packageName,
        cacheManager,
        generator,
      );
    }
    return GetResult(packages: results);
  }

  Future<PackageGetResult> _processPackage(
    String packageName,
    CacheManager cacheManager,
    DocGenerator generator,
  ) async {
    env.logger?.info('Processing $packageName...');

    // 1. Detect version from pubspec.lock.
    final version = project.getPackageVersion(packageName);
    env.logger?.detail('  Version in pubspec.lock: $version');

    // 2. Find source path from package_config.json.
    final sourceDir = project.getPackageSourceDir(packageName);
    env.logger?.detail('  Source: ${sourceDir.path}');

    // 3. Resolve doc version.
    final docVersion = version.docVersion(strategy);
    env.logger?.detail('  Doc version ($strategy): $docVersion');

    // 4. Check cache.
    final cacheResult = cacheManager.checkCache(
      packageName: packageName,
      packageVersion: version,
      strategy: strategy,
      useCache: useCache,
    );
    env.logger?.detail('  Cache action: ${cacheResult.action}');

    // 5. Generate if needed.
    if (cacheResult.action != CacheAction.reuse) {
      env.logger?.info(
        '  Generating documentation for $packageName $docVersion...',
      );

      // Copy the package source into a temp directory and synthesize
      // .dart_tool/package_config.json so the analyzer can resolve
      // dependency types (prevents them from appearing as `dynamic`).
      final tempDir = env.fs.systemTempDirectory.createTempSync(
        'pubdoc_$packageName\_',
      );
      try {
        _copyDirectory(sourceDir, tempDir);
        final dartToolDir = tempDir.childDirectory('.dart_tool');
        dartToolDir.createSync();
        final packageConfigJson =
            jsonDecode(project.packageConfigFile.readAsStringSync())
                as Map<String, dynamic>;
        final Map<String, dynamic> configToWrite;
        if (project.packageGraphFile.existsSync()) {
          final graphJson =
              jsonDecode(project.packageGraphFile.readAsStringSync())
                  as Map<String, dynamic>;
          configToWrite = buildPackageConfigFor(
            package: packageName,
            projectPackageConfig: packageConfigJson,
            projectPackageGraph: graphJson,
          );
        } else {
          configToWrite = packageConfigJson;
        }
        dartToolDir
            .childFile('package_config.json')
            .writeAsStringSync(jsonEncode(configToWrite));

        await generator.generate(
          sourcePath: tempDir.path,
          outputDir: cacheResult.cacheDir,
        );
      } on Exception catch (e) {
        throw PubdocException(
          'Failed to generate documentation for $packageName: $e',
        );
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }

      // 7. Write metadata.json.
      CacheMetadata(
        version: docVersion,
        packageVersion: version.toString(),
        source: Uri.file(sourceDir.path).toString(),
        toolVersion: env.toolVersion,
      ).write(cacheResult.cacheDir, fs: env.fs);

      env.logger?.info('  Documentation generated.');
    } else {
      env.logger?.info('  Using cached documentation.');
    }

    // 8. Create/update symlink.
    _createSymlink(packageName, cacheResult.cacheDir);

    final sourcePath = cacheResult.action == CacheAction.reuse
        ? Uri.parse(cacheResult.metadata!.source).toFilePath()
        : sourceDir.path;

    final linkPath = '${project.pubdocDir.path}/$packageName';
    return PackageGetResult(
      documentation: linkPath,
      source: sourcePath,
      version: docVersion,
      cacheStatus: switch (cacheResult.action) {
        CacheAction.reuse => CacheStatus.hit,
        CacheAction.generate => CacheStatus.miss,
        CacheAction.regenerate => CacheStatus.refreshed,
      },
    );
  }

  void _createSymlink(String packageName, String cacheDir) {
    if (!project.pubdocDir.existsSync()) {
      project.pubdocDir.createSync(recursive: true);
    }

    final linkPath = '${project.pubdocDir.path}/$packageName';
    final link = env.fs.link(linkPath);

    if (link.existsSync()) {
      link.deleteSync();
    }

    link.createSync(cacheDir);
    env.logger?.detail('  Symlink: $linkPath -> $cacheDir');
  }
}
