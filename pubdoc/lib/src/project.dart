import 'dart:convert';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

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
  Version getPackageVersion(String packageName) {
    final content = pubspecLockFile.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;
    final packages = yaml['packages'] as YamlMap?;
    if (packages == null || !packages.containsKey(packageName)) {
      throw PubdocException(
        "Package '$packageName' not found in pubspec.lock.",
      );
    }
    final versionStr = (packages[packageName] as YamlMap)['version'] as String;
    return Version.parse(versionStr);
  }

  /// Parses `.dart_tool/package_config.json` and returns the source directory
  /// for [packageName].
  Directory getPackageSourceDir(String packageName) {
    final content = packageConfigFile.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final packages = json['packages'] as List<dynamic>;
    for (final pkg in packages) {
      final map = pkg as Map<String, dynamic>;
      if (map['name'] == packageName) {
        final rootUri = Uri.parse(map['rootUri'] as String);
        // Resolve relative URIs against the package_config.json location.
        final resolved = Uri.file(
          '${packageConfigFile.parent.path}/',
        ).resolveUri(rootUri);
        return env.fs.directory(resolved.toFilePath());
      }
    }
    throw PubdocException(
      "Package '$packageName' not found in package_config.json.",
    );
  }
}
