# Subagent instructions: pubdoc

Follow these steps in order. You have been given a list of package names and the
absolute path to the project root.

## 1. Ensure pubdoc is installed

```
pubdoc --version
```

If not found, follow `skill/references/installation.md` before continuing.

## 2. Run `pubdoc get`

From the project root:

```
pubdoc get <package-name1> <package-name2> ...
```

This resolves each package to the version pinned in `pubspec.lock`, generates
structured text documentation if not cached, and creates symlinks:

```
<project-root>/.pubdoc/
  ├── firebase_core  →  ~/.pubdoc/cache/firebase_core/firebase_core-4.5.4/
  └── dio            →  ~/.pubdoc/cache/dio/dio-5.2.x/
```

> **Pre-requirement:** `dart pub get` must have been run at least once so that
> `pubspec.lock` and `.dart_tool/package_config.json` exist. If `pubdoc get`
> fails citing a missing lock file or package config, tell the user to run
> `dart pub get` (or `fvm dart pub get`) first and then retry.

## 3. Enrich documentation with examples

pubdoc does not include a package's `example/` directory. Adding it (plus a
plain-English overview) makes docs much more useful for understanding practical
usage patterns. Do this for each package:

### a. Find the source path

Read `.pubdoc/<package>/metadata.json`:

```json
{
  "version": "4.5.x",
  "package_version": "4.5.4",
  "source": "file:///Users/username/.pub-cache/hosted/pub.dev/firebase_core-4.5.4"
}
```

Strip the `file://` prefix from `source` to get the local filesystem path.

### b. Check whether `example/` exists in the source

Look for `<source-path>/example/`. If absent, skip this package — not all
packages ship examples.

### c. Check whether examples are already up-to-date

Read `.pubdoc/<package>/.examples_package_version` if it exists. If its content
matches `package_version` in `metadata.json`, examples are current — skip to the
next package.

### d. Copy examples into the documentation

```
cp -r <source-path>/example/ .pubdoc/<package>/example/
```

The symlink at `.pubdoc/<package>` points to the real cache directory, so this
write lands in the shared cache and is reused across projects.

### e. Write EXAMPLES.md

Read every `.dart` file inside the copied `example/` directory and write
`.pubdoc/<package>/EXAMPLES.md` with this structure:

1. **Table of Contents** at the top — one line per example file, linked to its
   section heading. An agent can read just this section to orient quickly.

2. **One section per example file**, containing:
   - Short prose: what the example demonstrates and which key APIs or classes it
     uses
   - Essential code snippets — not the full file, just the parts showing the
     core usage pattern (initialization, key method calls, important config)
   - A path link to the source file for further reading, e.g.
     `[example/lib/main.dart](example/lib/main.dart)`

Goal: an agent skimming EXAMPLES.md should be able to identify the most relevant
example and extract enough to write correct code, without opening the raw
`.dart` files.

### f. Record the package version

Write `package_version` (just the version string) to
`.pubdoc/<package>/.examples_package_version` so future runs can skip
regeneration when nothing has changed.

## 4. Generate OVERVIEW.md

OVERVIEW.md is the single entry point to the documentation. It should give an
agent everything it needs to orient quickly: what the package does, how to use
it, and where to find specific details.

Do this for each package:

### a. Check whether OVERVIEW.md is up-to-date

Read `.pubdoc/<package>/.overview_package_version` if it exists. If its content
matches `package_version` in `metadata.json`, OVERVIEW.md is current — skip to
the next package.

### b. Gather source material

From `metadata.json`, take the local `source` path (strip the `file://` prefix).

- **README:** read `<source-path>/README.md`. If absent, skip the summary
  section and proceed to the documentation guide below.
- **Topics:** list `.pubdoc/<package>/topics/` if it exists — note each `.md`
  filename and read the first heading or first sentence to get a one-line
  description.
- **Libraries:** list the subdirectories in `.pubdoc/<package>/` that contain an
  `index.md` file — these are the public library directories.

### c. Write OVERVIEW.md

Write `.pubdoc/<package>/OVERVIEW.md` with two sections:

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

3. **Topics** (only if `.pubdoc/<package>/topics/` contains `.md` files): Add a
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

### d. Record the package version

Write `package_version` to `.pubdoc/<package>/.overview_package_version` so
future runs skip regeneration when nothing has changed.

## 5. Report back

Return the absolute paths to each package's documentation:

```
Documentation ready:
- firebase_core: /path/to/project/.pubdoc/firebase_core
- dio:           /path/to/project/.pubdoc/dio
```
