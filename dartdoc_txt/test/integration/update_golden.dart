import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'test_helper.dart';

Future<void> main() async {
  // Suppress logging from dartdoc.
  hierarchicalLoggingEnabled = true;
  Logger('dartdoc').level = Level.OFF;

  var packageRoot = Directory.current.path;
  var goldenTestDir = p.join(packageRoot, 'test', 'integration');

  // Ensure the dart-core submodule is initialized.
  print('Initializing dart-core submodule...');
  var repoRoot = _findRepoRoot(packageRoot);
  var submodulePath = p.relative(
    p.join(goldenTestDir, 'fixture', 'dart-core'),
    from: repoRoot,
  );
  var submoduleResult = await Process.run(
    'git',
    ['submodule', 'update', '--init', submodulePath],
    workingDirectory: repoRoot,
  );
  if (submoduleResult.exitCode != 0) {
    stderr.writeln('Failed to initialize submodule:');
    stderr.writeln(submoduleResult.stderr);
    exit(1);
  }

  // Run pub get in path fixture.
  var pathFixturePath = p.join(
    goldenTestDir,
    'fixture',
    'dart-core',
    'pkgs',
    'path',
  );
  print('Running pub get in path fixture...');
  var pubGetResult = await Process.run(
    'fvm',
    ['dart', 'pub', 'get'],
    workingDirectory: pathFixturePath,
  );
  if (pubGetResult.exitCode != 0) {
    stderr.writeln('Failed to run pub get in path fixture:');
    stderr.writeln(pubGetResult.stderr);
    exit(1);
  }

  var fixtures = {
    'basic': p.join(goldenTestDir, 'fixture', 'basic'),
    'path': pathFixturePath,
  };

  var totalFiles = 0;

  for (var entry in fixtures.entries) {
    var name = entry.key;
    var fixturePath = entry.value;
    var goldensDir = p.join(goldenTestDir, 'golden', name);

    print('Rendering $name fixture...');
    var docTree = await renderFixture(fixturePath);
    var files = collectFiles(docTree);

    // Delete old golden dir and recreate.
    var dir = Directory(goldensDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }

    for (var fileEntry in files.entries) {
      var goldenFile = File(p.join(goldensDir, '${fileEntry.key}.expect'));
      goldenFile.parent.createSync(recursive: true);
      goldenFile.writeAsStringSync(fileEntry.value);
    }

    print('  Wrote ${files.length} golden files for $name.');
    totalFiles += files.length;
  }

  print('Done. $totalFiles golden files written in total.');
}

/// Walks up from [start] to find the repo root (directory containing .git).
String _findRepoRoot(String start) {
  var dir = Directory(start);
  while (true) {
    if (Directory(p.join(dir.path, '.git')).existsSync() ||
        File(p.join(dir.path, '.git')).existsSync()) {
      return dir.path;
    }
    var parent = dir.parent;
    if (parent.path == dir.path) {
      // Fallback: return start if we can't find .git.
      return start;
    }
    dir = parent;
  }
}
