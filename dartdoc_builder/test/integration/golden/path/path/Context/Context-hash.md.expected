# Context.hash

```dart
hash(String path) → int
```

Source: lib/src/context.dart:920:931

Returns a hash code for [path] that matches the semantics of [equals].

Note that the same path may have different hash codes in different
[Context]s.

## Source

```dart
int hash(String path) {
  // Make [path] absolute to ensure that equivalent relative and absolute
  // paths have the same hash code.
  path = absolute(path);

  final result = _hashFast(path);
  if (result != null) return result;

  final parsed = _parse(path);
  parsed.normalize();
  return _hashFast(parsed.toString())!;
}
```
