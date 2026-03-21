# path Index

Version: 1.9.1

## path library

A comprehensive, cross-platform path manipulation library.

The path library was designed to be imported with a prefix, though you don't
have to if you don't want to:

    import 'package:path/path.dart' as p;

The most common way to use the library is through the top-level functions.
These manipulate path strings based on your current working directory and
the path style (POSIX, Windows, or URLs) of the host platform. For example:

    p.join('directory', 'file.txt');

This calls the top-level [join] function to join "directory" and "file.txt"
using the current platform's directory separator.

If you want to work with paths for a specific platform regardless of the
underlying platform that the program is running on, you can create a
[Context] and give it an explicit [Style]:

    var context = p.Context(style: Style.windows);
    context.join('directory', 'file.txt');

This will join "directory" and "file.txt" using the Windows path separator,
even when the program is run on a POSIX machine.

### Classes from path

- [Context](path/Context/Context.md) — An instantiable class for manipulating paths. Unlike the top-level functions, this lets you explicitly select what platform the paths will use.
- [PathMap](path/PathMap/PathMap.md) — A map whose keys are paths, compared using [p.equals] and [p.hash].
- [PathSet](path/PathSet/PathSet.md) — A set containing paths, compared using [p.equals] and [p.hash].
- [Style](path/Style/Style.md) — An enum type describing a "flavor" of path.
### Functions from path

See [top-level-functions.md](path/top-level-functions/top-level-functions.md) for more details.

- absolute — Returns a new path with the given path parts appended to [current].
- basename — Gets the part of [path] after the last separator.
- basenameWithoutExtension — Gets the part of [path] after the last separator, and without any trailing file extension.
- dirname — Gets the part of [path] before the last separator.
- extension — Gets the file extension of [path]: the portion of [basename] from the last `.` to the end (including the `.` itself).
- rootPrefix — Returns the root of [path], if it's absolute, or the empty string if it's relative.
- isAbsolute — Returns `true` if [path] is an absolute path and `false` if it is a relative path.
- isRelative — Returns `true` if [path] is a relative path and `false` if it is absolute. On POSIX systems, absolute paths start with a `/` (forward slash). On Windows, an absolute path starts with `\\`, or a drive letter followed by `:/` or `:\`.
- isRootRelative — Returns `true` if [path] is a root-relative path and `false` if it's not.
- join — Joins the given path parts into a single path using the current platform's [separator]. Example:
- joinAll — Joins the given path parts into a single path using the current platform's [separator]. Example:
- split — Splits [path] into its components using the current platform's [separator].
- canonicalize — Canonicalizes [path].
- normalize — Normalizes [path], simplifying it by handling `..`, and `.`, and removing redundant path separators whenever possible.
- relative — Attempts to convert [path] to an equivalent relative path from the current directory.
- isWithin — Returns `true` if [child] is a path beneath `parent`, and `false` otherwise.
- equals — Returns `true` if [path1] points to the same location as [path2], and `false` otherwise.
- hash — Returns a hash code for [path] such that, if [equals] returns `true` for two paths, their hash codes are the same.
- withoutExtension — Removes a trailing extension from the last part of [path].
- setExtension — Returns [path] with the trailing extension set to [extension].
- fromUri — Returns the path represented by [uri], which may be a [String] or a [Uri].
- toUri — Returns the URI that represents [path].
- prettyUri — Returns a terse, human-readable representation of [uri].

### Properties from path

See [top-level-properties.md](path/top-level-properties/top-level-properties.md) for more details.

- posix — A default context for manipulating POSIX paths.
- windows — A default context for manipulating Windows paths.
- url — A default context for manipulating URLs.
- context — The system path context.
- style — Returns the [Style] of the current context.
- current — Gets the path to the current working directory.
- separator — Gets the path separator for the current platform. This is `\` on Windows and `/` on other platforms (including the browser).

