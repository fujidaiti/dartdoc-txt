/// Mustache template for the typedefs page of a library.
const typedefsTemplate = r'''
# Typedefs — {{{libraryName}}}

{{#typedefs}}
## {{{name}}}

```dart
{{{sourceCode}}}
```

{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
---

{{/typedefs}}
''';
