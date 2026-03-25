# Agent skill for pubdoc

The [doc-explorer](plugin/doc-explorer) is a [Claude Code skill][] that answers
questions about Dart/Flutter packages using version-accurate documentation
provided by the [pubdoc][] command.

[Claude Code skill]: https://docs.anthropic.com/en/docs/claude-code/skills
[pubdoc]: https://github.com/fujidaiti/pubdoc-tools/tree/main/pubdoc

## Usage

Typically you don't need to be aware of that skill; your agent automatically
uses it when relevant. Just ask questions about Dart/Flutter packages or
delegate implementation tasks to the agent as you normally would, for example:

```
Help me migrate the app's navigation logic to use go_router
```

Then the agent will decide to use the skill while building an implementation
plan:

```
...

⏺ Now let me design the migration plan.

⏺ Plan(Design go_router migration plan)
  ⎿  Done (13 tool uses · 43.9k tokens · 1m 40s)
  (ctrl+o to expand)

⏺ Let me read the critical files and check the go_router API before finalizing.

⏺ Read 3 files (ctrl+o to expand)

⏺ Now let me check the go_router API documentation.

⏺ Skill(pubdoc-skills:doc-explorer)
  ⎿  Successfully loaded skill

...
```

See [CHAT.log](example/CHAT.log) for an example conversation with Claude Code
demonstrating the skill in action.

## Requirements

Under the hood, the skill uses [pubdoc][] command to generate and manage the
documentation for Dart/Flutter packages. Make sure that the command is installed
globally. If not, you can install it via [dart install][] (requires Dart SDK
3.10 or later):

```shell
dart install pubdoc
```

Also verify that the command is available in your PATH:

```shell
pubdoc --version
```

[dart install]: https://dart.dev/tools/dart-install

## Installation

### Add from marketplace

This option installs the skill as a plugin from this [marketplace][]. Launch
Claude Code and add the marketplace first:

```
/plugin marketplace add fujidaiti/claude-plugin-marketplace
```

Then, install the plugin:

```
/plugin install pubdoc-skills@norelease-dev-plugins
```

Now you should see the `doc-explorer` skill in your skill list:

```
/skills

─────────────────────────────────────────────────────────────────────
  Skills
  1 skill

  Plugin skills (plugin)
  doc-explorer · pubdoc-skills · ~158 description tokens
```

[marketplace]: https://github.com/fujidaiti/claude-plugin-marketplace

### Clone and load locally

Alternatively, you can clone this repository and copy the skill directory to
your `.claude/skills/`:

```shell
git clone https://github.com/fujidaiti/pubdoc-tools.git
cp -r pubdoc-tools/skill/plugin/doc-explorer /path/to/your/.claude/skills/
```

## What content does the skill read/write?

<!-- - create a doc directory in the cache (write)
- read the doc directory to answer questions (read)
- read the pub-cache directory to get the package source code (read)
- may add packages to project's pubspec.yaml (write)
- create summary files in the doc directory (write, experimental)
  - install the experimental plugin instead of the stable one -->

This skill runs [pubdoc-get][] command to prepare the documentation for the
queried packages, and the command:

- **reads** `pubspec.lock` and `.dart_tool/` directory to find out the exact
  package versions used in the project
- **reads** the source code of the packages to generate documentation, which is
  typically located in `~/.pub-cache/`
- **writes** the generated documentation to a [cache][] directory, which is
  typically located in `~/.pubdoc/cache/`

Also, the skill itself:

- **reads** the generated documentation to answer questions
- **may add** the queried packages to the project's `pubspec.yaml` if they are
  not already included, as per the `pubdoc get` command's [requirements][].
- **may write** summary files in the documentation directory (experimental, see
  the next section for details)

[pubdoc-get]:
  https://github.com/fujidaiti/pubdoc-tools/blob/main/pubdoc/USAGE.md#get
[cache]:
  https://github.com/fujidaiti/pubdoc-tools/blob/main/pubdoc/PRINCIPLE.md#shared-cache
[requirements]:
  https://github.com/fujidaiti/pubdoc-tools/blob/main/pubdoc/PRINCIPLE.md#requirements

### Documentation enrichment

> [!WARNING]
>
> This feature is unstable and not included in the `doc-explorer` skill from the
> pubdoc-skills plugin. To enable it, install the **pubdoc-skills-experimental**
> plugin instead:
>
> ```
> /plugin install pubdoc-skills-experimental@norelease-dev-plugins
> ```
>
> Do not enable both plugins at the same time, otherwise it would confuse the
> agent and cause unexpected behaviors.

> [!WARNING]
>
> Currently this feature requires write permission to generate summary files.
> That is, it will fail if the agent is running in a read-only environment such
> as the Plan mode in Claude Code.

The skill also writes summary files in the generated documentation to improve
future queries:

- `OVERVIEW.md`: a streamlined version of the package's README, stripping away
  non-technical content and cosmetic elements such as HTML tags; also includes a
  reading guide to the documentation.

- `EXAMPLES.md`: a summary of the package's `example/` directory, if it exists.

You can find examples of these summary files [here](example).

## Q&As

### My agent doesn't use the skill

Try including this phrase in your prompt (e.g., in CLAUDE.md):

```markdown
**Proactively** use the `pubdoc-skills:doc-explorer` skill.
```
