import 'package:mockito/mockito.dart';
import 'package:pubdoc/src/cache.dart';
import 'package:pubdoc/src/config.dart';
import 'package:pubdoc/src/exceptions.dart';
import 'package:pubdoc/src/get_command.dart';
import 'package:pubdoc/src/project.dart';
import 'package:pubdoc/src/version_resolution.dart';
import 'package:test/test.dart';

import 'src/mocks.dart';
import 'src/test_environment.dart';

const _projectRoot = '/Users/testuser/projects/my_app';
const _homeDir = '/Users/testuser/.pubdoc';
const _cacheDir = '/Users/testuser/.pubdoc/cache';
const _pubCacheBase = '/Users/testuser/.pub-cache/hosted/pub.dev';

void main() {
  late TestEnvironment env;
  late MockDocGenerator generator;

  setUp(() {
    env = TestEnvironment(
      projectRoot: _projectRoot,
      pubCacheBase: _pubCacheBase,
    )..setUp();

    generator = MockDocGenerator();
    when(
      generator.generate(
        sourcePath: anyNamed('sourcePath'),
        outputDir: anyNamed('outputDir'),
      ),
    ).thenAnswer((invocation) async {
      // The output content doesn't matter for these tests,
      // so just create an empty directory here to simulate generation.
      final outputDir = invocation.namedArguments[#outputDir] as String;
      env.fs.directory(outputDir).createSync(recursive: true);
    });
  });

  GetCommand makeCommand({
    required ResolutionStrategy strategy,
    bool useCache = true,
  }) {
    return GetCommand(
      project: ProjectContext.from(_projectRoot, env: env),
      config: PubdocConfig(homeDir: _homeDir, cacheDir: _cacheDir),
      env: env,
      generator: generator,
      strategy: strategy,
      useCache: useCache,
    );
  }

  group('Basic behaviors', () {
    late GetCommand command;

    setUp(() {
      command = makeCommand(strategy: .exact);
    });

    test('correct cache dir and full metadata', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              version: '5.3.2',
              source: '$_pubCacheBase/dio-5.3.2/',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );

      final cacheDir = '$_cacheDir/dio/dio-5.3.2';
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: cacheDir,
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(env.fs.directory(cacheDir).existsSync(), isTrue);
      expect(env.fs.link('$_projectRoot/.pubdoc/dio').existsSync(), isTrue);
      expect(env.fs.link('$_projectRoot/.pubdoc/dio').targetSync(), cacheDir);
      expect(
        CacheMetadata.read(cacheDir, fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.3.2', pkgVersion: '5.3.2'),
      );
    });

    test('includes resolved package config in working directory', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      String? capturedSourcePath;
      when(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: anyNamed('outputDir'),
        ),
      ).thenAnswer((invocation) async {
        capturedSourcePath = invocation.namedArguments[#sourcePath] as String;
        // During generation the working dir and package_config.json
        // should exist.
        expect(env.fs.directory(capturedSourcePath!).existsSync(), isTrue);
        expect(
          env.fs
              .file('$capturedSourcePath/.dart_tool/package_config.json')
              .existsSync(),
          isTrue,
        );

        // Simulate doc generation by creating the output dir.
        final outputDir = invocation.namedArguments[#outputDir] as String;
        env.fs.directory(outputDir).createSync(recursive: true);
      });

      await command.run(packageNames: ['dio']);

      // After the command finishes the working dir should be deleted.
      expect(capturedSourcePath, isNotNull);
      expect(env.fs.directory(capturedSourcePath!).existsSync(), isFalse);
    });

    test('multiple packages at the same time', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubspec.addDependency('http', '1.2.0');
      env.pubGet();
      final result = await command.run(packageNames: ['dio', 'http']);

      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              source: '$_pubCacheBase/dio-5.3.2/',
              version: '5.3.2',
              cacheStatus: CacheStatus.miss,
            ),
            'http': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/http',
              source: '$_pubCacheBase/http-1.2.0/',
              version: '1.2.0',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );

      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.3.2',
        ),
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/http/http-1.2.0',
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(env.fs.directory('$_cacheDir/dio/dio-5.3.2').existsSync(), isTrue);
      expect(
        env.fs.directory('$_cacheDir/http/http-1.2.0').existsSync(),
        isTrue,
      );
      expect(env.fs.link('$_projectRoot/.pubdoc/dio').existsSync(), isTrue);
      expect(
        env.fs.link('$_projectRoot/.pubdoc/dio').targetSync(),
        '$_cacheDir/dio/dio-5.3.2',
      );
      expect(env.fs.link('$_projectRoot/.pubdoc/http').existsSync(), isTrue);
      expect(
        env.fs.link('$_projectRoot/.pubdoc/http').targetSync(),
        '$_cacheDir/http/http-1.2.0',
      );
    });

    test('useCache=true reuses cache on second run if available', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      await command.run(packageNames: ['dio']);
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.3.2',
        ),
      );

      reset(generator);
      final result = await command.run(packageNames: ['dio']);
      verifyNoMoreInteractions(generator);
      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              source: '$_pubCacheBase/dio-5.3.2/',
              version: '5.3.2',
              cacheStatus: CacheStatus.hit,
            ),
          },
        ),
      );
    });

    test('useCache=false always generates even when cache exists', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      // First run populates cache.
      await makeCommand(strategy: .exact).run(packageNames: ['dio']);

      final cacheDir = '$_cacheDir/dio/dio-5.3.2';
      final projectCacheDir = '$_projectRoot/.pubdoc';
      expect(env.fs.directory('$_cacheDir/dio/dio-5.3.2').existsSync(), isTrue);
      expect(env.fs.link('$projectCacheDir/dio').existsSync(), isTrue);
      expect(env.fs.link('$projectCacheDir/dio').targetSync(), cacheDir);

      reset(generator);
      final result = await makeCommand(
        strategy: .exact,
        useCache: false,
      ).run(packageNames: ['dio']);

      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.3.2',
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              version: '5.3.2',
              source: '$_pubCacheBase/dio-5.3.2/',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );
    });
  });

  group('Resolution strategy - exact', () {
    late GetCommand command;

    setUp(() {
      command = makeCommand(strategy: .exact);
    });

    test('patch bump creates separate cache dir', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      await command.run(packageNames: ['dio']);
      // Update to a new patch version.
      env.pubspec.addDependency('dio', '5.3.6');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              version: '5.3.6',
              source: '$_pubCacheBase/dio-5.3.6/',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );

      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.3.2',
        ),
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.3.6',
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(
        env.fs.directory('$_cacheDir/dio/dio-5.3.6').existsSync(),
        isTrue,
        reason: 'Patch bump should create a separate cache dir.',
      );
      expect(
        env.fs.directory('$_cacheDir/dio/dio-5.3.2').existsSync(),
        isTrue,
        reason: 'Original cache dir should still exist.',
      );

      expect(
        CacheMetadata.read('$_cacheDir/dio/dio-5.3.2', fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.3.2', pkgVersion: '5.3.2'),
      );
      expect(
        CacheMetadata.read('$_cacheDir/dio/dio-5.3.6', fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.3.6', pkgVersion: '5.3.6'),
      );
    });
  });

  group('Resolution strategy - loosePatch', () {
    late GetCommand command;

    setUp(() {
      command = makeCommand(strategy: .loosePatch);
    });

    test('correct cache dir and full metadata', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              source: '$_pubCacheBase/dio-5.3.2/',
              version: '5.3.x',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );

      final cacheDir = '$_cacheDir/dio/dio-5.3.x';
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: cacheDir,
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(env.fs.directory(cacheDir).existsSync(), isTrue);
      expect(env.fs.link('$_projectRoot/.pubdoc/dio').existsSync(), isTrue);
      expect(env.fs.link('$_projectRoot/.pubdoc/dio').targetSync(), cacheDir);
      expect(
        CacheMetadata.read(cacheDir, fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.3.x', pkgVersion: '5.3.2'),
      );
    });

    test('patch bump regenerates in same cache dir', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      await command.run(packageNames: ['dio']);
      env.pubspec.addDependency('dio', '5.3.6');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              source: '$_pubCacheBase/dio-5.3.6/',
              version: '5.3.x',
              cacheStatus: CacheStatus.refreshed,
            ),
          },
        ),
      );

      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.3.x',
        ),
      ).called(2);
      verifyNoMoreInteractions(generator);
      expect(
        CacheMetadata.read('$_cacheDir/dio/dio-5.3.x', fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.3.x', pkgVersion: '5.3.6'),
      );
    });

    test('patch bump reuses cache when cached version is compatible', () async {
      // Generate docs for a newer patch version first.
      env.pubspec.addDependency('dio', '5.3.6');
      env.pubGet();
      await command.run(packageNames: ['dio']);
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.3.x',
        ),
      );

      // Bump to an older compatible patch version.
      reset(generator);
      env.pubspec.addDependency('dio', '5.3.3');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      verifyNoMoreInteractions(generator);
      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              source: '$_pubCacheBase/dio-5.3.6/',
              version: '5.3.x',
              cacheStatus: CacheStatus.hit,
            ),
          },
        ),
      );
      expect(
        CacheMetadata.read('$_cacheDir/dio/dio-5.3.x', fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.3.x', pkgVersion: '5.3.6'),
      );
    });

    test('minor bump creates separate cache dir', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      await command.run(packageNames: ['dio']);
      // Update to a new minor version.
      env.pubspec.addDependency('dio', '5.4.0');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              source: '$_pubCacheBase/dio-5.4.0/',
              version: '5.4.x',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );

      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.3.x',
        ),
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.4.x',
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(env.fs.directory('$_cacheDir/dio/dio-5.3.x').existsSync(), isTrue);
      expect(env.fs.directory('$_cacheDir/dio/dio-5.4.x').existsSync(), isTrue);
      expect(
        CacheMetadata.read('$_cacheDir/dio/dio-5.3.x', fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.3.x', pkgVersion: '5.3.2'),
      );
      expect(
        CacheMetadata.read('$_cacheDir/dio/dio-5.4.x', fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.4.x', pkgVersion: '5.4.0'),
      );
    });
  });

  group('Resolution strategy - looseMinor', () {
    late GetCommand command;

    setUp(() {
      command = makeCommand(strategy: .looseMinor);
    });

    test('correct cache dir and full metadata', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              source: '$_pubCacheBase/dio-5.3.2/',
              version: '5.x',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );

      final cacheDir = '$_cacheDir/dio/dio-5.x';
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: cacheDir,
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(env.fs.directory(cacheDir).existsSync(), isTrue);
      expect(env.fs.link('$_projectRoot/.pubdoc/dio').existsSync(), isTrue);
      expect(env.fs.link('$_projectRoot/.pubdoc/dio').targetSync(), cacheDir);
      expect(
        CacheMetadata.read(cacheDir, fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.x', pkgVersion: '5.3.2'),
      );
    });

    test('minor bump regenerates in same cache dir', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      await command.run(packageNames: ['dio']);
      // Update to a new minor version.
      env.pubspec.addDependency('dio', '5.4.0');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              source: '$_pubCacheBase/dio-5.4.0/',
              version: '5.x',
              cacheStatus: CacheStatus.refreshed,
            ),
          },
        ),
      );

      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.x',
        ),
      ).called(2);
      verifyNoMoreInteractions(generator);
      expect(
        CacheMetadata.read('$_cacheDir/dio/dio-5.x', fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.x', pkgVersion: '5.4.0'),
      );
    });

    test('minor bump reuses cache when cached version is newer', () async {
      // Generate docs for a newer minor version first.
      env.pubspec.addDependency('dio', '5.4.0');
      env.pubGet();
      await command.run(packageNames: ['dio']);
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.x',
        ),
      );

      // Bump to an older compatible minor version.
      reset(generator);
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);
      verifyNoMoreInteractions(generator);
      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              source: '$_pubCacheBase/dio-5.4.0/',
              version: '5.x',
              cacheStatus: CacheStatus.hit,
            ),
          },
        ),
      );
      expect(
        CacheMetadata.read('$_cacheDir/dio/dio-5.x', fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.x', pkgVersion: '5.4.0'),
      );
    });

    test('major bump creates separate cache dir', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      await command.run(packageNames: ['dio']);
      // Update to a new major version.
      env.pubspec.addDependency('dio', '6.0.0');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              source: '$_pubCacheBase/dio-6.0.0/',
              version: '6.x',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );

      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-5.x',
        ),
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-6.x',
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(env.fs.directory('$_cacheDir/dio/dio-5.x').existsSync(), isTrue);
      expect(env.fs.directory('$_cacheDir/dio/dio-6.x').existsSync(), isTrue);
      expect(
        CacheMetadata.read('$_cacheDir/dio/dio-5.x', fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '5.x', pkgVersion: '5.3.2'),
      );
      expect(
        CacheMetadata.read('$_cacheDir/dio/dio-6.x', fs: env.fs),
        _isCacheMetadata(pkgName: 'dio', version: '6.x', pkgVersion: '6.0.0'),
      );
    });
  });

  group('Pre-release versions', () {
    test('exact with pre-release', () async {
      final command = makeCommand(strategy: .exact);
      env.pubspec.addDependency('dio', '1.0.0-dev.1');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      final cacheDir = '$_cacheDir/dio/dio-1.0.0-dev.1';
      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              version: '1.0.0-dev.1',
              source: '$_pubCacheBase/dio-1.0.0-dev.1/',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: cacheDir,
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(env.fs.directory(cacheDir).existsSync(), isTrue);
      expect(env.fs.link('$_projectRoot/.pubdoc/dio').existsSync(), isTrue);
      expect(env.fs.link('$_projectRoot/.pubdoc/dio').targetSync(), cacheDir);
      expect(
        CacheMetadata.read(cacheDir, fs: env.fs),
        _isCacheMetadata(
          pkgName: 'dio',
          version: '1.0.0-dev.1',
          pkgVersion: '1.0.0-dev.1',
        ),
      );
    });

    test('loosePatch with pre-release uses exact version', () async {
      final command = makeCommand(strategy: .loosePatch);
      env.pubspec.addDependency('dio', '1.0.0-dev.1');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              version: '1.0.0-dev.1',
              source: '$_pubCacheBase/dio-1.0.0-dev.1/',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );
      final cacheDir = '$_cacheDir/dio/dio-1.0.0-dev.1';
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: cacheDir,
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(
        CacheMetadata.read(cacheDir, fs: env.fs),
        _isCacheMetadata(
          pkgName: 'dio',
          version: '1.0.0-dev.1',
          pkgVersion: '1.0.0-dev.1',
        ),
      );
    });

    test('looseMinor with pre-release uses exact version', () async {
      final command = makeCommand(strategy: .looseMinor);
      env.pubspec.addDependency('dio', '1.0.0-dev.1');
      env.pubGet();
      final result = await command.run(packageNames: ['dio']);

      final cacheDir = '$_cacheDir/dio/dio-1.0.0-dev.1';
      expect(
        result,
        _isGetResult(
          packages: {
            'dio': _isPackageGetResult(
              documentation: '$_projectRoot/.pubdoc/dio',
              version: '1.0.0-dev.1',
              source: '$_pubCacheBase/dio-1.0.0-dev.1/',
              cacheStatus: CacheStatus.miss,
            ),
          },
        ),
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: cacheDir,
        ),
      );
      verifyNoMoreInteractions(generator);
      expect(
        CacheMetadata.read(cacheDir, fs: env.fs),
        _isCacheMetadata(
          pkgName: 'dio',
          version: '1.0.0-dev.1',
          pkgVersion: '1.0.0-dev.1',
        ),
      );
    });

    test('never share docs with stable versions', () async {
      final command = makeCommand(strategy: .looseMinor);

      // First: pre-release version
      env.pubspec.addDependency('dio', '1.0.0-dev.1');
      env.pubGet();
      await command.run(packageNames: ['dio']);

      // Then: stable version
      env.pubspec.addDependency('dio', '1.0.0');
      env.pubGet();
      await command.run(packageNames: ['dio']);

      verifyInOrder([
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-1.0.0-dev.1',
        ),
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '$_cacheDir/dio/dio-1.x',
        ),
      ]);
      verifyNoMoreInteractions(generator);
      expect(
        env.fs.directory('$_cacheDir/dio/dio-1.0.0-dev.1').existsSync(),
        isTrue,
      );
      expect(env.fs.directory('$_cacheDir/dio/dio-1.x').existsSync(), isTrue);
    });
  });

  group('Error cases', () {
    late GetCommand command;

    setUp(() {
      command = makeCommand(strategy: .exact);
    });
    test('empty package list throws an exception', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      expect(
        () => command.run(packageNames: []),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            'No packages specified. Usage: pubdoc get <package1> [package2 ...]',
          ),
        ),
      );
    });

    test('missing pubspec.lock throws an exception', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      env.pubspecLock.deleteSync();

      expect(
        () => command.run(packageNames: ['dio']),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            'pubspec.lock not found in $_projectRoot. Run `dart pub get` first.',
          ),
        ),
      );
    });

    test('missing package_config.json throws an exception', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      env.packageConfig.deleteSync();

      expect(
        () => command.run(packageNames: ['dio']),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            '.dart_tool/package_config.json not found. Run `dart pub get` first.',
          ),
        ),
      );
    });

    test('missing pubspec.yaml throws an exception', () {
      env.fs.file('$_projectRoot/pubspec.yaml').deleteSync();
      expect(
        () => ProjectContext.from(_projectRoot, env: env),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            'pubspec.yaml not found in $_projectRoot.\n'
                'Make sure the working directory is the root of a Dart/Flutter project, '
                'or specify the project path via --project option.',
          ),
        ),
      );
    });

    test('package not in pubspec.lock throws an exception', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      expect(
        () => command.run(packageNames: ['unknown_pkg']),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            "Package 'unknown_pkg' not found in pubspec.lock.",
          ),
        ),
      );
    });

    test('doc generation failure throws an exception', () async {
      when(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: anyNamed('outputDir'),
        ),
      ).thenThrow(Exception('dartdoc crashed'));

      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      expect(
        () => command.run(packageNames: ['dio']),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            contains('Failed to generate documentation for dio'),
          ),
        ),
      );
    });

    test('package not in package_config.json throws an exception', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubspec.addDependency('missing_pkg', '1.0.0');
      env.pubGet();

      // Remove missing_pkg from package_config.json only.
      env.packageConfig.removePackage('missing_pkg');
      env.packageConfig.write();

      expect(
        () => command.run(packageNames: ['missing_pkg']),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            "Package 'missing_pkg' not found in package_config.json.",
          ),
        ),
      );
    });
  });

  group('Workspace support', () {
    const workspaceRoot = '/Users/testuser/projects/my_workspace';
    const memberRelativePath = 'packages/my_app';
    const memberRoot = '$workspaceRoot/$memberRelativePath';

    late WorkspaceTestEnvironment env;

    GetCommand commandFor(String projectRoot) {
      return GetCommand(
        project: ProjectContext.from(projectRoot, env: env),
        config: PubdocConfig(homeDir: _homeDir, cacheDir: _cacheDir),
        env: env,
        generator: generator,
        strategy: .exact,
      );
    }

    setUp(() {
      env = WorkspaceTestEnvironment(
        workspaceRoot: workspaceRoot,
        memberRelativePath: memberRelativePath,
        pubCacheBase: _pubCacheBase,
      )..setUp();
      when(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: anyNamed('outputDir'),
        ),
      ).thenAnswer((invocation) async {
        final outputDir = invocation.namedArguments[#outputDir] as String;
        env.fs.directory(outputDir).createSync(recursive: true);
      });
    });

    test('running from workspace root uses workspace root', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      await commandFor(workspaceRoot).run(packageNames: ['dio']);

      expect(env.fs.link('$workspaceRoot/.pubdoc/dio').existsSync(), isTrue);
    });

    test('running from workspace member uses workspace root', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      await commandFor(memberRoot).run(packageNames: ['dio']);

      expect(env.fs.link('$workspaceRoot/.pubdoc/dio').existsSync(), isTrue);
      expect(
        env.fs.link('$memberRoot/.pubdoc/dio').existsSync(),
        isFalse,
        reason:
            'Cache link should be created in workspace root, not member root.',
      );
    });

    test(
      'missing pubspec.lock from workspace root names workspace root',
      () async {
        env.pubspec.addDependency('dio', '5.3.2');
        env.pubGet();
        env.pubspecLock.deleteSync();

        expect(
          () => commandFor(memberRoot).run(packageNames: ['dio']),
          throwsA(
            isA<PubdocException>().having(
              (e) => e.message,
              'message',
              'pubspec.lock not found in $workspaceRoot. Run `dart pub get` first.',
            ),
          ),
        );
      },
    );

    test('no workspace root found throws PubdocException', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();
      // Delete the workspace root pubspec.yaml so the walk finds nothing.
      env.fs.file('$workspaceRoot/pubspec.yaml').deleteSync();

      expect(
        () => commandFor(memberRoot).run(packageNames: ['dio']),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            'pubspec.yaml in $memberRoot declares `resolution: workspace`, '
                'but no workspace root (pubspec.yaml with `workspace:` key) was found '
                'in the parent directories.',
          ),
        ),
      );
    });
  });
}

Matcher _isCacheMetadata({
  required String version,
  required String pkgName,
  required String pkgVersion,
}) {
  return isA<CacheMetadata>()
      .having((m) => m.version, 'version', version)
      .having((m) => m.packageVersion, 'packageVersion', pkgVersion)
      .having(
        (m) => m.source,
        'source',
        'file://$_pubCacheBase/$pkgName-$pkgVersion/',
      );
}

Matcher _isGetResult({required Map<String, Matcher> packages}) {
  return isA<GetResult>().having(
    (r) => r.packages,
    'packages',
    allOf([
      for (final entry in packages.entries)
        containsPair(entry.key, entry.value),
    ]),
  );
}

Matcher _isPackageGetResult({
  required String documentation,
  required String source,
  required String version,
  required CacheStatus cacheStatus,
}) {
  return isA<PackageGetResult>()
      .having((r) => r.documentation, 'documentation', documentation)
      .having((r) => r.source, 'source', source)
      .having((r) => r.version, 'version', version)
      .having((r) => r.cacheStatus, 'cacheStatus', cacheStatus);
}
