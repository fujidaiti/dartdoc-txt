/// A library demonstrating generics in Dart.
library generics;

/// A generic box that holds a value of type [T].
class Box<T> {
  /// The value stored in this box.
  final T value;

  /// Creates a [Box] with the given [value].
  Box(this.value);

  /// Returns the value stored in this box.
  T unwrap() => value;
}

/// A generic box with a bounded type parameter.
class BoundedBox<T extends Comparable<T>> {
  /// The value stored in this box.
  final T value;

  /// Creates a [BoundedBox] with the given [value].
  BoundedBox(this.value);
}

/// A generic identity function that returns its input.
T identity<T>(T value) => value;
