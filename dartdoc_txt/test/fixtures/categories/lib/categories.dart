library categories;

/// A greeting class.
///
/// {@category Getting Started}
class Greeter {
  /// The name.
  final String name;

  /// Creates a [Greeter].
  Greeter(this.name);

  /// Returns a greeting.
  String greet() => 'Hello, $name!';
}

/// Basic colors.
///
/// {@category Getting Started}
enum BasicColor { red, green, blue }

/// A string helper.
///
/// {@category Utilities}
class StringHelper {
  /// Reverses [input].
  String reverse(String input) => input.split('').reversed.join();
}

/// Capitalizes [input].
///
/// {@category Utilities}
String capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}
