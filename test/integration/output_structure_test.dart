import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  late Directory outputDir;

  setUpAll(() async {
    outputDir = await renderFixture('basic_library');
  });

  group('output structure', () {
    test('creates index.md at root', () {
      expect(File(p.join(outputDir.path, 'index.md')).existsSync(), isTrue);
    });

    test('creates library directory', () {
      expect(
        Directory(p.join(outputDir.path, 'basic_library')).existsSync(),
        isTrue,
      );
    });

    test('creates library index.md', () {
      expect(
        File(p.join(outputDir.path, 'basic_library', 'index.md')).existsSync(),
        isTrue,
      );
    });

    test('creates class file', () {
      expect(
        File(
          p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
        ).existsSync(),
        isTrue,
      );
    });

    test('creates enum file', () {
      expect(
        File(
          p.join(outputDir.path, 'basic_library', 'Color', 'Color.md'),
        ).existsSync(),
        isTrue,
      );
    });

    test('creates top-level-functions.md', () {
      expect(
        File(
          p.join(outputDir.path, 'basic_library', 'top-level-functions.md'),
        ).existsSync(),
        isTrue,
      );
    });

    test('creates top-level-properties.md', () {
      expect(
        File(
          p.join(outputDir.path, 'basic_library', 'top-level-properties.md'),
        ).existsSync(),
        isTrue,
      );
    });

    test('creates detail subdirectory for class with large method', () {
      expect(
        Directory(
          p.join(outputDir.path, 'basic_library', 'MyClass'),
        ).existsSync(),
        isTrue,
      );
    });

    test('creates detail page for method exceeding threshold', () {
      expect(
        File(
          p.join(outputDir.path, 'basic_library', 'MyClass', 'processData.md'),
        ).existsSync(),
        isTrue,
      );
    });
  });

  group('src library filtering', () {
    test('does not create src/ directory in output', () {
      expect(Directory(p.join(outputDir.path, 'src')).existsSync(), isFalse);
    });

    test('index.md does not reference src libraries', () {
      var content = File(p.join(outputDir.path, 'index.md')).readAsStringSync();
      expect(content, isNot(contains('src/')));
    });

    test('re-exported elements appear under top-level library', () {
      // MyClass is defined in lib/src/my_class.dart but exported by lib/basic_library.dart
      expect(
        File(
          p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
        ).existsSync(),
        isTrue,
      );
    });
  });

  group('package index content', () {
    test('contains package name', () {
      var content = File(p.join(outputDir.path, 'index.md')).readAsStringSync();
      expect(content, contains('# basic_library'));
    });

    test('contains version', () {
      var content = File(p.join(outputDir.path, 'index.md')).readAsStringSync();
      expect(content, contains('Version: 1.0.0'));
    });

    test('contains library link', () {
      var content = File(p.join(outputDir.path, 'index.md')).readAsStringSync();
      expect(content, contains('[basic_library](basic_library/index.md)'));
    });
  });

  group('library index content', () {
    test('contains library name', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'index.md'),
      ).readAsStringSync();
      expect(content, contains('# basic_library library'));
    });

    test('lists classes', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'index.md'),
      ).readAsStringSync();
      expect(content, contains('[MyClass](MyClass/MyClass.md)'));
    });

    test('lists enums', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'index.md'),
      ).readAsStringSync();
      expect(content, contains('[Color](Color/Color.md)'));
    });

    test('references top-level functions file', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'index.md'),
      ).readAsStringSync();
      expect(content, contains('top-level-functions.md'));
    });
  });

  group('class file content', () {
    test('contains class declaration', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
      ).readAsStringSync();
      expect(content, contains('```dart\nclass MyClass\n```'));
    });

    test('contains documentation', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
      ).readAsStringSync();
      expect(content, contains('A simple class with documentation.'));
    });

    test('contains constructors section', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
      ).readAsStringSync();
      expect(content, contains('## Constructors'));
      expect(content, contains('### MyClass.new('));
    });

    test('contains properties section', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
      ).readAsStringSync();
      expect(content, contains('## Properties'));
      expect(content, contains('### name → String'));
    });

    test('contains methods section', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
      ).readAsStringSync();
      expect(content, contains('## Methods'));
      expect(content, contains('### greet() → String'));
    });

    test('embeds small method source inline', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
      ).readAsStringSync();
      // greet() is small enough to be inline
      expect(content, contains("return 'Hello, \$name!';"));
    });

    test('links large method to detail page', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
      ).readAsStringSync();
      expect(content, contains('[full implementation](processData.md)'));
    });

    test('does not include inherited Object members', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
      ).readAsStringSync();
      // Should NOT have hashCode, runtimeType, noSuchMethod, operator ==
      expect(content, isNot(contains('### hashCode')));
      expect(content, isNot(contains('### runtimeType')));
      expect(content, isNot(contains('### noSuchMethod')));
    });

    test('source code has no HTML entities', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
      ).readAsStringSync();
      expect(content, isNot(contains('&#39;')));
      expect(content, isNot(contains('&amp;')));
      expect(content, isNot(contains('&lt;')));
      expect(content, isNot(contains('&gt;')));
    });
  });

  group('detail page content', () {
    test('contains parent.member title', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'processData.md'),
      ).readAsStringSync();
      expect(content, contains('# MyClass.processData'));
    });

    test('contains signature', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'processData.md'),
      ).readAsStringSync();
      expect(content, contains('processData(String input) → String'));
    });

    test('contains full source code', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'processData.md'),
      ).readAsStringSync();
      expect(content, contains('## Source'));
      expect(content, contains('result = result.toLowerCase()'));
    });
  });
}
