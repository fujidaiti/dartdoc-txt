# Context.joinAll

```dart
joinAll(Iterable parts) → String
```

Source: lib/src/context.dart:300:339

Joins the given path parts into a single path. Example:

    context.joinAll(['path', 'to', 'foo']); // -> 'path/to/foo'

If any part ends in a path separator, then a redundant separator will not
be added:

    context.joinAll(['path/', 'to', 'foo']); // -> 'path/to/foo'

If a part is an absolute path, then anything before that will be ignored:

    context.joinAll(['path', '/to', 'foo']); // -> '/to/foo'

For a fixed number of parts, [join] is usually terser.

## Source

```dart
String joinAll(Iterable<String> parts) {
  final buffer = StringBuffer();
  var needsSeparator = false;
  var isAbsoluteAndNotRootRelative = false;

  for (var part in parts.where((part) => part != '')) {
    if (isRootRelative(part) && isAbsoluteAndNotRootRelative) {
      // If the new part is root-relative, it preserves the previous root but
      // replaces the path after it.
      final parsed = _parse(part);
      final path = buffer.toString();
      parsed.root =
          path.substring(0, style.rootLength(path, withDrive: true));
      if (style.needsSeparator(parsed.root!)) {
        parsed.separators[0] = style.separator;
      }
      buffer.clear();
      buffer.write(parsed.toString());
    } else if (isAbsolute(part)) {
      isAbsoluteAndNotRootRelative = !isRootRelative(part);
      // An absolute path discards everything before it.
      buffer.clear();
      buffer.write(part);
    } else {
      if (part.isNotEmpty && style.containsSeparator(part[0])) {
        // The part starts with a separator, so we don't need to add one.
      } else if (needsSeparator) {
        buffer.write(separator);
      }

      buffer.write(part);
    }

    // Unless this part ends with a separator, we'll need to add one before
    // the next part.
    needsSeparator = style.needsSeparator(part);
  }

  return buffer.toString();
}
```
