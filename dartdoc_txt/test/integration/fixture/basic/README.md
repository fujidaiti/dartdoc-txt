A comprehensive test fixture for dartdoc_txt.

This package covers all rendering features including classes, enums, functions,
generics, inheritance, modifiers, extensions, and source threshold behavior.

## Features

- **Classes**: Constructors (unnamed, named, factory), methods, properties
- **Enums**: Simple enums with documented values
- **Functions**: Top-level functions, constants, and variables
- **Generics**: Type parameters, bounded type parameters, generic functions
- **Inheritance**: Class hierarchies, mixins, and mixin applications
- **Modifiers**: Abstract, sealed, base, final, interface, and mixin classes
- **Extensions**: Extension methods, extension types, typedefs, operator
  overloading
- **Threshold**: Source code inclusion based on line count thresholds

## Usage

This package is not intended for direct use. It serves as a test fixture for the
dartdoc_txt golden tests, validating that the Markdown renderer produces correct
output for a wide range of Dart language constructs.
