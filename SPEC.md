# dartdoc-txt: Specification & Implementation Plan

## Overview

`dartdoc-txt` is a Dart CLI package that generates **Markdown documentation** from a Dart/Flutter package's source code. It wraps the `dartdoc` package, reusing its analysis engine and model layer, but replaces the HTML rendering pipeline with a Markdown output tailored for **LLM consumption**.

### Goals

- Generate structured, grep-friendly Markdown documentation
- Resolve doc comment directives (`{@template}`, `{@macro}`, `{@example}`)
- Adaptively include source code snippets based on size
- Support `dartdoc_options.yaml` categories (e.g. migration guides)
- Produce output that LLMs can efficiently traverse and understand

### Non-goals

- Browser-friendly navigation (search, sidebars, JS)
- Internal hyperlink resolution for comment references (`[ClassName]` stays as-is)
- `{@youtube}`, `{@animation}`, `{@inject-html}` support (stripped or ignored)

---

## Architecture

### Relationship to dartdoc

```
┌─────────────────────────────────────────────────────┐
│ dartdoc (upstream package)                          │
│                                                     │
│  ┌──────────────────────┐  ┌──────────────────────┐ │
│  │ Dart Analyzer         │  │ Model Layer           │ │
│  │ (source analysis)     │  │ (PackageGraph, etc.)  │ │
│  └──────────┬───────────┘  └──────────┬───────────┘ │
│             │                         │              │
│             ▼                         │              │
│  ┌──────────────────────┐             │              │
│  │ PubPackageBuilder     │─────────────┘              │
│  │ (builds PackageGraph) │                            │
│  └──────────┬───────────┘                            │
│             │                                        │
└─────────────┼────────────────────────────────────────┘
              │  ← dartdoc-txt uses this boundary
              ▼
┌─────────────────────────────────────────────────────┐
│ dartdoc-txt (this package)                           │
│                                                     │
│  ┌──────────────────────┐  ┌──────────────────────┐ │
│  │ CLI / Config          │  │ Markdown Renderer     │ │
│  │ (argument parsing,    │  │ (walks PackageGraph,  │ │
│  │  option handling)     │  │  emits .md files)     │ │
│  └──────────────────────┘  └──────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### What we reuse from dartdoc

| Component | dartdoc API | Purpose |
|-----------|-------------|---------|
| Option parsing | `parseOptions()` | CLI args, `dartdoc_options.yaml` |
| Package metadata | `pubPackageMetaProvider` | Package name, version, etc. |
| Analysis + model building | `PubPackageBuilder.buildPackageGraph()` | The expensive step: Dart analysis → `PackageGraph` |
| Model classes | `Package`, `Library`, `Class`, `Method`, `Field`, etc. | All documentation data |
| Doc comment processing | `ModelElement.documentation` | Directives resolved, macros expanded, still Markdown |
| Source code | `ModelElement.sourceCode` | Raw source text of element |
| Categories | `Category`, `CategoryDefinition` | Category metadata + linked markdown files |

### What we do NOT use from dartdoc

- `Generator`, `GeneratorBackend`, `HtmlGeneratorBackend`
- `Templates`, `HtmlAotTemplates`, Mustachio codegen
- `DocumentationRendererHtml` (Markdown→HTML conversion)
- Sidebar, search index, 404 page, CSS/JS resources
- `href`, `filePath`, `fileName` properties on model elements (HTML-oriented paths)

---

## Output Structure

```
<output-dir>/
├── index.md                              # Package overview + library listing
├── topics/
│   ├── Migration-Guide.md                # From dartdoc_options.yaml categories
│   └── Plugins.md                        # Raw markdown content from the package
├── <library-name>/
│   ├── index.md                          # Library overview + element listing
│   ├── <ClassName>.md                    # One file per class/enum/mixin/extension/extensionType
│   ├── <ClassName>/
│   │   ├── <methodName>.md              # Detail page (only for members with large source)
│   │   └── <otherMethod>.md
│   ├── top-level-functions.md            # All top-level functions grouped
│   ├── top-level-functions/
│   │   └── <functionName>.md            # Detail page (only for large functions)
│   ├── top-level-properties.md           # All top-level properties + constants grouped
│   ├── typedefs.md                       # All typedefs grouped
│   └── extensions.md                     # All extensions grouped (if not one-file-per)
```

### File naming rules

- Library directory name: `library.dirName` (reuse dartdoc's logic; e.g. `dart:core` → `dart-core`)
- Container files: `{Name}.md` (e.g. `Animation.md`, `AnimationController.md`)
- Detail subdirectory: `{Name}/` matching the parent file
- Detail files: `{memberName}.md`
- Top-level groups: `top-level-functions.md`, `top-level-properties.md`, `typedefs.md`
- Topic files: `topics/{category-name}.md`

---

## Document Formats

### index.md (Package)

```markdown
# {packageName}

