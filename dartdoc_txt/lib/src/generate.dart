import 'package:dartdoc/dartdoc.dart';

import 'doc_tree.dart';
import 'element_renderers.dart';
import 'markdown_renderer.dart';

/// Generates LLM-friendly Markdown documentation for a Dart package.
///
/// Analyzes the package at [RenderOptions.packageRoot] and writes
/// documentation files to [outputDir]. The output directory is created
/// if it doesn't exist.
Future<void> generateDocs({
  required String outputDir,
  required RenderOptions options,
}) async {
  final docTree = await buildDocs(options);
  writeDocTree(docTree, outputDir);
}

Future<DocDir> buildDocs(RenderOptions options) async {
  final config = parseOptions(pubPackageMetaProvider, [
    '--input',
    options.packageRoot,
    '--no-show-progress',
    '--quiet',
  ]);
  if (config == null) {
    throw StateError('Failed to parse dartdoc options.');
  }

  final packageBuilder = PubPackageBuilder(config, pubPackageMetaProvider);
  final packageGraph = await packageBuilder.buildPackageGraph();

  return MarkdownRenderer(
    packageGraph: packageGraph,
    options: options,
  ).render();
}
