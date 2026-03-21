---
name: pubdoc
description: >
  Look up how a Dart/Flutter package works using version-accurate documentation
  generated from the project's actual dependencies. Use this skill whenever you
  need to understand a package API before writing code — don't rely on training
  knowledge, as APIs may have changed. This includes implementing features with
  a third-party package, debugging errors or stack traces involving one, looking
  up method signatures or class behavior, figuring out how to configure or
  integrate a package, or migrating/upgrading to a new version. If you're about
  to call into a package you're not 100% sure about, use this skill first.
---

# pubdoc

Answers questions about Dart/Flutter packages by generating version-accurate
documentation and exploring it.

## Step 1: Run `pubdoc get`

From the project root, run:

```
fvm dart run pubdoc get --json=0 --quiet <package-name1> <package-name2> ...
```

Parse the JSON output and extract per-package `source` and `documentation`:

```json
{
  "output": {
    "packages": {
      "dio": {
        "documentation": "/path/to/project/.pubdoc/dio",
        "version": "5.3.x",
        "source": "/Users/you/.pub-cache/hosted/pub.dev/dio-5.3.6",
        "cache": "hit"
      }
    }
  },
  "errors": [],
  "logs": []
}
```

If the command fails or `errors` is non-empty, read
`references/troubleshooting.md` and follow its guidance.

## Step 2: Enrich documentation (if needed)

For each package where `cache != "hit"` (freshly generated docs), spawn an
enrichment subagent. If multiple packages need enrichment, spawn them in
parallel and wait for all to finish before continuing.

- **Model:** fast, low-latency (e.g., Claude Haiku)
- **Permissions:** read-only, except it may write/delete `OVERVIEW.md` and
  `EXAMPLES.md` (and copy `example/` dirs) under `.pubdoc/<package>/`
- **Pass:** the package's `documentation` and `source` paths, and the project
  root
- **Instructions:** read and follow `references/doc-enrichment.md`

Example prompt:

```
Generate OVERVIEW.md and EXAMPLES.md for the package at:
  Documentation: /path/to/project/.pubdoc/dio/
  Source: /Users/you/.pub-cache/hosted/pub.dev/dio-5.3.6

Read and follow <absolute-path-to-skill>/references/doc-enrichment.md.
```

If you cannot spawn a subagent, check each package for a missing `OVERVIEW.md`
and generate it yourself by following `references/doc-enrichment.md`.

## Step 3: Explore documentation

If you can spawn a subagent, delegate the exploration:

- **Model:** fast, low-latency (e.g., Claude Haiku)
- **Permissions:** read-only
- **Pass:** the query, per-package `documentation` paths from step 1, and the
  project root
- **Instructions:** read and follow `agents/doc-explorer.md`

If you cannot spawn a subagent, read and follow `agents/doc-explorer.md`
yourself.

Example prompts:

```
Read the documentation at /path/to/project/.pubdoc/app_links/
and explain how to set up deep link handling on Android and iOS.

Read the documentation at /path/to/project/.pubdoc/dio/
and describe the interceptor API: what parameters it accepts, how to chain
multiple interceptors, and common patterns.
```

Wait for the findings, then use them to proceed with your task.

## Note on documentation access

Generated docs live at `.pubdoc/<package>/` in the project root. Rely on the
subagent's findings — do not read the documentation yourself unless the
subagent's report is insufficient and further reading is clearly needed.
