import 'dart:io';

import 'package:path/path.dart' as p;

class PubdocConfig {
  final String homeDir;
  final String cacheDir;

  PubdocConfig({required this.homeDir, required this.cacheDir});

  /// Resolves the default configuration.
  ///
  /// For now, hardcodes to `$HOME/.pubdoc/` and `$HOME/.pubdoc/cache/`.
  factory PubdocConfig.resolve() {
    final home = Platform.environment['HOME'] ?? '.';
    final homeDir = p.join(home, '.pubdoc');
    return PubdocConfig(homeDir: homeDir, cacheDir: p.join(homeDir, 'cache'));
  }

  /// Returns the cache directory for a specific package and doc version.
  ///
  /// E.g. `~/.pubdoc/cache/dio/dio-5.3.x/`
  String packageCacheDir(String packageName, String docVersion) {
    return p.join(cacheDir, packageName, '$packageName-$docVersion');
  }
}
