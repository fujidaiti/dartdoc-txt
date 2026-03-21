import 'package:dartdoc_txt/src/template/_category_section.mustache.dart';
import 'package:dartdoc_txt/src/template/_constructor.mustache.dart';
import 'package:dartdoc_txt/src/template/_element_list.mustache.dart';
import 'package:dartdoc_txt/src/template/_field.mustache.dart';
import 'package:dartdoc_txt/src/template/_library_section.mustache.dart';
import 'package:dartdoc_txt/src/template/_method.mustache.dart';
import 'package:dartdoc_txt/src/template/_operator.mustache.dart';
import 'package:dartdoc_txt/src/template/category.mustache.dart';
import 'package:dartdoc_txt/src/template/container.mustache.dart';
import 'package:dartdoc_txt/src/template/detail_page.mustache.dart';
import 'package:dartdoc_txt/src/template/index.mustache.dart';
import 'package:dartdoc_txt/src/template/top_level_functions.mustache.dart';
import 'package:dartdoc_txt/src/template/top_level_properties.mustache.dart';
import 'package:dartdoc_txt/src/template/typedefs.mustache.dart';
import 'package:mustache_template/mustache_template.dart';

/// Holds parsed Mustache [Template] objects, keyed by name.
class Templates {
  Templates._() : _cache = {} {
    Template? resolvePartial(String name) {
      return _cache['_$name'] ?? _cache[name];
    }

    _register('container', containerTemplate, resolvePartial);
    _register('index', indexTemplate, resolvePartial);
    _register('top_level_functions', topLevelFunctionsTemplate, resolvePartial);
    _register(
      'top_level_properties',
      topLevelPropertiesTemplate,
      resolvePartial,
    );
    _register('detail_page', detailPageTemplate, resolvePartial);
    _register('category', categoryTemplate, resolvePartial);
    _register('typedefs', typedefsTemplate, resolvePartial);
    _register('_constructor', constructorTemplate, resolvePartial);
    _register('_field', fieldTemplate, resolvePartial);
    _register('_method', methodTemplate, resolvePartial);
    _register('_operator', operatorTemplate, resolvePartial);
    _register('_library_section', librarySectionTemplate, resolvePartial);
    _register('_element_list', elementListTemplate, resolvePartial);
    _register('_category_section', categorySectionTemplate, resolvePartial);
  }

  /// Returns a [Templates] instance with all templates loaded.
  factory Templates.load() => Templates._();
  final Map<String, Template> _cache;

  void _register(
    String name,
    String source,
    Template? Function(String) resolver,
  ) {
    _cache[name] = Template(
      source,
      name: '$name.mustache',
      htmlEscapeValues: false,
      partialResolver: resolver,
    );
  }

  /// Returns the template with the given [name].
  Template operator [](String name) {
    final template = _cache[name];
    if (template == null) {
      throw ArgumentError('No template named "$name"');
    }
    return template;
  }
}
