# Examples

This document is a summary of curated examples of the args package. Actual example code lives in the `example/` directory.

## Basic ArgParser Usage

This example demonstrates how to use ArgParser to define options and flags, then parse command-line arguments. It shows configuration options, default values, allowed value constraints, and help text generation. The example creates a comprehensive set of options across different categories (platform, runtime, output, etc.) and displays the usage information.

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

parser.addOption('mode',
    abbr: 'm',
    defaultsTo: 'debug',
    help: 'Mode in which to run tests',
    allowed: ['debug', 'release']);

print(parser.usage);
```

See also:

- example/arg_parser/example.dart: the original source file for this example.
- args/ArgParser/ArgParser.md: the documentation page for ArgParser.
- args/ArgParser/ArgParser-addOption.md: the addOption method documentation.
- args/ArgParser/ArgParser-addFlag.md: the addFlag method documentation.

## CommandRunner for Command-Based Applications

This example demonstrates how to use CommandRunner and Command to build a command-based application. It shows a `draw` tool with multiple commands (square, circle, triangle) that have their own options, subcommands, and global options. Each command returns a string that represents drawn ASCII art using the specified character.

```dart
final runner = CommandRunner<String>('draw', 'Draws shapes')
  ..addCommand(SquareCommand())
  ..addCommand(CircleCommand())
  ..addCommand(TriangleCommand());
runner.argParser.addOption('char', help: 'The character to use for drawing');

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
    // Draw the square
  }
}
```

See also:

- example/command_runner/draw.dart: the original source file for this example.
- command_runner/CommandRunner/CommandRunner.md: the documentation page for CommandRunner.
- command_runner/Command/Command.md: the documentation page for Command.