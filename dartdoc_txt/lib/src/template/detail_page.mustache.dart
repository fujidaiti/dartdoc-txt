/// Mustache template for detail pages of elements with large source code.
const detailPageTemplate = r'''
# {{{title}}}

```dart
{{{signature}}}
```

{{#hasAnnotations}}
{{{annotations}}}

{{/hasAnnotations}}
{{#isDeprecated}}
{{{deprecation}}}

{{/isDeprecated}}
{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
## Source

```dart
{{{sourceCode}}}
```
''';
