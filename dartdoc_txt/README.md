# dartdoc_txt

A CLI tool that generates Markdown documentation from Dart/Flutter packages,
optimized for LLM consumption.

Unlike `dartdoc` (which generates interactive HTML), `dartdoc_txt` reuses
dartdoc's analysis engine but produces structured, grep-friendly Markdown files
designed for language models to traverse and understand.

### Requirements

Run `dart pub get` in the target package directory before running `dartdoc_txt`.
Otherwise, types from dependency packages appear as `dynamic` in the generated
documentation.

## Usage

```
Usage: dart run dartdoc_txt [options]

-i, --input (mandatory)      Input directory.
-o, --output (mandatory)     Output directory.
    --source-threshold       Max lines of source to embed inline (default: 10).
                             (defaults to "10")
    --[no-]include-source    Include source code snippets.
                             (defaults to on)
-h, --help                   Show usage information.
    --version                Print the tool version.
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