Version: {version}

{package documentation from README or dartdoc_options}

## Libraries

- [{libraryName}]({libraryDirName}/index.md) — {first paragraph of library doc}
- ...

## Topics

- [{categoryName}](topics/{categoryName}.md) — {first paragraph of category doc}
- ...
```

### Library index.md

```markdown
# {libraryName} library

{library documentation}

## Classes

- [{ClassName}]({ClassName}.md) — {summary}
- ...

## Enums

- [{EnumName}]({EnumName}.md) — {summary}
- ...

## Mixins

- [{MixinName}]({MixinName}.md) — {summary}
- ...

## Extensions

- [{ExtensionName}]({ExtensionName}.md) — {summary}
- ...

## Extension Types

- [{ExtTypeName}]({ExtTypeName}.md) — {summary}
- ...

## Functions

See [top-level-functions.md](top-level-functions.md)

## Properties

See [top-level-properties.md](top-level-properties.md)

## Typedefs

See [typedefs.md](typedefs.md)
```

### ClassName.md (Class / Enum / Mixin / Extension / ExtensionType)

```markdown
# {ClassName}

```dart
{class declaration with modifiers, supertype, mixins, interfaces}
```

> **Deprecated:** {deprecation message}          ← only if @deprecated

{full documentation from doc comment}

## Constructors

### {ClassName}({params}) {const?}

{annotations as inline badges: `@required` · `@visibleForTesting`}

{documentation}

```dart                                          ← only if source ≤ threshold
{constructor source code}
```

See [full source]({ClassName}/{constructorName}.md)  ← only if source > threshold

---

## Properties

### {name} → {Type}

{attribute badges: `final` · `late` · `@override`}

{documentation}

---

## Methods

### {name}({params}) → {ReturnType}

{annotation badges}

{documentation}

```dart                                          ← only if source ≤ threshold
{method source code}
```

See [full source]({ClassName}/{methodName}.md)    ← only if source > threshold

---

## Operators

### operator {op}({params}) → {ReturnType}

{documentation}
```

### Detail Page ({ClassName}/{methodName}.md)

Created only when source code exceeds the line threshold.

```markdown
# {ClassName}.{methodName}

```dart
{full method signature}
```

{annotation badges}

{full documentation}

## Source

```dart
{full source code}
```
```

### top-level-functions.md

```markdown
# Top-level Functions — {libraryName}

## {functionName}

```dart
{ReturnType} {functionName}({params})
```

{documentation}

```dart                                          ← inline or reference, same rules
{source}
```
```

### topics/{categoryName}.md

```markdown
{raw content of the markdown file referenced in dartdoc_options.yaml}

## Elements in this category

### Classes
- [{ClassName}]({lib}/{ClassName}.md)
- ...

### Functions
- ...
```

---

## Source Code Snippet Rules

### Threshold

- **≤ 10 lines of source**: embed inline in the parent document
- **> 10 lines of source**: create a detail page and link to it
- The threshold should be configurable via CLI flag (default: 10)

### What counts as "source"

- `ModelElement.sourceCode` — the raw source text from the AST node
- This includes the signature, body, and any annotations on the element
- Doc comments are NOT included in `sourceCode`

### When to include source

Source code is included for:
- Methods, operators
- Constructors
- Top-level functions
- Getters and setters (when non-trivial)

Source code is NOT included for:
- Classes/enums/mixins (the declaration line is already shown)
- Fields/properties (type + name is sufficient; getters/setters are separate)
- Typedefs (the alias is already shown in the signature)
- Abstract methods (no body)

---

## Documentation Text Handling

### Pipeline

```
ModelElement.documentationComment     ← raw, with /// delimiters
        ↓
ModelElement.documentation            ← directives resolved, macros expanded,
                                        still Markdown (NOT HTML)
        ↓
dartdoc-txt strips residual HTML       ← remove {@youtube}, {@animation},
                                        {@inject-html} artifacts
        ↓
