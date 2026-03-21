import 'dart:io';

import 'package:dartdoc/dartdoc.dart';
import 'package:dartdoc_txt/dartdoc_txt.dart';

/// Builds a [PackageGraph] from a fixture at [fixturePath].
Future<PackageGraph> buildFixtureGraph(String fixturePath) async {
  var config = parseOptions(pubPackageMetaProvider, [
    '--input',
    fixturePath,
    '--no-validate-links',
    '--no-show-progress',
  ]);
  if (config == null) {
    throw StateError('Failed to parse options for fixture: $fixturePath');
  }
  var packageBuilder = PubPackageBuilder(config, pubPackageMetaProvider);
  return packageBuilder.buildPackageGraph();
}

/// Builds a [PackageGraph] and runs the [MarkdownRenderer], returning the
/// document tree.
Future<DocDir> renderFixture(
  String fixturePath, {
  int sourceThreshold = 10,
  bool includeSource = true,
}) async {
  var packageGraph = await buildFixtureGraph(fixturePath);
  var renderer = MarkdownRenderer(
    packageGraph: packageGraph,
    sourceLineThreshold: sourceThreshold,
    includeSource: includeSource,
    packageRoot: fixturePath,
  );
  return renderer.render();
}

/// Recursively collects all file paths and their rendered content.
Map<String, String> collectFiles(DocDir dir, [String prefix = '']) {
  var result = <String, String>{};
  for (var child in dir.children) {
    switch (child) {
      case DocFile():
        var path = prefix.isEmpty ? child.name : '$prefix/${child.name}';
        result[path] = child.renderContent();
      case DocDir():
        var dirPath = prefix.isEmpty ? child.name : '$prefix/${child.name}';
        result.addAll(collectFiles(child, dirPath));
    }
  }
  return result;
}
