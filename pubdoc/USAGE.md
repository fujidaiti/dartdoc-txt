# Usage

This document describes available CLI sub commands, and how to configure pubdoc
globally via `.pubdocrc` file.

## Sub commands

The following options are available for all sub commands:

- `--verbose`: Print detailed information while processing the request.

- `--quiet`: Suppress all log output.

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

- `version`: the documentation version (see `--resolution`).
- `documentation`: the absolute path to the generated documentation.
- `source`: the package source directory the documentation was generated from.
- `cache`: the cache status, which can be one of the following:
  - `hit`: the existing cache was reused as-is.
  - `miss`: the documentation was generated fresh.
  - `refreshed`: the cache existed but was not compatible with the package
    version your project depends on, so it was regenerated.

```
dio
  version:       5.3.x
  documentation: /Users/username/.pubdoc/cache/dio/dio-5.3.x
  source:        /Users/username/.pub-cache/hosted/pub.dev/dio-5.3.6
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
