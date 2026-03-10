import 'dart:io';

import 'package:dartdoc/src/model/model.dart';
import 'package:path/path.dart' as p;

import 'element_renderers.dart';
import 'template_loader.dart';
import 'utilities.dart';

/// Walks a [PackageGraph] and generates Markdown documentation files.
class MarkdownRenderer {
  final PackageGraph packageGraph;
  final String outputDir;
  final int sourceLineThreshold;
  final bool includeSource;

  late final RenderOptions _options;

  MarkdownRenderer({
    required this.packageGraph,
    required this.outputDir,
    this.sourceLineThreshold = 10,
    this.includeSource = true,
  }) {
    _options = RenderOptions(
      sourceLineThreshold: sourceLineThreshold,
      includeSource: includeSource,
    );
  }

  Future<void> render() async {
    var templates = Templates.load();
    var package = packageGraph.defaultPackage;

    _renderReadme(package);
    _renderIndex(package, templates);

    for (var lib in _documentedLibraries(package)) {
      _renderLibrary(lib, templates);
    }

    _renderCategories(package, templates);
  }

  void _renderReadme(Package package) {
    var doc = package.documentation;
    if (doc == null || doc.isEmpty) return;

    _writeFile('README.md', stripResidualHtml(doc));
  }

  void _renderIndex(Package package, Templates templates) {
    var libraries = _documentedLibraries(package);

    var data = {
      'packageName': package.name,
      'version': package.version,
      'hasCategories': package.hasDocumentedCategories,
      'categories': package.hasDocumentedCategories
          ? package.documentedCategoriesSorted.map((category) {
              var summary = extractSummary(category.documentation);
              var desc = summary.isNotEmpty ? ' — $summary' : '';
              return {
                'line':
                    '- [${category.name}](topics/${_topicFileName(category)})$desc',
              };
            }).toList()
          : <Map<String, dynamic>>[],
      'libraries': libraries.map((lib) => _librarySectionData(lib)).toList(),
    };

    _writeFile('INDEX.md', templates['index'].renderString(data));
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
    var publicProperties =
        library.properties.where((p) => p.isPublic).toList();
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

  void _renderLibrary(Library library, Templates templates) {
    var libDir = library.displayName;

    // Render container files
    for (var cls in library.classes.where((c) => c.isPublic)) {
      _renderContainerFile(cls, libDir, templates);
    }
    for (var e in library.enums.where((e) => e.isPublic)) {
      _renderContainerFile(e, libDir, templates);
    }
    for (var m in library.mixins.where((m) => m.isPublic)) {
      _renderContainerFile(m, libDir, templates);
    }
    for (var ext in library.extensions.where((e) => e.isPublic)) {
      _renderContainerFile(ext, libDir, templates);
    }
    for (var et in library.extensionTypes.where((e) => e.isPublic)) {
      _renderContainerFile(et, libDir, templates);
    }

    // Top-level functions
    var functionsContent =
        renderTopLevelFunctions(library, _options, templates);
    if (functionsContent.isNotEmpty) {
      _writeFile(
        p.join(libDir, 'top-level-functions', 'top-level-functions.md'),
        functionsContent,
      );
      _renderDetailPagesForFunctions(library, libDir, templates);
    }

    // Top-level properties
    var propertiesContent = renderTopLevelProperties(library, templates);
    if (propertiesContent.isNotEmpty) {
      _writeFile(
        p.join(libDir, 'top-level-properties', 'top-level-properties.md'),
        propertiesContent,
      );
    }

    // Typedefs
    var typedefsContent = renderTypedefs(library, templates);
    if (typedefsContent.isNotEmpty) {
      _writeFile(p.join(libDir, 'typedefs', 'typedefs.md'), typedefsContent);
    }
  }

  void _renderContainerFile(
    Container container,
    String libDir,
    Templates templates,
  ) {
    var content = renderContainer(container, _options, templates);
    _writeFile(
      p.join(libDir, container.name, '${container.name}.md'),
      content,
    );

    // Create detail pages for members with large source
    _renderDetailPagesForContainer(container, libDir, templates);
  }

  void _renderDetailPagesForContainer(
    Container container,
    String libDir,
    Templates templates,
  ) {
    var detailDir = p.join(libDir, container.name);

    // Constructors
    if (container is Constructable) {
      for (var ctor in container.publicConstructorsSorted) {
        if (needsDetailPage(ctor, _options)) {
          var content =
              renderDetailPage(ctor, container.name, _options, templates);
          _writeFile(
            p.join(
              detailDir,
              '${container.name}-${ctorBaseName(ctor.name, container.name)}.md',
            ),
            content,
          );
        }
      }
    }

    // Methods (declared only)
    for (var method in container.declaredMethods.whereType<Method>().where(
      (m) => !m.isOperator && m.isPublic,
    )) {
      if (needsDetailPage(method, _options)) {
        var content =
            renderDetailPage(method, container.name, _options, templates);
        _writeFile(
          p.join(
            detailDir,
            '${container.name}-${safeFileName(method.name)}.md',
          ),
          content,
        );
      }
    }
    for (var method in container.staticMethods.where((m) => m.isPublic)) {
      if (needsDetailPage(method, _options)) {
        var content =
            renderDetailPage(method, container.name, _options, templates);
        _writeFile(
          p.join(
            detailDir,
            '${container.name}-${safeFileName(method.name)}.md',
          ),
          content,
        );
      }
    }

    // Operators (declared only)
    for (var op in container.declaredOperators.where((o) => o.isPublic)) {
      if (needsDetailPage(op, _options)) {
        var safeName = safeFileName('operator ${op.element.name}');
        var content =
            renderDetailPage(op, container.name, _options, templates);
        _writeFile(
          p.join(detailDir, '${container.name}-$safeName.md'),
          content,
        );
      }
    }
  }

  void _renderDetailPagesForFunctions(
    Library library,
    String libDir,
    Templates templates,
  ) {
    var detailDir = p.join(libDir, 'top-level-functions');
    for (var func in library.functions.where((f) => f.isPublic)) {
      if (needsDetailPage(func, _options)) {
        var content =
            renderDetailPage(func, library.name, _options, templates);
        _writeFile(p.join(detailDir, '${func.name}.md'), content);
      }
    }
  }

  void _renderCategories(Package package, Templates templates) {
    if (!package.hasDocumentedCategories) return;

    for (var category in package.documentedCategoriesSorted) {
      var content = renderCategory(category, templates);
      _writeFile(p.join('topics', _topicFileName(category)), content);
    }
  }

  String _topicFileName(Category category) {
    final docFile = category.documentationFile;
    if (docFile != null) return p.basename(docFile.path);
    return '${category.name.replaceAll(RegExp(r'\s+'), '_')}.md';
  }

  List<Library> _documentedLibraries(Package package) {
    return package.publicLibrariesSorted
        .where((lib) => !lib.displayName.startsWith('src/'))
        .toList();
  }

  void _writeFile(String relativePath, String content) {
    var file = File(p.join(outputDir, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }
}
