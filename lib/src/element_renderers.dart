import 'package:dartdoc/src/model/model.dart';

import 'signature_builder.dart';
import 'template_loader.dart';
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
String renderContainer(
  Container container,
  RenderOptions options,
  Templates templates,
) {
  var data = _containerData(container, options);
  return templates['container'].renderString(data);
}

/// Renders an Extension to Markdown.
String renderExtension(
  Extension extension,
  RenderOptions options,
  Templates templates,
) {
  return renderContainer(extension, options, templates);
}

/// Renders all top-level functions for a library.
String renderTopLevelFunctions(
  Library library,
  RenderOptions options,
  Templates templates,
) {
  var functions = library.functions.where((f) => f.isPublic).toList();
  if (functions.isEmpty) return '';

  var data = {
    'libraryName': library.name,
    'functions': functions.map((func) {
      var sourceData = _sourceData(func, func.name, options);
      return {
        'name': func.name,
        'signature': renderSignature(func),
        'isDeprecated': func.isDeprecated,
        'deprecation': renderDeprecation(func),
        'hasAnnotations': renderAnnotations(func).isNotEmpty,
        'annotations': renderAnnotations(func),
        'hasDocumentation': _cleanDoc(func.documentation).isNotEmpty,
        'documentation': _cleanDoc(func.documentation),
        ...sourceData,
      };
    }).toList(),
  };

  return templates['top_level_functions'].renderString(data);
}

/// Renders all top-level properties and constants for a library.
String renderTopLevelProperties(Library library, Templates templates) {
  var properties = library.properties.where((p) => p.isPublic).toList();
  var constants = library.constants.where((c) => c.isPublic).toList();
  if (properties.isEmpty && constants.isEmpty) return '';

  var data = {
    'libraryName': library.name,
    'hasConstants': constants.isNotEmpty,
    'constants': constants.map((c) {
      var doc = _cleanDoc(c.documentation);
      return {
        'name': c.name,
        'typeName': plainTypeName(c.modelType),
        'hasConstantValue': c.constantValue.isNotEmpty,
        'constantValue': unescapeHtml(c.constantValue),
        'hasDocumentation': doc.isNotEmpty,
        'documentation': doc,
      };
    }).toList(),
    'hasProperties': properties.isNotEmpty,
    'properties': properties.map((prop) {
      var doc = _cleanDoc(prop.documentation);
      return {
        'name': prop.name,
        'typeName': plainTypeName(prop.modelType),
        'hasDocumentation': doc.isNotEmpty,
        'documentation': doc,
      };
    }).toList(),
  };

  return templates['top_level_properties'].renderString(data);
}

/// Renders all typedefs for a library.
String renderTypedefs(Library library, Templates templates) {
  var typedefs = library.typedefs.where((t) => t.isPublic).toList();
  if (typedefs.isEmpty) return '';

  var data = {
    'libraryName': library.name,
    'typedefs': typedefs.map((td) {
      var doc = _cleanDoc(td.documentation);
      return {
        'name': td.name,
        'sourceCode': unescapeHtml(td.sourceCode),
        'hasDocumentation': doc.isNotEmpty,
        'documentation': doc,
      };
    }).toList(),
  };

  return templates['typedefs'].renderString(data);
}

/// Renders a detail page for an element whose source exceeds the threshold.
String renderDetailPage(
  ModelElement element,
  String parentName,
  RenderOptions options,
  Templates templates,
) {
  var title = element is Constructor
      ? (element.name == parentName ? '$parentName.new' : element.name)
      : '$parentName.${element.name}';

  var annotations = renderAnnotations(element);
  var doc = _cleanDoc(element.documentation);

  var data = {
    'title': title,
    'signature': renderSignature(element),
    'hasAnnotations': annotations.isNotEmpty,
    'annotations': annotations,
    'isDeprecated': element.isDeprecated,
    'deprecation': renderDeprecation(element),
    'hasDocumentation': doc.isNotEmpty,
    'documentation': doc,
    'sourceCode': unescapeHtml(element.sourceCode),
  };

  return templates['detail_page'].renderString(data);
}

