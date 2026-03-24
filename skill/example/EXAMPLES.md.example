# Examples

This document is a summary of curated examples of the args package. Actual
example code lives in the `example/` directory.

## ArgParser with Options and Flags

This example demonstrates how to create an `ArgParser` with various options and
flags, including options with allowed values, help text, and handling of
abbreviated flags.

```dart
var parser = ArgParser();

parser.addOption('compiler',
    abbr: 'c',
    defaultsTo: 'none',
    help: 'Specify any compilation step (if needed).',
    allowed: ['none', 'dart2js', 'dartc'],
    allowedHelp: {
      'none': 'Do not compile the Dart code (run native Dart code on the VM).',
      'dart2js': 'Compile dart code to JavaScript by running dart2js.',
      'dartc': 'Perform static analysis on Dart code by running dartc.',
    });

parser.addFlag('verbose',
    abbr: 'v',
    defaultsTo: false,
    help: 'Verbose output');

var results = parser.parse(['--compiler', 'dart2js', '-v']);
print(results.option('compiler')); // dart2js
print(results.flag('verbose'));    // true
```

This example shows how to use options with allowed values and help text, add
flags with abbreviations, and parse command-line arguments to retrieve their
values.

See also:

- example/arg_parser/example.dart: the original source file for this example.
- args/ArgParser/ArgParser.md: documentation for the ArgParser class.
- args/ArgResults/ArgResults.md: documentation for the ArgResults class.

## CommandRunner with Commands and Subcommands

This example demonstrates how to use `CommandRunner` to build a command-based
CLI application with multiple commands, global options, command-specific
options, and subcommands.

```dart
void main(List<String> args) async {
  final runner = CommandRunner<String>('draw', 'Draws shapes')
    ..addCommand(SquareCommand())
    ..addCommand(CircleCommand())
    ..addCommand(TriangleCommand());
  runner.argParser.addOption('char', help: 'The character to use for drawing');
  final output = await runner.run(args);
  print(output);
}

class SquareCommand extends Command<String> {
  SquareCommand() {
    argParser.addOption('size', help: 'Size of the square');
  }

  @override
  String get name => 'square';

  @override
  String get description => 'Draws a square';

  @override
  FutureOr<String>? run() {
    final size = int.parse(argResults?.option('size') ?? '20');
    final char = globalResults?.option('char')?[0] ?? '#';
    return draw(size, size, char);
  }
}

class TriangleCommand extends Command<String> {
  TriangleCommand() {
    addSubcommand(EquilateralTriangleCommand());
    addSubcommand(IsoscelesTriangleCommand());
  }

  @override
  String get name => 'triangle';

  @override
  String get description => 'Draws a triangle';
}
```

This example shows how to create a `CommandRunner` with global options, define
multiple commands with their own options, create subcommands, and access both
global and command-specific options within a command's `run()` method.

See also:

- example/command_runner/draw.dart: the original source file for this example.
- command_runner/CommandRunner/CommandRunner.md: documentation for the
  CommandRunner class.
- command_runner/Command/Command.md: documentation for the Command class.
