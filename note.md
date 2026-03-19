Fix: Dynamic types in generated documentation (Issue #6)

Context

When pubdoc generates documentation for a cached package (e.g. smooth_sheets),
it passes the pub-cache path (e.g.
~/.pub-cache/hosted/pub.dev/smooth_sheets-0.12.2/) as inputDir to dartdoc. That
directory has no .dart_tool/package_config.json (since dart pub get was never
run there), so the Dart analyzer cannot resolve types from dependencies (Flutter
SDK, etc.). These unresolved types become InvalidType, which dartdoc renders as
dynamic.

Fix: Before invoking dartdoc, copy the user's project package_config.json into
<targetPackageSourceDir>/.dart_tool/package_config.json. Since the target
package is a dependency of the user's project, the user's config already
contains all transitive dependency entries with correct absolute file:// URIs.
No modifications to the entries are needed.
