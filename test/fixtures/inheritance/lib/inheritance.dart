/// A library demonstrating class inheritance in Dart.
library inheritance;

/// A base animal class.
class Animal {
  /// The name of this animal.
  String name;

  /// Creates an [Animal] with the given [name].
  Animal(this.name);

  /// Returns the sound this animal makes.
  String speak() => name;
}

/// A dog that extends [Animal].
class Dog extends Animal {
  /// Creates a [Dog] with the given [name].
  Dog(super.name);

  @override
  String speak() => 'Woof';
}

/// A mixin that provides swimming ability.
mixin Swimmable {
  /// Makes this object swim.
  void swim() {}
}

/// A Labrador that extends [Dog] and mixes in [Swimmable].
class Labrador extends Dog with Swimmable {
  /// Creates a [Labrador] with the given [name].
  Labrador(super.name);
}
