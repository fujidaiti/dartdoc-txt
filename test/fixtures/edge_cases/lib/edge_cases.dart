/// A library demonstrating edge cases in Dart.
library edge_cases;

/// A class that overloads operators.
class Comparable2 {
  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);

  @override
  String toString() => 'Comparable2';

  /// Adds two [Comparable2] instances.
  Comparable2 operator +(Comparable2 other) => this;
}

/// A typedef for a callback that takes a [String].
typedef StringCallback = void Function(String);

/// An extension on [String] that adds utility methods.
extension StringExtras on String {
  /// Returns this string with an exclamation mark appended.
  String exclaim() => '$this!';
}

/// An extension type wrapping an [int].
extension type Wrapper(int value) {
  /// Returns the value doubled.
  int doubled() => value * 2;
}
