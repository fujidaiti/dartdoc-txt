/// Mustache template for top-level properties and constants page.
const topLevelPropertiesTemplate = '''
# Top-level Properties — {{{libraryName}}}

{{#hasConstants}}
## Constants

{{#constants}}
### {{{name}}} → {{{typeName}}}

{{#hasConstantValue}}
`{{{constantValue}}}`

{{/hasConstantValue}}
{{#hasSourceLocation}}
Source: {{{sourceLocation}}}

{{/hasSourceLocation}}
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

{{#hasSourceLocation}}
Source: {{{sourceLocation}}}

{{/hasSourceLocation}}
{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
---

{{/properties}}
{{/hasProperties}}
''';
