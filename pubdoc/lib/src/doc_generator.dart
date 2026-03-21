import 'package:dartdoc_txt/dartdoc_txt.dart';

import 'environment.dart';
import 'logger.dart';

class DocGenerator {
  final Environment env;

  DocGenerator({required this.env});

  /// Generates documentation for the package at [sourcePath] and writes it
  /// to [outputDir].
  Future<void> generate({
    required String sourcePath,
    required String outputDir,
  }) async {
    // Clear output dir if it already exists (regeneration case).
    final outDir = env.fs.directory(outputDir);
    if (outDir.existsSync()) {
      outDir.deleteSync(recursive: true);
    }

    log.fine('Analyzing package at $sourcePath...');
    await generateDocs(
      outputDir: outputDir,
      options: RenderOptions(packageRoot: sourcePath),
    );
  }
}
