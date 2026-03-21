import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  // Suppress logging from dartdoc.
  hierarchicalLoggingEnabled = true;
  Logger('dartdoc').level = Level.OFF;

  group('basic', () {
    late Map<String, String> generatedFiles;

    final fixturePath = p.join(
      Directory.current.path,
      'test',
      'integration',
      'fixture',
      'basic',
    );
    final goldensDir = p.join(
      Directory.current.path,
      'test',
      'integration',
      'golden',
      'basic',
    );

    setUpAll(() async {
      var docTree = await renderFixture(fixturePath);
      generatedFiles = collectFiles(docTree);
    });

    test('generated files match golden files', () {
      for (var entry in generatedFiles.entries) {
        var goldenFile = File(p.join(goldensDir, '${entry.key}.expect'));
        expect(
          goldenFile.existsSync(),
          isTrue,
          reason: 'Missing golden file for ${entry.key}',
        );
        expect(
          entry.value,
          equals(goldenFile.readAsStringSync()),
          reason: 'Content mismatch for ${entry.key}',
        );
      }
    });

    test('no stray golden files', () {
      var goldenFiles = Directory(goldensDir)
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => p.relative(f.path, from: goldensDir))
          .toSet();
      var expectedGoldens =
          generatedFiles.keys.map((k) => '$k.expect').toSet();
      expect(goldenFiles, equals(expectedGoldens));
    });
  });

  group('path', () {
    late Map<String, String> generatedFiles;

    final submoduleDir = p.join(
      Directory.current.path,
      'test',
      'integration',
      'fixture',
      'dart-core',
    );
    final fixturePath = p.join(submoduleDir, 'pkgs', 'path');
    final goldensDir = p.join(
      Directory.current.path,
      'test',
      'integration',
      'golden',
      'path',
    );

    setUpAll(() async {
      var pubspecFile = File(p.join(fixturePath, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        throw StateError(
          'dart-core submodule not initialized.\n'
          'Run: git submodule update --init\n'
          'Or:  fvm dart run test/integration/update_golden.dart',
        );
      }

      // Verify the submodule is at the pinned commit.
      var repoRoot = findRepoRoot(Directory.current.path);
      var relSubmodulePath = p.relative(submoduleDir, from: repoRoot);
      var lsTree = await Process.run(
        'git',
        ['ls-tree', 'HEAD', relSubmodulePath],
        workingDirectory: repoRoot,
      );
      var pinnedCommit =
          (lsTree.stdout as String).split(RegExp(r'\s+'))[2];
      var actualHead = await Process.run(
        'git',
        ['rev-parse', 'HEAD'],
        workingDirectory: submoduleDir,
      );
      var actualCommit = (actualHead.stdout as String).trim();
      if (pinnedCommit != actualCommit) {
        throw StateError(
          'dart-core submodule is at $actualCommit but should be at '
          '$pinnedCommit.\n'
          'Run: git submodule update --init',
        );
      }
      var docTree = await renderFixture(fixturePath);
      generatedFiles = collectFiles(docTree);
    });

    test('generated files match golden files', () {
      for (var entry in generatedFiles.entries) {
        var goldenFile = File(p.join(goldensDir, '${entry.key}.expect'));
        expect(
          goldenFile.existsSync(),
          isTrue,
          reason: 'Missing golden file for ${entry.key}',
        );
        expect(
          entry.value,
          equals(goldenFile.readAsStringSync()),
          reason: 'Content mismatch for ${entry.key}',
        );
      }
    });

    test('no stray golden files', () {
      var goldenFiles = Directory(goldensDir)
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => p.relative(f.path, from: goldensDir))
          .toSet();
      var expectedGoldens =
          generatedFiles.keys.map((k) => '$k.expect').toSet();
      expect(goldenFiles, equals(expectedGoldens));
    });
  });
}
