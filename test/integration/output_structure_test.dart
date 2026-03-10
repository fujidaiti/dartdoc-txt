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
    test('creates INDEX.md at root', () {
      expect(File(p.join(outputDir.path, 'INDEX.md')).existsSync(), isTrue);
    });

    test('creates library directory', () {
      expect(
        Directory(p.join(outputDir.path, 'basic_library')).existsSync(),
        isTrue,
      );
    });

    test('does not create library INDEX.md', () {
      expect(
        File(p.join(outputDir.path, 'basic_library', 'INDEX.md')).existsSync(),
        isFalse,
      );
    });

    test('creates README.md at root', () {
      expect(File(p.join(outputDir.path, 'README.md')).existsSync(), isTrue);
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
          p.join(
            outputDir.path,
            'basic_library',
            'top-level-functions',
            'top-level-functions.md',
          ),
        ).existsSync(),
        isTrue,
      );
    });

    test('creates top-level-properties.md', () {
      expect(
        File(
          p.join(
            outputDir.path,
            'basic_library',
            'top-level-properties',
            'top-level-properties.md',
          ),
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
          p.join(
            outputDir.path,
            'basic_library',
            'MyClass',
            'MyClass-processData.md',
          ),
        ).existsSync(),
        isTrue,
      );
    });

    test('creates detail page for named constructor exceeding threshold', () {
      expect(
        File(
          p.join(
            outputDir.path,
            'basic_library',
            'MyClass',
            'MyClass-fromMap.md',
          ),
        ).existsSync(),
        isTrue,
      );
    });
  });

  group('src library filtering', () {
    test('does not create src/ directory in output', () {
      expect(Directory(p.join(outputDir.path, 'src')).existsSync(), isFalse);
    });

    test('INDEX.md does not reference src libraries', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
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
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('# basic_library Index'));
    });

    test('contains version', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('Version: 1.0.0'));
    });

    test('contains library heading', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('## basic_library library'));
    });
  });

  group('library index content', () {
    test('contains library name', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('## basic_library library'));
    });

    test('lists classes', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('[MyClass](basic_library/MyClass/MyClass.md)'));
    });

    test('lists enums', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('[Color](basic_library/Color/Color.md)'));
    });

    test('references top-level functions file', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(
        content,
        contains('basic_library/top-level-functions/top-level-functions.md'),
      );
    });

    test('"See" references include "for more details."', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(
        content,
        contains(
          'See [top-level-functions.md](basic_library/top-level-functions/top-level-functions.md) for more details.',
        ),
      );
      expect(
        content,
        contains(
          'See [top-level-properties.md](basic_library/top-level-properties/top-level-properties.md) for more details.',
        ),
      );
    });

    test('lists functions inline', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('- add — A simple top-level function.'));
    });

    test('lists properties inline', () {
      var content = File(p.join(outputDir.path, 'INDEX.md')).readAsStringSync();
      expect(content, contains('- defaultName — A top-level constant.'));
      expect(content, contains('- globalCounter — A top-level variable.'));
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
      expect(
        content,
        contains('[full implementation](MyClass-processData.md)'),
      );
    });

    test('links large named constructor to detail page', () {
      var content = File(
        p.join(outputDir.path, 'basic_library', 'MyClass', 'MyClass.md'),
      ).readAsStringSync();
      expect(content, contains('[full implementation](MyClass-fromMap.md)'));
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
        p.join(
          outputDir.path,
          'basic_library',
          'MyClass',
          'MyClass-processData.md',
        ),
      ).readAsStringSync();
      expect(content, contains('# MyClass.processData'));
    });

    test('contains signature', () {
      var content = File(
        p.join(
          outputDir.path,
          'basic_library',
          'MyClass',
          'MyClass-processData.md',
        ),
      ).readAsStringSync();
      expect(content, contains('processData(String input) → String'));
    });

    test('contains full source code', () {
      var content = File(
        p.join(
          outputDir.path,
          'basic_library',
          'MyClass',
          'MyClass-processData.md',
        ),
      ).readAsStringSync();
      expect(content, contains('## Source'));
      expect(content, contains('result = result.toLowerCase()'));
    });
  });

  group('constructor detail page content', () {
    test('contains parent.member title', () {
      var content = File(
        p.join(
          outputDir.path,
          'basic_library',
          'MyClass',
          'MyClass-fromMap.md',
        ),
      ).readAsStringSync();
      expect(content, contains('# MyClass.fromMap'));
    });

    test('contains full source code', () {
      var content = File(
        p.join(
          outputDir.path,
          'basic_library',
          'MyClass',
          'MyClass-fromMap.md',
        ),
      ).readAsStringSync();
      expect(content, contains('## Source'));
      expect(content, contains("throw ArgumentError('name is required')"));
    });
  });

  group('edge_cases library index', () {
    late Directory edgeCasesOutputDir;

    setUpAll(() async {
      edgeCasesOutputDir = await renderFixture('edge_cases');
    });

    test('lists typedefs inline', () {
      var content = File(
        p.join(edgeCasesOutputDir.path, 'INDEX.md'),
      ).readAsStringSync();
      expect(
        content,
        contains(
          '- StringCallback — A typedef for a callback that takes a [String].',
        ),
      );
    });

    test('"See" reference for typedefs includes "for more details."', () {
      var content = File(
        p.join(edgeCasesOutputDir.path, 'INDEX.md'),
      ).readAsStringSync();
      expect(
        content,
        contains(
          'See [typedefs.md](edge_cases/typedefs/typedefs.md) for more details.',
        ),
      );
    });
  });
}
