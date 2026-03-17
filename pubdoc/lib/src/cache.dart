import 'dart:convert';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'config.dart';
import 'environment.dart';
import 'version_resolution.dart';

enum CacheAction {
  /// The cached documentation can be reused as-is.
  reuse,

  /// No cache exists; generate fresh documentation.
  generate,

  /// Cache exists but is outdated; regenerate.
  regenerate,
}

class CacheResult {
  final CacheAction action;
  final String cacheDir;
  final String docVersion;
  final CacheMetadata? metadata;

  CacheResult({
    required this.action,
    required this.cacheDir,
    required this.docVersion,
    this.metadata,
  });
}

class CacheMetadata {
  final String version;
  final String packageVersion;
  final String source;

  CacheMetadata({
    required this.version,
    required this.packageVersion,
    required this.source,
  });

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      version: json['version'] as String,
      packageVersion: json['package_version'] as String,
      source: json['source'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'package_version': packageVersion,
    'source': source,
  };

  static CacheMetadata? read(String cacheDir, {required FileSystem fs}) {
    final file = fs.file(p.join(cacheDir, 'metadata.json'));
    if (!file.existsSync()) return null;
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return CacheMetadata.fromJson(json);
  }

  void write(String cacheDir, {required FileSystem fs}) {
    final file = fs.file(p.join(cacheDir, 'metadata.json'));
    file.parent.createSync(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(toJson()));
  }
}

class CacheManager {
  final PubdocConfig config;
  final Environment env;

  CacheManager(this.config, {required this.env});

  /// Checks whether the cache can be reused for the given package.
  CacheResult checkCache({
    required String packageName,
    required Version packageVersion,
    required ResolutionStrategy strategy,
    required bool useCache,
  }) {
    final docVer = packageVersion.docVersion(strategy);
    final cacheDir = config.packageCacheDir(packageName, docVer);

    if (!useCache) {
      return CacheResult(
        action: CacheAction.generate,
        cacheDir: cacheDir,
        docVersion: docVer,
      );
    }

    if (!env.fs.directory(cacheDir).existsSync()) {
      return CacheResult(
        action: CacheAction.generate,
        cacheDir: cacheDir,
        docVersion: docVer,
      );
    }

    final metadata = CacheMetadata.read(cacheDir, fs: env.fs);
    if (metadata == null) {
      return CacheResult(
        action: CacheAction.regenerate,
        cacheDir: cacheDir,
        docVersion: docVer,
      );
    }

    // For exact strategy, if the cache dir exists, just reuse.
    if (strategy == ResolutionStrategy.exact) {
      return CacheResult(
        action: CacheAction.reuse,
        cacheDir: cacheDir,
        docVersion: docVer,
        metadata: metadata,
      );
    }

    // For loose-* strategies, check if cached version is fresh enough.
    final cachedVersion = Version.parse(metadata.packageVersion);
    if (cachedVersion >= packageVersion) {
      return CacheResult(
        action: CacheAction.reuse,
        cacheDir: cacheDir,
        docVersion: docVer,
        metadata: metadata,
      );
    } else {
      return CacheResult(
        action: CacheAction.regenerate,
        cacheDir: cacheDir,
        docVersion: docVer,
        metadata: metadata,
      );
    }
  }
}
