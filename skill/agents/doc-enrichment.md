# Documentation enrichment

Write OVERVIEW.md and EXAMPLES.md for a package. You have been given the
package's `documentation` directory path.

## Write EXAMPLES.md

Run `test -d <documentation>/example/` to check whether an `example/`
subdirectory is present. If absent, skip — not all packages ship examples.
Otherwise:

1. Explore the `<documentation>/example/` directory and write
   `<documentation>/EXAMPLES.md` following this template:

Goal is that the reader of EXAMPLES.md should be able to identify the most
relevant example and extract enough to write correct code, without opening the
raw `.dart` files.

Use this template for EXAMPLES.md:

````markdown
# Examples

This document is a summary of curated examples of the <package-name> package.
Actual example code lives in the `example/` directory.

## Example Title

<!-- short prose: what this example demonstrates and which key APIs or classes it uses -->

```dart
<!-- essential snippets only — not the full file; just initialization, key method calls, and important configuration -->
```

<!-- List the paths to related files for this example -->

See also:

- example/bin/main.dart: the original source file for this example.
- <library>/ClassName/ClassName.md: the documentation page for a key class used
  in this example.

## Example Title 2

<!-- Another section for a different example goes here following the same structure -->
````

## Write OVERVIEW.md

The goal is to preserve every piece of technical information from the README so
that OVERVIEW.md can fully replace it. Do **not** summarize or distill — keep
all usage examples, API descriptions, configuration options, and caveats
verbatim.

Gather source material:

- README: read `<documentation>/README.md`.
- Topics: run `ls <documentation>/topics/` (or Glob `topics/*.md`) if the
  directory exists — read each `.md` file enough to write a 3-sentence summary.
- Libraries: read `<documentation>/INDEX.md` — it lists all public API of the
  package.

Then, write `<documentation>/OVERVIEW.md` using the template below. Follow these
guidelines:

- Make it concise without summarizing — all technical sections kept verbatim.
- Prefer natural prose or bullet lists over cosmetic format such as tables and
  HTML.
- **IMPORTANT**: strip anything that doesn't help a reader _use_ the package:
  - Badges/shields (`![badge]`, `[![...](...)`)
  - Cosmetic HTML (`<p align="center">`, `<img>`, `<br>`, `<div>`)
  - Duplicate blank lines, extra whitespace, and other formatting that doesn't
    add technical value
  - Contribution guides, links to CONTRIBUTING.md, "how to file issues", "star
    us on GitHub" sections
  - Issue tracker triage rules, bug priority labels (P0/P1/P2…), and other
    project-management content
  - Links to ecosystem/related repos that aren't about how to use this package
  - Background commentary ("The story behind this package…")

Here's the template for OVERVIEW.md:

````markdown
# <package-name>

<!-- README content comes here -->

## Reading Guide

Use this guide to find what you need without exploring every file.

### Documentation structure

<!-- Eliminate items from the structure overview if they don't exist -->

```
<documentation>/
├── OVERVIEW.md # This file
├── INDEX.md # Full API listing: all libraries, classes, functions
├── EXAMPLES.md # Curated code examples with explanations
├── example/ # Raw example code
├── topics/ # Additional notes and guides on specific topics
│   └── <TopicName>.md
└── <library>/
    ├── <ClassName>/
    │   ├── <ClassName>.md # Class overview: constructors, fields, methods
    │   └── <ClassName>-<methodName>.md # Detail page for a large method
    ├── top-level-functions/
    │   ├── top-level-functions.md # Top level functions overview
    │   └── <functionName>.md # Detail page for a large function
    ├── top-level-properties/
    │   ├── top-level-properties.md # Top level properties overview
    │   └── <topLevelProperty>.md # Detail page for a large property
    └── typedefs/
        ├── typedefs.md # Overview of typedefs in this library
        └── <TypedefName>.md # Detail page for a large typedef

```

### Topics

<!-- Include only if `<documentation>/topics/` exists. One entry per file -->

- Topic Name
  - Location: topics/TopicName.md
  - Summary: <3-sentence summary of the topic>
- Topic Name 2
  - Location: topics/TopicName2.md
  - Summary: <3-sentence summary of the topic>

### Where to look

<!-- Eliminate items that don't match the actual documentation content -->

- "How do I do X?" — check EXAMPLES.md for usage patterns, then drill into the
  relevant class/method pages
- "What does class/method Y do?" — go directly to the class or method page under
  `<library>/<ClassName>/<ClassName>.md`
- "What API does the package expose?" — read INDEX.md for the full library
  listing
- "Debug this error about Z" — look for the class/method mentioned in the error,
  check for topics/ that might cover common pitfalls or migration guides
````

## Cleanup

After you write OVERVIEW.md and EXAMPLES.md, remove the original README, as
OVERVIEW.md is now the main entry point:

```shell
rm <documentation>/README.md
```
