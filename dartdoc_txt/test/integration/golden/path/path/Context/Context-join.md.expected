# Context.join

```dart
join(String part1, [String? part2, String? part3, String? part4, String? part5, String? part6, String? part7, String? part8, String? part9, String? part10, String? part11, String? part12, String? part13, String? part14, String? part15, String? part16]) → String
```

Source: lib/src/context.dart:248:284

Joins the given path parts into a single path. Example:

    context.join('path', 'to', 'foo'); // -> 'path/to/foo'

If any part ends in a path separator, then a redundant separator will not
be added:

    context.join('path/', 'to', 'foo'); // -> 'path/to/foo'

If a part is an absolute path, then anything before that will be ignored:

    context.join('path', '/to', 'foo'); // -> '/to/foo'

## Source

```dart
String join(String part1,
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
    String? part15,
    String? part16]) {
  final parts = <String?>[
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
    part15,
    part16,
  ];
  _validateArgList('join', parts);
  return joinAll(parts.whereType<String>());
}
```
