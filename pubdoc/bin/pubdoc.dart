import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:pubdoc/src/config.dart';
import 'package:pubdoc/src/environment.dart';
import 'package:pubdoc/src/exceptions.dart';
import 'package:pubdoc/src/get_command.dart' as cmd;
import 'package:pubdoc/src/logger.dart';
import 'package:pubdoc/src/project.dart';
import 'package:pubdoc/src/version_resolution.dart';

const String version = '0.0.1';

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
      ..addFlag('version', negatable: false, help: 'Print the tool version.')
      ..addOption(
        'json',
        valueHelp: 'indent',
        help:
            'Output results in JSON format. '
            'Value is the indent level (e.g. --json=0 for minified, --json=2 for 2-space indent).',
      );
    addCommand(_GetCommand());
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.flag('version')) {
      print('pubdoc version: $version');
      return 0;
    }
    final rawJson = topLevelResults['json'] as String?;
    final jsonIndent = rawJson == null ? null : int.tryParse(rawJson);
    if (rawJson != null && (jsonIndent == null || jsonIndent < 0)) {
      usageException(
        '--json requires a non-negative integer (e.g. --json=0 or --json=2).',
      );
    }
    return super.runCommand(topLevelResults);
  }
}

class _GetCommand extends Command<int> {
  @override
  final String name = 'get';
  @override
  final String description = 'Generate documentation for specified packages.';

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
            'Strategy to resolve the documentation version from the package version.',
      );
  }

  @override
  Future<int> run() async {
    final global = globalResults!;
    final verbose = global.flag('verbose');
    final rawJson = global['json'] as String?;
    final jsonIndent = rawJson == null ? null : int.tryParse(rawJson);
    final useJson = jsonIndent != null;

    final env = useJson
        ? PlatformEnvironment(logger: CollectingLogger(verbose: verbose))
        : PlatformEnvironment(verbose: verbose);
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
      return 0;
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
