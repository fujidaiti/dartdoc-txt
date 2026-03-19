import 'package:dartdoc/dartdoc.dart';

import 'doc_tree.dart';
import 'markdown_renderer.dart';

/// Generates LLM-friendly Markdown documentation for a Dart package.
///
/// Analyzes the package at [inputDir] and writes documentation files to
/// [outputDir]. The output directory is created if it doesn't exist.
///
/// [sourceLineThreshold] controls how many lines of source code are embedded
/// inline (default: 10). Set [includeSource] to `false` to omit source
/// snippets entirely.
Future<void> generateDocs({
  required String inputDir,
  required String outputDir,
  int sourceLineThreshold = 10,
  bool includeSource = true,
}) async {
  final config = parseOptions(pubPackageMetaProvider, [
    '--input',
    inputDir,
    '--output',
    outputDir,
    '--no-show-progress',
    '--quiet',
  ]);
  if (config == null) {
    throw StateError('Failed to parse dartdoc options.');
  }

  final packageBuilder = PubPackageBuilder(config, pubPackageMetaProvider);
  final packageGraph = await packageBuilder.buildPackageGraph();

  final renderer = MarkdownRenderer(
    packageGraph: packageGraph,
    sourceLineThreshold: sourceLineThreshold,
    includeSource: includeSource,
    packageRoot: inputDir,
  );
  final docTree = renderer.render();
  writeDocTree(docTree, outputDir);
}
