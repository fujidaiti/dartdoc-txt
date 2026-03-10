import 'package:dartdoc/src/element_type.dart';
import 'package:dartdoc/src/model/model.dart';

import 'utilities.dart';

/// Strips HTML tags and unescapes entities to get a clean type name.
///
/// dartdoc's `nameWithGenericsPlain` can contain residual HTML for some
/// parameterized types. This function ensures a completely clean output.
String plainTypeName(ElementType type) {
  var name = type.nameWithGenericsPlain;
  // Remove any residual HTML tags (e.g. <wbr>, <span>)
  name = name.replaceAll(RegExp(r'<[^>]+>'), '');
  return unescapeHtml(name);
}

/// Renders a class/mixin/enum/extension type declaration as plain Dart code.
String renderDeclaration(Container container) {
  var buffer = StringBuffer();

  if (container is InheritingContainer) {
    for (var mod in container.containerModifiers) {
      buffer.write('${mod.name} ');
    }
  }

  // Determine the keyword
  if (container is Enum) {
    buffer.write('enum ${container.name}');
  } else if (container is Mixin) {
    buffer.write('mixin ${container.name}');
  } else if (container is ExtensionType) {
    buffer.write('extension type ${container.name}');
  } else if (container is Extension) {
    buffer.write('extension ${container.name}');
  } else {
    buffer.write('class ${container.name}');
  }

  // Type parameters
  if (container is TypeParameters) {
    var typeParams = (container as TypeParameters).typeParameters;
    if (typeParams.isNotEmpty) {
      buffer.write('<');
      buffer.write(
        typeParams
            .map((t) {
              var rawName = t.element.name!;
              var bound = t.element.bound;
              if (bound != null && !bound.isDartCoreObject) {
                return '$rawName extends ${bound.getDisplayString()}';
              }
              return rawName;
            })
            .join(', '),
      );
      buffer.write('>');
    }
  }

  if (container is InheritingContainer) {
    // Supertype
    if (container.supertype != null) {
      var supertypeName = plainTypeName(container.supertype!);
      if (supertypeName != 'Object' && supertypeName != 'Enum') {
        buffer.write(' extends $supertypeName');
      }
    }

    // Mixins (only for Class)
    if (container is Class && container.mixedInTypes.isNotEmpty) {
      buffer.write(
        '\n    with ${container.mixedInTypes.map(plainTypeName).join(', ')}',
      );
    }

    // Interfaces
    if (container.publicInterfaces.isNotEmpty) {
      buffer.write(
        '\n    implements ${container.publicInterfaces.map(plainTypeName).join(', ')}',
      );
    }
  }

  // Mixin: show superclass constraints
  if (container is Mixin && container.publicSuperclassConstraints.isNotEmpty) {
    buffer.write(
      ' on ${container.publicSuperclassConstraints.map(plainTypeName).join(', ')}',
    );
  }

  // Extension: show extended type
  if (container is Extension) {
    buffer.write(' on ${plainTypeName(container.extendedElement)}');
  }

  return buffer.toString();
}

/// Renders a method/function/constructor signature as a single line.
String renderSignature(ModelElement element) {
  var buffer = StringBuffer();

  if (element is Constructor) {
    buffer.write(element.name);
    buffer.write('(${_renderParams(element.parameters)})');
    if (element.isConst) buffer.write(' const');
    if (element.isFactory) {
      var enclosingName = element.enclosingElement.name;
      return '$enclosingName ${buffer.toString()} factory';
    }
    return buffer.toString();
  }

  if (element is Operator) {
    buffer.write('operator ${element.element.name}');
    buffer.write('(${_renderParams(element.parameters)})');
    buffer.write(' → ${_returnTypeName(element)}');
    return buffer.toString();
  }

  if (element is Method || element is ModelFunction) {
    buffer.write(element.name);
    // Type parameters
    if (element is TypeParameters) {
      var typeParams = (element as TypeParameters).typeParameters;
      if (typeParams.isNotEmpty) {
        buffer.write('<${typeParams.map((t) => t.name).join(', ')}>');
      }
    }
    buffer.write('(${_renderParams(element.parameters)})');
    buffer.write(' → ${_returnTypeName(element)}');
    return buffer.toString();
  }

  return element.name;
}

String _returnTypeName(ModelElement element) {
  if (element is Method) {
    return plainTypeName(element.modelType.returnType);
  }
  if (element is ModelFunction) {
    return plainTypeName(element.modelType.returnType);
  }
  return 'void';
}

String _renderParams(List<Parameter> parameters) {
  if (parameters.isEmpty) return '';

  var positionalRequired = parameters
      .where((p) => p.isRequiredPositional)
      .toList();
  var optionalPositional = parameters
      .where((p) => p.isOptionalPositional)
      .toList();
  var named = parameters.where((p) => p.isNamed).toList();

  var parts = <String>[];

  for (var p in positionalRequired) {
    parts.add(_renderParam(p));
  }

  if (optionalPositional.isNotEmpty) {
    var optParts = optionalPositional.map(_renderParam).join(', ');
    parts.add('[$optParts]');
  }

  if (named.isNotEmpty) {
    var namedParts = named
        .map((p) {
          var prefix = p.isRequiredNamed ? 'required ' : '';
          return '$prefix${_renderParam(p)}';
        })
        .join(', ');
    parts.add('{$namedParts}');
  }

  return parts.join(', ');
}

String _renderParam(Parameter p) {
  var typeName = plainTypeName(p.modelType);
  var result = '$typeName ${p.name}';
  if (p.hasDefaultValue) {
    result += ' = ${p.defaultValue}';
  }
  return result;
}

/// Renders annotations as inline code badges.
///
/// Returns something like: `` `@override` · `@protected` ``
/// Excludes `@deprecated` (handled separately) and `@override` if requested.
String renderAnnotations(ModelElement element, {bool skipOverride = false}) {
  var annotations = element.annotations
      .where((a) => a.name != 'deprecated' && a.name != 'Deprecated')
      .where((a) => !skipOverride || a.name != 'override')
      .map((a) => '`@${a.name}`')
      .toList();

  return annotations.join(' · ');
}

/// Renders field attributes (final, late, const, static) as inline code badges.
String renderAttributes(Field field) {
  var badges = <String>[];

  if (field.isStatic) badges.add('`static`');
  if (field.isLate) badges.add('`late`');
  if (field.isConst) badges.add('`const`');
  if (field.isFinal) badges.add('`final`');

  // Add annotations (non-deprecated)
  var annotationStr = renderAnnotations(field);
  if (annotationStr.isNotEmpty) {
    badges.add(annotationStr);
  }

  return badges.join(' · ');
}

/// Renders deprecation notice as a blockquote.
///
/// Returns empty string if the element is not deprecated.
String renderDeprecation(ModelElement element) {
  if (!element.isDeprecated) return '';

  // Try to extract the deprecation message from annotations
  for (var annotation in element.annotations) {
    if (annotation.name == 'deprecated' || annotation.name == 'Deprecated') {
      var source = annotation.linkedNameWithParameters;
      // Extract message from @Deprecated('message')
      var match = RegExp(r"""Deprecated\(['"](.+?)['"]\)""").firstMatch(source);
      if (match != null) {
        return '> **Deprecated:** ${match.group(1)}';
      }
      return '> **Deprecated**';
    }
  }

  return '> **Deprecated**';
}
