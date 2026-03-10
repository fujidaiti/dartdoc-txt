/// A base animal class.
class Animal {
  /// The name of this animal.
  String name;

  /// Creates an [Animal] with the given [name].
  Animal(this.name);

  /// Returns the sound this animal makes.
  String speak() => name;
}
