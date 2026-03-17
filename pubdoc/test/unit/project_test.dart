import 'dart:convert';

import 'package:file/memory.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubdoc/src/exceptions.dart';
import 'package:pubdoc/src/project.dart';
import 'package:test/test.dart';

import '../integration/src/test_environment.dart';

const _projectRoot = '/project';
const _pubCacheBase = '/pub-cache';

void main() {
  late TestEnvironment env;
  late ProjectContext project;

  setUp(() {
    env = TestEnvironment(
      projectRoot: _projectRoot,
      pubCacheBase: _pubCacheBase,
    );
    project = ProjectContext(_projectRoot, env: env);
  });

  group('getPackageVersion', () {
    test('returns version for a known package', () async {
      env.pubspec.addDependency('dio', '5.7.0');
      env.pubGet();

      final version = await project.getPackageVersion('dio');

      expect(version, Version.parse('5.7.0'));
    });

    test(
      'finds the correct package when multiple packages are present',
      () async {
        env.pubspec.addDependency('dio', '5.7.0');
        env.pubspec.addDependency('http', '1.2.0');
        env.pubspec.addDependency('path', '1.9.0');
        env.pubGet();

        expect(await project.getPackageVersion('dio'), Version.parse('5.7.0'));
        expect(await project.getPackageVersion('http'), Version.parse('1.2.0'));
        expect(await project.getPackageVersion('path'), Version.parse('1.9.0'));
      },
    );

    test('throws PubdocException when package is not found', () async {
      env.pubspec.addDependency('dio', '5.7.0');
      env.pubGet();

      expect(
        () => project.getPackageVersion('http'),
        throwsA(isA<PubdocException>()),
      );
    });
  });

  group('getPackageSourceDir', () {
    test('returns directory for a known package with absolute URI', () async {
      env.pubspec.addDependency('dio', '5.7.0');
      env.pubGet();

      final dir = await project.getPackageSourceDir('dio');

      expect(dir.path, '$_pubCacheBase/dio-5.7.0/');
    });

    test(
      'finds the correct package when multiple packages are present',
      () async {
        env.pubspec.addDependency('dio', '5.7.0');
        env.pubspec.addDependency('http', '1.2.0');
        env.pubGet();

        final dioDir = await project.getPackageSourceDir('dio');
        final httpDir = await project.getPackageSourceDir('http');

        expect(dioDir.path, '$_pubCacheBase/dio-5.7.0/');
        expect(httpDir.path, '$_pubCacheBase/http-1.2.0/');
      },
    );

    test(
      'resolves relative rootUri against package_config.json location',
      () async {
        // Write package_config.json manually with a relative rootUri.
        final configFile = env.fs.file(
          '$_projectRoot/.dart_tool/package_config.json',
        );
        configFile.parent.createSync(recursive: true);
        configFile.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert({
            'configVersion': 2,
            'packages': [
              {
                'name': 'my_pkg',
                'rootUri': '../some/relative/path/',
                'packageUri': 'lib/',
              },
            ],
          }),
        );

        final dir = await project.getPackageSourceDir('my_pkg');

        // .dart_tool/../some/relative/path -> /project/some/relative/path
        // The trailing slash comes from the rootUri ending with '/'.
        expect(dir.path, '$_projectRoot/some/relative/path/');
      },
    );

    test('throws PubdocException when package is not found', () async {
      env.pubspec.addDependency('dio', '5.7.0');
      env.pubGet();

      expect(
        () => project.getPackageSourceDir('http'),
        throwsA(isA<PubdocException>()),
      );
    });
  });
}
