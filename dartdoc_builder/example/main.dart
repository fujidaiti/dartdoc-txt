import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dartdoc_builder/dartdoc_builder.dart';

Future<void> main(List<String> arguments) async {
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
    );

  final String inputDir;
  final String outputDir;
  final int sourceThreshold;
  final bool includeSource;
  try {
    final results = argParser.parse(arguments);
    inputDir = results.option('input')!;
    outputDir = results.option('output')!;
    sourceThreshold = int.parse(results.option('source-threshold')!);
    includeSource = results.flag('include-source');
    // The above try block may throw both Error and Exception, so we catch all.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    stdout.writeln('Usage: dart run dartdoc_builder [options]');
    stdout.writeln('');
    stdout.writeln(argParser.usage);
    exit(1);
  }

  await generateDocs(
    outputDir: outputDir,
    options: RenderOptions(
      packageRoot: inputDir,
      sourceLineThreshold: sourceThreshold,
      includeSource: includeSource,
    ),
  );
}
