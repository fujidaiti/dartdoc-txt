import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dartdoc_txt/dartdoc_txt.dart';
import 'package:logging/logging.dart';

const String _version = '0.1.0';

Future<void> main(List<String> arguments) async {
  final log = Logger('dartdoc_txt');
  _setupLogging();

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
    stdout.writeln('dartdoc_txt version: $_version');
    return;
  }

  final inputDir = results.option('input')!;
  final outputDir = results.option('output')!;
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
  stdout.writeln('Usage: dart run dartdoc_txt [options]');
  stdout.writeln('');
  stdout.writeln(argParser.usage);
}

/// Configures the root logger for CLI usage.
///
/// Routes INFO and below to stdout, WARNING and above to stderr.
/// Returns the subscription so it can be cancelled if needed.
StreamSubscription<LogRecord> _setupLogging({bool verbose = false}) {
  Logger.root.level = verbose ? Level.ALL : Level.INFO;
  return Logger.root.onRecord.listen((record) {
    if (record.level >= Level.WARNING) {
      stderr.writeln(record.message);
    } else {
      stdout.writeln(record.message);
    }
  });
}
