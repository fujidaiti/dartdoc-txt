import 'dart:io';

import 'package:path/path.dart' as p;

sealed class DocNode {
  String get name;
}

/// A document file that lazily renders its content.
abstract class DocFile extends DocNode {
  DocFile(this.name);
  @override
  final String name;

  /// Lazily renders the document content.
  String renderContent();
}

/// A directory node containing child [DocNode]s.
class DocDir extends DocNode {
  DocDir(this.name, [List<DocNode>? children]) : children = children ?? [];
  @override
  final String name;
  final List<DocNode> children;

  /// Finds a [DocFile] by slash-separated path (e.g. 'lib/MyClass/MyClass.md').
  DocFile? findFile(String path) {
    final parts = path.split('/');
    var current = this;
    for (var i = 0; i < parts.length - 1; i++) {
      final next = current.children
          .whereType<DocDir>()
          .where((d) => d.name == parts[i])
          .firstOrNull;
      if (next == null) {
        return null;
      }
      current = next;
    }
    return current.children
        .whereType<DocFile>()
        .where((f) => f.name == parts.last)
        .firstOrNull;
  }

  /// Finds a [DocDir] by slash-separated path (e.g. 'lib/MyClass').
  DocDir? findDir(String path) {
    final parts = path.split('/');
    var current = this;
    for (final part in parts) {
      final next = current.children
          .whereType<DocDir>()
          .where((d) => d.name == part)
          .firstOrNull;
      if (next == null) {
        return null;
      }
      current = next;
    }
    return current;
  }
}

/// Materializes a [DocDir] tree to actual files on disk.
void writeDocTree(DocDir root, String outputDir) {
  _writeNode(root, outputDir);
}

void _writeNode(DocNode node, String currentPath) {
  switch (node) {
    case DocFile():
      final file = File(p.join(currentPath, node.name));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(node.renderContent());
    case DocDir():
      final dirPath = node.name.isEmpty
          ? currentPath
          : p.join(currentPath, node.name);
      for (final child in node.children) {
        _writeNode(child, dirPath);
      }
  }
}
