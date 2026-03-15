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
      expect(
        env.fs.directory(cacheDir).existsSync(),
        isTrue,
        reason: 'Cache dir should use exact version: dio-5.3.2',
      );
      final metadata = CacheMetadata.read(cacheDir, fs: env.fs);
      expect(metadata, isNotNull, reason: 'metadata.json should exist');
      expect(
        metadata!.version,
        '5.3.2',
        reason: 'Doc version should be the exact version string.',
      );
      expect(
        metadata.packageVersion,
        '5.3.2',
        reason: 'Package version should match the resolved version.',
      );
      expect(
        metadata.source,
        'file://$_pubCacheBase/dio-5.3.2/',
        reason: 'Source should point to the pub cache directory.',
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: cacheDir,
        ),
      );
      verifyNoMoreInteractions(generator);
    });

    test('multiple packages', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubspec.addDependency('http', '1.2.0');
      env.pubGet();

      await command.run(packageNames: ['dio', 'http']);

      expect(env.fs.directory('$_cacheDir/dio/dio-5.3.2').existsSync(), isTrue);
      expect(
        env.fs.directory('$_cacheDir/http/http-1.2.0').existsSync(),
        isTrue,
      );
      expect(env.fs.link('$_projectRoot/.pubdoc/dio').existsSync(), isTrue);
      expect(env.fs.link('$_projectRoot/.pubdoc/http').existsSync(), isTrue);
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
    test('patch bump creates separate cache dir', () async {
      final command = makeCommand(strategy: .exact);
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      await command.run(packageNames: ['dio']);

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
        env.fs.directory('$_cacheDir/dio/dio-5.3.2').existsSync(),
        isTrue,
        reason: 'Original cache dir should still exist.',
      );
      expect(
        env.fs.directory('$_cacheDir/dio/dio-5.3.6').existsSync(),
        isTrue,
        reason: 'Patch bump should create a separate cache dir.',
      );
    });
  });

  group('Resolution strategy - loosePatch', () {
    test('correct cache dir and full metadata', () async {
      final command = makeCommand(strategy: .loosePatch);
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      await command.run(packageNames: ['dio']);

      final cacheDir = '$_cacheDir/dio/dio-5.3.x';
      expect(
        env.fs.directory(cacheDir).existsSync(),
        isTrue,
        reason: 'Cache dir should use wildcard patch: dio-5.3.x',
      );
      final metadata = CacheMetadata.read(cacheDir, fs: env.fs);
      expect(metadata, isNotNull, reason: 'metadata.json should exist');
      expect(
        metadata!.version,
        '5.3.x',
        reason: 'Doc version should wildcard the patch segment.',
      );
      expect(
        metadata.packageVersion,
        '5.3.2',
        reason: 'Package version should match the resolved version.',
      );
      expect(
        metadata.source,
        'file://$_pubCacheBase/dio-5.3.2/',
        reason: 'Source should point to the pub cache directory.',
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: cacheDir,
        ),
      );
      verifyNoMoreInteractions(generator);
    });

    test('patch bump regenerates in same cache dir', () async {
      final command = makeCommand(strategy: .loosePatch);
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

      final metadata = CacheMetadata.read(
        '$_cacheDir/dio/dio-5.3.x',
        fs: env.fs,
      );
      expect(
        metadata!.packageVersion,
        '5.3.6',
        reason:
            'Metadata should reflect the new package version after regeneration.',
      );
    });

    test('minor bump creates separate cache dir', () async {
      final command = makeCommand(strategy: .loosePatch);
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      await command.run(packageNames: ['dio']);

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

      expect(
        env.fs.directory('$_cacheDir/dio/dio-5.3.x').existsSync(),
        isTrue,
        reason: 'Original cache dir should still exist.',
      );
      expect(
        env.fs.directory('$_cacheDir/dio/dio-5.4.x').existsSync(),
        isTrue,
        reason: 'Minor bump should create a separate cache dir.',
      );
    });
  });

  group('Resolution strategy - looseMinor', () {
    test('correct cache dir and full metadata', () async {
      final command = makeCommand(strategy: .looseMinor);
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      await command.run(packageNames: ['dio']);

      final cacheDir = '$_cacheDir/dio/dio-5.x';
      expect(
        env.fs.directory(cacheDir).existsSync(),
        isTrue,
        reason: 'Cache dir should use wildcard minor: dio-5.x',
      );
      final metadata = CacheMetadata.read(cacheDir, fs: env.fs);
      expect(metadata, isNotNull, reason: 'metadata.json should exist');
      expect(
        metadata!.version,
        '5.x',
        reason: 'Doc version should wildcard the minor segment.',
      );
      expect(
        metadata.packageVersion,
        '5.3.2',
        reason: 'Package version should match the resolved version.',
      );
      expect(
        metadata.source,
        'file://$_pubCacheBase/dio-5.3.2/',
        reason: 'Source should point to the pub cache directory.',
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: cacheDir,
        ),
      );
      verifyNoMoreInteractions(generator);
    });

    test('minor bump regenerates in same cache dir', () async {
      final command = makeCommand(strategy: .looseMinor);
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      await command.run(packageNames: ['dio']);

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

      final metadata = CacheMetadata.read('$_cacheDir/dio/dio-5.x', fs: env.fs);
      expect(
        metadata!.packageVersion,
        '5.4.0',
        reason:
            'Metadata should reflect the new package version after regeneration.',
      );
    });

    test('major bump creates separate cache dir', () async {
      final command = makeCommand(strategy: .looseMinor);
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      await command.run(packageNames: ['dio']);

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

      expect(
        env.fs.directory('$_cacheDir/dio/dio-5.x').existsSync(),
        isTrue,
        reason: 'Original cache dir should still exist.',
      );
      expect(
        env.fs.directory('$_cacheDir/dio/dio-6.x').existsSync(),
        isTrue,
        reason: 'Major bump should create a separate cache dir.',
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
