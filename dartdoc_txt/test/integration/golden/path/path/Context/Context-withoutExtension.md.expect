# Context.withoutExtension

```dart
withoutExtension(String path) → String
```

Source: lib/src/context.dart:993:1004

Removes a trailing extension from the last part of [path].

    context.withoutExtension('path/to/foo.dart'); // -> 'path/to/foo'

## Source

```dart
String withoutExtension(String path) {
  final parsed = _parse(path);

  for (var i = parsed.parts.length - 1; i >= 0; i--) {
    if (parsed.parts[i].isNotEmpty) {
      parsed.parts[i] = parsed.basenameWithoutExtension;
      break;
    }
  }

  return parsed.toString();
}
```
