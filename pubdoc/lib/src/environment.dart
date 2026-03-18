import 'dart:io' show Platform;

import 'package:file/file.dart';
import 'package:file/local.dart';

import 'logger.dart';

/// Abstracts all I/O operations (file system, logging, environment variables).
///
/// Implement this class to substitute the I/O layer in tests.
abstract class Environment {
  FileSystem get fs;
  Logger? get logger;
  String? getVariable(String name);
}

/// The default [Environment] backed by real platform I/O.
class PlatformEnvironment implements Environment {
  @override
  final FileSystem fs = const LocalFileSystem();

  @override
  final Logger? logger;

  PlatformEnvironment({bool verbose = false, Logger? logger})
    : logger = logger ?? Logger(verbose: verbose);

  @override
  String? getVariable(String name) => Platform.environment[name];
}
