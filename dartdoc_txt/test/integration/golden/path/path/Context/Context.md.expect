# Context

```dart
class Context
```

Source: lib/src/context.dart:18:1111

An instantiable class for manipulating paths. Unlike the top-level
functions, this lets you explicitly select what platform the paths will use.

## Constructors

### Context Context.new({Style? style, String? current}) factory

Source: lib/src/context.dart:28:45

Creates a new path context for the given style and current directory.

If [style] is omitted, it uses the host operating system's path style. If
only [current] is omitted, it defaults ".". If *both* [style] and
[current] are omitted, [current] defaults to the real current working
directory.

On the browser, [style] defaults to [Style.url] and [current] defaults to
the current URL.

See [full implementation](Context-new.md)

---
## Properties

### style → InternalStyle

`final`

The style of path that this context works with.

---
### current → String

The current directory that relative paths are relative to.

---
### separator → String

Gets the path separator for the context's [style]. On Mac and Linux,
this is `/`. On Windows, it's `\`.

---
## Methods

### absolute(String part1, [String? part2, String? part3, String? part4, String? part5, String? part6, String? part7, String? part8, String? part9, String? part10, String? part11, String? part12, String? part13, String? part14, String? part15]) → String

Source: lib/src/context.dart:77:118

Returns a new path with the given path parts appended to [current].

Equivalent to [join()] with [current] as the first argument. Example:

    var context = Context(current: '/root');
    context.absolute('path', 'to', 'foo'); // -> '/root/path/to/foo'

If [current] isn't absolute, this won't return an absolute path. Does not
[normalize] or [canonicalize] paths.

See [full implementation](Context-absolute.md)

---
### basename(String path) → String

Source: lib/src/context.dart:129:129

Gets the part of [path] after the last separator on the context's
platform.

    context.basename('path/to/foo.dart'); // -> 'foo.dart'
    context.basename('path/to');          // -> 'to'

Trailing separators are ignored.

    context.basename('path/to/'); // -> 'to'

```dart
String basename(String path) => _parse(path).basename;
```

---
### basenameWithoutExtension(String path) → String

Source: lib/src/context.dart:139:140

Gets the part of [path] after the last separator on the context's
platform, and without any trailing file extension.

    context.basenameWithoutExtension('path/to/foo.dart'); // -> 'foo'

Trailing separators are ignored.

    context.basenameWithoutExtension('path/to/foo.dart/'); // -> 'foo'

```dart
String basenameWithoutExtension(String path) =>
    _parse(path).basenameWithoutExtension;
```

---
### dirname(String path) → String

Source: lib/src/context.dart:150:159

Gets the part of [path] before the last separator.

    context.dirname('path/to/foo.dart'); // -> 'path/to'
    context.dirname('path/to');          // -> 'path'

Trailing separators are ignored.

    context.dirname('path/to/'); // -> 'path'

```dart
String dirname(String path) {
  final parsed = _parse(path);
  parsed.removeTrailingSeparators();
  if (parsed.parts.isEmpty) return parsed.root ?? '.';
  if (parsed.parts.length == 1) return parsed.root ?? '.';
  parsed.parts.removeLast();
  parsed.separators.removeLast();
  parsed.removeTrailingSeparators();
  return parsed.toString();
}
```

---
### extension(String path, [int level = 1]) → String

Source: lib/src/context.dart:184:185

Gets the file extension of [path]: the portion of [basename] from the last
`.` to the end (including the `.` itself).

    context.extension('path/to/foo.dart'); // -> '.dart'
    context.extension('path/to/foo'); // -> ''
    context.extension('path.to/foo'); // -> ''
    context.extension('path/to/foo.dart.js'); // -> '.js'

If the file name starts with a `.`, then it is not considered an
extension:

    context.extension('~/.bashrc');    // -> ''
    context.extension('~/.notes.txt'); // -> '.txt'

Takes an optional parameter `level` which makes possible to return
multiple extensions having `level` number of dots. If `level` exceeds the
number of dots, the full extension is returned. The value of `level` must
be greater than 0, else `RangeError` is thrown.

    context.extension('foo.bar.dart.js', 2);   // -> '.dart.js
    context.extension('foo.bar.dart.js', 3);   // -> '.bar.dart.js'
    context.extension('foo.bar.dart.js', 10);  // -> '.bar.dart.js'
    context.extension('path/to/foo.bar.dart.js', 2);  // -> '.dart.js'

```dart
String extension(String path, [int level = 1]) =>
    _parse(path).extension(level);
```

---
### rootPrefix(String path) → String

Source: lib/src/context.dart:203:203

