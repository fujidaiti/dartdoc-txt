/// Mustache partial template for a single method entry.
const methodTemplate = '''
### {{{signature}}}

{{#hasSourceLocation}}
Source: {{{sourceLocation}}}

{{/hasSourceLocation}}
{{#hasAnnotations}}
{{{annotations}}}

{{/hasAnnotations}}
{{#isDeprecated}}
{{{deprecation}}}

{{/isDeprecated}}
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
''';
