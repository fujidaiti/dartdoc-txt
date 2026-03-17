/// A top-level constant.
const String defaultName = 'World';

/// A top-level variable.
int globalCounter = 0;

/// An immutable 2D point.
class Point {
  final int x;
  final int y;

  /// Creates a point with the given coordinates.
  const Point(this.x, this.y);
}

/// The origin point.
const Point origin = Point(0, 0);
