import 'package:dartdoc/src/model/model.dart';

import 'signature_builder.dart';
import 'utilities.dart';

/// Options controlling rendering behavior.
class RenderOptions {
  final int sourceLineThreshold;
  final bool includeSource;

  const RenderOptions({
    this.sourceLineThreshold = 10,
    this.includeSource = true,
  });
}

/// Renders a container (Class, Enum, Mixin, ExtensionType) to Markdown.
String renderContainer(Container container, RenderOptions options) {
  var buffer = StringBuffer();

  // Title
  buffer.writeln('# ${container.name}');
  buffer.writeln();

  // Declaration
  buffer.writeln('```dart');
  buffer.writeln(renderDeclaration(container));
  buffer.writeln('```');
  buffer.writeln();

  // Deprecation
  if (container.isDeprecated) {
    buffer.writeln(renderDeprecation(container));
    buffer.writeln();
  }

  // Documentation
  var doc = _cleanDoc(container.documentation);
  if (doc.isNotEmpty) {
    buffer.writeln(doc);
    buffer.writeln();
  }

  // Enum values
  if (container is Enum && container.publicEnumValues.isNotEmpty) {
    buffer.writeln('## Enum Values');
    buffer.writeln();
    for (var value in container.publicEnumValues) {
      buffer.writeln('### ${value.name}');
      buffer.writeln();
      var valueDoc = _cleanDoc(value.documentation);
      if (valueDoc.isNotEmpty) {
        buffer.writeln(valueDoc);
        buffer.writeln();
      }
      buffer.writeln('---');
      buffer.writeln();
    }
  }

  // Constructors
  if (container is Constructable && container.hasPublicConstructors) {
    buffer.writeln('## Constructors');
    buffer.writeln();
    for (var ctor in container.publicConstructorsSorted) {
      buffer.write(_renderConstructor(ctor, container.name, options));
    }
  }

  // Properties
  var publicInstanceFields = container.availableInstanceFieldsSorted
      .where((f) => f.isPublic)
      .toList();
  var publicStaticFields = container.staticFields
      .where((f) => f.isPublic)
      .toList();
  var allPublicFields = [...publicInstanceFields, ...publicStaticFields];
  if (allPublicFields.isNotEmpty) {
    buffer.writeln('## Properties');
    buffer.writeln();
    for (var field in allPublicFields) {
      buffer.write(_renderField(field));
    }
  }

  // Methods
  var publicMethods = container.availableInstanceMethodsSorted
      .where((m) => m.isPublic)
      .toList();
  var publicStaticMethods = container.staticMethods
      .where((m) => m.isPublic)
      .toList();
  var allPublicMethods = [...publicMethods, ...publicStaticMethods];
  if (allPublicMethods.isNotEmpty) {
    buffer.writeln('## Methods');
    buffer.writeln();
    for (var method in allPublicMethods) {
      buffer.write(_renderMethod(method, container.name, options));
    }
  }

  // Operators
  var publicOperators = container.availableInstanceOperatorsSorted
      .where((o) => o.isPublic)
      .toList();
  if (publicOperators.isNotEmpty) {
    buffer.writeln('## Operators');
    buffer.writeln();
    for (var op in publicOperators) {
      buffer.write(_renderOperator(op, container.name, options));
    }
  }

  return buffer.toString();
}

/// Renders an Extension to Markdown.
String renderExtension(Extension extension, RenderOptions options) {
  return renderContainer(extension, options);
}

/// Renders all top-level functions for a library.
String renderTopLevelFunctions(Library library, RenderOptions options) {
  var functions = library.functions.where((f) => f.isPublic).toList();
  if (functions.isEmpty) return '';

  var buffer = StringBuffer();
  buffer.writeln('# Top-level Functions — ${library.name}');
  buffer.writeln();

  for (var func in functions) {
    buffer.writeln('## ${func.name}');
    buffer.writeln();
    buffer.writeln('```dart');
    buffer.writeln(renderSignature(func));
    buffer.writeln('```');
    buffer.writeln();

    if (func.isDeprecated) {
      buffer.writeln(renderDeprecation(func));
      buffer.writeln();
    }

    var annotations = renderAnnotations(func);
    if (annotations.isNotEmpty) {
      buffer.writeln(annotations);
      buffer.writeln();
    }

    var doc = _cleanDoc(func.documentation);
    if (doc.isNotEmpty) {
      buffer.writeln(doc);
      buffer.writeln();
    }

    if (options.includeSource) {
      _writeSource(buffer, func, 'top-level-functions/${func.name}', options);
    }

    buffer.writeln('---');
    buffer.writeln();
  }

  return buffer.toString();
}

