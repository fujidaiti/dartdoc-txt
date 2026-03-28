/// Unescapes HTML entities in source code.
///
/// dartdoc's model applies `HtmlEscape` to source code since it's intended
/// for HTML output. We need to reverse this for Markdown output.
String unescapeHtml(String text) {
  return text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&#x27;', "'")
      .replaceAll('&#x2F;', '/')
      .replaceAll('&#47;', '/');
}

/// Extracts the first paragraph from a documentation string.
String extractSummary(String? documentation) {
  if (documentation == null || documentation.isEmpty) {
    return '';
  }
  final paragraphs = documentation.split(RegExp(r'\n\s*\n'));
  for (final p in paragraphs) {
    final trimmed = p.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.replaceAll(RegExp(r'\s*\n\s*'), ' ');
    }
  }
  return '';
}

/// Strips residual HTML artifacts from documentation text.
///
/// Removes `<iframe>`, `<video>`, and `<dartdoc-html>` elements that are
/// injected by `{@youtube}`, `{@animation}`, and `{@inject-html}` directives.
String stripResidualHtml(String text) {
  var result = text;
  // Strip <iframe ...>...</iframe> (from {@youtube})
  result = result.replaceAll(
    RegExp('<iframe[^>]*>.*?</iframe>', dotAll: true),
    '',
  );
  // Strip <video ...>...</video> (from {@animation})
  result = result.replaceAll(
    RegExp('<video[^>]*>.*?</video>', dotAll: true),
    '',
  );
  // Strip <dartdoc-html>...</dartdoc-html> (from {@inject-html})
  result = result.replaceAll(
    RegExp('<dartdoc-html>.*?</dartdoc-html>', dotAll: true),
    '',
  );
  // Clean up extra blank lines left behind
  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return result.trim();
}

/// Counts the number of lines in source code text.
int sourceLineCount(String? sourceCode) {
  if (sourceCode == null || sourceCode.isEmpty) {
    return 0;
  }
  return sourceCode.split('\n').length;
}

/// Returns the short name for a constructor, suitable for file names.
///
/// Unnamed constructors (whose name equals the container) return `'new'`.
/// Named constructors like `MyClass.fromJson` return `'fromJson'`.
String ctorBaseName(String ctorName, String containerName) {
  if (ctorName == containerName) {
    return 'new';
  }
  return ctorName.substring(containerName.length + 1);
}

/// Makes a file-name-safe string from an element name.
///
/// Operators are converted to descriptive names.
String safeFileName(String name) {
  const operatorNames = {
    'operator ==': 'operator_equals',
    'operator +': 'operator_plus',
    'operator -': 'operator_minus',
    'operator *': 'operator_multiply',
    'operator /': 'operator_divide',
    'operator ~/': 'operator_truncate_divide',
    'operator %': 'operator_modulo',
    'operator <': 'operator_less',
    'operator >': 'operator_greater',
    'operator <=': 'operator_less_equal',
    'operator >=': 'operator_greater_equal',
    'operator &': 'operator_bitwise_and',
    'operator |': 'operator_bitwise_or',
    'operator ^': 'operator_bitwise_xor',
    'operator ~': 'operator_bitwise_negate',
    'operator <<': 'operator_shift_left',
    'operator >>': 'operator_shift_right',
    'operator >>>': 'operator_unsigned_shift_right',
    'operator []': 'operator_index',
    'operator []=': 'operator_index_assign',
    'operator unary-': 'operator_unary_minus',
  };

  return operatorNames[name] ?? name;
}
