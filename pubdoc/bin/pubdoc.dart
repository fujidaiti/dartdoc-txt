import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:pubdoc/src/config.dart';
import 'package:pubdoc/src/environment.dart';
import 'package:pubdoc/src/exceptions.dart';
import 'package:pubdoc/src/get_command.dart';
import 'package:pubdoc/src/logger.dart';
import 'package:pubdoc/src/project.dart';

const String version = '0.0.1';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.')
    ..addOption(
      'json',
      valueHelp: 'indent',
      help:
          'Output results in JSON format. '
          'Value is the indent level (e.g. --json=0 for minified, --json=2 for 2-space indent).',
    )
    ..addCommand(
      'get',
      ArgParser()..addOption(
        'project',
        abbr: 'p',
        valueHelp: 'path',
        help:
            'The path to the Dart/Flutter project root—a directory that '
            'has pubspec.yaml, including pub workspaces. '
            'Defaults to the current directory.',
      ),
    );
}

String _toJson(Object? obj, int indent) => indent == 0
    ? jsonEncode(obj)
    : JsonEncoder.withIndent(' ' * indent).convert(obj);

void printUsage(ArgParser argParser) {
  print('Usage: pubdoc <command> [options] [arguments]');
  print('');
  print('Commands:');
  print('  get    Generate documentation for specified packages.');
  print('');
  print('Global options:');
  print(argParser.usage);
}

Future<void> main(List<String> arguments) async {
  final argParser = buildParser();

  final normalizedArgs = arguments
      .map((a) => a == '--json' ? '--json=2' : a)
      .toList();

  ArgResults results;
  try {
    results = argParser.parse(normalizedArgs);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln('');
    printUsage(argParser);
    exitCode = 64;
    return;
  }

  if (results.flag('help')) {
    printUsage(argParser);
    return;
  }
  if (results.flag('version')) {
    print('pubdoc version: $version');
    return;
  }

  final verbose = results.flag('verbose');
  final rawJson = results['json'] as String?;
  final jsonIndent = rawJson == null ? null : int.tryParse(rawJson);
  if (rawJson != null && (jsonIndent == null || jsonIndent < 0)) {
    stderr.writeln(
      '--json requires a non-negative integer (e.g. --json=0 or --json=2).',
    );
    exitCode = 64;
    return;
  }
  final useJson = jsonIndent != null;
  final env = useJson
      ? PlatformEnvironment(logger: CollectingLogger(verbose: verbose))
      : PlatformEnvironment(verbose: verbose);
  final command = results.command;

  if (command == null) {
    printUsage(argParser);
    exitCode = 64;
    return;
  }

  try {
    switch (command.name) {
      case 'get':
        final config = PubdocConfig.resolve(env);
        final projectPath = command.option('project') ?? Directory.current.path;
        final project = ProjectContext.from(projectPath, env: env);
        final getCommand = GetCommand(
          project: project,
          config: config,
          env: env,
        );
        final result = await getCommand.run(packageNames: command.rest);
        if (useJson) {
          final cl = env.logger as CollectingLogger;
          print(
            _toJson({
              'output': result.toJson(),
              'errors': cl.errors,
              'logs': cl.logs,
            }, jsonIndent!),
          );
        } else {
          print(result.format());
        }
      default:
        stderr.writeln("Unknown command '${command.name}'.");
        printUsage(argParser);
        exitCode = 64;
    }
  } on PubdocException catch (e) {
    if (useJson) {
      final cl = env.logger as CollectingLogger;
      print(
        _toJson({
          'output': null,
          'errors': [...cl.errors, e.message],
          'logs': cl.logs,
        }, jsonIndent!),
      );
    } else {
      env.logger?.error(e.message);
    }
    exitCode = 1;
  }
}
