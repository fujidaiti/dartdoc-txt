import 'package:dartdoc_builder/src/utilities.dart';
import 'package:test/test.dart';

void main() {
  group('extractSummary', () {
    test('returns first paragraph from multi-paragraph doc', () {
      expect(
        extractSummary('First paragraph.\n\nSecond paragraph.'),
        equals('First paragraph.'),
      );
    });

    test('returns full text when single paragraph', () {
      expect(
        extractSummary('Just one paragraph.'),
        equals('Just one paragraph.'),
      );
    });

    test('returns empty string for null input', () {
      expect(extractSummary(null), isEmpty);
    });

    test('returns empty string for empty input', () {
      expect(extractSummary(''), isEmpty);
    });

    test('handles doc with leading blank lines', () {
      expect(
        extractSummary('\n\nFirst paragraph.\n\nSecond.'),
        equals('First paragraph.'),
      );
    });

    test('trims whitespace from result', () {
      expect(
        extractSummary('  First paragraph.  \n\nSecond.'),
        equals('First paragraph.'),
      );
    });

    test('collapses intra-paragraph newlines into spaces', () {
      expect(
        extractSummary(
          'A widget that dismisses\nthe keyboard when\nthe user drags.',
        ),
        equals('A widget that dismisses the keyboard when the user drags.'),
      );
    });
  });

  group('stripResidualHtml', () {
    test('strips <iframe> from youtube artifacts', () {
      const input = 'Before\n<iframe src="youtube.com"></iframe>\nAfter';
      expect(stripResidualHtml(input), equals('Before\n\nAfter'));
    });

    test('strips <video> from animation artifacts', () {
      const input = 'Before\n<video src="anim.mp4">fallback</video>\nAfter';
      expect(stripResidualHtml(input), equals('Before\n\nAfter'));
    });

    test('strips <dartdoc-html> placeholders', () {
      const input = 'Before\n<dartdoc-html>abc123</dartdoc-html>\nAfter';
      expect(stripResidualHtml(input), equals('Before\n\nAfter'));
    });

    test('preserves normal markdown content', () {
      const input = '# Hello\n\nSome **bold** text.';
      expect(stripResidualHtml(input), equals(input));
    });

    test('handles mixed content with HTML and markdown', () {
      const input = '# Title\n\n<iframe></iframe>\n\nParagraph.';
      final result = stripResidualHtml(input);
      expect(result, contains('# Title'));
      expect(result, contains('Paragraph.'));
      expect(result, isNot(contains('<iframe')));
    });
  });

  group('sourceLineCount', () {
    test('counts lines of source code correctly', () {
      expect(sourceLineCount('line1\nline2\nline3'), equals(3));
    });

    test('returns 0 for empty source', () {
      expect(sourceLineCount(''), equals(0));
    });

    test('returns 0 for null source', () {
      expect(sourceLineCount(null), equals(0));
    });

    test('handles single line', () {
      expect(sourceLineCount('single line'), equals(1));
    });

    test('handles trailing newline', () {
      expect(sourceLineCount('line1\nline2\n'), equals(3));
    });
  });

  group('ctorBaseName', () {
    test('returns "new" for unnamed constructor', () {
      expect(ctorBaseName('MyClass', 'MyClass'), equals('new'));
    });

    test('returns suffix for named constructor', () {
      expect(ctorBaseName('MyClass.fromJson', 'MyClass'), equals('fromJson'));
    });

    test('returns suffix for private named constructor', () {
      expect(ctorBaseName('MyClass._internal', 'MyClass'), equals('_internal'));
    });
  });

  group('safeFileName', () {
    test('passes through normal names', () {
      expect(safeFileName('myMethod'), equals('myMethod'));
    });

    test('converts operator ==', () {
      expect(safeFileName('operator =='), equals('operator_equals'));
    });

    test('converts operator +', () {
      expect(safeFileName('operator +'), equals('operator_plus'));
    });

    test('converts operator []', () {
      expect(safeFileName('operator []'), equals('operator_index'));
    });

    test('converts operator []=', () {
      expect(safeFileName('operator []='), equals('operator_index_assign'));
    });
  });

  group('unescapeHtml', () {
    test('unescapes common entities', () {
      expect(unescapeHtml('&amp;'), equals('&'));
      expect(unescapeHtml('&lt;'), equals('<'));
      expect(unescapeHtml('&gt;'), equals('>'));
      expect(unescapeHtml('&#39;'), equals("'"));
      expect(unescapeHtml('&quot;'), equals('"'));
    });

    test('unescapes decimal &#47; entity to /', () {
      expect(unescapeHtml('a&#47;b'), equals('a/b'));
    });

    test('handles multiple entities in one string', () {
      expect(
        unescapeHtml('Map&lt;String, int&gt;'),
        equals('Map<String, int>'),
      );
    });

    test('preserves text without entities', () {
      expect(unescapeHtml('hello world'), equals('hello world'));
    });
  });
}
