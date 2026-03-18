import 'dart:io';

class Logger {
  final bool verbose;

  Logger({this.verbose = false});

  void info(String message) {
    stdout.writeln(message);
  }

  void detail(String message) {
    if (verbose) {
      stdout.writeln(message);
    }
  }

  void error(String message) {
    stderr.writeln(message);
  }
}

class CollectingLogger extends Logger {
  final List<String> logs = [];
  final List<String> errors = [];

  CollectingLogger({super.verbose});

  @override
  void info(String message) => logs.add(message);

  @override
  void detail(String message) {
    if (verbose) logs.add(message);
  }

  @override
  void error(String message) => errors.add(message);
}
