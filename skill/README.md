# pubdoc skill

A [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills)
that answers questions about Dart/Flutter packages using version-accurate
documentation generated from the project's actual dependencies.

See [CHAT.log](example/CHAT.example) for an example conversation with Claude
Code demonstrating the skill in action.

## Why

Claude's training knowledge about package APIs may be outdated. This skill
generates documentation directly from the packages installed in your project, so
the information always matches the version you're actually using.

## When it triggers

The skill activates whenever Claude needs to understand a package API before
writing code — including:

- Implementing a feature with a third-party package
- Debugging errors or stack traces that involve a package
- Looking up method signatures or class behavior
- Figuring out how to configure or integrate a package
- Migrating to a new version of a package

## How it works

**Step 1 — Prepare:** A Dart script (`scripts/prepare_documentation.dart`)
extracts package documentation from the project's dependencies and caches it
locally.

**Step 2 — Enrich:** For packages that lack structured summaries, a subagent
generates `OVERVIEW.md` and `EXAMPLES.md` files to make exploration faster.

**Step 3 — Explore:** A read-only subagent searches the documentation and
returns findings for use in the main task.

## Directory structure

```
pubdoc/
├── SKILL.md                      # Skill definition and step-by-step instructions
├── agents/
│   ├── doc-enrichment.md         # Instructions for the enrichment subagent
│   └── doc-explorer.md           # Instructions for the exploration subagent
├── references/
│   └── troubleshooting.md        # Error handling guidance for Step 1
└── scripts/
    └── prepare_documentation.dart # Extracts and caches package documentation
```

## Installation

Copy or symlink the `pubdoc/` directory into your Claude Code skills path
(typically `~/.claude/skills/`), or follow the instructions in the
[Claude Code skills documentation](https://docs.anthropic.com/en/docs/claude-code/skills).
