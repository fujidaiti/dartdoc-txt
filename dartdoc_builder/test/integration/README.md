# Golden Tests

Golden tests for the dartdoc_builder renderer. Each fixture package is rendered
and compared against expected `.expect` files.

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
cd dartdoc_builder
dart test test/integration/golden_test.dart
```

The `path` fixture requires the git submodule to be initialized. If it is
missing, the test will fail with instructions to run:

```sh
git submodule update --init
```

## Updating golden files

To regenerate golden files after changing the renderer or fixtures:

```sh
cd dartdoc_builder
dart run test/integration/update_golden.dart
```
