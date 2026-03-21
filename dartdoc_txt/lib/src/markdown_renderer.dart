import 'package:dartdoc/src/model/model.dart';

import 'doc_tree.dart';
import 'element_renderers.dart';
import 'template_loader.dart';
import 'utilities.dart';

/// Walks a [PackageGraph] and builds a lazy [DocDir] tree.
class MarkdownRenderer {
  final PackageGraph packageGraph;
  final RenderOptions _options;

  MarkdownRenderer({required this.packageGraph, required RenderOptions options})
    : _options = options;

  DocDir render() {
    var templates = Templates.load();
    var package = packageGraph.defaultPackage;
    var libraries = _documentedLibraries(package);
    var root = DocDir('');

    // README
    var doc = package.documentation;
    if (doc != null && doc.isNotEmpty) {
      root.children.add(ReadmePage(doc, fileExtension: _options.fileExtension));
    }

    // INDEX
    root.children.add(
      IndexPage(
        package,
        libraries,
        templates,
        _librarySectionData,
        fileExtension: _options.fileExtension,
      ),
    );

    // Libraries
    for (var lib in libraries) {
      root.children.add(_buildLibraryDir(lib, templates));
    }

    // Categories
    if (package.hasDocumentedCategories) {
      var topicsDir = DocDir('topics');
      for (var cat in package.documentedCategoriesSorted) {
        topicsDir.children.add(
          CategoryPage(cat, templates, fileExtension: _options.fileExtension),
        );
      }
      root.children.add(topicsDir);
    }

    return root;
  }

  Map<String, dynamic> _librarySectionData(Library library) {
    var libDir = library.displayName;
    var doc = library.documentation;
    var cleanDoc = doc.isNotEmpty ? stripResidualHtml(doc) : '';

    // Element lists (classes, enums, mixins, extensions, extension types)
    var elementLists = <Map<String, dynamic>>[];
    _addElementList(
      elementLists,
      'Classes',
      library.classes.where((c) => c.isPublic).toList(),
      libDir,
      library.name,
    );
    _addElementList(
      elementLists,
      'Enums',
      library.enums.where((e) => e.isPublic).toList(),
      libDir,
      library.name,
    );
    _addElementList(
      elementLists,
      'Mixins',
      library.mixins.where((m) => m.isPublic).toList(),
      libDir,
      library.name,
    );
    _addElementList(
      elementLists,
      'Extensions',
      library.extensions.where((e) => e.isPublic).toList(),
      libDir,
      library.name,
    );
    _addElementList(
      elementLists,
      'Extension Types',
      library.extensionTypes.where((e) => e.isPublic).toList(),
      libDir,
      library.name,
    );

    // Functions
    var publicFunctions = library.functions.where((f) => f.isPublic).toList();

    // Properties and constants
    var publicProperties = library.properties.where((p) => p.isPublic).toList();
    var publicConstants = library.constants.where((c) => c.isPublic).toList();

    // Typedefs
    var publicTypedefs = library.typedefs.where((t) => t.isPublic).toList();

    return {
      'libraryName': library.name,
      'libDir': libDir,
      'hasDocumentation': cleanDoc.isNotEmpty,
      'documentation': cleanDoc,
      'elementLists': elementLists,
      'hasFunctions': publicFunctions.isNotEmpty,
      'functions': publicFunctions.map((func) {
        var summary = extractSummary(func.documentation);
        var desc = summary.isNotEmpty ? ' — $summary' : '';
        return {'line': '- ${func.name}$desc'};
      }).toList(),
      'hasPropertiesOrConstants':
          publicProperties.isNotEmpty || publicConstants.isNotEmpty,
      'propertiesAndConstants': [
        ...publicConstants.map((c) {
          var summary = extractSummary(c.documentation);
          var desc = summary.isNotEmpty ? ' — $summary' : '';
          return {'line': '- ${c.name}$desc'};
        }),
        ...publicProperties.map((prop) {
          var summary = extractSummary(prop.documentation);
          var desc = summary.isNotEmpty ? ' — $summary' : '';
          return {'line': '- ${prop.name}$desc'};
        }),
      ],
      'hasTypedefs': publicTypedefs.isNotEmpty,
      'typedefs': publicTypedefs.map((td) {
        var summary = extractSummary(td.documentation);
        var desc = summary.isNotEmpty ? ' — $summary' : '';
        return {'line': '- ${td.name}$desc'};
      }).toList(),
    };
  }