Returns the root of [path] if it's absolute, or an empty string if it's
relative.

    // Unix
    context.rootPrefix('path/to/foo'); // -> ''
    context.rootPrefix('/path/to/foo'); // -> '/'

    // Windows
    context.rootPrefix(r'path\to\foo'); // -> ''
    context.rootPrefix(r'C:\path\to\foo'); // -> r'C:\'
    context.rootPrefix(r'\\server\share\a\b'); // -> r'\\server\share'

    // URL
    context.rootPrefix('path/to/foo'); // -> ''
    context.rootPrefix('https://dart.dev/path/to/foo');
      // -> 'https://dart.dev'

```dart
String rootPrefix(String path) => path.substring(0, style.rootLength(path));
```

---
### isAbsolute(String path) → bool

Source: lib/src/context.dart:217:217

Returns `true` if [path] is an absolute path and `false` if it is a
relative path.

On POSIX systems, absolute paths start with a `/` (forward slash). On
Windows, an absolute path starts with `\\`, or a drive letter followed by
`:/` or `:\`. For URLs, absolute paths either start with a protocol and
optional hostname (e.g. `https://dart.dev`, `file://`) or with a `/`.

URLs that start with `/` are known as "root-relative", since they're
relative to the root of the current URL. Since root-relative paths are
still absolute in every other sense, [isAbsolute] will return true for
them. They can be detected using [isRootRelative].

```dart
bool isAbsolute(String path) => style.rootLength(path) > 0;
```

---
### isRelative(String path) → bool

Source: lib/src/context.dart:223:223

Returns `true` if [path] is a relative path and `false` if it is absolute.
On POSIX systems, absolute paths start with a `/` (forward slash). On
Windows, an absolute path starts with `\\`, or a drive letter followed by
`:/` or `:\`.

```dart
bool isRelative(String path) => !isAbsolute(path);
```

---
### isRootRelative(String path) → bool

Source: lib/src/context.dart:233:233

Returns `true` if [path] is a root-relative path and `false` if it's not.

URLs that start with `/` are known as "root-relative", since they're
relative to the root of the current URL. Since root-relative paths are
still absolute in every other sense, [isAbsolute] will return true for
them. They can be detected using [isRootRelative].

No POSIX and Windows paths are root-relative.

```dart
bool isRootRelative(String path) => style.isRootRelative(path);
```

---
### join(String part1, [String? part2, String? part3, String? part4, String? part5, String? part6, String? part7, String? part8, String? part9, String? part10, String? part11, String? part12, String? part13, String? part14, String? part15, String? part16]) → String

Source: lib/src/context.dart:248:284

Joins the given path parts into a single path. Example:

    context.join('path', 'to', 'foo'); // -> 'path/to/foo'

If any part ends in a path separator, then a redundant separator will not
be added:

    context.join('path/', 'to', 'foo'); // -> 'path/to/foo'

If a part is an absolute path, then anything before that will be ignored:

    context.join('path', '/to', 'foo'); // -> '/to/foo'

See [full implementation](Context-join.md)

---
### joinAll(Iterable parts) → String

Source: lib/src/context.dart:300:339

Joins the given path parts into a single path. Example:

    context.joinAll(['path', 'to', 'foo']); // -> 'path/to/foo'

If any part ends in a path separator, then a redundant separator will not
be added:

    context.joinAll(['path/', 'to', 'foo']); // -> 'path/to/foo'

If a part is an absolute path, then anything before that will be ignored:

    context.joinAll(['path', '/to', 'foo']); // -> '/to/foo'

For a fixed number of parts, [join] is usually terser.

See [full implementation](Context-joinAll.md)

---
### split(String path) → List

Source: lib/src/context.dart:364:370

Splits [path] into its components using the current platform's
[separator]. Example:

    context.split('path/to/foo'); // -> ['path', 'to', 'foo']

The path will *not* be normalized before splitting.

    context.split('path/../foo'); // -> ['path', '..', 'foo']

If [path] is absolute, the root directory will be the first element in the
array. Example:

    // Unix
    context.split('/path/to/foo'); // -> ['/', 'path', 'to', 'foo']

    // Windows
    context.split(r'C:\path\to\foo'); // -> [r'C:\', 'path', 'to', 'foo']
    context.split(r'\\server\share\path\to\foo');
      // -> [r'\\server\share', 'path', 'to', 'foo']

    // Browser
    context.split('https://dart.dev/path/to/foo');
      // -> ['https://dart.dev', 'path', 'to', 'foo']

```dart
List<String> split(String path) {
  final parsed = _parse(path);
  // Filter out empty parts that exist due to multiple separators in a row.
  parsed.parts = parsed.parts.where((part) => part.isNotEmpty).toList();
  if (parsed.root != null) parsed.parts.insert(0, parsed.root!);
  return parsed.parts;
}
```

---
### canonicalize(String path) → String

Source: lib/src/context.dart:384:391

Canonicalizes [path].

This is guaranteed to return the same path for two different input paths
if and only if both input paths point to the same location. Unlike
[normalize], it returns absolute paths when possible and canonicalizes
ASCII case on Windows.

Note that this does not resolve symlinks.

If you want a map that uses path keys, it's probably more efficient to use
a Map with [equals] and [hash] specified as the callbacks to use for keys
than it is to canonicalize every key.

```dart
String canonicalize(String path) {
  path = absolute(path);
  if (style != Style.windows && !_needsNormalization(path)) return path;

  final parsed = _parse(path);
  parsed.normalize(canonicalize: true);
  return parsed.toString();
}
```

---
### normalize(String path) → String

Source: lib/src/context.dart:401:407

Normalizes [path], simplifying it by handling `..`, and `.`, and
removing redundant path separators whenever possible.

Note that this is *not* guaranteed to return the same result for two
equivalent input paths. For that, see [canonicalize]. Or, if you're using
paths as map keys use [equals] and [hash] as the key callbacks.

    context.normalize('path/./to/..//file.text'); // -> 'path/file.txt'

```dart
String normalize(String path) {
  if (!_needsNormalization(path)) return path;

  final parsed = _parse(path);
  parsed.normalize();
  return parsed.toString();
}
```

---
### relative(String path, {String? from}) → String

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

See [full implementation](Context-relative.md)

---
### isWithin(String parent, String child) → bool

Source: lib/src/context.dart:594:595

Returns `true` if [child] is a path beneath `parent`, and `false`
otherwise.

    path.isWithin('/root/path', '/root/path/a'); // -> true
    path.isWithin('/root/path', '/root/other'); // -> false
    path.isWithin('/root/path', '/root/path'); // -> false

```dart
bool isWithin(String parent, String child) =>
    _isWithinOrEquals(parent, child) == _PathRelation.within;
