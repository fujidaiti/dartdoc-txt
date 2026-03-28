import 'package:dartdoc_builder/dartdoc_builder.dart';
import 'package:pubdoc/src/environment.dart';
import 'package:pubdoc/src/exceptions.dart';
import 'package:pubdoc/src/logger.dart';

class DocGenerator {
  DocGenerator({required this.env});
  final Environment env;

  /// Generates documentation for the package at [sourcePath] and writes it
  /// to [outputDir].
  Future<void> generate({
    required String sourcePath,
    required String outputDir,
    String? sdkDir,
  }) async {
    // Clear output dir if it already exists (regeneration case).
    final outDir = env.fs.directory(outputDir);
    if (outDir.existsSync()) {
      outDir.deleteSync(recursive: true);
    }

    log.fine('Analyzing package at $sourcePath...');
    try {
      await generateDocs(
        outputDir: outputDir,
        options: RenderOptions(packageRoot: sourcePath, sdkDir: sdkDir),
      );
      // Intentionally catch errors to handle a null type cast error
      // that may be thrown by DartdocOptionContext.sdkDir
      // ignore: avoid_catching_errors
    } on Error {
      if (sdkDir == null) {
        throw PubdocException(
          'Failed to generate documentation for $sourcePath. '
          'This may be due to lack of --sdk-dir argument, which is required '
          'when running pubdoc as a standalone executable.',
        );
      } else {
        rethrow;
      }
    }
  }
}
