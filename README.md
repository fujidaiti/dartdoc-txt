# dartdoc_md

A CLI tool that generates Markdown documentation from Dart/Flutter packages, optimized for LLM consumption.

Unlike `dartdoc` (which generates interactive HTML), `dartdoc_md` reuses dartdoc's analysis engine but produces structured, grep-friendly Markdown files designed for language models to traverse and understand.

## Usage

```
dart run dartdoc_md [options]
```

### Options

| Option                  | Description                         | Default                 |
| ----------------------- | ----------------------------------- | ----------------------- |
| `-i`, `--input`         | Input package directory             | `.` (current directory) |
| `-o`, `--output`        | Output directory                    | `doc/md`                |
| `--source-threshold`    | Max lines of source to embed inline | `10`                    |
| `--[no-]include-source` | Include source code snippets        | on                      |
| `-h`, `--help`          | Show usage information              |                         |
| `--version`             | Print the tool version              |                         |

### Example

```bash
dart run dartdoc_md -i path/to/my_package -o docs
```

## Output Structure

```
<output>/
├── index.md                    # Package overview + library & topic listing
├── topics/
│   └── Getting-Started.md      # Category pages (from dartdoc_options.yaml)
└── <library>/
    ├── index.md                # Library overview + element listing
    ├── ClassName/
    │   ├── ClassName.md        # One file per class/enum/mixin/extension
    │   └── methodName.md       # Detail pages for large members
    ├── top-level-functions.md  # Grouped top-level functions
    ├── top-level-properties.md # Properties and constants
    └── typedefs.md             # Type definitions
```

## Features

- **LLM-optimized output** — Structured Markdown with full type signatures, modifiers, and doc comments
- **Smart source embedding** — Short source code is inlined; long source is linked to separate detail pages
- **Public API only** — Filters out private elements and `lib/src/` internal libraries
- **Category/topic support** — Reads `dartdoc_options.yaml` for category definitions and generates topic pages
- **Doc comment directives** — Resolves `{@template}`, `{@macro}`, `{@example}` and strips unsupported directives
- **Comprehensive coverage** — Classes, enums, mixins, extensions, extension types, constructors, methods, properties, operators, typedefs, and top-level elements
