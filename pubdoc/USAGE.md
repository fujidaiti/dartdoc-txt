# Usage

This document describes available CLI sub commands, and how to configure pubdoc
globally via `.pubdocrc` file.

## Sub commands

The following options are available for all sub commands:

- `--verbose`: Print detailed information while processing the request.

- `--help`: Show the help message for the command.

- `--json=<indent>`: Output the result in JSON format. The value is the
  indentation level: `--json=0` for minified output, `--json=2` for
  2-space-indented output. Logs and errors are included in the JSON payload
  rather than printed to stdout/stderr.

### get

Given package names, it builds the documentation for the versions of those
packages that your project depends on.

```bash
pubdoc get [options] package_name1 package_name2 ...
```

Intended to be run from the project root. Note that, since this command utilizes
the package management mechanism of the `pub` command, **you must run
`dart pub get` at least once before using this command**. Otherwise, it exits
with an error.

This command automatically detects the version of the specified package that
your project actually uses, and generates documentation for that version from
the source if it doesn't exist in the shared cache yet.

It also adds a symlink to the documentation in the `.pubdoc/` in the project
root, so that agents can easily access the documentation for that package
without knowing the actual version and the cache location.

```
<project-root>/
`-- .pubdoc/
    |-- firebase_core -> ~/.pubdoc/cache/firebase_core/firebase_core-4.5.4/
    |-- dio -> ~/.pubdoc/cache/dio/dio-5.2.x/
    `-- ...
```

After running, the command prints a summary for each package:

- `documentation`: the symlink in `.pubdoc/` that points to the generated docs.
- `version`: the documentation version (see `--resolution`).
- `source`: the package source directory the documentation was generated from.
- `cache`: the cache status, which can be one of the following:
  - `hit`: the existing cache was reused as-is.
  - `miss`: the documentation was generated fresh.
  - `refreshed`: the cache existed but was not compatible with the package
    version your project depends on, so it was regenerated.

```
dio
  documentation: /path/to/project/.pubdoc/dio
  version:       5.3.x
  source:        /Users/you/.pub-cache/hosted/pub.dev/dio-5.3.6/
  cache:         hit
```

Refer to [PRINCIPLE.md][1] to learn more about the inner workings of
`pubdoc get`.

[1]: PRINCIPLE.md

#### Options

- `-p, --project`: The path to the Dart/Flutter project root—a directory that
  has `pubspec.yaml`, including [pub workspaces][2]. Defaults to the current
  directory.

- `--resolution`: The strategy to resolve the documentation version from the
  package version. Valid values are `exact`, `loose-patch`, and `loose-minor`.
  The default is `loose-patch`, which means that projects depending on the same
  package with different patch numbers would both use the same documentation,
  like v5.3.x. See [Resolve documentation version][3] for more details about
  each strategy.

- `--[no-]cache`: Use cache whenever possible. If `--no-cache` is specified, it
  always generates documentation regardless of the cache. Even `--cache` is set,
  however, it may still regenerate and update the cache if the cached
  documentation is not compatible with the package version that your project
  depends on (see [Version management][4] for more details). Default is
  `--cache`.

[2]: https://dart.dev/tools/pub/workspaces
[3]: PRINCIPLE.md#resolve-documentation-version
[4]: PRINCIPLE.md#version-management

### doctor

Print environment information such as effective `.pubdocrc` file and cache
location for the current project.

```bash
pubdoc doctor
```

It reports the following information:

- The location of the [pubdoc home](#pubdoc-home).
- The location of the shared cache.
- Global and project-level `.pubdocrc` files.
- Environment variables that pubdoc is recognizing, such as `$PUBDOC_HOME`.

## .pubdocrc file

You can also configure default behavior of pubdoc globally via JSON file named
`.pubdocrc`. pubdoc looks for this file in the following locations in order, and
merges them in a cascading way (lower level configuration overrides higher level
ones):

- `<pubdoc-home>/.pubdocrc` ([pubdoc home](#pubdoc-home))
- `./.pubdocrc` (project root)

Note that, in pub workspaces, pubdoc is only aware of the `.pubdocrc` in the
workspace root; `.pubdocrc` files in individual project directories are ignored.

### Available fields

- `resolution`: The default value for the `--resolution` option of `pubdoc get`
  command.

## Files

This section describes where pubdoc stores the generated documentation and
related files. You can always check the effective locations of those files and
directories via the `doctor` command.

### Pubdoc home

pubdoc stores the global `.pubdocrc` and miscellaneous stuff in a directory
called _pubdoc home_. You can configure the location of this directory by
setting the `$PUBDOC_HOME` environment variable. If not set, it tries
`$XDG_CONFIG_HOME/pubdoc` first, then falls back to `$HOME/.pubdoc/`.

### Shared cache

Generated documentation is stored in a shared cache. You can configure the
location of the cache directory by setting the `$PUBDOC_CACHE` environment
variable. If not set, it tries `$XDG_CACHE_HOME/pubdoc` first, then falls back
to `<pubdoc-home>/cache/`.
