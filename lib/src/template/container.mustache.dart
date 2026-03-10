/// Mustache template for class, enum, mixin, extension, and extension type pages.
const containerTemplate = r'''
# {{{name}}}

```dart
{{{declaration}}}
```

{{#isDeprecated}}
{{{deprecation}}}

{{/isDeprecated}}
{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
{{#hasEnumValues}}
## Enum Values

{{#enumValues}}
### {{{name}}}

{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
---

{{/enumValues}}
{{/hasEnumValues}}
{{#hasConstructors}}
## Constructors

{{#constructors}}
{{> constructor}}
{{/constructors}}
{{/hasConstructors}}
{{#hasProperties}}
## Properties

{{#properties}}
{{> field}}
{{/properties}}
{{/hasProperties}}
{{#hasMethods}}
## Methods

{{#methods}}
{{> method}}
{{/methods}}
{{/hasMethods}}
{{#hasOperators}}
## Operators

{{#operators}}
{{> operator}}
{{/operators}}
{{/hasOperators}}
''';
