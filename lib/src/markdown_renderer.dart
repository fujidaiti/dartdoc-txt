import 'dart:io';

import 'package:dartdoc/src/model/model.dart';
import 'package:path/path.dart' as p;

import 'element_renderers.dart';
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
    var package = packageGraph.defaultPackage;

    _renderReadme(package);
    _renderIndex(package);

    for (var lib in _documentedLibraries(package)) {
      _renderLibrary(lib);
    }

    _renderCategories(package);
  }

  void _renderReadme(Package package) {
    var doc = package.documentation;
    if (doc == null || doc.isEmpty) return;

    _writeFile('README.md', stripResidualHtml(doc));
  }

  void _renderIndex(Package package) {
    var buffer = StringBuffer();
    buffer.writeln('# ${package.name} Index');
    buffer.writeln();
    buffer.writeln('Version: ${package.version}');
    buffer.writeln();

    if (package.hasDocumentedCategories) {
      buffer.writeln('## Topics');
      buffer.writeln();
      for (var category in package.documentedCategoriesSorted) {
        var summary = extractSummary(category.documentation);
        var desc = summary.isNotEmpty ? ' — $summary' : '';
        buffer.writeln(
          '- [${category.name}](topics/${_topicFileName(category)})$desc',
        );
      }
      buffer.writeln();
    }

    for (var lib in _documentedLibraries(package)) {
      _writeLibrarySection(buffer, lib);
    }

    _writeFile('INDEX.md', buffer.toString());
  }

  void _writeLibrarySection(StringBuffer buffer, Library library) {
    var libDir = library.displayName;

    buffer.writeln('## ${library.name} library');
    buffer.writeln();

    var doc = library.documentation;
    if (doc != null && doc.isNotEmpty) {
      buffer.writeln(stripResidualHtml(doc));
      buffer.writeln();
    }

    // Classes
    _writeElementList(
      buffer,
      'Classes',
      library.classes.where((c) => c.isPublic).toList(),
      libDir,
      library.name,
    );

    // Enums
    _writeElementList(
      buffer,
      'Enums',
      library.enums.where((e) => e.isPublic).toList(),
      libDir,
      library.name,
    );

    // Mixins
    _writeElementList(
      buffer,
      'Mixins',
      library.mixins.where((m) => m.isPublic).toList(),
      libDir,
      library.name,
    );

    // Extensions
    _writeElementList(
      buffer,
      'Extensions',
      library.extensions.where((e) => e.isPublic).toList(),
      libDir,
      library.name,
    );

    // Extension Types
    _writeElementList(
      buffer,
      'Extension Types',
      library.extensionTypes.where((e) => e.isPublic).toList(),
      libDir,
      library.name,
    );

    // Functions reference
    var publicFunctions = library.functions.where((f) => f.isPublic).toList();
    if (publicFunctions.isNotEmpty) {
      buffer.writeln('### Functions from ${library.name}');
      buffer.writeln();
      buffer.writeln(
        'See [top-level-functions.md]($libDir/top-level-functions/top-level-functions.md) for more details.',
      );
      buffer.writeln();
      for (var func in publicFunctions) {
        var summary = extractSummary(func.documentation);
        var desc = summary.isNotEmpty ? ' — $summary' : '';
        buffer.writeln('- ${func.name}$desc');
      }
      buffer.writeln();
    }

    // Properties reference
    var publicProperties = library.properties.where((p) => p.isPublic).toList();
    var publicConstants = library.constants.where((c) => c.isPublic).toList();
    if (publicProperties.isNotEmpty || publicConstants.isNotEmpty) {
      buffer.writeln('### Properties from ${library.name}');
      buffer.writeln();
      buffer.writeln(
        'See [top-level-properties.md]($libDir/top-level-properties/top-level-properties.md) for more details.',
      );
      buffer.writeln();
      for (var constant in publicConstants) {
        var summary = extractSummary(constant.documentation);
        var desc = summary.isNotEmpty ? ' — $summary' : '';
        buffer.writeln('- ${constant.name}$desc');
      }
      for (var prop in publicProperties) {
        var summary = extractSummary(prop.documentation);
        var desc = summary.isNotEmpty ? ' — $summary' : '';
        buffer.writeln('- ${prop.name}$desc');
      }
      buffer.writeln();
    }

    // Typedefs reference
    var publicTypedefs = library.typedefs.where((t) => t.isPublic).toList();
    if (publicTypedefs.isNotEmpty) {
      buffer.writeln('### Typedefs from ${library.name}');
      buffer.writeln();
      buffer.writeln(
        'See [typedefs.md]($libDir/typedefs/typedefs.md) for more details.',
      );
      buffer.writeln();
      for (var typedef in publicTypedefs) {
        var summary = extractSummary(typedef.documentation);
        var desc = summary.isNotEmpty ? ' — $summary' : '';
        buffer.writeln('- ${typedef.name}$desc');
      }
      buffer.writeln();
    }
  }

  void _renderLibrary(Library library) {
    var libDir = library.displayName;

    // Render container files
    for (var cls in library.classes.where((c) => c.isPublic)) {
      _renderContainerFile(cls, libDir);
    }
    for (var e in library.enums.where((e) => e.isPublic)) {
      _renderContainerFile(e, libDir);
    }
    for (var m in library.mixins.where((m) => m.isPublic)) {
      _renderContainerFile(m, libDir);
    }
    for (var ext in library.extensions.where((e) => e.isPublic)) {
      _renderContainerFile(ext, libDir);
    }
    for (var et in library.extensionTypes.where((e) => e.isPublic)) {
      _renderContainerFile(et, libDir);
    }

    // Top-level functions
    var functionsContent = renderTopLevelFunctions(library, _options);
    if (functionsContent.isNotEmpty) {
      _writeFile(
        p.join(libDir, 'top-level-functions', 'top-level-functions.md'),
        functionsContent,
      );
      _renderDetailPagesForFunctions(library, libDir);
    }

    // Top-level properties
    var propertiesContent = renderTopLevelProperties(library);
    if (propertiesContent.isNotEmpty) {
      _writeFile(
        p.join(libDir, 'top-level-properties', 'top-level-properties.md'),
        propertiesContent,
      );
    }

    // Typedefs
    var typedefsContent = renderTypedefs(library);
    if (typedefsContent.isNotEmpty) {
      _writeFile(p.join(libDir, 'typedefs', 'typedefs.md'), typedefsContent);
    }
  }

  void _renderContainerFile(Container container, String libDir) {
    var content = renderContainer(container, _options);
    _writeFile(p.join(libDir, container.name, '${container.name}.md'), content);

    // Create detail pages for members with large source
    _renderDetailPagesForContainer(container, libDir);
  }

  void _renderDetailPagesForContainer(Container container, String libDir) {
    var detailDir = p.join(libDir, container.name);

    // Constructors
    if (container is Constructable) {
      for (var ctor in container.publicConstructorsSorted) {
        if (needsDetailPage(ctor, _options)) {
          var content = renderDetailPage(ctor, container.name, _options);
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
        var content = renderDetailPage(method, container.name, _options);
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
        var content = renderDetailPage(method, container.name, _options);
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
        var content = renderDetailPage(op, container.name, _options);
        _writeFile(
          p.join(detailDir, '${container.name}-$safeName.md'),
          content,
        );
      }
    }
  }

  void _renderDetailPagesForFunctions(Library library, String libDir) {
    var detailDir = p.join(libDir, 'top-level-functions');
    for (var func in library.functions.where((f) => f.isPublic)) {
      if (needsDetailPage(func, _options)) {
        var content = renderDetailPage(func, library.name, _options);
        _writeFile(p.join(detailDir, '${func.name}.md'), content);
      }
    }
  }

  void _renderCategories(Package package) {
    if (!package.hasDocumentedCategories) return;

    for (var category in package.documentedCategoriesSorted) {
      var content = renderCategory(category);
      _writeFile(p.join('topics', _topicFileName(category)), content);
    }
  }

  String _topicFileName(Category category) {
    final docFile = category.documentationFile;
    if (docFile != null) return p.basename(docFile.path);
    return '${category.name.replaceAll(RegExp(r'\s+'), '_')}.md';
  }

  void _writeElementList(
    StringBuffer buffer,
    String heading,
    List<ModelElement> elements,
    String libDir,
    String libraryName,
  ) {
    if (elements.isEmpty) return;

    buffer.writeln('### $heading from $libraryName');
    buffer.writeln();
    for (var element in elements) {
      var summary = extractSummary(element.documentation);
      var desc = summary.isNotEmpty ? ' — $summary' : '';
      buffer.writeln(
        '- [${element.name}]($libDir/${element.name}/${element.name}.md)$desc',
      );
    }
    buffer.writeln();
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