/// Renders a category page.
String renderCategory(Category category, Templates templates) {
  var doc = category.documentation;
  var cleanDoc = (doc != null && doc.isNotEmpty) ? stripResidualHtml(doc) : '';

  var sections = <Map<String, dynamic>>[];
  _addCategorySection(sections, 'Classes', category.classes, category);
  _addCategorySection(sections, 'Enums', category.enums, category);
  _addCategorySection(sections, 'Mixins', category.mixins, category);
  _addCategorySection(sections, 'Extensions', category.extensions, category);
  _addCategorySection(
    sections,
    'Extension Types',
    category.extensionTypes,
    category,
  );
  _addCategorySection(sections, 'Functions', category.functions, category);
  _addCategorySection(sections, 'Properties', category.properties, category);
  _addCategorySection(sections, 'Typedefs', category.typedefs, category);

  var data = {
    'hasDocumentation': cleanDoc.isNotEmpty,
    'documentation': cleanDoc,
    'sections': sections,
  };

  return templates['category'].renderString(data);
}

// --- Private helpers ---

String _cleanDoc(String? documentation) {
  if (documentation == null || documentation.isEmpty) return '';
  return stripResidualHtml(documentation);
}

Map<String, dynamic> _containerData(
  Container container,
  RenderOptions options,
) {
  var doc = _cleanDoc(container.documentation);

  // Enum values
  var hasEnumValues =
      container is Enum && container.publicEnumValues.isNotEmpty;
  var enumValues = <Map<String, dynamic>>[];
  if (container is Enum) {
    for (var value in container.publicEnumValues) {
      var valueDoc = _cleanDoc(value.documentation);
      enumValues.add({
        'name': value.name,
        'hasDocumentation': valueDoc.isNotEmpty,
        'documentation': valueDoc,
      });
    }
  }

  // Constructors
  var hasConstructors =
      container is Constructable && container.hasPublicConstructors;
  var constructors = <Map<String, dynamic>>[];
  if (container is Constructable) {
    for (var ctor in container.publicConstructorsSorted) {
      constructors.add(_constructorData(ctor, container.name, options));
    }
  }

  // Properties (declared only, not inherited, excluding enum values)
  var publicFields = container.declaredFields
      .where((f) => f.isPublic && !f.isEnumValue)
      .where((f) => f.name != 'hashCode')
      .toList();
  var properties = publicFields.map(_fieldData).toList();

  // Methods (declared only, not inherited)
  var publicMethods = container.declaredMethods
      .whereType<Method>()
      .where((m) => !m.isOperator)
      .where((m) => m.isPublic)
      .where((m) => m.name != 'toString')
      .toList();
  var publicStaticMethods =
      container.staticMethods.where((m) => m.isPublic).toList();
  var allPublicMethods = [...publicMethods, ...publicStaticMethods];
  var methods = allPublicMethods
      .map((m) => _methodData(m, container.name, options))
      .toList();

  // Operators (declared only, not inherited)
  var publicOperators = container.declaredOperators
      .where((o) => o.isPublic)
      .where((o) => o.name != 'operator ==')
      .toList();
  var operators = publicOperators
      .map((o) => _operatorData(o, container.name, options))
      .toList();

  return {
    'name': container.name,
    'declaration': renderDeclaration(container),
    'isDeprecated': container.isDeprecated,
    'deprecation': renderDeprecation(container),
    'hasDocumentation': doc.isNotEmpty,
    'documentation': doc,
    'hasEnumValues': hasEnumValues,
    'enumValues': enumValues,
    'hasConstructors': hasConstructors,
    'constructors': constructors,
    'hasProperties': publicFields.isNotEmpty,
    'properties': properties,
    'hasMethods': allPublicMethods.isNotEmpty,
    'methods': methods,
    'hasOperators': publicOperators.isNotEmpty,
    'operators': operators,
  };
}

