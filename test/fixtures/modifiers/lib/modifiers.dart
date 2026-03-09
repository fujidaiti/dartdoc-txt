/// A library demonstrating various class modifiers in Dart.
library modifiers;

/// An abstract class that cannot be instantiated directly.
abstract class AbstractFoo {}

/// A sealed class that can only be extended within this library.
sealed class SealedBar {}

/// A base class that can be extended but not implemented.
base class BaseBaz {}

/// A final class that cannot be extended or implemented.
final class FinalQux {}

/// An interface class that can be implemented but not extended.
interface class InterfaceQuux {}

/// A mixin class that can be used as both a class and a mixin.
mixin class MixinClass {}

/// A mixin that provides shared behavior.
mixin MyMixin {}
