/// Mustache template for the typedefs page of a library.
const typedefsTemplate = '''
# Typedefs — {{{libraryName}}}

{{#typedefs}}
## {{{name}}}

```dart
{{{sourceCode}}}
```

{{#hasSourceLocation}}
Source: {{{sourceLocation}}}

{{/hasSourceLocation}}
{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
---

{{/typedefs}}
''';
