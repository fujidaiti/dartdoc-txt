import 'dart:io';

import 'package:dartdoc_builder/src/doc_tree.dart';
import 'package:dartdoc_builder/src/element_renderers.dart';
import 'package:dartdoc_builder/src/generate.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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
      final docTree = await buildDocs(RenderOptions(packageRoot: fixturePath));
      generatedFiles = _collectFiles(docTree);
    });

    test('generated files match golden files', () {
      for (final entry in generatedFiles.entries) {
        final goldenFile = File(p.join(goldensDir, '${entry.key}.expected'));
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
      final goldenFiles = Directory(goldensDir)
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => p.relative(f.path, from: goldensDir))
          .toSet();
      final expectedGoldens = generatedFiles.keys
          .map((k) => '$k.expected')
          .toSet();
      expect(goldenFiles, equals(expectedGoldens));
    });
  });

  group('path', () {
    late Map<String, String> generatedFiles;

    final fixturePath = p.join(
      Directory.current.path,
      'test',
      'integration',
      'fixture',
      'dart-core',
      'pkgs',
      'path',
    );

    final goldensDir = p.join(
      Directory.current.path,
      'test',
      'integration',
      'golden',
      'path',
    );

    setUpAll(() async {
      final pubspecFile = File(p.join(fixturePath, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        throw StateError(
          'dart-core submodule not initialized.\n'
          'Run: git submodule update --init\n'
          'Or see test/integration/README.md for setup instructions.',
        );
      }
      final docTree = await buildDocs(RenderOptions(packageRoot: fixturePath));
      generatedFiles = _collectFiles(docTree);
    });

    test('generated files match golden files', () {
      for (final entry in generatedFiles.entries) {
        final goldenFile = File(p.join(goldensDir, '${entry.key}.expected'));
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
      final goldenFiles = Directory(goldensDir)
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => p.relative(f.path, from: goldensDir))
          .toSet();
      final expectedGoldens = generatedFiles.keys
          .map((k) => '$k.expected')
          .toSet();
      expect(goldenFiles, equals(expectedGoldens));
    });
  });
}

/// Recursively collects all file paths and their rendered content.
Map<String, String> _collectFiles(DocDir dir, [String prefix = '']) {
  final result = <String, String>{};
  for (final child in dir.children) {
    switch (child) {
      case DocFile():
        final path = prefix.isEmpty ? child.name : '$prefix/${child.name}';
        result[path] = child.renderContent();
      case DocDir():
        final dirPath = prefix.isEmpty ? child.name : '$prefix/${child.name}';
        result.addAll(_collectFiles(child, dirPath));
    }
  }
  return result;
}