Write to .md file                     ← final output
```

### Key property: `ModelElement.documentation`

This is the interception point. At this stage:
- `{@template}`/`{@endtemplate}` — extracted and stored
- `{@macro name}` — fully expanded (recursively)
- `{@example}` — converted to fenced code blocks
- `{@category}`, `{@canonicalFor}` — stripped
- The text is still **pure Markdown**, before any HTML conversion

### Residual HTML stripping

`{@youtube}` and `{@animation}` inject `<iframe>` and `<video>` HTML into the Markdown text at the `documentation` stage. These should be stripped or replaced with a plain-text note (e.g. `(Video: {url})`).

`{@inject-html}` inserts `<dartdoc-html>...</dartdoc-html>` placeholders. These should be stripped entirely.

### Summary extraction

`oneLineDoc` exists but is HTML. Instead, extract the first paragraph from `documentation`:

```dart
String extractSummary(String? documentation) {
  if (documentation == null || documentation.isEmpty) return '';
  // Split on double newline (paragraph break) and take the first paragraph.
  var firstParagraph = documentation.split(RegExp(r'\n\s*\n')).first;
  return firstParagraph.trim();
}
```

---

## Metadata Rendering

### Class/container declaration

Render as a fenced Dart code block showing the full declaration:

```dart
String renderDeclaration(InheritingContainer c) {
  var buffer = StringBuffer();
  // Modifiers: abstract, sealed, base, final, interface, mixin
  for (var mod in c.containerModifiers) {
    buffer.write('${mod.name} ');
  }
  buffer.write('class ${c.name}');
  // Type parameters
  if (c.typeParameters.isNotEmpty) {
    buffer.write('<${c.typeParameters.map((t) => t.name).join(', ')}>');
  }
  // Supertype
  if (c.supertype != null) {
    buffer.write(' extends ${c.supertype!.nameWithGenericsPlain}');
  }
  // Mixins (for Class)
  if (c is Class && c.mixedInTypes.isNotEmpty) {
    buffer.write('\n    with ${c.mixedInTypes.map((t) => t.nameWithGenericsPlain).join(', ')}');
  }
  // Interfaces
  if (c.publicInterfaceElements.isNotEmpty) {
    buffer.write('\n    implements ${c.publicInterfaceElements.map((e) => e.name).join(', ')}');
  }
  return buffer.toString();
}
```

Note: Use `nameWithGenericsPlain` (not `nameWithGenerics` which contains HTML).

### Method/function signature

```
### {name}({paramSignature}) → {ReturnType}
```

Build param signature from `element.parameters`:
- `required Type name` for required named params
- `Type name` for positional params
- `[Type name = default]` for optional positional
- `{Type name = default}` for optional named

Use `parameter.modelType.nameWithGenericsPlain` for the type.

### Annotations

Render as inline code badges on a line below the heading:

```
`@override` · `@protected` · `@visibleForTesting`
```

Use `element.annotations` list. Skip `@override` on operators where it's obvious.

### Deprecation

Render as a blockquote with the deprecation message:

```
> **Deprecated:** {message}
```

Extract message from the `@Deprecated('message')` annotation.

### Attributes

Render `final`, `late`, `const`, `static` as inline code badges alongside annotations:

```
`final` · `@override`
```

---

## CLI Interface

```
dart run dartdoc_txt [options]

Options:
  --input         Input directory (default: current directory)
  --output        Output directory (default: doc/md)
  --source-threshold
                  Max lines of source to embed inline (default: 10)
  --include-source
                  Include source code snippets (default: true)
  --help          Show usage information
