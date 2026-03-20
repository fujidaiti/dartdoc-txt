import 'package:pubdoc/src/get_command.dart';
import 'package:test/test.dart';

typedef _ConfigPackage = ({String name, String rootUri, String packageUri});
typedef _GraphPackage = ({String name, List<String> deps});

Map<String, dynamic> _buildPackageConfig(
  List<_ConfigPackage> packages, {
  int configVersion = 2,
  Map<String, dynamic> extra = const {},
}) {
  return {
    'configVersion': configVersion,
    ...extra,
    'packages': [
      for (final p in packages)
        {'name': p.name, 'rootUri': p.rootUri, 'packageUri': p.packageUri},
    ],
  };
}

Map<String, dynamic> _buildPackageGraph(
  List<_GraphPackage> packages, {
  int configVersion = 1,
}) {
  return {
    'configVersion': configVersion,
    'packages': [
      for (final p in packages) {'name': p.name, 'dependencies': p.deps},
    ],
  };
}

List<String> _packageNames(Map<String, dynamic> config) {
  return [
    for (final p in config['packages'] as List)
      (p as Map<String, dynamic>)['name'] as String,
  ];
}

void main() {
  group('buildPackageConfigFor', () {
    test('returns transitive closure, excludes unrelated packages', () {
      final packageConfig = _buildPackageConfig([
        (name: 'A', rootUri: '../a', packageUri: 'lib/'),
        (name: 'B', rootUri: '../b', packageUri: 'lib/'),
        (name: 'C', rootUri: '../c', packageUri: 'lib/'),
        (name: 'D', rootUri: '../d', packageUri: 'lib/'),
        (name: 'E', rootUri: '../e', packageUri: 'lib/'),
      ]);
      final packageGraph = _buildPackageGraph([
        (name: 'A', deps: ['B']),
        (name: 'B', deps: ['C', 'D']),
        (name: 'C', deps: ['D']),
        (name: 'D', deps: []),
        (name: 'E', deps: []),
      ]);

      final result = buildPackageConfigFor(
        package: 'A',
        projectPackageConfig: packageConfig,
        projectPackageGraph: packageGraph,
      );

      expect(_packageNames(result), containsAll(['A', 'B', 'C', 'D']));
      expect(_packageNames(result), isNot(contains('E')));
    });

    test('root with no deps keeps only the root package', () {
      final packageConfig = _buildPackageConfig([
        (name: 'root', rootUri: '../root', packageUri: 'lib/'),
        (name: 'other', rootUri: '../other', packageUri: 'lib/'),
      ]);
      final packageGraph = _buildPackageGraph([
        (name: 'root', deps: []),
        (name: 'other', deps: []),
      ]);

      final result = buildPackageConfigFor(
        package: 'root',
        projectPackageConfig: packageConfig,
        projectPackageGraph: packageGraph,
      );

      expect(_packageNames(result), ['root']);
    });

    test('preserves top-level fields', () {
      final packageConfig = _buildPackageConfig(
        [(name: 'foo', rootUri: '../foo', packageUri: 'lib/')],
        extra: {'generator': 'pub', 'generatorVersion': '3.0.0'},
      );
      final packageGraph = _buildPackageGraph([(name: 'foo', deps: [])]);

      final result = buildPackageConfigFor(
        package: 'foo',
        projectPackageConfig: packageConfig,
        projectPackageGraph: packageGraph,
      );

      expect(result['configVersion'], 2);
      expect(result['generator'], 'pub');
      expect(result['generatorVersion'], '3.0.0');
    });

    test('does not modify the original maps', () {
      final packageConfig = _buildPackageConfig([
        (name: 'A', rootUri: '../a', packageUri: 'lib/'),
        (name: 'B', rootUri: '../b', packageUri: 'lib/'),
      ]);
      final packageGraph = _buildPackageGraph([
        (name: 'A', deps: []),
        (name: 'B', deps: []),
      ]);

      buildPackageConfigFor(
        package: 'A',
        projectPackageConfig: packageConfig,
        projectPackageGraph: packageGraph,
      );

      expect(
        packageConfig,
        _buildPackageConfig([
          (name: 'A', rootUri: '../a', packageUri: 'lib/'),
          (name: 'B', rootUri: '../b', packageUri: 'lib/'),
        ]),
      );
    });
  });
}
