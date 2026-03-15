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
    );

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

  GetCommand makeCommand({required ResolutionStrategy strategy}) {
    return GetCommand(
      project: ProjectContext(_projectRoot, env: env),
      config: PubdocConfig(homeDir: _homeDir, cacheDir: _cacheDir),
      env: env,
      generator: generator,
      strategy: strategy,
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
      await command.run(packageNames: ['dio']);

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

    test('multiple packages at the same time', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubspec.addDependency('http', '1.2.0');
      env.pubGet();
      await command.run(packageNames: ['dio', 'http']);

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

    test('cache reuse on second run', () async {
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
      await command.run(packageNames: ['dio']);
      verifyNoMoreInteractions(generator);
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
      await command.run(packageNames: ['dio']);

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
      await command.run(packageNames: ['dio']);

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
      await command.run(packageNames: ['dio']);

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
      await command.run(packageNames: ['dio']);
      verifyNoMoreInteractions(generator);
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
      await command.run(packageNames: ['dio']);

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
      await command.run(packageNames: ['dio']);

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
      await command.run(packageNames: ['dio']);

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
      await command.run(packageNames: ['dio']);
      verifyNoMoreInteractions(generator);
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
      await command.run(packageNames: ['dio']);

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