```

---
### equals(String path1, String path2) → bool

Source: lib/src/context.dart:602:603

Returns `true` if [path1] points to the same location as [path2], and
`false` otherwise.

The [hash] function returns a hash code that matches these equality
semantics.

```dart
bool equals(String path1, String path2) =>
    _isWithinOrEquals(path1, path2) == _PathRelation.equal;
```

---
### hash(String path) → int

Source: lib/src/context.dart:920:931

Returns a hash code for [path] that matches the semantics of [equals].

Note that the same path may have different hash codes in different
[Context]s.

See [full implementation](Context-hash.md)

---
### withoutExtension(String path) → String

Source: lib/src/context.dart:993:1004

Removes a trailing extension from the last part of [path].

    context.withoutExtension('path/to/foo.dart'); // -> 'path/to/foo'

See [full implementation](Context-withoutExtension.md)

---
### setExtension(String path, String extension) → String

Source: lib/src/context.dart:1017:1018

Returns [path] with the trailing extension set to [extension].

If [path] doesn't have a trailing extension, this just adds [extension] to
the end.

    context.setExtension('path/to/foo.dart', '.js')
      // -> 'path/to/foo.js'
    context.setExtension('path/to/foo.dart.js', '.map')
      // -> 'path/to/foo.dart.map'
    context.setExtension('path/to/foo', '.js')
      // -> 'path/to/foo.js'

```dart
String setExtension(String path, String extension) =>
    withoutExtension(path) + extension;
```

---
### fromUri(Object? uri) → String

Source: lib/src/context.dart:1040:1040

Returns the path represented by [uri], which may be a [String] or a [Uri].

For POSIX and Windows styles, [uri] must be a `file:` URI. For the URL
style, this will just convert [uri] to a string.

    // POSIX
    context.fromUri('file:///path/to/foo')
      // -> '/path/to/foo'

    // Windows
    context.fromUri('file:///C:/path/to/foo')
      // -> r'C:\path\to\foo'

    // URL
    context.fromUri('https://dart.dev/path/to/foo')
      // -> 'https://dart.dev/path/to/foo'

If [uri] is relative, a relative path will be returned.

    path.fromUri('path/to/foo'); // -> 'path/to/foo'

```dart
String fromUri(Object? uri) => style.pathFromUri(_parseUri(uri!));
```

---
### toUri(String path) → Uri

Source: lib/src/context.dart:1058:1064

Returns the URI that represents [path].

For POSIX and Windows styles, this will return a `file:` URI. For the URL
style, this will just convert [path] to a [Uri].

    // POSIX
    context.toUri('/path/to/foo')
      // -> Uri.parse('file:///path/to/foo')

    // Windows
    context.toUri(r'C:\path\to\foo')
      // -> Uri.parse('file:///C:/path/to/foo')

    // URL
    context.toUri('https://dart.dev/path/to/foo')
      // -> Uri.parse('https://dart.dev/path/to/foo')

```dart
Uri toUri(String path) {
  if (isRelative(path)) {
    return style.relativePathToUri(path);
  } else {
    return style.absolutePathToUri(join(current, path));
  }
}
```

---
### prettyUri(Object? uri) → String

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

See [full implementation](Context-prettyUri.md)

---
