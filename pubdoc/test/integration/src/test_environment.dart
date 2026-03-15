import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:pubdoc/src/doc_generator.dart';

class FakeDocGenerator extends DocGenerator {
  int generateCallCount = 0;

  FakeDocGenerator({required super.fs});

  @override
  Future<void> generate({
    required String sourcePath,
    required String outputDir,
  }) async {
    generateCallCount++;
    fs.directory(outputDir).createSync(recursive: true);
  }
}

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

class TestEnvironment {
  static const projectRoot = '/Users/testuser/projects/my_app';
  static const homeDir = '/Users/testuser/.pubdoc';
  static const cacheDir = '/Users/testuser/.pubdoc/cache';
  static const pubCacheBase = '/Users/testuser/.pub-cache/hosted/pub.dev';

  final MemoryFileSystem fs;
  final PubspecYaml pubspec = PubspecYaml();

  File get pubspecLock => fs.file('$projectRoot/pubspec.lock');
  File get packageConfig =>
      fs.file('$projectRoot/.dart_tool/package_config.json');

  TestEnvironment() : this._(MemoryFileSystem.test());

  TestEnvironment._(this.fs);

  void pubGet() {
    _writePubspecLock();
    _writePackageConfig();
    _createPackageSourceDirs();
  }

  void _writePubspecLock() {
    final packages = <String, dynamic>{};
    for (final entry in pubspec.dependencies.entries) {
      packages[entry.key] = {
        'dependency': 'direct main',
        'version': entry.value,
      };
    }
    final content = jsonEncode({'packages': packages});
    pubspecLock.parent.createSync(recursive: true);
    pubspecLock.writeAsStringSync(content);
  }

  void _writePackageConfig() {
    final packages = pubspec.dependencies.entries.map((e) {
      return {
        'name': e.key,
        'rootUri': '$pubCacheBase/${e.key}-${e.value}/',
        'packageUri': 'lib/',
      };
    }).toList();
    final json = {'configVersion': 2, 'packages': packages};
    packageConfig.parent.createSync(recursive: true);
    packageConfig.writeAsStringSync(jsonEncode(json));
  }

  void _createPackageSourceDirs() {
    for (final entry in pubspec.dependencies.entries) {
      fs
          .directory('$pubCacheBase/${entry.key}-${entry.value}')
          .createSync(recursive: true);
    }
  }
}
