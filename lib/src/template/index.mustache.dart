/// Mustache template for the package INDEX.md with topics and library sections.
const indexTemplate = r'''
# {{{packageName}}} Index

Version: {{{version}}}

{{#hasCategories}}
## Topics

{{#categories}}
{{{line}}}
{{/categories}}

{{/hasCategories}}
{{#libraries}}
{{> library_section}}
{{/libraries}}
''';
