/// A simple class in an anonymous library (no library directive).
class Greeting {
  /// The greeting message.
  final String message;

  /// Creates a [Greeting] with the given [message].
  Greeting(this.message);

  /// Returns the greeting as a string.
  @override
  String toString() => message;
}