/// Renders all top-level properties and constants for a library.
String renderTopLevelProperties(Library library) {
  var properties = library.properties.where((p) => p.isPublic).toList();
  var constants = library.constants.where((c) => c.isPublic).toList();
  if (properties.isEmpty && constants.isEmpty) return '';

  var buffer = StringBuffer();
  buffer.writeln('# Top-level Properties — ${library.name}');
  buffer.writeln();

  if (constants.isNotEmpty) {
    buffer.writeln('## Constants');
    buffer.writeln();
    for (var c in constants) {
      buffer.writeln('### ${c.name} → ${c.modelType.nameWithGenericsPlain}');
      buffer.writeln();
      if (c.constantValue != null) {
        buffer.writeln('`${c.constantValue}`');
        buffer.writeln();
      }
      var doc = _cleanDoc(c.documentation);
      if (doc.isNotEmpty) {
        buffer.writeln(doc);
        buffer.writeln();
      }
      buffer.writeln('---');
      buffer.writeln();
    }
  }

  if (properties.isNotEmpty) {
    buffer.writeln('## Properties');
    buffer.writeln();
    for (var prop in properties) {
      buffer.writeln(
        '### ${prop.name} → ${prop.modelType.nameWithGenericsPlain}',
      );
      buffer.writeln();
      var doc = _cleanDoc(prop.documentation);
      if (doc.isNotEmpty) {
        buffer.writeln(doc);
        buffer.writeln();
      }
      buffer.writeln('---');
      buffer.writeln();
    }
  }

  return buffer.toString();
}

