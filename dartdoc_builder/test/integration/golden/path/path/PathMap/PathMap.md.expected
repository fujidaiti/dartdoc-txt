# PathMap

```dart
class PathMap<V> extends MapView
```

Source: lib/src/path_map.dart:10:38

A map whose keys are paths, compared using [p.equals] and [p.hash].

## Constructors

### PathMap.new({Context? context})

Source: lib/src/path_map.dart:15:15

Creates an empty [PathMap] whose keys are compared using `context.equals`
and `context.hash`.

The [context] defaults to the current path context.

```dart
PathMap({p.Context? context}) : super(_create(context));
```

---
### PathMap.of(Map other, {Context? context})

Source: lib/src/path_map.dart:23:24

Creates a [PathMap] with the same keys and values as [other] whose keys
are compared using `context.equals` and `context.hash`.

The [context] defaults to the current path context. If multiple keys in
[other] represent the same logical path, the last key's value will be
used.

```dart
PathMap.of(Map<String, V> other, {p.Context? context})
    : super(_create(context)..addAll(other));
```

---
