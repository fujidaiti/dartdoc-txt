# Style

```dart
abstract class Style
```

Source: lib/src/style.dart:11:85

An enum type describing a "flavor" of path.

## Constructors

### Style.new()

Source: lib/src/style.dart:11

---
## Properties

### posix → Style

`static` · `final`

POSIX-style paths use "/" (forward slash) as separators. Absolute paths
start with "/". Used by UNIX, Linux, Mac OS X, and others.

---
### windows → Style

`static` · `final`

Windows paths use `\` (backslash) as separators. Absolute paths start with
a drive letter followed by a colon (example, `C:`) or two backslashes
(`\\`) for UNC paths.

---
### url → Style

`static` · `final`

URLs aren't filesystem paths, but they're supported to make it easier to
manipulate URL paths in the browser.

URLs use "/" (forward slash) as separators. Absolute paths either start
with a protocol and optional hostname (e.g. `https://dart.dev`,
`file://`) or with "/".

---
### platform → Style

`static` · `final`

The style of the host platform.

When running on the command line, this will be [windows] or [posix] based
on the host operating system. On a browser, this will be [url].

---
### name → String

The name of this path style. Will be "posix" or "windows".

---
### context → Context

A [Context] that uses this style.

---
### separator → String

`@new`

> **Deprecated**

---
### separatorPattern → Pattern

`@new`

> **Deprecated**

---
### needsSeparatorPattern → Pattern

`@new`

> **Deprecated**

---
### rootPattern → Pattern

`@new`

> **Deprecated**

---
### relativeRootPattern → Pattern?

`@new`

> **Deprecated**

---
## Methods

### getRoot(String path) → String?

Source: lib/src/style.dart:69:70

`@new`

> **Deprecated**

---
### getRelativeRoot(String path) → String?

Source: lib/src/style.dart:72:73

`@new`

> **Deprecated**

---
### pathFromUri(Uri uri) → String

Source: lib/src/style.dart:75:76

`@new`

> **Deprecated**

---
### relativePathToUri(String path) → Uri

Source: lib/src/style.dart:78:79

`@new`

> **Deprecated**

---
### absolutePathToUri(String path) → Uri

Source: lib/src/style.dart:81:82

`@new`

> **Deprecated**

---
