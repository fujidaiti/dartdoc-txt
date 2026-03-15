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
