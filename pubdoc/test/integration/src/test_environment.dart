import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:pubdoc/src/environment.dart';
import 'package:pubdoc/src/logger.dart';

class PubspecYaml {
  final File _file;
  final Map<String, String> _dependencies = {};

  /// The `resolution` field of the pubspec.yaml (e.g. `'workspace'` for
  /// workspace members).
  String? resolution;

  /// The `workspace` field of the pubspec.yaml listing relative member paths.
  /// Non-empty only in a workspace root pubspec.yaml.
  final List<String> workspace = [];

  PubspecYaml(this._file);

  Map<String, String> get dependencies => Map.unmodifiable(_dependencies);

  void addDependency(String name, String version) {
    _dependencies[name] = version;
  }

  void removeDependency(String name) {
    _dependencies.remove(name);
  }

  /// Writes a minimal pubspec.yaml containing [resolution] and [workspace]
  /// fields (if set), creating parent directories as needed.
  void write() {
    _file.parent.createSync(recursive: true);
    final buf = StringBuffer();
    if (resolution != null) buf.writeln('resolution: $resolution');
    if (workspace.isNotEmpty) {
      buf.writeln('workspace:');
      for (final m in workspace) {
        buf.writeln('  - $m');
      }
    }
    _file.writeAsStringSync(buf.toString());
  }
}

class PubspecLock {
  final File _file;
  final Map<String, Map<String, dynamic>> _packages = {};

  PubspecLock(this._file);

  void addPackage(
    String name, {
    required String version,
    String dependency = 'direct main',
  }) {
    _packages[name] = {'dependency': dependency, 'version': version};
  }

  void write() {
    _file.parent.createSync(recursive: true);
    _file.writeAsStringSync(jsonEncode({'packages': _packages}));
  }

  void deleteSync() => _file.deleteSync();
}

class PackageConfigJson {
  final File _file;
  final List<({String name, String rootUri, String packageUri})> _packages = [];

  PackageConfigJson(this._file);

  void addPackage({
    required String name,
    required String rootUri,
    String packageUri = 'lib/',
  }) {
    _packages.add((name: name, rootUri: rootUri, packageUri: packageUri));
  }

  void removePackage(String name) {
    _packages.removeWhere((p) => p.name == name);
  }

  void write() {
    _file.parent.createSync(recursive: true);
    _file.writeAsStringSync(
      jsonEncode({
        'configVersion': 2,
        'packages': [
          for (final pkg in _packages)
            {
              'name': pkg.name,
              'rootUri': pkg.rootUri,
              'packageUri': pkg.packageUri,
            },
        ],
      }),
    );
  }

  void deleteSync() => _file.deleteSync();
}

class TestEnvironment implements Environment {
  final String projectRoot;
  final String pubCacheBase;
  late final PubspecYaml pubspec;
  late final PubspecLock pubspecLock;
  late final PackageConfigJson packageConfig;
  final Map<String, String> _variables;

  @override
  final MemoryFileSystem fs;

  @override
  final Logger? logger;

  TestEnvironment({
    required this.projectRoot,
    required this.pubCacheBase,
    this.logger,
    Map<String, String> variables = const {},
  }) : fs = MemoryFileSystem.test(),
       _variables = variables {
    pubspec = PubspecYaml(fs.file('$projectRoot/pubspec.yaml'));
    pubspecLock = PubspecLock(fs.file('$projectRoot/pubspec.lock'));
    packageConfig = PackageConfigJson(
      fs.file('$projectRoot/.dart_tool/package_config.json'),
    );
  }

  @override
  String? getVariable(String name) => _variables[name];

  var _setUpCalled = false;

  /// Sets up the test environment.
  ///
  /// Must be called before any other operations related to the environment.
  @mustCallSuper
  void setUp() {
    assert(
      !_setUpCalled,
      'setUp() should only be called once per TestEnvironment',
    );
    _setUpCalled = true;
    pubspec.write();
  }

  void pubGet() {
    assert(_setUpCalled);
    // Write pubspec.lock.
    pubspecLock._packages.clear();
    for (final entry in pubspec.dependencies.entries) {
      pubspecLock.addPackage(entry.key, version: entry.value);
    }
    pubspecLock.write();

    // Write package_config.json.
    packageConfig._packages.clear();
    for (final entry in pubspec.dependencies.entries) {
      packageConfig.addPackage(
        name: entry.key,
        rootUri: '$pubCacheBase/${entry.key}-${entry.value}/',
      );
    }
    packageConfig.write();

    // Create package source dirs in pub cache.
    for (final entry in pubspec.dependencies.entries) {
      fs
          .directory('$pubCacheBase/${entry.key}-${entry.value}')
          .createSync(recursive: true);
    }
  }
}

/// A [TestEnvironment] configured for a pub workspace scenario.
///
/// The workspace root pubspec.yaml lists [memberRelativePath] under `workspace:`,
/// and the member pubspec.yaml at [memberRoot] declares `resolution: workspace`.
/// Lock and config files are created under [projectRoot] (the workspace root),
/// matching real pub workspace behavior. Use [memberRoot] as the `projectRoot`
/// when constructing a [ProjectContext] to exercise workspace detection.
class WorkspaceTestEnvironment extends TestEnvironment {
  /// The absolute path of the workspace member directory, derived from
  /// `workspaceRoot + memberRelativePath`.
  final String memberRoot;

  /// The pubspec.yaml model for the workspace member.
  late final PubspecYaml memberPubspec;

  final String memberRelativePath;

  WorkspaceTestEnvironment({
    required String workspaceRoot,
    required this.memberRelativePath,
    required super.pubCacheBase,
    super.logger,
  }) : memberRoot = p.join(workspaceRoot, memberRelativePath),
       super(projectRoot: workspaceRoot) {
    memberPubspec = PubspecYaml(fs.file(p.join(memberRoot, 'pubspec.yaml')));
  }

  @override
  void setUp() {
    pubspec.workspace.add(memberRelativePath);
    super.setUp();
    memberPubspec.resolution = 'workspace';
    memberPubspec.write();
  }
}
