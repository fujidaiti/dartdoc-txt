/// Mustache partial template for one library's section in the package index.
const librarySectionTemplate = r'''
## {{{libraryName}}} library

{{#hasDocumentation}}
{{{documentation}}}

{{/hasDocumentation}}
{{#elementLists}}
{{> element_list}}
{{/elementLists}}
{{#hasFunctions}}
### Functions from {{{libraryName}}}

See [top-level-functions.md]({{{libDir}}}/top-level-functions/top-level-functions.md) for more details.

{{#functions}}
{{{line}}}
{{/functions}}

{{/hasFunctions}}
{{#hasPropertiesOrConstants}}
### Properties from {{{libraryName}}}

See [top-level-properties.md]({{{libDir}}}/top-level-properties/top-level-properties.md) for more details.

{{#propertiesAndConstants}}
{{{line}}}
{{/propertiesAndConstants}}

{{/hasPropertiesOrConstants}}
{{#hasTypedefs}}
### Typedefs from {{{libraryName}}}

See [typedefs.md]({{{libDir}}}/typedefs/typedefs.md) for more details.

{{#typedefs}}
{{{line}}}
{{/typedefs}}

{{/hasTypedefs}}
''';
