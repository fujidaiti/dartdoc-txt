import 'package:pub_semver/pub_semver.dart';

enum ResolutionStrategy {
  exact,
  loosePatch,
  looseMinor;

  @override
  String toString() => switch (this) {
    exact => 'exact',
    loosePatch => 'loose-patch',
    looseMinor => 'loose-minor',
  };
}

extension VersionDocResolution on Version {
  /// Returns the documentation version string for the given strategy.
  ///
  /// - `exact`: `"1.2.3"`
  /// - `loosePatch`: `"1.2.x"`
  /// - `looseMinor`: `"1.x"`
  String docVersion(ResolutionStrategy strategy) => switch (strategy) {
    ResolutionStrategy.exact => '$major.$minor.$patch',
    ResolutionStrategy.loosePatch => '$major.$minor.x',
    ResolutionStrategy.looseMinor => '$major.x',
  };
}
