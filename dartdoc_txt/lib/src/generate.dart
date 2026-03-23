import 'package:dartdoc/dartdoc.dart';
import 'package:dartdoc_txt/src/doc_tree.dart';
import 'package:dartdoc_txt/src/element_renderers.dart';
import 'package:dartdoc_txt/src/markdown_renderer.dart';

/// Generates Markdown documentation for a Dart package.
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
    if (options.sdkDir != null) ...['--sdk-dir', options.sdkDir!],
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
