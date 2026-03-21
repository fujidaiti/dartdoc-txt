# Golden Tests

Golden tests for the dartdoc_txt Markdown renderer. Each fixture package is
rendered and compared against expected `.expect` files.

## Fixtures

- **basic** — A synthetic package covering all rendering features: classes,
  enums, functions, generics, inheritance, modifiers, extensions, typedefs,
  categories, `{@template}`/`{@macro}`, anonymous libraries, and source
  threshold behavior.
- **path** — The real-world `path` package from
  [dart-lang/core](https://github.com/dart-lang/core), included as a git
  submodule pinned to a specific commit.

## Running the tests

```sh
cd dartdoc_txt
dart test test/integration/golden_test.dart
```

The `path` fixture requires the git submodule to be initialized. If it is
missing, the test will fail with instructions to run:

```sh
git submodule update --init
```

## Updating golden files

To regenerate golden files after changing the renderer or fixtures, run the CLI
on each fixture:

```sh
cd dartdoc_txt

# basic fixture
dart run bin/dartdoc_txt.dart -i test/integration/fixture/basic -o test/integration/golden/basic

# path fixture (requires submodule init + pub get first)
git submodule update --init
(cd test/integration/fixture/dart-core/pkgs/path && dart pub get)
dart run bin/dartdoc_txt.dart -i test/integration/fixture/dart-core/pkgs/path -o test/integration/golden/path
```
