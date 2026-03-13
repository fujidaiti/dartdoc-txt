import 'dart:io';

import 'package:dartdoc_txt/dartdoc_txt.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('basic_library', () => _goldenTest('basic_library'));
  group('edge_cases', () => _goldenTest('edge_cases'));
  group('anonymous_library', () => _goldenTest('anonymous_library'));
  group('multi_library', () => _goldenTest('multi_library'));
  group('categories', () => _goldenTest('categories'));
}

/// Recursively collects all file paths and their rendered content.
Map<String, String> _collectFiles(DocDir dir, [String prefix = '']) {
  var result = <String, String>{};
  for (var child in dir.children) {
    switch (child) {
      case DocFile():
        var path = prefix.isEmpty ? child.name : '$prefix/${child.name}';
        result[path] = child.renderContent();
      case DocDir():
        var dirPath = prefix.isEmpty ? child.name : '$prefix/${child.name}';
        result.addAll(_collectFiles(child, dirPath));
    }
  }
  return result;
}

/// Runs golden tests for a fixture.
void _goldenTest(
  String fixtureName, {
  int sourceThreshold = 10,
  bool includeSource = true,
}) {
  late Map<String, String> generatedFiles;

  final goldensDir = p.join(
    Directory.current.path,
    'test',
    'integration',
    'golden',
    fixtureName,
  );

  setUpAll(() async {
    var docTree = await renderFixture(
      fixtureName,
      sourceThreshold: sourceThreshold,
      includeSource: includeSource,
    );
    generatedFiles = _collectFiles(docTree);
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
    var expectedGoldens = generatedFiles.keys.map((k) => '$k.expect').toSet();
    expect(goldenFiles, equals(expectedGoldens));
  });
}
