// dartdoc does not re-export model classes from its public API.
// ignore: implementation_imports
import 'package:dartdoc/src/model/model.dart';
import 'package:dartdoc_txt/src/doc_tree.dart';
import 'package:dartdoc_txt/src/signature_builder.dart';
import 'package:dartdoc_txt/src/template_loader.dart';
import 'package:dartdoc_txt/src/utilities.dart';
import 'package:path/path.dart' as p;

/// Options controlling rendering behavior.
class RenderOptions {
  const RenderOptions({
    required this.packageRoot,
    this.sourceLineThreshold = 10,
    this.includeSource = true,
    this.fileExtension = 'md',
  });
  final String packageRoot;
  final int sourceLineThreshold;
  final bool includeSource;
  final String fileExtension;
}

/// Renders a container (Class, Enum, Mixin, ExtensionType) to Markdown.
String renderContainer(
  Container container,
  RenderOptions options,
  Templates templates,
) {
  final data = _containerData(container, options);
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
  final functions = library.functions.where((f) => f.isPublic).toList();
  if (functions.isEmpty) {
    return '';
  }

  final data = {
    'libraryName': library.name,
    'functions': functions.map((func) {
      final sourceData = _sourceData(func, func.name, options);
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
        ..._sourceLocationData(func, options.packageRoot),
      };
    }).toList(),
  };

  return templates['top_level_functions'].renderString(data);
}

/// Renders all top-level properties and constants for a library.
String renderTopLevelProperties(
  Library library,
  RenderOptions options,
  Templates templates,
) {
  final properties = library.properties.where((p) => p.isPublic).toList();
  final constants = library.constants.where((c) => c.isPublic).toList();
  if (properties.isEmpty && constants.isEmpty) {
    return '';
  }

  final data = {
    'libraryName': library.name,
    'hasConstants': constants.isNotEmpty,
    'constants': constants.map((c) {
      final doc = _cleanDoc(c.documentation);
      return {
        'name': c.name,
        'typeName': plainTypeName(c.modelType),
        'hasConstantValue': c.constantValueBase.isNotEmpty,
        'constantValue': unescapeHtml(c.constantValueBase),
        'hasDocumentation': doc.isNotEmpty,
        'documentation': doc,
        ..._sourceLocationData(c, options.packageRoot),
      };
    }).toList(),
    'hasProperties': properties.isNotEmpty,
    'properties': properties.map((prop) {
      final doc = _cleanDoc(prop.documentation);
      return {
        'name': prop.name,
        'typeName': plainTypeName(prop.modelType),
        'hasDocumentation': doc.isNotEmpty,
        'documentation': doc,
        ..._sourceLocationData(prop, options.packageRoot),
      };
    }).toList(),
  };

  return templates['top_level_properties'].renderString(data);
}

