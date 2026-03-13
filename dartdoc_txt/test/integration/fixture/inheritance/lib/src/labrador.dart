import 'dog.dart';
import 'swimmable.dart';

/// A Labrador that extends [Dog] and mixes in [Swimmable].
class Labrador extends Dog with Swimmable {
  /// Creates a [Labrador] with the given [name].
  Labrador(super.name);
}
