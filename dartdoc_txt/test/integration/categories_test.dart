import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  late Directory outputDir;

  setUpAll(() async {
    outputDir = await renderFixture('categories');
  });

  group('topics directory structure', () {
    test('creates topics/ directory', () {
      expect(Directory(p.join(outputDir.path, 'topics')).existsSync(), isTrue);
    });

    test('creates getting-started.md from doc/ subdirectory', () {
      expect(
        File(
          p.join(outputDir.path, 'topics', 'getting-started.md'),
        ).existsSync(),
        isTrue,
      );
    });

    test('creates utilities.md', () {
      expect(
        File(p.join(outputDir.path, 'topics', 'utilities.md')).existsSync(),
        isTrue,
      );
    });
  });

  group('package index topics section', () {
    test('contains Topics heading', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('## Topics'));
    });

    test('links to Getting Started topic file', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('[Getting Started](topics/getting-started.md)'));
    });

    test('links to Utilities topic file', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('[Utilities](topics/utilities.md)'));
    });
  });

  group('topic file content — Getting Started', () {
    late String content;

    setUp(() {
      content = File(
        p.join(outputDir.path, 'topics', 'getting-started.md'),
      ).readAsStringSync();
    });

    test('contains documentation text', () {
      expect(content, contains('Welcome to the categories package.'));
    });

    test('contains elements heading', () {
      expect(content, contains('## Elements in this category'));
    });

    test('contains Classes section with Greeter', () {
      expect(content, contains('### Classes'));
      expect(content, contains('[Greeter](categories/Greeter/Greeter.md)'));
    });

    test('contains Enums section with BasicColor', () {
      expect(content, contains('### Enums'));
      expect(
        content,
        contains('[BasicColor](categories/BasicColor/BasicColor.md)'),
      );
    });

    test('does not contain elements from other categories', () {
      expect(content, isNot(contains('StringHelper')));
      expect(content, isNot(contains('capitalize')));
    });
  });

  group('topic file content — Utilities', () {
    late String content;

    setUp(() {
      content = File(
        p.join(outputDir.path, 'topics', 'utilities.md'),
      ).readAsStringSync();
    });

    test('contains documentation text', () {
      expect(content, contains('Utility classes and functions.'));
    });

    test('contains Classes section with StringHelper', () {
      expect(content, contains('### Classes'));
      expect(
        content,
        contains('[StringHelper](categories/StringHelper/StringHelper.md)'),
      );
    });

    test('contains Functions section with capitalize as plain text', () {
      expect(content, contains('### Functions'));
      expect(content, contains('- capitalize'));
    });

    test('does not contain elements from other categories', () {
      expect(content, isNot(contains('Greeter')));
      expect(content, isNot(contains('BasicColor')));
    });
  });
}
