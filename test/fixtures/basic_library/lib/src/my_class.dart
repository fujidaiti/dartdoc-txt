/// A simple class with documentation.
///
/// This class demonstrates basic features like
/// constructors, methods, and properties.
class MyClass {
  /// The name of this instance.
  final String name;

  /// The count value.
  int count;

  /// Creates a new [MyClass] with the given [name].
  MyClass(this.name, {this.count = 0});

  /// Creates a [MyClass] with default values.
  MyClass.defaults() : name = 'default', count = 0;

  /// Creates a [MyClass] from a map of values.
  ///
  /// This constructor validates and processes the input map.
  MyClass.fromMap(Map<String, dynamic> map) : name = '', count = 0 {
    var rawName = map['name'];
    if (rawName == null) {
      throw ArgumentError('name is required');
    }
    if (rawName is! String) {
      throw ArgumentError('name must be a String');
    }
    if (rawName.isEmpty) {
      throw ArgumentError('name must not be empty');
    }
    var rawCount = map['count'] ?? 0;
    if (rawCount is! int) {
      throw ArgumentError('count must be an int');
    }
  }

  /// Returns a greeting message.
  String greet() {
    return 'Hello, $name!';
  }

  /// A method with a longer body that exceeds the threshold.
  ///
  /// This method does multiple things:
  /// - Validates input
  /// - Processes data
  /// - Returns result
  String processData(String input) {
    if (input.isEmpty) {
      return '';
    }
    var result = input.trim();
    result = result.toLowerCase();
    result = result.replaceAll(' ', '_');
    if (result.length > 100) {
      result = result.substring(0, 100);
    }
    return result;
  }

  @override
  String toString() => 'MyClass($name)';
}
