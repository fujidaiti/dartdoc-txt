import 'package:file/file.dart';

import 'cache.dart';
import 'config.dart';
import 'doc_generator.dart';
import 'exceptions.dart';
import 'logger.dart';
import 'project.dart';
import 'version_resolution.dart';

class GetCommand {
  final ProjectContext project;
  final PubdocConfig config;
  final Logger logger;
  final FileSystem fs;
  final ResolutionStrategy strategy;
  final bool useCache;

  GetCommand({
    required this.project,
    required this.config,
    required this.logger,
    required this.fs,
    this.strategy = ResolutionStrategy.loosePatch,
    this.useCache = true,
  });

  Future<void> run(List<String> packageNames) async {
    if (packageNames.isEmpty) {
      throw PubdocException(
        'No packages specified. Usage: pubdoc get <package1> [package2 ...]',
      );
    }

    project.validate();

    final cacheManager = CacheManager(config, fs: fs);
    final generator = DocGenerator(logger: logger, fs: fs);

    for (final packageName in packageNames) {
      await _processPackage(packageName, cacheManager, generator);
    }
  }

  Future<void> _processPackage(
    String packageName,
    CacheManager cacheManager,
    DocGenerator generator,
  ) async {
    logger.info('Processing $packageName...');

    // 1. Detect version from pubspec.lock.
    final version = project.getPackageVersion(packageName);
    logger.detail('  Version in pubspec.lock: $version');

    // 2. Find source path from package_config.json.
    final sourceDir = project.getPackageSourceDir(packageName);
    logger.detail('  Source: ${sourceDir.path}');

    // 3. Resolve doc version.
    final docVersion = version.docVersion(strategy);
    logger.detail('  Doc version ($strategy): $docVersion');

    // 4. Check cache.
    final cacheResult = cacheManager.checkCache(
      packageName: packageName,
      packageVersion: version,
      strategy: strategy,
      useCache: useCache,
    );
    logger.detail('  Cache action: ${cacheResult.action}');

    // 5. Generate if needed.
    if (cacheResult.action != CacheAction.reuse) {
      logger.info('  Generating documentation for $packageName $docVersion...');
      await generator.generate(
        sourcePath: sourceDir.path,
        outputDir: cacheResult.cacheDir,
      );

      // 6. Write metadata.json.
      CacheMetadata(
        version: docVersion,
        packageVersion: version.toString(),
        source: Uri.file(sourceDir.path).toString(),
      ).write(cacheResult.cacheDir, fs: fs);

      logger.info('  Documentation generated.');
    } else {
      logger.info('  Using cached documentation.');
    }

    // 7. Create/update symlink.
    _createSymlink(packageName, cacheResult.cacheDir);
  }

  void _createSymlink(String packageName, String cacheDir) {
    if (!project.pubdocDir.existsSync()) {
      project.pubdocDir.createSync(recursive: true);
    }

    final linkPath = '${project.pubdocDir.path}/$packageName';
    final link = fs.link(linkPath);

    if (link.existsSync()) {
      link.deleteSync();
    }

    link.createSync(cacheDir);
    logger.detail('  Symlink: $linkPath -> $cacheDir');
  }
}