Map<String, dynamic> _constructorData(
  Constructor ctor,
  String containerName,
  RenderOptions options,
) {
  var annotations = renderAnnotations(ctor);
  var doc = _cleanDoc(ctor.documentation);
  var sourceData = options.includeSource
      ? _sourceData(
          ctor,
          '$containerName-${ctorBaseName(ctor.name, containerName)}',
          options,
        )
      : _noSourceData();

  return {
    'signature': renderSignature(ctor),
    'hasAnnotations': annotations.isNotEmpty,
    'annotations': annotations,
    'isDeprecated': ctor.isDeprecated,
    'deprecation': renderDeprecation(ctor),
    'hasDocumentation': doc.isNotEmpty,
    'documentation': doc,
    ...sourceData,
  };
}

Map<String, dynamic> _fieldData(Field field) {
  var attributes = renderAttributes(field);
  var doc = _cleanDoc(field.documentation);

  return {
    'name': field.name,
    'typeName': plainTypeName(field.modelType),
    'hasAttributes': attributes.isNotEmpty,
    'attributes': attributes,
    'isDeprecated': field.isDeprecated,
    'deprecation': renderDeprecation(field),
    'hasDocumentation': doc.isNotEmpty,
    'documentation': doc,
  };
}

Map<String, dynamic> _methodData(
  Method method,
  String containerName,
  RenderOptions options,
) {
  var annotations = renderAnnotations(method);
  var doc = _cleanDoc(method.documentation);
  var sourceData =
      (options.includeSource && !method.element.isAbstract)
          ? _sourceData(
              method,
              '$containerName-${safeFileName(method.name)}',
              options,
            )
          : _noSourceData();

  return {
    'signature': renderSignature(method),
    'hasAnnotations': annotations.isNotEmpty,
    'annotations': annotations,
    'isDeprecated': method.isDeprecated,
    'deprecation': renderDeprecation(method),
    'hasDocumentation': doc.isNotEmpty,
    'documentation': doc,
    ...sourceData,
  };
}

Map<String, dynamic> _operatorData(
  Operator op,
  String containerName,
  RenderOptions options,
) {
  var doc = _cleanDoc(op.documentation);
  var safeName = safeFileName('operator ${op.element.name}');
  var sourceData =
      (options.includeSource && !op.element.isAbstract)
          ? _sourceData(op, '$containerName-$safeName', options)
          : _noSourceData();

  return {
    'signature': renderSignature(op),
    'hasDocumentation': doc.isNotEmpty,
    'documentation': doc,
    ...sourceData,
  };
}

/// Computes source display data for an element.
Map<String, dynamic> _sourceData(
  ModelElement element,
  String detailPath,
  RenderOptions options,
) {
  var source = unescapeHtml(element.sourceCode);
  if (source.isEmpty) return _noSourceData();

  var lineCount = sourceLineCount(source);
  if (lineCount <= options.sourceLineThreshold) {
    return {
      'hasInlineSource': true,
      'inlineSource': source,
      'hasDetailLink': false,
    };
  } else {
    return {
      'hasInlineSource': false,
      'hasDetailLink': true,
      'detailLink': '$detailPath.md',
    };
  }
}

Map<String, dynamic> _noSourceData() {
  return {
    'hasInlineSource': false,
    'hasDetailLink': false,
  };
}

/// Returns true if a detail page is needed for this element.
bool needsDetailPage(ModelElement element, RenderOptions options) {
  if (!options.includeSource) return false;
  if (element is Method && element.element.isAbstract) return false;
  if (element is Operator && element.element.isAbstract) return false;
  var source = unescapeHtml(element.sourceCode);
  if (source.isEmpty) return false;
  return sourceLineCount(source) > options.sourceLineThreshold;
}

void _addCategorySection(
  List<Map<String, dynamic>> sections,
  String heading,
  Iterable<ModelElement> elements,
  Category category,
) {
  var publicElements = elements.where((e) => e.isPublic).toList();
  if (publicElements.isEmpty) return;

  sections.add({
    'heading': heading,
    'elements': publicElements.map((element) {
      var lib = element.canonicalLibrary ?? element.library;
      if (element is Container && lib != null) {
        return {
          'line':
              '- [${element.name}](${lib.displayName}/${element.name}/${element.name}.md)',
        };
      } else {
        return {'line': '- ${element.name}'};
      }
    }).toList(),
  });
}
