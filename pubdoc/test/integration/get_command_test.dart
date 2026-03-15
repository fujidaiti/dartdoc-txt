import 'dart:convert';

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

void main() {
  late TestEnvironment env;
  late MockDocGenerator generator;
  late GetCommand command;

  setUp(() {
    env = TestEnvironment();

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

    command = GetCommand(
      project: ProjectContext(TestEnvironment.projectRoot, fs: env.fs),
      config: PubdocConfig(
        homeDir: TestEnvironment.homeDir,
        cacheDir: TestEnvironment.cacheDir,
      ),
      fs: env.fs,
      generator: generator,
    );
  });

  group('Happy path', () {
    test('single package generation', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      await command.run(['dio']);

      // Cache dir created with metadata.json
      final cacheDir = '${TestEnvironment.cacheDir}/dio/dio-5.3.x';
      expect(env.fs.directory(cacheDir).existsSync(), isTrue);
      final metadata = CacheMetadata.read(cacheDir, fs: env.fs);
      expect(metadata, isNotNull);
      expect(metadata!.version, '5.3.x');
      expect(metadata.packageVersion, '5.3.2');

      // Symlink created
      final link = env.fs.link('${TestEnvironment.projectRoot}/.pubdoc/dio');
      expect(link.existsSync(), isTrue);
      expect(link.targetSync(), cacheDir);

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

      await command.run(['dio', 'http']);

      expect(
        env.fs
            .directory('${TestEnvironment.cacheDir}/dio/dio-5.3.x')
            .existsSync(),
        isTrue,
      );
      expect(
        env.fs
            .directory('${TestEnvironment.cacheDir}/http/http-1.2.x')
            .existsSync(),
        isTrue,
      );
      expect(
        env.fs.link('${TestEnvironment.projectRoot}/.pubdoc/dio').existsSync(),
        isTrue,
      );
      expect(
        env.fs.link('${TestEnvironment.projectRoot}/.pubdoc/http').existsSync(),
        isTrue,
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '${TestEnvironment.cacheDir}/dio/dio-5.3.x',
        ),
      );
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '${TestEnvironment.cacheDir}/http/http-1.2.x',
        ),
      );
      verifyNoMoreInteractions(generator);
    });

    test('cache reuse on second run', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      await command.run(['dio']);

      // Second run should reuse cache.
      await command.run(['dio']);
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '${TestEnvironment.cacheDir}/dio/dio-5.3.x',
        ),
      );
      verifyNoMoreInteractions(generator);
    });

    test('cache regeneration on version bump', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      await command.run(['dio']);

      // Bump version to 5.3.6 — same doc version (5.3.x) but newer package
      // version triggers regeneration.
      env.pubspec.addDependency('dio', '5.3.6');
      env.pubGet();

      await command.run(['dio']);
      verify(
        generator.generate(
          sourcePath: anyNamed('sourcePath'),
          outputDir: '${TestEnvironment.cacheDir}/dio/dio-5.3.x',
        ),
      ).called(2);
      verifyNoMoreInteractions(generator);

      final metadata = CacheMetadata.read(
        '${TestEnvironment.cacheDir}/dio/dio-5.3.x',
        fs: env.fs,
      );
      expect(
        metadata!.packageVersion,
        '5.3.6',
        reason:
            'Metadata should reflect the new package version after regeneration.',
      );
    });
  });

  group('Error cases', () {
    test('empty package list throws PubdocException', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      expect(
        () => command.run([]),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            'No packages specified. Usage: pubdoc get <package1> [package2 ...]',
          ),
        ),
      );
    });

    test('missing pubspec.lock throws PubdocException', () async {
      // Only write package_config.json, not pubspec.lock.
      env.packageConfig.parent.createSync(recursive: true);
      env.packageConfig.writeAsStringSync(
        jsonEncode({'configVersion': 2, 'packages': []}),
      );

      expect(
        () => command.run(['dio']),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            'pubspec.lock not found in ${TestEnvironment.projectRoot}. Run `dart pub get` first.',
          ),
        ),
      );
    });

    test('missing package_config.json throws PubdocException', () async {
      // Only write pubspec.lock, not package_config.json.
      env.pubspec.addDependency('dio', '5.3.2');
      // Manually write just pubspec.lock via pubGet internals isn't available,
      // so write it directly.
      final buffer = jsonEncode({
        'packages': {
          'dio': {'dependency': 'direct main', 'version': '5.3.2'},
        },
      });
      env.pubspecLock.parent.createSync(recursive: true);
      env.pubspecLock.writeAsStringSync(buffer);

      expect(
        () => command.run(['dio']),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            '.dart_tool/package_config.json not found. Run `dart pub get` first.',
          ),
        ),
      );
    });

    test('package not in pubspec.lock throws PubdocException', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubGet();

      expect(
        () => command.run(['unknown_pkg']),
        throwsA(
          isA<PubdocException>().having(
            (e) => e.message,
            'message',
            "Package 'unknown_pkg' not found in pubspec.lock.",
          ),
        ),
      );
    });

    test('package not in package_config.json throws PubdocException', () async {
      env.pubspec.addDependency('dio', '5.3.2');
      env.pubspec.addDependency('missing_pkg', '1.0.0');
      env.pubGet();

      // Remove missing_pkg from package_config.json only.
      final config =
          jsonDecode(env.packageConfig.readAsStringSync())
              as Map<String, dynamic>;
      final packages = (config['packages'] as List)
          .where((p) => (p as Map)['name'] != 'missing_pkg')
          .toList();
      env.packageConfig.writeAsStringSync(
        jsonEncode({'configVersion': 2, 'packages': packages}),
      );

      expect(
        () => command.run(['missing_pkg']),
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

  group('Resolution strategies', () {
    GetCommand makeCommand(TestEnvironment env, ResolutionStrategy strategy) {
      return GetCommand(
        project: ProjectContext(TestEnvironment.projectRoot, fs: env.fs),
        config: PubdocConfig(
          homeDir: TestEnvironment.homeDir,
          cacheDir: TestEnvironment.cacheDir,
        ),
        fs: env.fs,
        generator: generator,
        strategy: strategy,
      );
    }

    group('exact', () {
      test('correct cache dir and full metadata', () async {
        env = TestEnvironment();
        final command = makeCommand(env, ResolutionStrategy.exact);
        env.pubspec.addDependency('dio', '5.3.2');
        env.pubGet();

        await command.run(['dio']);

        final cacheDir = '${TestEnvironment.cacheDir}/dio/dio-5.3.2';
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
          'file://${TestEnvironment.pubCacheBase}/dio-5.3.2/',
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

      test('patch bump creates separate cache dir', () async {
        env = TestEnvironment();
        final command = makeCommand(env, ResolutionStrategy.exact);
        env.pubspec.addDependency('dio', '5.3.2');
        env.pubGet();

        await command.run(['dio']);

        env.pubspec.addDependency('dio', '5.3.6');
        env.pubGet();

        await command.run(['dio']);
        verify(
          generator.generate(
            sourcePath: anyNamed('sourcePath'),
            outputDir: '${TestEnvironment.cacheDir}/dio/dio-5.3.2',
          ),
        );
        verify(
          generator.generate(
            sourcePath: anyNamed('sourcePath'),
            outputDir: '${TestEnvironment.cacheDir}/dio/dio-5.3.6',
          ),
        );
        verifyNoMoreInteractions(generator);

        expect(
          env.fs
              .directory('${TestEnvironment.cacheDir}/dio/dio-5.3.2')
              .existsSync(),
          isTrue,
          reason: 'Original cache dir should still exist.',
        );
        expect(
          env.fs
              .directory('${TestEnvironment.cacheDir}/dio/dio-5.3.6')
              .existsSync(),
          isTrue,
          reason: 'Patch bump should create a separate cache dir.',
        );
      });
    });

    group('loosePatch', () {
      test('correct cache dir and full metadata', () async {
        env = TestEnvironment();
        final command = makeCommand(env, ResolutionStrategy.loosePatch);
        env.pubspec.addDependency('dio', '5.3.2');
        env.pubGet();

        await command.run(['dio']);

        final cacheDir = '${TestEnvironment.cacheDir}/dio/dio-5.3.x';
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
          'file://${TestEnvironment.pubCacheBase}/dio-5.3.2/',
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
        env = TestEnvironment();
        final command = makeCommand(env, ResolutionStrategy.loosePatch);
        env.pubspec.addDependency('dio', '5.3.2');
        env.pubGet();

        await command.run(['dio']);

        env.pubspec.addDependency('dio', '5.3.6');
        env.pubGet();

        await command.run(['dio']);
        verify(
          generator.generate(
            sourcePath: anyNamed('sourcePath'),
            outputDir: '${TestEnvironment.cacheDir}/dio/dio-5.3.x',
          ),
        ).called(2);
        verifyNoMoreInteractions(generator);

        final metadata = CacheMetadata.read(
          '${TestEnvironment.cacheDir}/dio/dio-5.3.x',
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
        env = TestEnvironment();
        final command = makeCommand(env, ResolutionStrategy.loosePatch);
        env.pubspec.addDependency('dio', '5.3.2');
        env.pubGet();

        await command.run(['dio']);

        env.pubspec.addDependency('dio', '5.4.0');
        env.pubGet();

        await command.run(['dio']);
        verify(
          generator.generate(
            sourcePath: anyNamed('sourcePath'),
            outputDir: '${TestEnvironment.cacheDir}/dio/dio-5.3.x',
          ),
        );
        verify(
          generator.generate(
            sourcePath: anyNamed('sourcePath'),
            outputDir: '${TestEnvironment.cacheDir}/dio/dio-5.4.x',
          ),
        );
        verifyNoMoreInteractions(generator);

        expect(
          env.fs
              .directory('${TestEnvironment.cacheDir}/dio/dio-5.3.x')
              .existsSync(),
          isTrue,
          reason: 'Original cache dir should still exist.',
        );
        expect(
          env.fs
              .directory('${TestEnvironment.cacheDir}/dio/dio-5.4.x')
              .existsSync(),
          isTrue,
          reason: 'Minor bump should create a separate cache dir.',
        );
      });
    });

    group('looseMinor', () {
      test('correct cache dir and full metadata', () async {
        env = TestEnvironment();
        final command = makeCommand(env, ResolutionStrategy.looseMinor);
        env.pubspec.addDependency('dio', '5.3.2');
        env.pubGet();

        await command.run(['dio']);

        final cacheDir = '${TestEnvironment.cacheDir}/dio/dio-5.x';
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
          'file://${TestEnvironment.pubCacheBase}/dio-5.3.2/',
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
        env = TestEnvironment();
        final command = makeCommand(env, ResolutionStrategy.looseMinor);
        env.pubspec.addDependency('dio', '5.3.2');
        env.pubGet();

        await command.run(['dio']);

        env.pubspec.addDependency('dio', '5.4.0');
        env.pubGet();

        await command.run(['dio']);
        verify(
          generator.generate(
            sourcePath: anyNamed('sourcePath'),
            outputDir: '${TestEnvironment.cacheDir}/dio/dio-5.x',
          ),
        ).called(2);
        verifyNoMoreInteractions(generator);

        final metadata = CacheMetadata.read(
          '${TestEnvironment.cacheDir}/dio/dio-5.x',
          fs: env.fs,
        );
        expect(
          metadata!.packageVersion,
          '5.4.0',
          reason:
              'Metadata should reflect the new package version after regeneration.',
        );
      });

      test('major bump creates separate cache dir', () async {
        env = TestEnvironment();
        final command = makeCommand(env, ResolutionStrategy.looseMinor);
        env.pubspec.addDependency('dio', '5.3.2');
        env.pubGet();

        await command.run(['dio']);

        env.pubspec.addDependency('dio', '6.0.0');
        env.pubGet();

        await command.run(['dio']);
        verify(
          generator.generate(
            sourcePath: anyNamed('sourcePath'),
            outputDir: '${TestEnvironment.cacheDir}/dio/dio-5.x',
          ),
        );
        verify(
          generator.generate(
            sourcePath: anyNamed('sourcePath'),
            outputDir: '${TestEnvironment.cacheDir}/dio/dio-6.x',
          ),
        );
        verifyNoMoreInteractions(generator);

        expect(
          env.fs
              .directory('${TestEnvironment.cacheDir}/dio/dio-5.x')
              .existsSync(),
          isTrue,
          reason: 'Original cache dir should still exist.',
        );
        expect(
          env.fs
              .directory('${TestEnvironment.cacheDir}/dio/dio-6.x')
              .existsSync(),
          isTrue,
          reason: 'Major bump should create a separate cache dir.',
        );
      });
    });
  });
}
