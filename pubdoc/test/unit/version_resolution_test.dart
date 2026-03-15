import 'package:pub_semver/pub_semver.dart';
import 'package:pubdoc/src/version_resolution.dart';
import 'package:test/test.dart';

void main() {
  group('Version.docVersion', () {
    final v = Version.parse('4.5.3');

    test('exact returns full version', () {
      expect(v.docVersion(ResolutionStrategy.exact), '4.5.3');
    });

    test('loosePatch returns major.minor.x', () {
      expect(v.docVersion(ResolutionStrategy.loosePatch), '4.5.x');
    });

    test('looseMinor returns major.x', () {
      expect(v.docVersion(ResolutionStrategy.looseMinor), '4.x');
    });
  });
}
