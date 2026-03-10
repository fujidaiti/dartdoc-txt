import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  late Directory outputDir;
  late String indexContent;

  setUpAll(() async {
    outputDir = await renderFixture('multi_library');
    indexContent = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
  });

  group('multi-library INDEX.md structure', () {
    test('creates separate directories for each library', () {
      expect(
        Directory(p.join(outputDir.path, 'alpha')).existsSync(),
        isTrue,
      );
      expect(
        Directory(p.join(outputDir.path, 'beta')).existsSync(),
        isTrue,
      );
    });

    test('does not create per-library INDEX.md in either directory', () {
      expect(
        File(p.join(outputDir.path, 'alpha', 'INDEX.md')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(outputDir.path, 'beta', 'INDEX.md')).existsSync(),
        isFalse,
      );
    });

    test('INDEX.md contains alpha library heading', () {
      expect(indexContent, contains('## alpha library'));
    });

    test('INDEX.md contains beta library heading', () {
      expect(indexContent, contains('## beta library'));
    });

    test('both library sections appear in a single file', () {
      expect(indexContent, contains('## alpha library'));
      expect(indexContent, contains('## beta library'));
    });
  });

  group('alpha library section', () {
    test('contains Classes heading with Greeter link', () {
      expect(indexContent, contains('### Classes from alpha'));
      expect(
        indexContent,
        contains('[Greeter](alpha/Greeter/Greeter.md)'),
      );
    });

    test('contains Functions heading with hello', () {
      expect(indexContent, contains('### Functions from alpha'));
      expect(indexContent, contains('- hello'));
    });

    test('contains library description', () {
      expect(indexContent, contains('The alpha library.'));
    });
  });

  group('beta library section', () {
    test('contains Enums heading with Shape link', () {
      expect(indexContent, contains('### Enums from beta'));
      expect(
        indexContent,
        contains('[Shape](beta/Shape/Shape.md)'),
      );
    });

    test('contains library description', () {
      expect(indexContent, contains('The beta library.'));
    });

    test('does not contain alpha elements', () {
      // Extract the beta section from INDEX.md
      var betaStart = indexContent.indexOf('## beta library');
      var betaSection = indexContent.substring(betaStart);
      expect(betaSection, isNot(contains('Greeter')));
      expect(betaSection, isNot(contains('hello')));
    });
  });

  group('alpha library section isolation', () {
    test('does not contain beta elements', () {
      // Extract the alpha section (from its heading to the next ## heading)
      var alphaStart = indexContent.indexOf('## alpha library');
      var afterAlpha = indexContent.indexOf('\n## ', alphaStart + 1);
      var alphaSection = afterAlpha != -1
          ? indexContent.substring(alphaStart, afterAlpha)
          : indexContent.substring(alphaStart);
      expect(alphaSection, isNot(contains('Shape')));
    });
  });
}
