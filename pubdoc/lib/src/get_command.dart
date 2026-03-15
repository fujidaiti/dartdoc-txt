import 'cache.dart';
import 'config.dart';
import 'doc_generator.dart';
import 'environment.dart';
import 'exceptions.dart';
import 'project.dart';
import 'version_resolution.dart';

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

  Future<void> run({required List<String> packageNames}) async {
    if (packageNames.isEmpty) {
      throw PubdocException(
        'No packages specified. Usage: pubdoc get <package1> [package2 ...]',
      );
    }

    project.validate();

    final cacheManager = CacheManager(config, env: env);
    final generator = _generator ?? DocGenerator(env: env);

    for (final packageName in packageNames) {
      await _processPackage(packageName, cacheManager, generator);
    }
  }

  Future<void> _processPackage(
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
      try {
        await generator.generate(
          sourcePath: sourceDir.path,
          outputDir: cacheResult.cacheDir,
        );
      } on Exception catch (e) {
        throw PubdocException(
          'Failed to generate documentation for $packageName: $e',
        );
      }

      // 6. Write metadata.json.
      CacheMetadata(
        version: docVersion,
        packageVersion: version.toString(),
        source: Uri.file(sourceDir.path).toString(),
      ).write(cacheResult.cacheDir, fs: env.fs);

      env.logger?.info('  Documentation generated.');
    } else {
      env.logger?.info('  Using cached documentation.');
    }

    // 7. Create/update symlink.
    _createSymlink(packageName, cacheResult.cacheDir);
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
