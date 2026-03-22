# pubdoc

**pubdoc** is a CLI tool that provides LLM-friendly, version-aware API
documentation for Dart/Flutter packages. The documentation is LLM-friendly
because it consists of structured plain text files, and version-aware because
pubdoc serves documentation for the specific versions your project depends on,
not just the latest.

You can find examples of the generated documentation
[here](https://github.com/fujidaiti/pubdoc/tree/main/dartdoc_txt/test/integration/golden).

## Installation

> [!NOTE]
>
> Requires Dart SDK 3.10 or higher.

Use [dart install][] to globally activate the tool:

```shell
dart install pubdoc
```

Then, pubdoc will be available as the `pubdoc` command in your terminal.

[dart install]: https://dart.dev/tools/dart-install

## How to use

The main job of pubdoc is to provide API documentation for the given package.

```console
pubdoc get <package-name>
```

This command automatically detects the versions of the specified packages that
your project depends on, generates documentation for them if they are not
already cached on your storage, and creates symlinks to the cached documentation
under the `.pubdoc/` directory in your project root.

```
<project-root>/
`-- .pubdoc/
    |-- firebase_core -> ~/.pubdoc/cache/firebase_core/firebase_core-4.5.4/
    |-- app_links -> ~/.pubdoc/cache/app_links/app_links-6.4.x/
    `-- ...
```

That's all. You can then instruct your agents to read the documentation from the
`.pubdoc/` directory.

```
Implement the deep linking feature using @.pubdoc/app_links
```

Note that pubdoc utilizes the package management mechanism of the `pub` command
to build the appropriate version of documentation for the packages. So ensure
that the packages are included in the project's dependency and the dependency
tree is up-to-date by running `dart pub get` first.

## Learn more

- [USAGE.md](USAGE.md), which lists all the available CLI sub commands and
  options, and how to configure pubdoc globally via `.pubdocrc` file.
- [PRINCIPLE.md](PRINCIPLE.md), which explains how pubdoc generates and updates
  documentation, and how it detects which versions of the packages to generate
  documentation for.
- [Q&As](PRINCIPLE.md#qas), which answers some common questions about pubdoc.
