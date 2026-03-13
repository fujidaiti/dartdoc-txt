import 'dart:io';

import 'package:dartdoc/dartdoc.dart';
import 'package:dartdoc_txt/dartdoc_txt.dart';
import 'package:path/path.dart' as p;

/// Builds a [PackageGraph] from a test fixture.
Future<PackageGraph> buildFixtureGraph(String fixtureName) async {
  var fixturePath = p.join(
    Directory.current.path,
    'test',
    'integration',
    'fixture',
    fixtureName,
  );
  var config = parseOptions(pubPackageMetaProvider, [
    '--input',
    fixturePath,
    '--no-validate-links',
    '--no-show-progress',
  ]);
  if (config == null) {
    throw StateError('Failed to parse options for fixture: $fixtureName');
  }
  var packageBuilder = PubPackageBuilder(config, pubPackageMetaProvider);
  return packageBuilder.buildPackageGraph();
}

/// Builds a [PackageGraph] and runs the [MarkdownRenderer], returning the
/// document tree.
Future<DocDir> renderFixture(
  String fixtureName, {
  int sourceThreshold = 10,
  bool includeSource = true,
}) async {
  var packageGraph = await buildFixtureGraph(fixtureName);
  var renderer = MarkdownRenderer(
    packageGraph: packageGraph,
    sourceLineThreshold: sourceThreshold,
    includeSource: includeSource,
  );
  return renderer.render();
}