```

The tool should also respect `dartdoc_options.yaml` for:
- `exclude` / `include` (which libraries to document)
- `categories` (category definitions with markdown files)
- `examplePathPrefix`
- `showUndocumentedCategories`

These are handled by dartdoc's `parseOptions()` which we reuse.

---

## Package Layout

```
dartdoc_txt/
├── pubspec.yaml
├── bin/
│   └── dartdoc_txt.dart                    # CLI entry point: parse args, build
│                                          #   PackageGraph, invoke renderer
├── lib/
│   ├── dartdoc_txt.dart                    # Public API barrel file (if used as a library)
│   └── src/
│       ├── markdown_renderer.dart         # Top-level orchestrator: walks PackageGraph,
│       │                                  #   creates output directories, delegates to
│       │                                  #   element renderers, writes files
│       ├── element_renderers.dart         # Rendering functions per element type:
│       │                                  #   renderContainer(), renderExtension(),
│       │                                  #   renderMethod(), renderField(),
│       │                                  #   renderConstructor(), renderOperator(),
│       │                                  #   renderTopLevelFunctions(), renderTypedefs(),
│       │                                  #   renderDetailPage(), renderCategory()
│       ├── signature_builder.dart         # renderDeclaration(), renderSignature(),
│       │                                  #   renderAnnotations(), renderAttributes(),
│       │                                  #   renderDeprecation()
│       └── utilities.dart                 # extractSummary(), stripResidualHtml(),
│                                          #   sourceLineCount(), mdFileName()
└── test/
    ├── test_helper.dart                   # Shared renderFixture() helper
    ├── fixtures/
    │   ├── basic_library/
    │   │   ├── pubspec.yaml
    │   │   └── lib/
    │   │       └── basic_library.dart
    │   ├── modifiers/
    │   │   └── lib/
    │   │       └── modifiers.dart
    │   ├── inheritance/
    │   │   └── lib/
    │   │       └── inheritance.dart
    │   ├── generics/
    │   │   └── lib/
    │   │       └── generics.dart
    │   ├── documentation/
    │   │   ├── pubspec.yaml
    │   │   ├── dartdoc_options.yaml
    │   │   ├── doc/
    │   │   │   └── guide.md
    │   │   └── lib/
    │   │       └── documentation.dart
    │   ├── source_threshold/
    │   │   └── lib/
    │   │       └── source_threshold.dart
    │   └── edge_cases/
    │       └── lib/
    │           └── edge_cases.dart
    ├── unit/
    │   ├── utilities_test.dart
    │   ├── signature_test.dart
    │   ├── element_rendering_test.dart
    │   └── documentation_test.dart
    ├── integration/
    │   ├── output_structure_test.dart
    │   ├── categories_test.dart
    │   └── links_test.dart
    └── golden/
        ├── golden_test.dart
        └── basic_library/                 # Expected output snapshot
            ├── index.md
            └── basic_library/
                ├── index.md
                ├── MyClass.md
                └── ...
```

### Module responsibilities

| File | Responsibility |
|------|----------------|
| `bin/dartdoc_txt.dart` | CLI arg parsing, calls `parseOptions()` + `PubPackageBuilder`, invokes `MarkdownRenderer.render()` |
| `markdown_renderer.dart` | Owns the output directory. Iterates packages → libraries → elements. Calls element renderers, writes results to disk. Decides when to create detail subdirectories. |
| `element_renderers.dart` | Pure functions that take a model element + options and return a Markdown string. No file I/O — just string building. |
| `signature_builder.dart` | Pure functions for formatting declarations, signatures, annotations, and attributes as Markdown fragments. |
| `utilities.dart` | Small stateless helpers: summary extraction, HTML stripping, line counting, file name derivation. |
| `test_helper.dart` | `renderFixture()` — builds `PackageGraph` from a fixture path, runs the renderer to a temp directory, returns the output directory. |

---

## Implementation Plan

### Phase 1: Project Setup

1. Create a new Dart package `dartdoc_txt`
2. Add dependency on `package:dartdoc` (version `^9.0.0`)
3. Create `bin/dartdoc_txt.dart` entry point
4. Set up basic CLI argument parsing (reuse `parseOptions()` from dartdoc + custom args)

### Phase 2: Core Pipeline

5. Build the `PackageGraph` using `PubPackageBuilder`
6. Implement `MarkdownRenderer` class that walks the `PackageGraph`:

```dart
class MarkdownRenderer {
  final PackageGraph packageGraph;
  final String outputDir;
  final int sourceLineThreshold;

