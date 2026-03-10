/// Mustache partial template for a single constructor entry.
const constructorTemplate = r'''
### {{{signature}}}

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
