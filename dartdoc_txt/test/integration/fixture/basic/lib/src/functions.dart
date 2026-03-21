/// A simple top-level function.
///
/// Returns the sum of [a] and [b].
int add(int a, int b) => a + b;

/// A top-level constant.
const String defaultName = 'World';

/// A top-level variable.
int globalCounter = 0;

/// An immutable 2D point.
///
/// {@macro basic.my_class}
class Point {
  final int x;
  final int y;

  /// Creates a point with the given coordinates.
  const Point(this.x, this.y);
}

/// The origin point.
const Point origin = Point(0, 0);

/// Capitalizes [input].
///
/// {@category Utilities}
String capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}