  Future<void> render() async {
    _renderPackageIndex();
    for (var lib in packageGraph.localPublicLibraries) {
      _renderLibrary(lib);
    }
    _renderCategories();
  }
}
```

### Phase 3: Element Rendering

Implement rendering methods for each element type:

7. `_renderPackageIndex()` — `index.md`
8. `_renderLibrary(Library)` — `{lib}/index.md`
9. `_renderContainer(InheritingContainer)` — `{lib}/{Name}.md` (handles Class, Enum, Mixin, ExtensionType)
10. `_renderExtension(Extension)` — `{lib}/{Name}.md`
11. `_renderTopLevelFunctions(Library)` — `{lib}/top-level-functions.md`
12. `_renderTopLevelProperties(Library)` — `{lib}/top-level-properties.md`
13. `_renderTypedefs(Library)` — `{lib}/typedefs.md`

### Phase 4: Member Rendering

14. `_renderConstructor(Constructor)` — section within container file
15. `_renderMethod(Method)` — section within container file
16. `_renderField(Field)` — section within container file
17. `_renderOperator(Operator)` — section within container file
18. `_renderDetailPage(ModelElement)` — `{Name}/{member}.md` (when source > threshold)

### Phase 5: Utilities

19. `extractSummary(String?)` — first paragraph extraction
20. `renderDeclaration(Container)` — class/mixin/enum declaration builder
21. `renderSignature(ModelElement)` — method/function signature builder
22. `renderAnnotations(ModelElement)` — annotation badge line
23. `stripResidualHtml(String)` — remove `<iframe>`, `<video>`, `<dartdoc-html>` artifacts
24. `sourceLines(ModelElement)` → `int` — count lines to decide inline vs. detail page

### Phase 6: Categories

25. Read `Category` objects from `package.categories`
26. For categories with `documentationFile`, read the markdown and write to `topics/`
27. Append element listing to each category file

### Phase 7: Testing

28. Set up test infrastructure (see Testing Plan below)
29. Implement unit tests for utility functions
30. Implement unit tests for element rendering
31. Implement integration tests with fixture packages
32. Implement golden file tests for full output

### Phase 8: Polish

33. Add `--source-threshold` CLI option
34. Add `--include-source` / `--no-include-source` flag
35. Handle edge cases: anonymous libraries, operators (file-name-safe names), name collisions
36. Test against real packages (dio, riverpod, flutter/widgets)

---

## Testing Plan

### Strategy

Tests are split into three layers:

1. **Unit tests** — test individual rendering functions with mock/minimal model data
2. **Integration tests** — run the full pipeline against small fixture packages and assert on output
3. **Golden file tests** — snapshot the full output for a fixture package, review manually once, then assert no regressions

### Test fixtures

Create small Dart packages under `test/fixtures/` that exercise specific language features.
Each fixture is a minimal valid Dart package (with `pubspec.yaml` and `lib/`).

```
test/
  fixtures/
    basic_library/
      pubspec.yaml
      lib/
        basic_library.dart           # simple class, function, enum
    modifiers/
      lib/
        modifiers.dart               # abstract, sealed, base, final, interface, mixin class
    inheritance/
      lib/
        inheritance.dart             # extends, with, implements, super chains
    generics/
      lib/
        generics.dart                # type parameters, bounded generics, generic methods
    documentation/
      lib/
        documentation.dart           # {@template}, {@macro}, {@example}, no-doc elements
      dartdoc_options.yaml           # category definitions
      doc/
        guide.md                     # category markdown file
    source_threshold/
      lib/
        source_threshold.dart        # methods with varying body sizes (2, 10, 11, 50 lines)
    edge_cases/
      lib/
        edge_cases.dart              # operators, anonymous library, name collisions,
                                     #   extensions, extension types, typedefs
```

### Unit tests — utility functions

File: `test/unit/utilities_test.dart`

```dart
group('extractSummary', () {
  test('returns first paragraph from multi-paragraph doc', ...);
  test('returns full text when single paragraph', ...);
  test('returns empty string for null input', ...);
  test('returns empty string for empty input', ...);
  test('handles doc with leading blank lines', ...);
});

group('stripResidualHtml', () {
  test('strips <iframe> from {@youtube} artifacts', ...);
  test('strips <video> from {@animation} artifacts', ...);
  test('strips <dartdoc-html> placeholders', ...);
  test('preserves normal markdown content', ...);
  test('handles mixed content with HTML and markdown', ...);
});

group('sourceLines', () {
  test('counts lines of source code correctly', ...);
  test('returns 0 for empty source', ...);
  test('handles trailing newline', ...);
});
```

### Unit tests — signature rendering

File: `test/unit/signature_test.dart`

These tests build a `PackageGraph` from a fixture and then test rendering
functions against real model elements (not mocks — the model classes are
too complex to mock usefully).

```dart
// Build the PackageGraph once in setUpAll, then test against its elements.

group('renderDeclaration', () {
  test('simple class', () {
    // class Foo {}
    expect(renderDeclaration(fooClass), equals('class Foo'));
  });
  test('abstract class with supertype', () {
    // abstract class Bar extends Foo {}
    expect(renderDeclaration(barClass), equals('abstract class Bar extends Foo'));
  });
  test('class with mixins and interfaces', () {
    // class Baz extends Foo with MixinA implements InterfaceA, InterfaceB {}
    expect(renderDeclaration(bazClass), contains('with MixinA'));
    expect(renderDeclaration(bazClass), contains('implements InterfaceA, InterfaceB'));
  });
  test('sealed class', () {
    expect(renderDeclaration(sealedClass), startsWith('sealed class'));
  });
  test('class with type parameters', () {
    // class Generic<T extends Comparable<T>> {}
    expect(renderDeclaration(genericClass), contains('<T extends Comparable<T>>'));
  });
  test('mixin with superclass constraint', ...);
  test('enum', ...);
  test('extension type', ...);
});

