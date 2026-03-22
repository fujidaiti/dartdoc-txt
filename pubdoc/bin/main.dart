import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:pubdoc/src/config.dart';
import 'package:pubdoc/src/environment.dart';
import 'package:pubdoc/src/exceptions.dart';
import 'package:pubdoc/src/get_command.dart' as cmd;
import 'package:pubdoc/src/logger.dart';
import 'package:pubdoc/src/project.dart';
import 'package:pubdoc/src/version_resolution.dart';

String _toJson(Object? obj, int indent) => indent == 0
    ? jsonEncode(obj)
    : JsonEncoder.withIndent(' ' * indent).convert(obj);

class _PubdocRunner extends CommandRunner<int> {
  _PubdocRunner()
    : super('pubdoc', 'Generate documentation for Dart packages.') {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Show additional command output.',
      )
      ..addFlag(
        'quiet',
        abbr: 'q',
        negatable: false,
        help: 'Suppress all log output.',
      )
      ..addFlag('version', negatable: false, help: 'Print the tool version.')
      ..addOption(
        'json',
        valueHelp: 'indent',
        help:
            'Output results in JSON format. '
            'Value is the indent level '
            '(e.g. --json=0 for minified, --json=2 for 2-space indent).',
      );
    addCommand(_GetCommand());
  }
  final List<String> _logs = [];
  final List<String> _errors = [];

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.flag('version')) {
      stdout.writeln('pubdoc version: ${PlatformEnvironment().toolVersion}');
      return 0;
    }

    final verbose = topLevelResults.flag('verbose');
    final quiet = topLevelResults.flag('quiet');
    if (verbose && quiet) {
      usageException('--verbose and --quiet cannot be used together.');
    }
    final rawJson = topLevelResults['json'] as String?;
    final jsonIndent = rawJson == null ? null : int.tryParse(rawJson);
    if (rawJson != null && (jsonIndent == null || jsonIndent < 0)) {
      usageException(
        '--json requires a non-negative integer (e.g. --json=0 or --json=2).',
      );
    }
    final useJson = jsonIndent != null;

    // Configure logging.
    Logger.root.level = quiet ? Level.OFF : (verbose ? Level.ALL : Level.INFO);
    if (quiet) {
      // dartdoc enables hierarchicalLoggingEnabled and sets its own level,
      // so Logger.root.level alone doesn't suppress its output.
      // We must also suppress named loggers explicitly.
      hierarchicalLoggingEnabled = true;
      Logger('dartdoc').level = Level.OFF;
      Logger('pubdoc').level = Level.OFF;
    }
    Logger.root.onRecord.listen((record) {
      final message = verbose
          ? '[${record.loggerName}] ${record.message}'
          : record.message;
      if (useJson) {
        (record.level >= Level.WARNING ? _errors : _logs).add(message);
      } else {
        (record.level >= Level.WARNING ? stderr : stdout).writeln(message);
      }
    });

    return super.runCommand(topLevelResults);
  }
}

class _GetCommand extends Command<int> {
  _GetCommand() {
    argParser
      ..addOption(
        'project',
        abbr: 'p',
        valueHelp: 'path',
        help:
            'The path to the Dart/Flutter project root—a directory that '
            'has pubspec.yaml, including pub workspaces. '
            'Defaults to the current directory.',
      )
      ..addFlag(
        'cache',
        defaultsTo: true,
        help:
            'Use cache whenever possible. '
            'Use --no-cache to always regenerate documentation.',
      )
      ..addOption(
        'resolution',
        abbr: 'r',
        valueHelp: 'strategy',
        defaultsTo: 'loose-patch',
        allowed: ['exact', 'loose-patch', 'loose-minor'],
        allowedHelp: {
          'exact': 'Use the exact package version (e.g. 5.3.2).',
          'loose-patch':
              'Share docs across patch versions (e.g. 5.3.x). Default.',
          'loose-minor': 'Share docs across minor versions (e.g. 5.x).',
        },
        help:
            'Strategy to resolve the documentation version '
            'from the package version.',
      );
  }
  @override
  final String name = 'get';
  @override
  final String description = 'Generate documentation for specified packages.';

  @override
  Future<int> run() async {
    final runner = this.runner! as _PubdocRunner;
    final global = globalResults!;
    final rawJson = global['json'] as String?;
    final jsonIndent = rawJson == null ? null : int.tryParse(rawJson);
    final useJson = jsonIndent != null;

    final env = PlatformEnvironment();
    final config = PubdocConfig.resolve(env);
    final projectPath = argResults!.option('project') ?? Directory.current.path;
    final project = ProjectContext.from(projectPath, env: env);
    final useCache = argResults!.flag('cache');
    final strategy = switch (argResults!.option('resolution')) {
      'exact' => ResolutionStrategy.exact,
      'loose-minor' => ResolutionStrategy.looseMinor,
      _ => ResolutionStrategy.loosePatch,
    };

    try {
      final result = await cmd.GetCommand(
        project: project,
        config: config,
        env: env,
        strategy: strategy,
        useCache: useCache,
      ).run(packageNames: argResults!.rest);

      if (useJson) {
        stdout.writeln(
          _toJson({
            'output': result.toJson(),
            'errors': runner._errors,
            'logs': runner._logs,
          }, jsonIndent),
        );
      } else {
        stdout.writeln(result.format());
      }
      return 0;
    } on PubdocException catch (e) {
      if (useJson) {
        stdout.writeln(
          _toJson({
            'output': null,
            'errors': [...runner._errors, e.message],
            'logs': runner._logs,
          }, jsonIndent),
        );
      } else {
        log.severe(e.message);
      }
      return 1;
    }
  }
}

Future<void> main(List<String> arguments) async {
  final normalizedArgs = arguments
      .map((a) => a == '--json' ? '--json=2' : a)
      .toList();

  try {
    exitCode = await _PubdocRunner().run(normalizedArgs) ?? 0;
  } on UsageException catch (e) {
    stderr.writeln(e.message);
    exitCode = 64;
  }
}
