# Documentation enrichment

Write OVERVIEW.md and EXAMPLES.md for a package. You have been given the package's `documentation` directory root path.

## Write EXAMPLES.md

Goal is that the reader of EXAMPLES.md should be able to identify the most relevant example and extract enough to write correct code, without opening the raw `.dart` files.

First, run `test -d <documentation>/example/` to check whether an `example/` subdirectory is present. If absent, skip this section — not all packages ship examples. Otherwise, explore the `<documentation>/example/` directory and write `<documentation>/EXAMPLES.md`, following these guidelines:

- Make it concise — this file is an overview and guide to the examples, not a place for full code listings.
- Do not insert line breaks in the middle of a sentence just to make it look better visually.

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
- <library>/ClassName/ClassName.md: the documentation page for a key class used in this example.

## Example Title 2

<!-- Another section for a different example goes here following the same structure -->
````

## Write OVERVIEW.md

The goal is to preserve every piece of technical information from the README so that OVERVIEW.md can fully replace it. Do **not** summarize or distill — keep all usage examples, API descriptions, configuration options, and caveats verbatim.

Gather source material:

- README: read `<documentation>/README.md`.
- Topics: run `ls <documentation>/topics/` (or Glob `topics/*.md`) if the directory exists — read each `.md` file enough to write a 3-sentence summary.
- Libraries: read `<documentation>/INDEX.md` — it lists all public API of the package.

Then, write `<documentation>/OVERVIEW.md` using the template below. Follow these guidelines:

- Make it concise without summarizing — all technical sections kept verbatim.
- Do not insert line breaks in the middle of a sentence just to make it look better visually.
- Prefer natural prose or bullet lists over cosmetic format such as tables and HTML.
- **IMPORTANT**: strip anything that doesn't help a reader _use_ the package:
  - Badges/shields (`![badge]`, `[![...](...)`)
  - Cosmetic HTML (`<p align="center">`, `<img>`, `<br>`, `<div>`)
  - Duplicate blank lines, extra whitespace, and other formatting that doesn't add technical value
  - Contribution guides, links to CONTRIBUTING.md, "how to file issues", "star us on GitHub" sections
  - Issue tracker triage rules, bug priority labels (P0/P1/P2…), and other project-management content
  - Links to ecosystem/related repos that aren't about how to use this package
  - Background commentary ("The story behind this package…")

Use this template for OVERVIEW.md, replacing `{{variable}}`s with actual content:

````markdown
# {{package-name}}

## Table of Contents

<!-- Add a TOC of this document including sections in the original README. Make sure to include sections in the template if any (e.g., Reading Guide). Add brief descriptions for each section. No internal link is needed. -->

## Overview

<!-- README content comes here -->

## Reading Guide

Use this guide to find what you need without exploring every file.

### Documentation structure

Here's an overview of the documentation structure at {{documentation-root}}:

<!-- Update paths or descriptions to match the actual documentation if needed. Keep the guide abstract; do not list all files or directories. -->

- `OVERVIEW.md`: this file.
- `INDEX.md`: full API listing — all libraries, classes, and functions.
- `EXAMPLES.md`: curated code examples with explanations.
- `example/`: raw example source files.
- `topics/<TopicName>.md`: additional notes and guides on specific topics.
- `{{library}}/<ClassName>/<ClassName>.md`: class overview — constructors, fields, and methods of {{library}} library.
- `{{library}}/<ClassName>/<ClassName>-<methodName>.md`: detail page for a large method.
- `{{library}}/top-level-functions/top-level-functions.md`: top-level functions overview of {{library}} library.
- `{{library}}/top-level-functions/<topLevelFunctionName>.md`: detail page for a large top-level function.
- `{{library}}/top-level-properties/top-level-properties.md`: top-level properties overview of {{library}} library.
- `{{library}}/top-level-properties/<topLevelProperty>.md`: detail page for a large top-level property.
- `{{library}}/typedefs/typedefs.md`: overview of typedefs in {{library}} library.
- `{{library}}/typedefs/<TypedefName>.md`: detail page for a large typedef.

Note that the detail pages are not always present - only for items that require more than a few sentences to explain. It is recommended to read the overview pages first such as `<ClassName>.md` or `top-level-functions.md` to get a sense of the API, then drill into detail pages as needed.

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

- "How do I do X?" — check EXAMPLES.md for usage patterns, then drill into the relevant class/method pages
- "What does class/method Y do?" — go directly to the class or method page under `<library>/<ClassName>/<ClassName>.md`
- "What API does the package expose?" — INDEX.md is a good entry point for capturing the package overview
- "Debug this error about Z" — look for the class/method mentioned in the error, check for topics/ that might cover common pitfalls or migration guides
````

## Cleanup

After you write OVERVIEW.md and EXAMPLES.md, remove the original README, as OVERVIEW.md is now the main entry point:

```shell
rm <documentation>/README.md
```