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

  /// The workspace root if [projectRoot] is a workspace member, or null if it
  /// is not a workspace member (including the workspace root itself).
  final String? _workspaceRoot;

  ProjectContext._(
    this.projectRoot, {
    required this.env,
    required String? workspaceRoot,
  }) : _workspaceRoot = workspaceRoot;

  /// Detects whether [projectRoot] is a pub workspace member and, if so, walks
  /// up the directory tree to find the workspace root.
  ///
  /// Throws [PubdocException] if the project declares `resolution: workspace`
  /// but no workspace root can be found within 10 parent directories.
  factory ProjectContext.from(String projectRoot, {required Environment env}) {
    final pubspecFile = env.fs.file(p.join(projectRoot, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw PubdocException(
        'pubspec.yaml not found in $projectRoot.\n'
        'Make sure the working directory is the root of a Dart/Flutter project, '
        'or specify the project path via --project option.',
      );
    }
    String? workspaceRoot;
    if (pubspecFile.existsSync()) {
      final YamlMap? pubspec;
      try {
        pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap?;
      } catch (_) {
        return ProjectContext._(projectRoot, env: env, workspaceRoot: null);
      }
      if (pubspec != null && pubspec['resolution'] == 'workspace') {
        // Walk up to find the workspace root (max 10 levels).
        var current = p.dirname(projectRoot);
        for (var depth = 0; depth < 10; depth++) {
          final candidate = env.fs.file(p.join(current, 'pubspec.yaml'));
          if (candidate.existsSync()) {
            try {
              final yaml = loadYaml(candidate.readAsStringSync()) as YamlMap?;
              if (yaml != null && yaml.containsKey('workspace')) {
                workspaceRoot = current;
                break;
              }
            } catch (_) {}
          }
          final parent = p.dirname(current);
          if (parent == current) break;
          current = parent;
        }
        if (workspaceRoot == null) {
          // Found `resolution: workspace` but no workspace root — invalid repository structure.
          throw PubdocException(
            'pubspec.yaml in $projectRoot declares `resolution: workspace`, '
            'but no workspace root (pubspec.yaml with `workspace:` key) was found '
            'in the parent directories.',
          );
        }
      }
    }
    return ProjectContext._(
      projectRoot,
      env: env,
      workspaceRoot: workspaceRoot,
    );
  }

  /// Resolves to the workspace root when [projectRoot] is a workspace member,
  /// or [projectRoot] itself otherwise.
  String get _effectiveRoot => _workspaceRoot ?? projectRoot;

  File get pubspecLockFile =>
      env.fs.file(p.join(_effectiveRoot, 'pubspec.lock'));

  File get packageConfigFile =>
      env.fs.file(p.join(_effectiveRoot, '.dart_tool', 'package_config.json'));

  File get packageGraphFile =>
      env.fs.file(p.join(_effectiveRoot, '.dart_tool', 'package_graph.json'));

  Directory get pubdocDir =>
      env.fs.directory(p.join(_effectiveRoot, '.pubdoc'));

  /// Validates that required files exist.
  void validate() {
    if (!pubspecLockFile.existsSync()) {
      throw PubdocException(
        'pubspec.lock not found in $_effectiveRoot. '
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

  /// Returns the set of transitive dependency names for [packageName],
  /// including [packageName] itself.
  ///
  /// Uses `.dart_tool/package_graph.json` if available; returns `null`
  /// if the file does not exist (e.g., older Dart SDKs).
  Set<String>? getTransitiveDependencies(String packageName) {
    if (!packageGraphFile.existsSync()) return null;

    final json =
        jsonDecode(packageGraphFile.readAsStringSync()) as Map<String, dynamic>;
    final packages = json['packages'] as List<dynamic>;

    // Build adjacency map: name → [dependency names]
    final graph = <String, List<String>>{};
    for (final pkg in packages) {
      final map = pkg as Map<String, dynamic>;
      final name = map['name'] as String;
      final deps = (map['dependencies'] as List<dynamic>).cast<String>();
      graph[name] = deps;
    }

    // BFS from packageName
    final visited = <String>{};
    final queue = [packageName];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!visited.add(current)) continue;
      final deps = graph[current];
      if (deps != null) queue.addAll(deps);
    }
    return visited;
  }

  /// Returns the contents of package_config.json filtered to only include
  /// packages in [keepNames]. Falls back to the full file if [keepNames]
  /// is null.
  String filteredPackageConfig(Set<String>? keepNames) {
    final content = packageConfigFile.readAsStringSync();
    if (keepNames == null) return content;

    final json = jsonDecode(content) as Map<String, dynamic>;
    final packages = json['packages'] as List<dynamic>;
    json['packages'] = [
      for (final pkg in packages)
        if (keepNames.contains((pkg as Map<String, dynamic>)['name'])) pkg,
    ];
    return jsonEncode(json);
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
