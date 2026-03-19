import 'package:file/memory.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubdoc/src/cache.dart';
import 'package:pubdoc/src/config.dart';
import 'package:pubdoc/src/environment.dart';
import 'package:pubdoc/src/logger.dart';
import 'package:pubdoc/src/version_resolution.dart';
import 'package:test/test.dart';

class _TestEnvironment implements Environment {
  @override
  final MemoryFileSystem fs;
  @override
  final Logger? logger = null;
  @override
  final String toolVersion;

  _TestEnvironment({this.toolVersion = '1.0.0'}) : fs = MemoryFileSystem.test();

  @override
  String? getVariable(String name) => null;
}

void main() {
  late _TestEnvironment env;
  late PubdocConfig config;

  setUp(() {
    env = _TestEnvironment();
    config = PubdocConfig(homeDir: '/home/test', cacheDir: '/home/test/cache');
  });

  group('CacheManager.checkCache', () {
    test('returns generate when cache dir does not exist', () {
      final manager = CacheManager(config, env: env);
      final result = manager.checkCache(
        packageName: 'dio',
        packageVersion: Version.parse('5.3.2'),
        strategy: ResolutionStrategy.loosePatch,
        useCache: true,
      );
      expect(result.action, CacheAction.generate);
      expect(result.docVersion, '5.3.x');
    });

    test('returns generate when useCache is false', () {
      final manager = CacheManager(config, env: env);
      // Create the cache dir to prove it's ignored.
      env.fs
          .directory(config.packageCacheDir('dio', '5.3.x'))
          .createSync(recursive: true);

      final result = manager.checkCache(
        packageName: 'dio',
        packageVersion: Version.parse('5.3.2'),
        strategy: ResolutionStrategy.loosePatch,
        useCache: false,
      );
      expect(result.action, CacheAction.generate);
    });

    test('returns reuse for exact strategy when cache exists', () {
      final manager = CacheManager(config, env: env);
      final cacheDir = config.packageCacheDir('dio', '5.3.2');
      env.fs.directory(cacheDir).createSync(recursive: true);
      CacheMetadata(
        version: '5.3.2',
        packageVersion: '5.3.2',
        source: 'file:///test/source',
        toolVersion: '1.0.0',
      ).write(cacheDir, fs: env.fs);

      final result = manager.checkCache(
        packageName: 'dio',
        packageVersion: Version.parse('5.3.2'),
        strategy: ResolutionStrategy.exact,
        useCache: true,
      );
      expect(result.action, CacheAction.reuse);
    });

    test('returns reuse for loosePatch when cached version >= requested', () {
      final manager = CacheManager(config, env: env);
      final cacheDir = config.packageCacheDir('dio', '5.3.x');
      env.fs.directory(cacheDir).createSync(recursive: true);
      // Metadata says cached from 5.3.4
      CacheMetadata(
        version: '5.3.x',
        packageVersion: '5.3.4',
        source: 'file:///test/source',
        toolVersion: '1.0.0',
      ).write(cacheDir, fs: env.fs);

      final result = manager.checkCache(
        packageName: 'dio',
        packageVersion: Version.parse('5.3.2'),
        strategy: ResolutionStrategy.loosePatch,
        useCache: true,
      );
      expect(result.action, CacheAction.reuse);
    });

    test(
      'returns regenerate for loosePatch when cached version < requested',
      () {
        final manager = CacheManager(config, env: env);
        final cacheDir = config.packageCacheDir('dio', '5.3.x');
        env.fs.directory(cacheDir).createSync(recursive: true);
        // Metadata says cached from 5.3.1
        CacheMetadata(
          version: '5.3.x',
          packageVersion: '5.3.1',
          source: 'file:///test/source',
          toolVersion: '1.0.0',
        ).write(cacheDir, fs: env.fs);

        final result = manager.checkCache(
          packageName: 'dio',
          packageVersion: Version.parse('5.3.6'),
          strategy: ResolutionStrategy.loosePatch,
          useCache: true,
        );
        expect(result.action, CacheAction.regenerate);
      },
    );

    test('returns reuse for looseMinor when cached version >= requested', () {
      final manager = CacheManager(config, env: env);
      final cacheDir = config.packageCacheDir('dio', '5.x');
      env.fs.directory(cacheDir).createSync(recursive: true);
      CacheMetadata(
        version: '5.x',
        packageVersion: '5.7.0',
        source: 'file:///test/source',
        toolVersion: '1.0.0',
      ).write(cacheDir, fs: env.fs);

      final result = manager.checkCache(
        packageName: 'dio',
        packageVersion: Version.parse('5.3.2'),
        strategy: ResolutionStrategy.looseMinor,
        useCache: true,
      );
      expect(result.action, CacheAction.reuse);
    });

    test('returns regenerate when metadata is missing in loose mode', () {
      final manager = CacheManager(config, env: env);
      final cacheDir = config.packageCacheDir('dio', '5.3.x');
      // Dir exists but no metadata.json
      env.fs.directory(cacheDir).createSync(recursive: true);

      final result = manager.checkCache(
        packageName: 'dio',
        packageVersion: Version.parse('5.3.2'),
        strategy: ResolutionStrategy.loosePatch,
        useCache: true,
      );
      expect(result.action, CacheAction.regenerate);
    });
  });

  group('CacheMetadata', () {
    test('serializes and deserializes all fields', () {
      final metadata = CacheMetadata(
        version: '5.3.x',
        packageVersion: '5.3.4',
        source: 'file:///path/to/dio-5.3.4',
        toolVersion: '1.0.0',
      );
      env.fs.directory('/tmp/test').createSync(recursive: true);
      metadata.write('/tmp/test', fs: env.fs);

      final loaded = CacheMetadata.read('/tmp/test', fs: env.fs);
      expect(loaded, isNotNull);
      expect(loaded!.version, '5.3.x');
      expect(loaded.packageVersion, '5.3.4');
      expect(loaded.source, 'file:///path/to/dio-5.3.4');
      expect(loaded.toolVersion, '1.0.0');
    });

    test('read returns null when file does not exist', () {
      final result = CacheMetadata.read('/tmp/nonexistent', fs: env.fs);
      expect(result, isNull);
    });
  });
}
