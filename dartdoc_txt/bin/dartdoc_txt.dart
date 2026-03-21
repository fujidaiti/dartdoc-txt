import 'dart:io';

import 'package:args/args.dart';
import 'package:dartdoc_txt/dartdoc_txt.dart';
import 'package:dartdoc_txt/src/logger.dart';

const String version = '0.0.1';

Future<void> main(List<String> arguments) async {
  setupLogging();
  final argParser = ArgParser()
    ..addOption('input', abbr: 'i', help: 'Input directory.', mandatory: true)
    ..addOption('output', abbr: 'o', help: 'Output directory.', mandatory: true)
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
    log.severe(e.message);
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
    log.severe(e.message);
    _printUsage(argParser);
    exitCode = 64;
    return;
  }
  final sourceThreshold = int.parse(results.option('source-threshold')!);
  final includeSource = results.flag('include-source');

  log.info('Analyzing package...');
  await generateDocs(
    outputDir: outputDir,
    options: RenderOptions(
      packageRoot: inputDir,
      sourceLineThreshold: sourceThreshold,
      includeSource: includeSource,
    ),
  );
  log.info('Documentation written to $outputDir');
}

void _printUsage(ArgParser argParser) {
  print('Usage: dart run dartdoc_txt [options]');
  print('');
  print(argParser.usage);
}
