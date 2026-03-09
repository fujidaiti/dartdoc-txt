import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('anonymous library output', () {
    late Directory outputDir;

    setUpAll(() async {
      outputDir = await renderFixture('anonymous_library');
    });

    test('uses clean directory name for anonymous library', () {
      // Should use displayName (e.g., "anonymous_library"), not dirName
      // (which would be "file-___Users_..._anonymous_library")
      expect(
        Directory(p.join(outputDir.path, 'anonymous_library')).existsSync(),
        isTrue,
      );
    });

    test('does not create directory with file-prefix path', () {
      // Verify no directory starting with "file-" was created
      var dirs = Directory(
        outputDir.path,
      ).listSync().whereType<Directory>().map((d) => p.basename(d.path));
      expect(dirs, everyElement(isNot(startsWith('file-'))));
    });

    test('package index links use clean path', () {
      var content = File(p.join(outputDir.path, 'index.md')).readAsStringSync();
      expect(content, contains('anonymous_library/index.md'));
      expect(content, isNot(contains('file-')));
    });
  });
}
