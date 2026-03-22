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

## Step 1: Prepare documentation

From the project root, run:

```shell
fvm dart run pubdoc get --json=0 --quiet <package-name1> <package-name2> ...
```

Read the JSON output and extract per-package `source` and `documentation`:

```json
{
  "output": {
    "packages": {
      "dio": {
        "documentation": "/Users/you/.pubdoc/cache/dio/dio-5.3.x",
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

- Model: fast, low-latency (e.g., Claude Haiku)
- Permissions: read-only, except it may write/delete `OVERVIEW.md` and
  `EXAMPLES.md` (and copy `example/` dirs) under `documentation` directory
- Pass: the package's `documentation` and `source` paths, and the project root
- Instructions: read and follow `${CLAUDE_SKILL_DIR}/agents/doc-enrichment.md`

Example prompt:

```
Generate OVERVIEW.md and EXAMPLES.md for the package at:
  Documentation: /Users/you/.pubdoc/cache/dio/dio-5.3.x
  Source: /Users/you/.pub-cache/hosted/pub.dev/dio-5.3.6

Read and follow ${CLAUDE_SKILL_DIR}/agents/doc-enrichment.md.
```

If you cannot spawn a subagent, check each package for a missing `OVERV IEW.md`
and generate it yourself by following `agents/doc-enrichment.md`.

## Step 3: Explore documentation

Spawn a subagent to delegate the exploration:

- Model: fast, low-latency (e.g., Claude Haiku)
- Permissions: read-only
- Pass: the query, per-package `documentation` paths from step 1, and the
  project root
- Instructions: read and follow `${CLAUDE_SKILL_DIR}/agents/doc-explorer.md`

If you can use a built-in read-only agent optimized for searching and analyzing
codebases (e.g., Explore agent), use it here. If you cannot spawn a subagent,
read and follow `agents/doc-explorer.md` yourself.

Example prompts:

```
Read the documentation at /Users/you/.pubdoc/cache/app_links/app_links-5.3.x/
and explain how to set up deep link handling on Android and iOS.

Read the documentation at /Users/you/.pubdoc/cache/dio/dio-5.3.x/
and describe the interceptor API: what parameters it accepts, how to chain
multiple interceptors, and common patterns.
```

Wait for the findings, then use them to proceed with your task.

## Note on documentation access

Rely on the subagent's findings — do not read the documentation yourself unless
the subagent's report is insufficient and further reading is clearly needed.