  void _addElementList(
    List<Map<String, dynamic>> lists,
    String heading,
    List<ModelElement> elements,
    String libDir,
    String libraryName,
  ) {
    if (elements.isEmpty) return;

    lists.add({
      'heading': heading,
      'libraryName': libraryName,
      'elements': elements.map((element) {
        var summary = extractSummary(element.documentation);
        var desc = summary.isNotEmpty ? ' — $summary' : '';
        return {
          'line':
              '- [${element.name}]($libDir/${element.name}/${element.name}.md)$desc',
        };
      }).toList(),
    });
  }

  DocDir _buildLibraryDir(Library library, Templates templates) {
    var libDir = DocDir(library.displayName);

    // Containers (classes, enums, mixins, extensions, extension types)
    for (var cls in library.classes.where((c) => c.isPublic)) {
      libDir.children.add(_buildContainerDir(cls, templates));
    }
    for (var e in library.enums.where((e) => e.isPublic)) {
      libDir.children.add(_buildContainerDir(e, templates));
    }
    for (var m in library.mixins.where((m) => m.isPublic)) {
      libDir.children.add(_buildContainerDir(m, templates));
    }
    for (var ext in library.extensions.where((e) => e.isPublic)) {
      libDir.children.add(_buildContainerDir(ext, templates));
    }
    for (var et in library.extensionTypes.where((e) => e.isPublic)) {
      libDir.children.add(_buildContainerDir(et, templates));
    }

    // Top-level functions
    var functions = library.functions.where((f) => f.isPublic);
    if (functions.isNotEmpty) {
      var funcDir = DocDir('top-level-functions');
      funcDir.children.add(TopLevelFunctionsPage(library, _options, templates));
      for (var func in functions) {
        if (needsDetailPage(func, _options)) {
          funcDir.children.add(
            DetailPage(
              '${func.name}.${_options.fileExtension}',
              func,
              library.name,
              _options,
              templates,
            ),
          );
        }
      }
      libDir.children.add(funcDir);
    }

    // Top-level properties
    var properties = library.properties.where((p) => p.isPublic);
    var constants = library.constants.where((c) => c.isPublic);
    if (properties.isNotEmpty || constants.isNotEmpty) {
      var propDir = DocDir('top-level-properties');
      propDir.children.add(
        TopLevelPropertiesPage(library, _options, templates),
      );
      libDir.children.add(propDir);
    }

    // Typedefs
    var typedefs = library.typedefs.where((t) => t.isPublic);
    if (typedefs.isNotEmpty) {
      var tdDir = DocDir('typedefs');
      tdDir.children.add(TypedefsPage(library, _options, templates));
      libDir.children.add(tdDir);
    }

    return libDir;
  }

  DocDir _buildContainerDir(Container container, Templates templates) {
    var containerDir = DocDir(container.name);
    containerDir.children.add(ContainerPage(container, _options, templates));

    // Detail pages for constructors
    if (container is Constructable) {
      for (var ctor in container.publicConstructorsSorted) {
        if (needsDetailPage(ctor, _options)) {
          containerDir.children.add(
            DetailPage(
              '${container.name}-${ctorBaseName(ctor.name, container.name)}.${_options.fileExtension}',
              ctor,
              container.name,
              _options,
              templates,
            ),
          );
        }
      }
    }

    // Detail pages for methods (declared only)
    for (var method in container.declaredMethods.whereType<Method>().where(
      (m) => !m.isOperator && m.isPublic,
    )) {
      if (needsDetailPage(method, _options)) {
        containerDir.children.add(
          DetailPage(
            '${container.name}-${safeFileName(method.name)}.${_options.fileExtension}',
            method,
            container.name,
            _options,
            templates,
          ),
        );
      }
    }
    for (var method in container.staticMethods.where((m) => m.isPublic)) {
      if (needsDetailPage(method, _options)) {
        containerDir.children.add(
          DetailPage(
            '${container.name}-${safeFileName(method.name)}.${_options.fileExtension}',
            method,
            container.name,
            _options,
            templates,
          ),
        );
      }
    }

    // Detail pages for operators (declared only)
    for (var op in container.declaredOperators.where((o) => o.isPublic)) {
      if (needsDetailPage(op, _options)) {
        var safeName = safeFileName('operator ${op.element.name}');
        containerDir.children.add(
          DetailPage(
            '${container.name}-$safeName.${_options.fileExtension}',
            op,
            container.name,
            _options,
            templates,
          ),
        );
      }
    }

    return containerDir;
  }

  List<Library> _documentedLibraries(Package package) {
    return package.publicLibrariesSorted
        .where((lib) => !lib.displayName.startsWith('src/'))
        .toList();
  }
}
