/// A generic box that holds a value of type [T].
class Box<T> {
  /// Creates a [Box] with the given [value].
  Box(this.value);

  /// The value stored in this box.
  final T value;

  /// Returns the value stored in this box.
  T unwrap() => value;
}

/// A generic box with a bounded type parameter.
class BoundedBox<T extends Comparable<T>> {
  /// Creates a [BoundedBox] with the given [value].
  BoundedBox(this.value);

  /// The value stored in this box.
  final T value;
}

/// A generic identity function that returns its input.
T identity<T>(T value) => value;
