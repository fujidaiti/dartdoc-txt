import 'dart:io';

import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:pubdoc/src/config.dart';
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
    ..addCommand('get');
}

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

  ArgResults results;
  try {
    results = argParser.parse(arguments);
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
  final logger = Logger(verbose: verbose);
  final command = results.command;

  if (command == null) {
    printUsage(argParser);
    exitCode = 64;
    return;
  }

  try {
    switch (command.name) {
      case 'get':
        const fs = LocalFileSystem();
        final config = PubdocConfig.resolve();
        final project = ProjectContext(Directory.current.path, fs: fs);
        final getCommand = GetCommand(
          project: project,
          config: config,
          logger: logger,
          fs: fs,
        );
        await getCommand.run(command.rest);
      default:
        stderr.writeln("Unknown command '${command.name}'.");
        printUsage(argParser);
        exitCode = 64;
    }
  } on PubdocException catch (e) {
    logger.error(e.message);
    exitCode = 1;
  }
}
