import 'package:mustache_template/mustache_template.dart';

import 'template/_category_section.mustache.dart';
import 'template/_constructor.mustache.dart';
import 'template/_element_list.mustache.dart';
import 'template/_field.mustache.dart';
import 'template/_library_section.mustache.dart';
import 'template/_method.mustache.dart';
import 'template/_operator.mustache.dart';
import 'template/category.mustache.dart';
import 'template/container.mustache.dart';
import 'template/detail_page.mustache.dart';
import 'template/index.mustache.dart';
import 'template/top_level_functions.mustache.dart';
import 'template/top_level_properties.mustache.dart';
import 'template/typedefs.mustache.dart';

/// Holds parsed Mustache [Template] objects, keyed by name.
class Templates {
  final Map<String, Template> _cache;

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
    var template = _cache[name];
    if (template == null) {
      throw ArgumentError('No template named "$name"');
    }
    return template;
  }
}