/// Renders all typedefs for a library.
String renderTypedefs(
  Library library,
  RenderOptions options,
  Templates templates,
) {
  final typedefs = library.typedefs.where((t) => t.isPublic).toList();
  if (typedefs.isEmpty) {
    return '';
  }

  final data = {
    'libraryName': library.name,
    'typedefs': typedefs.map((td) {
      final doc = _cleanDoc(td.documentation);
      return {
        'name': td.name,
        'sourceCode': _rawSourceCode(td),
        'hasDocumentation': doc.isNotEmpty,
        'documentation': doc,
        ..._sourceLocationData(td, options.packageRoot),
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
  final title = element is Constructor
      ? (element.name == parentName ? '$parentName.new' : element.name)
      : '$parentName.${element.name}';

  final annotations = renderAnnotations(element);
  final doc = _cleanDoc(element.documentation);

  final data = {
    'title': title,
    'signature': renderSignature(element),
    'hasAnnotations': annotations.isNotEmpty,
    'annotations': annotations,
    'isDeprecated': element.isDeprecated,
    'deprecation': renderDeprecation(element),
    'hasDocumentation': doc.isNotEmpty,
    'documentation': doc,
    'sourceCode': _rawSourceCode(element),
    ..._sourceLocationData(element, options.packageRoot),
  };

  return templates['detail_page'].renderString(data);
}

/// Renders a category page.
String renderCategory(Category category, Templates templates) {
  final doc = category.documentation;
  final cleanDoc = (doc != null && doc.isNotEmpty)
      ? stripResidualHtml(doc)
      : '';

  final sections = <Map<String, dynamic>>[];
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

  final data = {
    'hasDocumentation': cleanDoc.isNotEmpty,
    'documentation': cleanDoc,
    'sections': sections,
  };

  return templates['category'].renderString(data);
}

/// Returns the raw source code for an element, bypassing dartdoc's HTML
/// escaping.
String _rawSourceCode(ModelElement element) {
  return element.modelNode?.sourceCode ?? '';
}

// --- Private helpers ---

String _cleanDoc(String? documentation) {
  if (documentation == null || documentation.isEmpty) {
    return '';
  }
  return stripResidualHtml(documentation);
}

Map<String, dynamic> _containerData(
  Container container,
  RenderOptions options,
) {
  final doc = _cleanDoc(container.documentation);

  // Enum values
  final hasEnumValues =
      container is Enum && container.publicEnumValues.isNotEmpty;
  final enumValues = <Map<String, dynamic>>[];
  if (container is Enum) {
    for (final value in container.publicEnumValues) {
      final valueDoc = _cleanDoc(value.documentation);
      enumValues.add({
        'name': value.name,
        'hasDocumentation': valueDoc.isNotEmpty,
        'documentation': valueDoc,
      });
    }
  }

  // Constructors
  final hasConstructors =
      container is Constructable && container.hasPublicConstructors;
  final constructors = <Map<String, dynamic>>[];
  if (container is Constructable) {
    for (final ctor in container.publicConstructorsSorted) {
      constructors.add(_constructorData(ctor, container.name, options));
    }
  }

  // Properties (declared only, not inherited, excluding enum values)
  final publicFields = container.declaredFields
      .where((f) => f.isPublic && !f.isEnumValue)
      .where((f) => f.name != 'hashCode')
      .toList();
  final properties = publicFields.map(_fieldData).toList();

  // Methods (declared only, not inherited)
  final publicMethods = container.declaredMethods
      .whereType<Method>()
      .where((m) => !m.isOperator)
      .where((m) => m.isPublic)
      .where((m) => m.name != 'toString')
      .toList();
  final publicStaticMethods = container.staticMethods
      .where((m) => m.isPublic)
      .toList();
  final allPublicMethods = [...publicMethods, ...publicStaticMethods];
  final methods = allPublicMethods
      .map((m) => _methodData(m, container.name, options))
      .toList();

  // Operators (declared only, not inherited)
  final publicOperators = container.declaredOperators
      .where((o) => o.isPublic)
      .where((o) => o.name != 'operator ==')
      .toList();
  final operators = publicOperators
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
    ..._sourceLocationData(container, options.packageRoot),
  };
}

Map<String, dynamic> _constructorData(
  Constructor ctor,
  String containerName,
  RenderOptions options,
) {
  final annotations = renderAnnotations(ctor);
  final doc = _cleanDoc(ctor.documentation);
  final sourceData = options.includeSource
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
    ..._sourceLocationData(ctor, options.packageRoot),
  };
}

Map<String, dynamic> _fieldData(Field field) {
  final attributes = renderAttributes(field);
  final doc = _cleanDoc(field.documentation);

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
  final annotations = renderAnnotations(method);
  final doc = _cleanDoc(method.documentation);
  final sourceData = (options.includeSource && !method.element.isAbstract)
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
    ..._sourceLocationData(method, options.packageRoot),
  };
}

Map<String, dynamic> _operatorData(
  Operator op,
  String containerName,
  RenderOptions options,
) {
  final doc = _cleanDoc(op.documentation);
  final safeName = safeFileName('operator ${op.element.name}');
  final sourceData = (options.includeSource && !op.element.isAbstract)
      ? _sourceData(op, '$containerName-$safeName', options)
      : _noSourceData();

  return {
    'signature': renderSignature(op),
    'hasDocumentation': doc.isNotEmpty,
    'documentation': doc,
    ...sourceData,
    ..._sourceLocationData(op, options.packageRoot),
  };
}

/// Computes source location data (relative path + line number range) for an
/// element.
Map<String, dynamic> _sourceLocationData(
  ModelElement element,
  String packageRoot,
) {
  final absolutePath = element.sourceFileName;
  final relativePath = p.relative(absolutePath, from: packageRoot);
  final startLine = element.characterLocation?.lineNumber;
  if (startLine == null) {
    return {'hasSourceLocation': true, 'sourceLocation': relativePath};
  }
  final lineCount = sourceLineCount(_rawSourceCode(element));
  final location = lineCount > 0
      ? '$relativePath:$startLine:${startLine + lineCount - 1}'
      : '$relativePath:$startLine';
  return {'hasSourceLocation': true, 'sourceLocation': location};
}

/// Computes source display data for an element.
Map<String, dynamic> _sourceData(
  ModelElement element,
  String detailPath,
  RenderOptions options,
) {
  final source = _rawSourceCode(element);
  if (source.isEmpty) {
    return _noSourceData();
  }

  final lineCount = sourceLineCount(source);
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
  return {'hasInlineSource': false, 'hasDetailLink': false};
}

/// Returns true if a detail page is needed for this element.
bool needsDetailPage(ModelElement element, RenderOptions options) {
  if (!options.includeSource) {
    return false;
  }
  if (element is Method && element.element.isAbstract) {
    return false;
  }
  if (element is Operator && element.element.isAbstract) {
    return false;
  }
  final source = _rawSourceCode(element);
  if (source.isEmpty) {
    return false;
  }
  return sourceLineCount(source) > options.sourceLineThreshold;
}

void _addCategorySection(
  List<Map<String, dynamic>> sections,
  String heading,
  Iterable<ModelElement> elements,
  Category category,
) {
  final publicElements = elements.where((e) => e.isPublic).toList();
  if (publicElements.isEmpty) {
    return;
  }

  sections.add({
    'heading': heading,
    'elements': publicElements.map((element) {
      final lib = element.canonicalLibrary ?? element.library;
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

// ---------------------------------------------------------------------------
// DocFile subclasses — self-rendering document nodes
// ---------------------------------------------------------------------------

/// Computes the file name for a category/topic page.
String topicFileName(Category category, [String fileExtension = 'md']) {
  final docFile = category.documentationFile;
  if (docFile != null) {
    return p.setExtension(p.basename(docFile.path), '.$fileExtension');
  }
  return '${category.name.replaceAll(RegExp(r'\s+'), '_')}.$fileExtension';
}

/// README page — strips HTML from package docs.
class ReadmePage extends DocFile {
  ReadmePage(this.documentation, {String fileExtension = 'md'})
    : super('README.$fileExtension');
  final String documentation;

  @override
  String renderContent() => stripResidualHtml(documentation);
}

/// Package-level INDEX.md.
class IndexPage extends DocFile {
  IndexPage(
    this.package,
    this.libraries,
    this.templates,
    this.librarySectionData, {
    String fileExtension = 'md',
  }) : super('INDEX.$fileExtension');
  final Package package;
  final List<Library> libraries;
  final Templates templates;
  final Map<String, dynamic> Function(Library) librarySectionData;

  @override
  String renderContent() {
    final data = {
      'packageName': package.name,
      'version': package.version,
      'hasCategories': package.hasDocumentedCategories,
      'categories': package.hasDocumentedCategories
          ? package.documentedCategoriesSorted.map((category) {
              final summary = extractSummary(category.documentation);
              final desc = summary.isNotEmpty ? ' — $summary' : '';
              return {
                'line':
                    '- [${category.name}](topics/${topicFileName(category)})$desc',
              };
            }).toList()
          : <Map<String, dynamic>>[],
      'libraries': libraries.map(librarySectionData).toList(),
    };
    return templates['index'].renderString(data);
  }
}

/// Container page (class, enum, mixin, extension, extension type).
class ContainerPage extends DocFile {
  ContainerPage(this.container, this.options, this.templates)
    : super('${container.name}.${options.fileExtension}');
  final Container container;
  final RenderOptions options;
  final Templates templates;

  @override
  String renderContent() => renderContainer(container, options, templates);
}

/// Detail page for members with large source.
class DetailPage extends DocFile {
  DetailPage(
    super.name,
    this.element,
    this.parentName,
    this.options,
    this.templates,
  );
  final ModelElement element;
  final String parentName;
  final RenderOptions options;
  final Templates templates;

  @override
  String renderContent() =>
      renderDetailPage(element, parentName, options, templates);
}

/// Top-level functions page.
class TopLevelFunctionsPage extends DocFile {
  TopLevelFunctionsPage(this.library, this.options, this.templates)
    : super('top-level-functions.${options.fileExtension}');
  final Library library;
  final RenderOptions options;
  final Templates templates;

  @override
  String renderContent() =>
      renderTopLevelFunctions(library, options, templates);
}

/// Top-level properties page.
class TopLevelPropertiesPage extends DocFile {
  TopLevelPropertiesPage(this.library, this.options, this.templates)
    : super('top-level-properties.${options.fileExtension}');
  final Library library;
  final RenderOptions options;
  final Templates templates;

  @override
  String renderContent() =>
      renderTopLevelProperties(library, options, templates);
}

/// Typedefs page.
class TypedefsPage extends DocFile {
  TypedefsPage(this.library, this.options, this.templates)
    : super('typedefs.${options.fileExtension}');
  final Library library;
  final RenderOptions options;
  final Templates templates;

  @override
  String renderContent() => renderTypedefs(library, options, templates);
}

/// Category/topic page.
class CategoryPage extends DocFile {
  CategoryPage(this.category, this.templates, {String fileExtension = 'md'})
    : super(topicFileName(category, fileExtension));
  final Category category;
  final Templates templates;

  @override
  String renderContent() => renderCategory(category, templates);
}
