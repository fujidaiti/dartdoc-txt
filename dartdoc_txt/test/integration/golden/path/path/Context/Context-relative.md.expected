# Context.relative

```dart
relative(String path, {String? from}) → String
```

Source: lib/src/context.dart:507:586

Attempts to convert [path] to an equivalent relative path relative to
[current].

    var context = Context(current: '/root/path');
    context.relative('/root/path/a/b.dart'); // -> 'a/b.dart'
    context.relative('/root/other.dart'); // -> '../other.dart'

If the [from] argument is passed, [path] is made relative to that instead.

    context.relative('/root/path/a/b.dart',
        from: '/root/path'); // -> 'a/b.dart'
    context.relative('/root/other.dart',
        from: '/root/path'); // -> '../other.dart'

If [path] and/or [from] are relative paths, they are assumed to be
relative to [current].

Since there is no relative path from one drive letter to another on
Windows, this will return an absolute path in that case.

    context.relative(r'D:\other', from: r'C:\other'); // -> 'D:\other'

This will also return an absolute path if an absolute [path] is passed to
a context with a relative path for [current].

    var context = Context(r'some/relative/path');
    context.relative(r'/absolute/path'); // -> '/absolute/path'

If [current] is relative, it may be impossible to determine a path from
[from] to [path]. For example, if [current] and [path] are "." and [from]
is "/", no path can be determined. In this case, a [PathException] will be
thrown.

## Source

```dart
String relative(String path, {String? from}) {
  // Avoid expensive computation if the path is already relative.
  if (from == null && isRelative(path)) return normalize(path);

  from = from == null ? current : absolute(from);

  // We can't determine the path from a relative path to an absolute path.
  if (isRelative(from) && isAbsolute(path)) {
    return normalize(path);
  }

  // If the given path is relative, resolve it relative to the context's
  // current directory.
  if (isRelative(path) || isRootRelative(path)) {
    path = absolute(path);
  }

  // If the path is still relative and `from` is absolute, we're unable to
  // find a path from `from` to `path`.
  if (isRelative(path) && isAbsolute(from)) {
    throw PathException('Unable to find a path to "$path" from "$from".');
  }

  final fromParsed = _parse(from)..normalize();
  final pathParsed = _parse(path)..normalize();

  if (fromParsed.parts.isNotEmpty && fromParsed.parts[0] == '.') {
    return pathParsed.toString();
  }

  // If the root prefixes don't match (for example, different drive letters
  // on Windows), then there is no relative path, so just return the absolute
  // one. In Windows, drive letters are case-insenstive and we allow
  // calculation of relative paths, even if a path has not been normalized.
  if (fromParsed.root != pathParsed.root &&
      ((fromParsed.root == null || pathParsed.root == null) ||
          !style.pathsEqual(fromParsed.root!, pathParsed.root!))) {
    return pathParsed.toString();
  }

  // Strip off their common prefix.
  while (fromParsed.parts.isNotEmpty &&
      pathParsed.parts.isNotEmpty &&
      style.pathsEqual(fromParsed.parts[0], pathParsed.parts[0])) {
    fromParsed.parts.removeAt(0);
    fromParsed.separators.removeAt(1);
    pathParsed.parts.removeAt(0);
    pathParsed.separators.removeAt(1);
  }

  // If there are any directories left in the from path, we need to walk up
  // out of them. If a directory left in the from path is '..', it cannot
  // be cancelled by adding a '..'.
  if (fromParsed.parts.isNotEmpty && fromParsed.parts[0] == '..') {
    throw PathException('Unable to find a path to "$path" from "$from".');
  }
  pathParsed.parts.insertAll(0, List.filled(fromParsed.parts.length, '..'));
  pathParsed.separators[0] = '';
  pathParsed.separators
      .insertAll(1, List.filled(fromParsed.parts.length, style.separator));

  // Corner case: the paths completely collapsed.
  if (pathParsed.parts.isEmpty) return '.';

  // Corner case: path was '.' and some '..' directories were added in front.
  // Don't add a final '/.' in that case.
  if (pathParsed.parts.length > 1 && pathParsed.parts.last == '.') {
    pathParsed.parts.removeLast();
    pathParsed.separators
      ..removeLast()
      ..removeLast()
      ..add('');
  }

  // Make it relative.
  pathParsed.root = '';
  pathParsed.removeTrailingSeparators();

  return pathParsed.toString();
}
```
