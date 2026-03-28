# Context.prettyUri

```dart
prettyUri(Object? uri) → String
```

Source: lib/src/context.dart:1091:1108

Returns a terse, human-readable representation of [uri].

[uri] can be a [String] or a [Uri]. If it can be made relative to the
current working directory, that's done. Otherwise, it's returned as-is.
This gracefully handles non-`file:` URIs for [Style.posix] and
[Style.windows].

The returned value is meant for human consumption, and may be either URI-
or path-formatted.

    // POSIX
    var context = Context(current: '/root/path');
    context.prettyUri('file:///root/path/a/b.dart'); // -> 'a/b.dart'
    context.prettyUri('https://dart.dev/'); // -> 'https://dart.dev'

    // Windows
    var context = Context(current: r'C:\root\path');
    context.prettyUri('file:///C:/root/path/a/b.dart'); // -> r'a\b.dart'
    context.prettyUri('https://dart.dev/'); // -> 'https://dart.dev'

    // URL
    var context = Context(current: 'https://dart.dev/root/path');
    context.prettyUri('https://dart.dev/root/path/a/b.dart');
        // -> r'a/b.dart'
    context.prettyUri('file:///root/path'); // -> 'file:///root/path'

## Source

```dart
String prettyUri(Object? uri) {
  final typedUri = _parseUri(uri!);
  if (typedUri.scheme == 'file' && style == Style.url) {
    return typedUri.toString();
  } else if (typedUri.scheme != 'file' &&
      typedUri.scheme != '' &&
      style != Style.url) {
    return typedUri.toString();
  }

  final path = normalize(fromUri(typedUri));
  final rel = relative(path);

  // Only return a relative path if it's actually shorter than the absolute
  // path. This avoids ugly things like long "../" chains to get to the root
  // and then go back down.
  return split(rel).length > split(path).length ? path : rel;
}
```
