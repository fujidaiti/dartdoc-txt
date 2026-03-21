import 'package:path/path.dart' as p;

import 'package:pubdoc/src/environment.dart';

class PubdocConfig {
  PubdocConfig({required this.homeDir, required this.cacheDir});

  /// Resolves the default configuration using the given [env].
  ///
  /// For now, hardcodes to `$HOME/.pubdoc/` and `$HOME/.pubdoc/cache/`.
  factory PubdocConfig.resolve(Environment env) {
    final home = env.getVariable('HOME') ?? '.';
    final homeDir = p.join(home, '.pubdoc');
    return PubdocConfig(homeDir: homeDir, cacheDir: p.join(homeDir, 'cache'));
  }
  final String homeDir;
  final String cacheDir;

  /// Returns the cache directory for a specific package and doc version.
  ///
  /// E.g. `~/.pubdoc/cache/dio/dio-5.3.x/`
  String packageCacheDir(String packageName, String docVersion) {
    return p.join(cacheDir, packageName, '$packageName-$docVersion');
  }
}
