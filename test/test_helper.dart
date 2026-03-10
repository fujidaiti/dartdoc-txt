import 'dart:io';

import 'package:dartdoc/dartdoc.dart';
import 'package:dartdoc/src/model/model.dart';
import 'package:path/path.dart' as p;

import 'package:dartdoc_md/src/markdown_renderer.dart';

/// Builds a [PackageGraph] from a test fixture.
///
/// Fixtures live under `test/fixtures/<fixtureName>/`.
Future<PackageGraph> buildFixtureGraph(String fixtureName) async {
  var fixturePath = p.join(
    Directory.current.path,
    'test',
    'fixtures',
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
/// output directory.
Future<Directory> renderFixture(
  String fixtureName, {
  int sourceThreshold = 10,
  bool includeSource = true,
}) async {
  var packageGraph = await buildFixtureGraph(fixtureName);

  var outputDir = Directory(
    p.join(Directory.current.path, 'tmp', 'test_output_$fixtureName'),
  );
  if (outputDir.existsSync()) {
    outputDir.deleteSync(recursive: true);
  }

  var renderer = MarkdownRenderer(
    packageGraph: packageGraph,
    outputDir: outputDir.path,
    sourceLineThreshold: sourceThreshold,
    includeSource: includeSource,
  );
  await renderer.render();
  return outputDir;
}
