import 'dart:io';

import 'package:args/args.dart';
import 'package:dartdoc/dartdoc.dart';
import 'package:dartdoc_txt/src/markdown_renderer.dart';

const String version = '0.0.1';

Future<void> main(List<String> arguments) async {
  final argParser = ArgParser()
    ..addOption(
      'input',
      abbr: 'i',
      help: 'Input directory.',
      mandatory: true,
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output directory.',
      mandatory: true,
    )
    ..addOption(
      'source-threshold',
      help: 'Max lines of source to embed inline (default: 10).',
      defaultsTo: '10',
    )
    ..addFlag(
      'include-source',
      help: 'Include source code snippets.',
      defaultsTo: true,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.');

  ArgResults results;
  try {
    results = argParser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln('');
    _printUsage(argParser);
    exitCode = 64;
    return;
  }

  if (results.flag('help')) {
    _printUsage(argParser);
    return;
  }
  if (results.flag('version')) {
    print('dartdoc_txt version: $version');
    return;
  }

  final String inputDir;
  final String outputDir;
  try {
    inputDir = results.option('input')!;
    outputDir = results.option('output')!;
  } on ArgumentError catch (e) {
    stderr.writeln(e.message);
    stderr.writeln('');
    _printUsage(argParser);
    exitCode = 64;
    return;
  }
  final sourceThreshold = int.parse(results.option('source-threshold')!);
  final includeSource = results.flag('include-source');

  // Build PackageGraph using dartdoc's analysis engine.
  final config = parseOptions(pubPackageMetaProvider, [
    '--input',
    inputDir,
    '--output',
    outputDir,
    '--no-show-progress',
  ]);
  if (config == null) {
    exitCode = 1;
    return;
  }

  print('Analyzing package...');
  final packageBuilder = PubPackageBuilder(config, pubPackageMetaProvider);
  final packageGraph = await packageBuilder.buildPackageGraph();

  print('Generating Markdown documentation...');
  final renderer = MarkdownRenderer(
    packageGraph: packageGraph,
    outputDir: outputDir,
    sourceLineThreshold: sourceThreshold,
    includeSource: includeSource,
  );
  await renderer.render();

  print('Documentation written to $outputDir');
}

void _printUsage(ArgParser argParser) {
  print('Usage: dart run dartdoc_txt [options]');
  print('');
  print(argParser.usage);
}
