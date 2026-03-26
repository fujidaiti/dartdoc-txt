---
name: doc-explorer
description: Answers questions about Dart/Flutter packages by exploring version-accurate documentation generated from the project's actual dependencies. Use this skill whenever you need to understand a package API — don't rely on training knowledge, as APIs may have changed. This includes implementing features with a third-party package, debugging errors or stack traces involving one, looking up method signatures or class behavior, figuring out how to configure or integrate a package, or migrating/upgrading to a new version. If you're about to call into a package, especially when adopting a new one, use this skill first.
---

# doc-explorer

Answers questions about Dart/Flutter packages by exploring version-accurate documentation generated from the project's actual dependencies.

## Step 1: Prepare documentation

Run a Dart script at `${CLAUDE_SKILL_DIR}/scripts/prepare_documentation.dart` to get the documentation locations for the packages you want to explore. Note that you must know the canonical package names. The script's usage is:

```
prepare_documentation.dart --project </absolute/path/to/dart/project/root> <package-name1> <package-name2> ...
```

**IMPORTANT**: Make sure to specify the path to the Dart/Flutter project root, which contains the `pubspec.yaml` file.

Then, read the JSON output:

```json
{
  "packages": {
    "dio": {
      "documentation": "/Users/you/.pubdoc/cache/dio/dio-5.3.x",
      "needsEnrichment": true
    }
  },
  "error": null
}
```

### Troubleshooting

**IMPORTANT**: if you encounter an error during this step, check these common issues first before trying to debug by yourself.

#### Package not found or name is incorrect

Stop processing and ask the user for the canonical package name.

## Step 2: Enrich documentation (if possible)

**IMPORTANT**: this step requires write permission to the documentation cache directory. If you are in a read-only mode (e.g., in Plan mode), skip this step and proceed to step 3.

For each package where `needsEnrichment == true`, spawn an enrichment subagent.
If multiple packages need enrichment, spawn them in parallel and wait for all to finish before continuing.

- Model: fast, low-latency
- Permissions: allow to read/write files in `documentation` directory
- Pass: the package's `documentation` path

Always use this prompt template:

```
Generate OVERVIEW.md and EXAMPLES.md for the package documentation at <documentation-path>.
Read and follow this for additional instructions: ${CLAUDE_SKILL_DIR}/agents/doc-enrichment.md.
```

If you cannot spawn a subagent, check each package for a missing `OVERVIEW.md` and generate it yourself by following `agents/doc-enrichment.md`.

**IMPORTANT**: do not proceed to step 3 until enrichment is complete for all packages that need it.

## Step 3: Explore documentation

Spawn a subagent to delegate the exploration:

- Model: fast, low-latency
- Permissions: read-only
- Pass: the query, per-package `documentation` paths from step 1

If you can use a built-in read-only agent optimized for searching and analyzing codebases (e.g., Explore agent), use it here. If you cannot spawn a subagent, read and follow `agents/doc-explorer.md` yourself.

Always use this prompt template:

```
Read the package documentation and answer the query:

- Documentation: <documentation-path>
- Query: <describe what you want to know about the package>

Read and follow this for additional instructions: ${CLAUDE_SKILL_DIR}/agents/doc-explorer.md.
```

Wait for the findings, then use them to proceed with your task.

## Note on documentation access

Rely on the subagent's findings — do not read the documentation yourself unless the subagent's report is insufficient and further reading is clearly needed.
