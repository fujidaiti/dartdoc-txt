# Context.new

```dart
Context Context.new({Style? style, String? current}) factory
```

Source: lib/src/context.dart:28:45

Creates a new path context for the given style and current directory.

If [style] is omitted, it uses the host operating system's path style. If
only [current] is omitted, it defaults ".". If *both* [style] and
[current] are omitted, [current] defaults to the real current working
directory.

On the browser, [style] defaults to [Style.url] and [current] defaults to
the current URL.

## Source

```dart
factory Context({Style? style, String? current}) {
  if (current == null) {
    if (style == null) {
      current = p.current;
    } else {
      current = '.';
    }
  }

  if (style == null) {
    style = Style.platform;
  } else if (style is! InternalStyle) {
    throw ArgumentError('Only styles defined by the path package are '
        'allowed.');
  }

  return Context._(style as InternalStyle, current);
}
```