group('renderSignature', () {
  test('simple method: no params, void return', () {
    expect(renderSignature(doStuff), equals('doStuff() → void'));
  });
  test('method with positional params', () {
    expect(renderSignature(m), equals('add(int a, int b) → int'));
  });
  test('method with named params and defaults', () {
    expect(renderSignature(m), equals('fetch({required String url, int? timeout}) → Future<Response>'));
  });
  test('method with optional positional params', () {
    expect(renderSignature(m), equals('greet(String name, [String? title]) → String'));
  });
  test('generic method', () {
    expect(renderSignature(m), equals('cast<T>(Object obj) → T'));
  });
  test('operator', () {
    expect(renderSignature(op), equals('operator ==(Object other) → bool'));
  });
  test('const constructor', () {
    expect(renderSignature(ctor), equals('Foo({required int x}) const'));
  });
  test('named constructor', () {
    expect(renderSignature(ctor), equals('Foo.named(int y)'));
  });
  test('factory constructor', () {
    expect(renderSignature(ctor), equals('Foo.create() → Foo factory'));
  });
});

group('renderAnnotations', () {
  test('single annotation', () {
    expect(renderAnnotations(element), equals('`@override`'));
  });
  test('multiple annotations joined with separator', () {
    expect(renderAnnotations(element), equals('`@protected` · `@visibleForTesting`'));
  });
  test('no annotations returns empty string', () {
    expect(renderAnnotations(element), isEmpty);
  });
  test('deprecated renders as blockquote, not badge', () {
    expect(renderDeprecation(element), equals('> **Deprecated:** Use NewClass instead.'));
  });
});

group('renderAttributes', () {
  test('final field', () {
    expect(renderAttributes(field), equals('`final`'));
  });
  test('static const field', () {
    expect(renderAttributes(field), equals('`static` · `const`'));
  });
  test('late final field with override', () {
    expect(renderAttributes(field), equals('`late` · `final` · `@override`'));
  });
});
```

### Unit tests — element rendering

File: `test/unit/element_rendering_test.dart`

Test the Markdown output of each rendering method. Use fixture packages
and assert on the generated string content.

```dart
group('renderContainer (Class)', () {
  test('includes declaration code block', () {
    var md = renderContainer(myClass);
    expect(md, contains('```dart\nclass MyClass'));
  });
  test('includes documentation', () {
    var md = renderContainer(myClass);
    expect(md, contains('A well-documented class.'));
  });
  test('includes Constructors section with all public constructors', () {
    var md = renderContainer(myClass);
    expect(md, contains('## Constructors'));
    expect(md, contains('### MyClass('));
  });
  test('includes Properties section with fields', () {
    var md = renderContainer(myClass);
    expect(md, contains('## Properties'));
  });
  test('includes Methods section', () {
    var md = renderContainer(myClass);
    expect(md, contains('## Methods'));
  });
  test('omits empty sections', () {
    // A class with no operators should not have ## Operators
    var md = renderContainer(noOperatorsClass);
    expect(md, isNot(contains('## Operators')));
  });
  test('deprecated class shows deprecation notice', () {
    var md = renderContainer(deprecatedClass);
    expect(md, contains('> **Deprecated:**'));
  });
  test('enum includes enum values section', ...);
  test('mixin includes superclass constraints', ...);
  test('extension shows extended type', ...);
});

