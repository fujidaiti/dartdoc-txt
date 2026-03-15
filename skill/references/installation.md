# Installing pubdoc

Run:

```
dart pub global activate pubdoc
```

If `dart` is not on PATH (the user may use [fvm](https://fvm.app/) to manage
Flutter SDK versions), try:

```
fvm dart pub global activate pubdoc
```

After installation, pubdoc lives at `~/.pub-cache/bin/pubdoc`. If the `pubdoc`
command is still not found after install, invoke it via that full path.
