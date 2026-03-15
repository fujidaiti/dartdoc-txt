import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:pubdoc/src/environment.dart';
import 'package:pubdoc/src/logger.dart';

class PubspecYaml {
  final Map<String, String> _dependencies = {};

  Map<String, String> get dependencies => Map.unmodifiable(_dependencies);

  void addDependency(String name, String version) {
    _dependencies[name] = version;
  }

  void removeDependency(String name) {
    _dependencies.remove(name);
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
  @override
  final MemoryFileSystem fs;
  @override
  final Logger? logger;
  final String projectRoot;
  final String pubCacheBase;
  final PubspecYaml pubspec = PubspecYaml();
  late final PubspecLock pubspecLock;
  late final PackageConfigJson packageConfig;
  final Map<String, String> _variables;

  TestEnvironment({
    required this.projectRoot,
    required this.pubCacheBase,
    this.logger,
    Map<String, String> variables = const {},
  }) : fs = MemoryFileSystem.test(),
       _variables = variables {
    pubspecLock = PubspecLock(fs.file('$projectRoot/pubspec.lock'));
    packageConfig = PackageConfigJson(
      fs.file('$projectRoot/.dart_tool/package_config.json'),
    );
  }

  @override
  String? getVariable(String name) => _variables[name];

  void pubGet() {
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
