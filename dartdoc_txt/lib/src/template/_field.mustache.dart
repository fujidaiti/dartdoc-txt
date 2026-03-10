/// Mustache partial template for a single field/property entry.
const fieldTemplate = r'''
### {{{name}}} → {{{typeName}}}

{{#hasAttributes}}
{{{attributes}}}

{{/hasAttributes}}
{{#isDeprecated}}
{{{deprecation}}}

{{/isDeprecated}}
{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
---
''';
