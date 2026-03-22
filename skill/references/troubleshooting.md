# Troubleshooting

## pubdoc not found

Install pubdoc:

```
dart pub global activate pubdoc
```

If `dart` is not on PATH (the user may use fvm to manage Flutter SDK versions),
try:

```
fvm dart pub global activate pubdoc
```

## Missing pubspec.lock or package_config.json

`pubdoc get` requires `pubspec.lock` and `.dart_tool/package_config.json` to
exist. Tell the user to run:

```
dart pub get
```

or, if the user uses fvm:

```
fvm dart pub get
```

Then retry `pubdoc get`.

## Non-empty `errors` array

When using `--json`, errors appear in the `errors` array of the JSON output
rather than on stderr. Show the error messages to the user and stop.
