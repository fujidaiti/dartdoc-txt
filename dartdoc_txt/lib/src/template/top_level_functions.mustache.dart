/// Mustache template for top-level functions page of a library.
const topLevelFunctionsTemplate = '''
# Top-level Functions — {{{libraryName}}}

{{#functions}}
## {{{name}}}

```dart
{{{signature}}}
```

{{#hasSourceLocation}}
Source: {{{sourceLocation}}}

{{/hasSourceLocation}}
{{#isDeprecated}}
{{{deprecation}}}

{{/isDeprecated}}
{{#hasAnnotations}}
{{{annotations}}}

{{/hasAnnotations}}
{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
{{#hasInlineSource}}
```dart
{{{inlineSource}}}
```

{{/hasInlineSource}}
{{#hasDetailLink}}
See [full implementation]({{{detailLink}}})

{{/hasDetailLink}}
---

{{/functions}}
''';
