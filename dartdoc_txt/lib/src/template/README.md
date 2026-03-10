# Template Files

Mustache templates used by `element_renderers.dart` and `markdown_renderer.dart` to generate Markdown documentation. All templates use triple-mustache (`{{{ }}}`) to avoid HTML escaping since the output is Markdown, not HTML.

## Main Templates

| File | Render function | Description |
|------|----------------|-------------|
| `container.mustache` | `renderContainer()` | Class, Enum, Mixin, Extension, ExtensionType page |
| `index.mustache` | `_renderIndex()` | Package INDEX.md with topics and library sections |
| `top_level_functions.mustache` | `renderTopLevelFunctions()` | Top-level functions page for a library |
| `top_level_properties.mustache` | `renderTopLevelProperties()` | Top-level properties and constants page |
| `typedefs.mustache` | `renderTypedefs()` | Typedefs page for a library |
| `detail_page.mustache` | `renderDetailPage()` | Detail page for elements with large source code |
| `category.mustache` | `renderCategory()` | Category/topic page listing categorized elements |

## Partials

Partials are included via `{{> name}}` (without the `_` prefix). For example, `{{> constructor}}` resolves to `_constructor.mustache`.

| File | Used in | Description |
|------|---------|-------------|
| `_constructor.mustache` | `container` | Single constructor entry |
| `_field.mustache` | `container` | Single field/property entry |
| `_method.mustache` | `container` | Single method entry |
| `_operator.mustache` | `container` | Single operator entry |
| `_library_section.mustache` | `index` | One library's section in the package index |
| `_element_list.mustache` | `_library_section` | Element list (classes, enums, etc.) within a library section |
| `_category_section.mustache` | `category` | Element group within a category page |

## Data Keys

### container.mustache

- `name` — Container name
- `declaration` — Full declaration (from `renderDeclaration()`)
- `isDeprecated` / `deprecation` — Deprecation notice
- `hasDocumentation` / `documentation` — Cleaned documentation text
- `hasEnumValues` / `enumValues[]` — Enum values (each has `name`, `hasDocumentation`, `documentation`)
- `hasConstructors` / `constructors[]` — Constructor data (see `_constructor` partial)
- `hasProperties` / `properties[]` — Field data (see `_field` partial)
- `hasMethods` / `methods[]` — Method data (see `_method` partial)
- `hasOperators` / `operators[]` — Operator data (see `_operator` partial)

### _constructor.mustache / _method.mustache

- `signature` — Full signature (from `renderSignature()`)
- `hasAnnotations` / `annotations` — Annotation badges
- `isDeprecated` / `deprecation` — Deprecation notice
- `hasDocumentation` / `documentation` — Cleaned documentation
- `hasInlineSource` / `inlineSource` — Inline source code (when below threshold)
- `hasDetailLink` / `detailLink` — Link to detail page (when above threshold)

### _field.mustache

- `name` — Field name
- `typeName` — Type name
- `hasAttributes` / `attributes` — Attribute badges (static, final, const, etc.)
- `isDeprecated` / `deprecation` — Deprecation notice
- `hasDocumentation` / `documentation` — Cleaned documentation

### _operator.mustache

- `signature` — Full signature
- `hasDocumentation` / `documentation` — Cleaned documentation
- `hasInlineSource` / `inlineSource` — Inline source code
- `hasDetailLink` / `detailLink` — Link to detail page

### detail_page.mustache

- `title` — Page title (e.g., `MyClass.methodName`)
- `signature` — Full signature
- `hasAnnotations` / `annotations` — Annotation badges
- `isDeprecated` / `deprecation` — Deprecation notice
- `hasDocumentation` / `documentation` — Cleaned documentation
- `sourceCode` — Full source code

### index.mustache

- `packageName` — Package name
- `version` — Package version
- `hasCategories` / `categories[]` — Topic entries (each has `line`)
- `libraries[]` — Library section data (see `_library_section` partial)

### _library_section.mustache

- `libraryName` — Library name
- `libDir` — Library directory name
- `hasDocumentation` / `documentation` — Library documentation
- `elementLists[]` — Element list data (see `_element_list` partial)
- `hasFunctions` / `functions[]` — Function entries (each has `line`)
- `hasPropertiesOrConstants` / `propertiesAndConstants[]` — Property entries (each has `line`)
- `hasTypedefs` / `typedefs[]` — Typedef entries (each has `line`)

### _element_list.mustache

- `heading` — Section heading (e.g., "Classes")
- `libraryName` — Library name
- `elements[]` — Element entries (each has `line`)

### category.mustache

- `hasDocumentation` / `documentation` — Category documentation
- `sections[]` — Category section data (see `_category_section` partial)

### _category_section.mustache

- `heading` — Section heading (e.g., "Classes")
- `elements[]` — Element entries (each has `line`)
