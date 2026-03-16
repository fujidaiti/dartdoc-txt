---
name: pubdoc
description: >
  Prepares LLM-friendly, version-accurate API documentation for Dart/Flutter
  packages and returns the local paths so you can read them. Use this skill
  whenever you need to look up or understand the API of a Dart/Flutter package
  before implementing a feature, debugging a call, checking method signatures,
  or exploring what a package offers. Always prefer this over relying on
  training knowledge for package APIs — docs may have changed. Triggers on
  prompts like "implement X using package Y", "how do I use package Z", "add
  deep linking with app_links", "integrate firebase_core", or any time you're
  about to write code that calls into a third-party Dart/Flutter package.
---

# pubdoc

Generates structured plain-text API documentation for the exact versions of
Dart/Flutter packages your project depends on, then returns the local paths so
you can read them.

## Delegate to a subagent

This is mechanical work (command execution + text summarization). Spawn a
subagent to keep the main context clean:

- **Model:** `claude-haiku-4-5-20251001`
- **Pass:** the package name(s) and the absolute path to the project root
- **Instructions:** read and follow `skill/references/subagent.md`

Wait for the subagent to return documentation paths, then proceed.

## Reading the documentation

Documentation lives at `.pubdoc/<package>/` in the project root:

```
.pubdoc/<package>/
├── OVERVIEW.md            ← start here: README summary + documentation guide
├── INDEX.md               ← full package overview from dartdoc
├── <library-name>/        ← one directory per public library
│   ├── <ClassName>/
│   │   ├── <ClassName>.md
│   │   └── <ClassName>-methodName.md
│   └── top-level-functions/
├── topics/                ← topic pages, e.g. migration guides (if available)
├── EXAMPLES.md            ← examples overview with snippets (if available)
└── example/               ← raw example .dart files (if available)
```

Recommended order: `OVERVIEW.md` → specific class/function pages as needed.
