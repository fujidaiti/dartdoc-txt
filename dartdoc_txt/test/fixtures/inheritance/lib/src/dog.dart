import 'animal.dart';

/// A dog that extends [Animal].
class Dog extends Animal {
  /// Creates a [Dog] with the given [name].
  Dog(super.name);

  @override
  String speak() => 'Woof';
}
