import 'dart:convert';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'environment.dart';
import 'exceptions.dart';

class ProjectContext {
  final String projectRoot;
  final Environment env;

  ProjectContext(this.projectRoot, {required this.env});

  File get pubspecLockFile => env.fs.file(p.join(projectRoot, 'pubspec.lock'));

  File get packageConfigFile =>
      env.fs.file(p.join(projectRoot, '.dart_tool', 'package_config.json'));

  Directory get pubdocDir => env.fs.directory(p.join(projectRoot, '.pubdoc'));

  /// Validates that required files exist.
  void validate() {
    if (!pubspecLockFile.existsSync()) {
      throw PubdocException(
        'pubspec.lock not found in $projectRoot. '
        'Run `dart pub get` first.',
      );
    }
    if (!packageConfigFile.existsSync()) {
      throw PubdocException(
        '.dart_tool/package_config.json not found. '
        'Run `dart pub get` first.',
      );
    }
  }

  /// Parses `pubspec.lock` and returns the version for [packageName].
  ///
  /// Reads the file as a stream of lines and stops as soon as the version
  /// for [packageName] is found, avoiding loading the full file into memory.
  Future<Version> getPackageVersion(String packageName) async {
    final lines = pubspecLockFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    var inPackage = false;
    await for (final line in lines) {
      if (!inPackage) {
        if (line == '  $packageName:') {
          inPackage = true;
        }
      } else {
        if (line.startsWith('    version: ')) {
          final versionStr = line
              .substring('    version: '.length)
              .trim()
              .replaceAll('"', '');
          return Version.parse(versionStr);
        }
        // A new 2-space-indented key means we've left the package section.
        if (line.length >= 3 &&
            line[0] == ' ' &&
            line[1] == ' ' &&
            line[2] != ' ' &&
            line.trim().isNotEmpty) {
          break;
        }
      }
    }
    throw PubdocException("Package '$packageName' not found in pubspec.lock.");
  }

  /// Parses `.dart_tool/package_config.json` and returns the source directory
  /// for [packageName].
  ///
  /// Reads the file as a stream of lines and stops as soon as the entry for
  /// [packageName] is found, avoiding loading the full file into memory.
  Future<Directory> getPackageSourceDir(String packageName) async {
    final lines = packageConfigFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    var inPackage = false;
    await for (final line in lines) {
      final trimmed = line.trim();
      if (!inPackage) {
        if (trimmed == '"name": "$packageName"' ||
            trimmed == '"name": "$packageName",') {
          inPackage = true;
        }
      } else {
        if (trimmed == '}' || trimmed == '},') {
          // Left the package object without finding rootUri; keep searching.
          inPackage = false;
          continue;
        }
        if (trimmed.startsWith('"rootUri": "')) {
          final uriStr = trimmed
              .substring('"rootUri": "'.length)
              .replaceAll(RegExp(r'",?$'), '');
          final rootUri = Uri.parse(uriStr);
          // Resolve relative URIs against the package_config.json location.
          final resolved = Uri.file(
            '${packageConfigFile.parent.path}/',
          ).resolveUri(rootUri);
          return env.fs.directory(resolved.toFilePath());
        }
      }
    }
    throw PubdocException(
      "Package '$packageName' not found in package_config.json.",
    );
  }
}
