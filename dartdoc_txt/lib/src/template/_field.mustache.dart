/// Mustache partial template for a single field/property entry.
const fieldTemplate = '''
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
