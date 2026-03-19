/// Mustache partial template for a single operator entry.
const operatorTemplate = r'''
### {{{signature}}}

{{#hasSourceLocation}}
Source: {{{sourceLocation}}}

{{/hasSourceLocation}}
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
