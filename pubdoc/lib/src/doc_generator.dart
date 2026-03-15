import 'package:dartdoc_txt/dartdoc_txt.dart';
import 'package:file/file.dart';

import 'logger.dart';

class DocGenerator {
  final Logger logger;
  final FileSystem fs;

  DocGenerator({required this.logger, required this.fs});

  /// Generates documentation for the package at [sourcePath] and writes it
  /// to [outputDir].
  Future<void> generate({
    required String sourcePath,
    required String outputDir,
  }) async {
    // Clear output dir if it already exists (regeneration case).
    final outDir = fs.directory(outputDir);
    if (outDir.existsSync()) {
      outDir.deleteSync(recursive: true);
    }

    logger.detail('Analyzing package at $sourcePath...');
    await generateDocs(inputDir: sourcePath, outputDir: outputDir);
  }
}
