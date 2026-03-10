/// Mustache template for category/topic pages listing categorized elements.
const categoryTemplate = r'''
{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
## Elements in this category

{{#sections}}
{{> category_section}}
{{/sections}}
''';
