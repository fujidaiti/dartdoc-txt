/// Mustache template for detail pages of elements with large source code.
const detailPageTemplate = '''
# {{{title}}}

```dart
{{{signature}}}
```

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
## Source

```dart
{{{sourceCode}}}
```
''';
