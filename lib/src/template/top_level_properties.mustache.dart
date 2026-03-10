/// Mustache template for top-level properties and constants page.
const topLevelPropertiesTemplate = r'''
# Top-level Properties — {{{libraryName}}}

{{#hasConstants}}
## Constants

{{#constants}}
### {{{name}}} → {{{typeName}}}

{{#hasConstantValue}}
`{{{constantValue}}}`

{{/hasConstantValue}}
{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
---

{{/constants}}
{{/hasConstants}}
{{#hasProperties}}
## Properties

{{#properties}}
### {{{name}}} → {{{typeName}}}

{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
---

{{/properties}}
{{/hasProperties}}
''';
