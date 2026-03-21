# dartdoc_txt

A CLI tool that generates Markdown documentation from Dart/Flutter packages,
optimized for LLM consumption.

Unlike `dartdoc` (which generates interactive HTML), `dartdoc_txt` reuses
dartdoc's analysis engine but produces structured, grep-friendly Markdown files
designed for language models to traverse and understand.

## Usage

```
dart run dartdoc_txt [options]
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

### Prerequisites

Run `dart pub get` (or `flutter pub get`) in the target package directory before
running `dartdoc_txt`. The analyzer needs `.dart_tool/package_config.json` to
resolve dependency types — without it, types from dependencies may appear as
`dynamic` in the generated documentation.

### Example

```bash
dart run dartdoc_txt -i path/to/my_package -o docs
```

## Output Structure

```
<output>/
├── README.md                         # Package readme (if present)
├── INDEX.md                          # Package overview + library & topic listing
├── topics/
│   └── getting-started.md            # Category pages (from dartdoc_options.yaml)
└── <library>/
    ├── ClassName/
    │   ├── ClassName.md              # One file per class/enum/mixin/extension
    │   └── ClassName-methodName.md   # Detail pages for large members
    ├── top-level-functions/
    │   ├── top-level-functions.md    # Grouped top-level functions
    │   └── functionName.md           # Detail pages for large functions
    ├── top-level-properties/
    │   └── top-level-properties.md   # Properties and constants
    └── typedefs/
        └── typedefs.md               # Type definitions
```

## Features

- **LLM-optimized output** — Structured Markdown with full type signatures,
  modifiers, and doc comments
- **Smart source embedding** — Short source code is inlined; long source is
  linked to separate detail pages
- **Public API only** — Filters out private elements and `lib/src/` internal
  libraries
- **Category/topic support** — Reads `dartdoc_options.yaml` for category
  definitions and generates topic pages
- **Doc comment directives** — Resolves `{@template}`, `{@macro}`, `{@example}`
  and strips unsupported directives
- **Comprehensive coverage** — Classes, enums, mixins, extensions, extension
  types, constructors, methods, properties, operators, typedefs, and top-level
  elements
