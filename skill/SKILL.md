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
pubdoc get --json=0 <package-name1> <package-name2> ... -p <project-root>
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

## Step 2: Explore documentation

Spawn a subagent to explore the docs and answer the query:

- **Model:** use a fast, low-latency model (e.g., Haiku for Claude)
- **Permissions:** read-only, except it may write/delete `OVERVIEW.md` and
  `EXAMPLES.md` (and copy `example/` dirs) under `.pubdoc/<package>/`
- **Pass:** the query, per-package `documentation` and `source` paths from step
  1, and the project root
- **Instructions:** read and follow `agents/doc-explorer.md`

Here are some examples of the prompt:

```
Read the documentation at /path/to/project/.pubdoc/app_links/
(source: /Users/you/.pub-cache/hosted/pub.dev/app_links-6.3.3)
and explain how to set up deep link handling on Android and iOS.

Read the documentation at /path/to/project/.pubdoc/dio/
(source: /Users/you/.pub-cache/hosted/pub.dev/dio-5.3.6)
and describe the interceptor API: what parameters it accepts, how to chain
multiple interceptors, and common patterns.
```

Wait for the findings, then use them to proceed with your task.

## Note on documentation access

Generated docs live at `.pubdoc/<package>/` in the project root. Rely on the
subagent's findings — do not read the documentation yourself unless the
subagent's report is insufficient and further reading is clearly needed.
