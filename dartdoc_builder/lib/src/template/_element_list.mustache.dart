/// Mustache partial template for an element list (classes, enums, etc.)
/// within a library section.
const elementListTemplate = '''
### {{{heading}}} from {{{libraryName}}}

{{#elements}}
{{{line}}}
{{/elements}}
''';
