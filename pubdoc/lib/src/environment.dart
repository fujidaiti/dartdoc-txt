import 'dart:io' show Platform;

import 'package:file/file.dart';
import 'package:file/local.dart';

/// Abstracts all I/O operations (file system, environment variables).
///
/// Implement this class to substitute the I/O layer in tests.
abstract class Environment {
  FileSystem get fs;
  String? getVariable(String name);
  String get toolVersion;
}

/// The default [Environment] backed by real platform I/O.
class PlatformEnvironment implements Environment {
  @override
  final FileSystem fs = const LocalFileSystem();

  @override
  String? getVariable(String name) => Platform.environment[name];

  @override
  String get toolVersion => '0.1.2';
}