group('source code threshold', () {
  test('small method source is embedded inline', () {
    var md = renderContainer(classWithSmallMethod, sourceThreshold: 10);
    expect(md, contains('```dart\nvoid smallMethod()'));
    // No link to detail file
    expect(md, isNot(contains('full source')));
  });
  test('large method source links to detail page', () {
    var md = renderContainer(classWithLargeMethod, sourceThreshold: 10);
    // Source NOT inline
    expect(md, isNot(contains('void largeMethod() {')));
    // Link to detail page present
    expect(md, contains('[full implementation]'));
  });
  test('abstract methods have no source section', () {
    var md = renderContainer(abstractClass, sourceThreshold: 10);
    expect(md, isNot(contains('```dart\nvoid abstractMethod()')));
  });
  test('threshold 0 means never embed inline', ...);
  test('threshold 999 means always embed inline', ...);
});
```

### Unit tests — documentation processing

File: `test/unit/documentation_test.dart`

Uses the `documentation` fixture package which has `{@template}`, `{@macro}`, etc.

```dart
group('documentation text', () {
  test('resolved macro content appears in output', () {
    // The fixture has {@template foo}...{@endtemplate} and {@macro foo}
    var md = renderContainer(classWithMacro);
    expect(md, contains('This text was defined in a template.'));
    // The {@macro foo} directive itself should not appear
    expect(md, isNot(contains('{@macro')));
    expect(md, isNot(contains('{@template')));
  });
  test('youtube artifacts are stripped', () {
    var md = renderContainer(classWithYoutube);
    expect(md, isNot(contains('<iframe')));
  });
  test('inject-html artifacts are stripped', () {
    var md = renderContainer(classWithInjectHtml);
    expect(md, isNot(contains('<dartdoc-html>')));
  });
  test('example directive produces fenced code block', () {
    var md = renderContainer(classWithExample);
    expect(md, contains('```'));
  });
  test('undocumented element has no documentation section', () {
    var md = renderContainer(undocumentedClass);
    // Should still render the declaration and members, just no doc text
    expect(md, contains('# UndocumentedClass'));
    expect(md, contains('```dart\nclass UndocumentedClass'));
  });
});
```

### Integration tests — full output structure

File: `test/integration/output_structure_test.dart`

Run the full `MarkdownRenderer` against a fixture package and check the
file tree.

```dart
group('output structure', () {
  late Directory outputDir;

  setUpAll(() async {
    // Build PackageGraph from basic_library fixture, render to temp dir
    outputDir = await renderFixture('basic_library');
  });

  test('creates index.md at root', () {
    expect(File('${outputDir.path}/index.md').existsSync(), isTrue);
  });
  test('creates library directory', () {
    expect(Directory('${outputDir.path}/basic_library').existsSync(), isTrue);
  });
  test('creates library index.md', () {
    expect(File('${outputDir.path}/basic_library/index.md').existsSync(), isTrue);
  });
  test('creates class file', () {
    expect(File('${outputDir.path}/basic_library/MyClass.md').existsSync(), isTrue);
  });
  test('creates detail subdirectory only when needed', () {
    // Only exists if a member exceeds the source threshold
  });
  test('creates top-level-functions.md when library has functions', ...);
  test('does not create top-level-functions.md when library has no functions', ...);
  test('creates topics directory when categories exist', ...);
});
```

### Integration tests — categories

File: `test/integration/categories_test.dart`

```dart
group('categories', () {
  late Directory outputDir;

  setUpAll(() async {
    outputDir = await renderFixture('documentation');
  });

  test('creates topic file from dartdoc_options.yaml', () {
    expect(File('${outputDir.path}/topics/Migration-Guide.md').existsSync(), isTrue);
  });
  test('topic file contains original markdown content', () {
    var content = File('${outputDir.path}/topics/Migration-Guide.md').readAsStringSync();
    expect(content, contains(/* expected content from doc/guide.md */));
  });
  test('topic file lists categorized elements', () {
    var content = File('${outputDir.path}/topics/Migration-Guide.md').readAsStringSync();
    expect(content, contains('## Elements in this category'));
  });
});
```

### Integration tests — link correctness

File: `test/integration/links_test.dart`

Verify that every internal Markdown link in the output points to a file
that actually exists.

```dart
group('internal links', () {
  late Directory outputDir;
  late List<File> allMdFiles;

  setUpAll(() async {
    outputDir = await renderFixture('basic_library');
    allMdFiles = outputDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();
  });

  test('all internal markdown links resolve to existing files', () {
    final linkPattern = RegExp(r'\[.*?\]\(([^)]+\.md)\)');
    for (var file in allMdFiles) {
      var content = file.readAsStringSync();
      for (var match in linkPattern.allMatches(content)) {
        var target = match.group(1)!;
        // Resolve relative to the file's directory
        var resolved = p.normalize(p.join(p.dirname(file.path), target));
        expect(File(resolved).existsSync(), isTrue,
            reason: 'Broken link in ${file.path}: $target');
      }
    }
  });
});
```

### Golden file tests

File: `test/golden/golden_test.dart`

Snapshot full output for a fixture and compare against checked-in golden files.
Use `dart test --update-goldens` to regenerate after intentional changes.

```
test/
  golden/
    golden_test.dart
    basic_library/                   # expected output snapshot
      index.md
      basic_library/
        index.md
        MyClass.md
        ...
