Utility classes and functions.

This category contains helper types and top-level functions that provide
commonly needed operations like string manipulation and data transformation.

## String Utilities

The [StringHelper] class provides methods for common string operations such as
reversing text. The [capitalize] top-level function offers a quick way to
capitalize the first letter of a string.

## Extension Methods

The [StringExtras] extension adds convenience methods directly to the [String]
type, so you can call them on any string instance without wrapping it in a
helper.

## Guidelines

When choosing between a helper class method and an extension method, prefer the
extension if the operation feels like a natural part of the type's API. Use a
helper class when the operation requires additional state or configuration.
