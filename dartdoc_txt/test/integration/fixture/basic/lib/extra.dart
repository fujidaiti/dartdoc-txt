/// A simple class in an anonymous library (no library directive).
class Greeting {
  /// Creates a [Greeting] with the given [message].
  Greeting(this.message);

  /// The greeting message.
  final String message;

  /// Returns the greeting as a string.
  @override
  String toString() => message;
}