```

```dart
group('golden', () {
  test('basic_library output matches golden files', () async {
    var outputDir = await renderFixture('basic_library');
    var goldenDir = Directory('test/golden/basic_library');

    for (var goldenFile in goldenDir.listSync(recursive: true).whereType<File>()) {
      var relativePath = p.relative(goldenFile.path, from: goldenDir.path);
      var actualFile = File(p.join(outputDir.path, relativePath));

      expect(actualFile.existsSync(), isTrue,
          reason: 'Missing output file: $relativePath');
      expect(actualFile.readAsStringSync(), equals(goldenFile.readAsStringSync()),
          reason: 'Mismatch in $relativePath');
    }
  });
});
```

### Test helper

A shared helper to build a `PackageGraph` from a fixture and run the renderer:

```dart
Future<Directory> renderFixture(String fixtureName, {int sourceThreshold = 10}) async {
  var fixturePath = p.join('test', 'fixtures', fixtureName);
  var config = parseOptions(pubPackageMetaProvider, ['--input', fixturePath]);
  var packageBuilder = PubPackageBuilder(config!, pubPackageMetaProvider);
  var packageGraph = await packageBuilder.buildPackageGraph();

  var outputDir = Directory.systemTemp.createTempSync('dartdoc_txt_test_');
  var renderer = MarkdownRenderer(
    packageGraph: packageGraph,
    outputDir: outputDir.path,
    sourceLineThreshold: sourceThreshold,
  );
  await renderer.render();
  return outputDir;
}
```

### What NOT to test

- **dartdoc's analysis correctness** — trust that `PackageGraph` gives us correct model data
- **dartdoc's directive resolution** — trust that `documentation` has macros expanded
- **Markdown validity** — we're generating simple Markdown; no need for a Markdown parser in tests
- **HTML rendering** — we don't render HTML

---

## Key dartdoc APIs Reference

### Entry point

```dart
import 'package:dartdoc/src/dartdoc_options.dart';
import 'package:dartdoc/src/model/model.dart';
import 'package:dartdoc/src/package_meta.dart';

var config = parseOptions(pubPackageMetaProvider, arguments);
var packageBuilder = PubPackageBuilder(config!, pubPackageMetaProvider);
var packageGraph = await packageBuilder.buildPackageGraph();
```

### Model traversal

```dart
packageGraph.defaultPackage              // Package
package.publicLibrariesSorted            // List<Library>
package.categories                       // List<Category>

library.classes                          // List<Class>
library.enums                            // List<Enum>
library.mixins                           // List<Mixin>
library.extensions                       // List<Extension>
library.extensionTypes                   // List<ExtensionType>
library.functions                        // List<ModelFunction>
library.properties                       // List<TopLevelVariable>
library.constants                        // Iterable<TopLevelVariable>
library.typedefs                         // List<Typedef>
library.dirName                          // String (directory name)

class.constructors                       // List<Constructor>
class.declaredMethods                    // Iterable<Method>
class.declaredFields                     // Iterable<Field>
class.declaredOperators                  // List<Operator>
class.instanceMethods                    // Iterable<Method> (incl. inherited)
class.instanceFields                     // Iterable<Field> (incl. inherited)
class.inheritedMethods                   // Iterable<Method> (inherited only)
class.supertype                          // DefinedElementType?
class.mixedInTypes                       // Iterable (for Class only)
class.containerModifiers                 // List<ContainerModifier>
```

### Element properties

```dart
element.name                             // String
element.documentation                    // String (Markdown, directives resolved)
element.hasDocumentation                 // bool
element.documentationComment             // String? (raw with ///)
element.sourceCode                       // String (raw source text)
element.isPublic                         // bool
element.isDocumented                     // bool
element.isDeprecated                     // bool
element.isCanonical                      // bool
element.annotations                      // List<Annotation>
element.attributes                       // Set<Attribute> (final, late, etc.)
element.parameters                       // List<Parameter>
element.modelType                        // ElementType (for fields, params)
element.characterLocation                // CharacterLocation?

parameter.name                           // String
parameter.modelType                      // ElementType
parameter.hasDefaultValue                // bool
parameter.defaultValue                   // String?
parameter.isRequiredPositional           // bool
parameter.isOptionalPositional           // bool
parameter.isRequiredNamed                // bool
parameter.isNamed                        // bool

elementType.nameWithGenericsPlain        // String (plain text, no HTML)
elementType.nullabilitySuffix            // String ("?" or "")
```

### Categories

```dart
package.categories                       // List<Category>
category.name                            // String (display name)
category.documentationFile               // File? (linked markdown)
category.documentation                   // String? (file contents)
category.classes                         // Iterable<Class>
category.enums                           // Iterable<Enum>
category.extensions                      // Iterable<Extension>
category.functions                       // Iterable<ModelFunction>
category.externalItems                   // Iterable<ExternalItem>
```
