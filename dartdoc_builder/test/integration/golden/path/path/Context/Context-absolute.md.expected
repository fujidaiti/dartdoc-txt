# Context.absolute

```dart
absolute(String part1, [String? part2, String? part3, String? part4, String? part5, String? part6, String? part7, String? part8, String? part9, String? part10, String? part11, String? part12, String? part13, String? part14, String? part15]) → String
```

Source: lib/src/context.dart:77:118

Returns a new path with the given path parts appended to [current].

Equivalent to [join()] with [current] as the first argument. Example:

    var context = Context(current: '/root');
    context.absolute('path', 'to', 'foo'); // -> '/root/path/to/foo'

If [current] isn't absolute, this won't return an absolute path. Does not
[normalize] or [canonicalize] paths.

## Source

```dart
String absolute(String part1,
    [String? part2,
    String? part3,
    String? part4,
    String? part5,
    String? part6,
    String? part7,
    String? part8,
    String? part9,
    String? part10,
    String? part11,
    String? part12,
    String? part13,
    String? part14,
    String? part15]) {
  _validateArgList('absolute', [
    part1,
    part2,
    part3,
    part4,
    part5,
    part6,
    part7,
    part8,
    part9,
    part10,
    part11,
    part12,
    part13,
    part14,
    part15
  ]);

  // If there's a single absolute path, just return it. This is a lot faster
  // for the common case of `p.absolute(path)`.
  if (part2 == null && isAbsolute(part1) && !isRootRelative(part1)) {
    return part1;
  }

  return join(current, part1, part2, part3, part4, part5, part6, part7, part8,
      part9, part10, part11, part12, part13, part14, part15);
}
```
