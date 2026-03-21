# Documentation enrichment

Generate OVERVIEW.md and EXAMPLES.md for a package. You have been given the
package's `source` path and its `documentation` path.

## 1. Generate EXAMPLES.md

Check if `<source>/example/` exists. If absent, skip — not all packages ship
examples. Otherwise:

1. Copy examples into the documentation:

   ```
   cp -r <source>/example/ <documentation>/example/
   ```

2. Explore the copied `example/` directory and write
   `<documentation>/EXAMPLES.md` with this structure:
   - **Table of Contents** at the top — one line per example file, linked to its
     section heading. An agent can read just this section to orient quickly.

   - **One section per example file**, containing:
     - Short prose: what the example demonstrates and which key APIs or classes
       it uses
     - Essential code snippets — not the full file, just the parts showing the
       core usage pattern (initialization, key method calls, important config)
     - A path link to the source file for further reading, e.g.
       `[example/lib/main.dart](example/lib/main.dart)`

   Goal: an agent skimming EXAMPLES.md should be able to identify the most
   relevant example and extract enough to write correct code, without opening
   the raw `.dart` files.

## 2. Generate OVERVIEW.md

Gather source material:

- **README:** read `<source>/README.md`. If absent, skip the summary section and
  proceed to the documentation guide below.
- **Topics:** list `<documentation>/topics/` if it exists — note each `.md`
  filename and read the first heading or first sentence to get a one-line
  description.
- **Libraries:** list the subdirectories in the documentation root that contain
  an `index.md` file — these are the public library directories.

Write `<documentation>/OVERVIEW.md` with two sections:

---

**Section 1 — Package summary** (from README)

Goal: a 3-minute read that tells the reader what the package does and how to use
it. Omit everything that doesn't help an agent write code.

- If the README is ≤ 80 lines of substantive content, include it with minimal
  editing (just strip the noise listed below).
- If longer, distill it: keep the purpose, core API concepts, key configuration,
  and any important caveats. Cut aggressively.

Strip unconditionally:

- Badges/shields (`![badge]`, `[![...](...)`)
- Cosmetic HTML (`<p align="center">`, `<img>`, `<br>`, `<div>`)
- Contribution guides, "how to file issues", "star us on GitHub" sections
- Changelog entries
- Non-technical background commentary ("The story behind this package…")

Convert markdown tables to bullet lists. For example, an options table:

```
| Option    | Default | Description      |
| --------- | ------- | ---------------- |
| --timeout | 30      | Request timeout  |
```

becomes:

```
- `--timeout` (default: 30) — request timeout
```

---

**Section 2 — Documentation guide**

Goal: help the reader find what they need without exploring every file.

Include:

1. A short paragraph explaining the directory layout — mention that
   `EXAMPLES.md` has curated snippets and that each `<library>/index.md` lists
   the available API.

2. A flat bullet list of the key files and directories:
   - One line per public library directory:
     `<library>/index.md — <brief description if inferrable from the library name, otherwise omit>`
   - `EXAMPLES.md — code examples with explanations` (only if it exists)

3. **Topics** (only if `<documentation>/topics/` contains `.md` files): Add a
   "Topics" sub-section with one bullet per file:
   `- [topics/<FileName>.md](topics/<FileName>.md) — <one-line description>`
   These often contain migration guides, advanced usage, or conceptual
   explanations worth consulting for deeper understanding.

---

The finished file should look like:

```markdown
# <PackageName>

<package summary — prose, no tables, no badges>

---

## Documentation

<one-paragraph explanation of layout>

Key files:

- `EXAMPLES.md` — code examples with explanations
- `<library>/index.md` — API reference for <library>
- ...

### Topics

- [`topics/MigrationGuide.md`](topics/MigrationGuide.md) — migrating from v1 to
  v2
```
