import 'package:pub_semver/pub_semver.dart';
import 'package:pubdoc/src/version_resolution.dart';
import 'package:test/test.dart';

void main() {
  group('Version.docVersion', () {
    test('exact returns full version', () {
      expect(
        Version.parse('4.5.3').docVersion(ResolutionStrategy.exact),
        '4.5.3',
      );
    });

    test('loosePatch returns major.minor.x', () {
      expect(
        Version.parse('4.5.3').docVersion(ResolutionStrategy.loosePatch),
        '4.5.x',
      );
    });

    test('looseMinor returns major.x', () {
      expect(
        Version.parse('4.5.3').docVersion(ResolutionStrategy.looseMinor),
        '4.x',
      );
    });
  });

  group('Pre-release versions', () {
    test('exact returns full version string', () {
      expect(
        Version.parse('1.0.0-dev.1').docVersion(ResolutionStrategy.exact),
        '1.0.0-dev.1',
      );
    });

    test('loosePatch returns full version string', () {
      expect(
        Version.parse('1.0.0-dev.1').docVersion(ResolutionStrategy.loosePatch),
        '1.0.0-dev.1',
      );
    });

    test('looseMinor returns full version string', () {
      expect(
        Version.parse('1.0.0-dev.1').docVersion(ResolutionStrategy.looseMinor),
        '1.0.0-dev.1',
      );
    });
  });
}
