# dartdoc_builder

A Dart package that provides APIs to generate Markdown documentation from
Dart/Flutter packages, optimized for LLM consumption.

Unlike [dartdoc][] (which generates interactive HTML), dartdoc_builder reuses
dartdoc's analysis engine but produces structured, grep-friendly Markdown files
designed for language models to traverse and understand.

See the [example][] for usage details.

[dartdoc]: https://pub.dev/packages/dartdoc
[example]: example/main.dart

## Output Structure

```
<output>/
├── README.md                         # Copy of the package README (if present)
├── INDEX.md                          # All libraries' public APIs
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