/// Renders all typedefs for a library.
String renderTypedefs(Library library) {
  var typedefs = library.typedefs.where((t) => t.isPublic).toList();
  if (typedefs.isEmpty) return '';

  var buffer = StringBuffer();
  buffer.writeln('# Typedefs — ${library.name}');
  buffer.writeln();

  for (var td in typedefs) {
    buffer.writeln('## ${td.name}');
    buffer.writeln();
    buffer.writeln('```dart');
    buffer.writeln(td.sourceCode);
    buffer.writeln('```');
    buffer.writeln();

    var doc = _cleanDoc(td.documentation);
    if (doc.isNotEmpty) {
      buffer.writeln(doc);
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln();
  }

  return buffer.toString();
}

/// Renders a detail page for an element whose source exceeds the threshold.
String renderDetailPage(
  ModelElement element,
  String parentName,
  RenderOptions options,
) {
  var buffer = StringBuffer();
  buffer.writeln('# $parentName.${element.name}');
  buffer.writeln();
  buffer.writeln('```dart');
  buffer.writeln(renderSignature(element));
  buffer.writeln('```');
  buffer.writeln();

  var annotations = renderAnnotations(element);
  if (annotations.isNotEmpty) {
    buffer.writeln(annotations);
    buffer.writeln();
  }

  if (element.isDeprecated) {
    buffer.writeln(renderDeprecation(element));
    buffer.writeln();
  }

  var doc = _cleanDoc(element.documentation);
  if (doc.isNotEmpty) {
    buffer.writeln(doc);
    buffer.writeln();
  }

  buffer.writeln('## Source');
  buffer.writeln();
  buffer.writeln('```dart');
  buffer.writeln(element.sourceCode);
  buffer.writeln('```');

  return buffer.toString();
}

/// Renders a category page.
String renderCategory(Category category) {
  var buffer = StringBuffer();

  // Raw documentation content
  var doc = category.documentation;
  if (doc != null && doc.isNotEmpty) {
    buffer.writeln(stripResidualHtml(doc));
    buffer.writeln();
  }

  buffer.writeln('## Elements in this category');
  buffer.writeln();

  _writeCategorySection(buffer, 'Classes', category.classes, category);
  _writeCategorySection(buffer, 'Enums', category.enums, category);
  _writeCategorySection(buffer, 'Mixins', category.mixins, category);
  _writeCategorySection(buffer, 'Extensions', category.extensions, category);
  _writeCategorySection(
    buffer,
    'Extension Types',
    category.extensionTypes,
    category,
  );
  _writeCategorySection(buffer, 'Functions', category.functions, category);
  _writeCategorySection(buffer, 'Properties', category.properties, category);
  _writeCategorySection(buffer, 'Typedefs', category.typedefs, category);

  return buffer.toString();
}

// --- Private helpers ---

String _cleanDoc(String? documentation) {
  if (documentation == null || documentation.isEmpty) return '';
  return stripResidualHtml(documentation);
}

String _renderConstructor(
  Constructor ctor,
  String containerName,
  RenderOptions options,
) {
  var buffer = StringBuffer();
  buffer.writeln('### ${renderSignature(ctor)}');
  buffer.writeln();

  var annotations = renderAnnotations(ctor);
  if (annotations.isNotEmpty) {
    buffer.writeln(annotations);
    buffer.writeln();
  }

  if (ctor.isDeprecated) {
    buffer.writeln(renderDeprecation(ctor));
    buffer.writeln();
  }

  var doc = _cleanDoc(ctor.documentation);
  if (doc.isNotEmpty) {
    buffer.writeln(doc);
    buffer.writeln();
  }

  if (options.includeSource) {
    _writeSource(
      buffer,
      ctor,
      '$containerName/${safeFileName(ctor.name)}',
      options,
    );
  }

  buffer.writeln('---');
  buffer.writeln();
  return buffer.toString();
}

String _renderField(Field field) {
  var buffer = StringBuffer();
  buffer.writeln(
    '### ${field.name} → ${field.modelType.nameWithGenericsPlain}',
  );
  buffer.writeln();

  var attributes = renderAttributes(field);
  if (attributes.isNotEmpty) {
    buffer.writeln(attributes);
    buffer.writeln();
  }

  if (field.isDeprecated) {
    buffer.writeln(renderDeprecation(field));
    buffer.writeln();
  }

  var doc = _cleanDoc(field.documentation);
  if (doc.isNotEmpty) {
    buffer.writeln(doc);
    buffer.writeln();
  }

  buffer.writeln('---');
  buffer.writeln();
  return buffer.toString();
}

String _renderMethod(
  Method method,
  String containerName,
  RenderOptions options,
) {
  var buffer = StringBuffer();
  buffer.writeln('### ${renderSignature(method)}');
  buffer.writeln();

  var annotations = renderAnnotations(method);
  if (annotations.isNotEmpty) {
    buffer.writeln(annotations);
    buffer.writeln();
  }

  if (method.isDeprecated) {
    buffer.writeln(renderDeprecation(method));
    buffer.writeln();
  }

  var doc = _cleanDoc(method.documentation);
  if (doc.isNotEmpty) {
    buffer.writeln(doc);
    buffer.writeln();
  }

  if (options.includeSource && !method.isAbstract) {
    _writeSource(
      buffer,
      method,
      '$containerName/${safeFileName(method.name)}',
      options,
    );
  }

  buffer.writeln('---');
  buffer.writeln();
  return buffer.toString();
}

String _renderOperator(
  Operator op,
  String containerName,
  RenderOptions options,
) {
  var buffer = StringBuffer();
  buffer.writeln('### ${renderSignature(op)}');
  buffer.writeln();

  var doc = _cleanDoc(op.documentation);
  if (doc.isNotEmpty) {
    buffer.writeln(doc);
    buffer.writeln();
  }

  if (options.includeSource && !op.isAbstract) {
    var safeName = safeFileName('operator ${op.element.name}');
    _writeSource(buffer, op, '$containerName/$safeName', options);
  }

  buffer.writeln('---');
  buffer.writeln();
  return buffer.toString();
}

/// Writes inline source or a link to a detail page depending on threshold.
///
/// Returns true if a detail page should be created.
void _writeSource(
  StringBuffer buffer,
  ModelElement element,
  String detailPath,
  RenderOptions options,
) {
  var source = element.sourceCode;
  if (source.isEmpty) return;

  var lineCount = sourceLineCount(source);
  if (lineCount <= options.sourceLineThreshold) {
    buffer.writeln('```dart');
    buffer.writeln(source);
    buffer.writeln('```');
    buffer.writeln();
  } else {
    buffer.writeln('See [full implementation]($detailPath.md)');
    buffer.writeln();
  }
}

/// Returns true if a detail page is needed for this element.
bool needsDetailPage(ModelElement element, RenderOptions options) {
  if (!options.includeSource) return false;
  if (element is Method && element.isAbstract) return false;
  if (element is Operator && element.isAbstract) return false;
  var source = element.sourceCode;
  if (source.isEmpty) return false;
  return sourceLineCount(source) > options.sourceLineThreshold;
}

void _writeCategorySection(
  StringBuffer buffer,
  String heading,
  Iterable<ModelElement> elements,
  Category category,
) {
  var publicElements = elements.where((e) => e.isPublic).toList();
  if (publicElements.isEmpty) return;

  buffer.writeln('### $heading');
  buffer.writeln();
  for (var element in publicElements) {
    var lib = element.library;
    if (element is Container) {
      buffer.writeln('- [${element.name}](${lib.dirName}/${element.name}.md)');
    } else {
      buffer.writeln('- ${element.name}');
    }
  }
  buffer.writeln();
}
