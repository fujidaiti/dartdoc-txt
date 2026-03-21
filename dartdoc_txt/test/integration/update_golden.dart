import 'dart:io';

import 'package:dartdoc_txt/dartdoc_txt.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final integrationDir = p.dirname(Platform.script.toFilePath());
  final fixtureDir = p.join(integrationDir, 'fixture');
  final goldenDir = p.join(integrationDir, 'golden');
  final submoduleDir = p.join(fixtureDir, 'dart-core');
  final pathPkgDir = p.join(submoduleDir, 'pkgs', 'path');
  final pathGoldenDir = p.join(goldenDir, 'path');
  final basicGoldenDir = p.join(goldenDir, 'basic');
  final basicFixtureDir = p.join(fixtureDir, 'basic');

  await _pubGet(basicFixtureDir);
  _cleanDir(basicGoldenDir);
  await generateDocs(
    outputDir: basicGoldenDir,
    options: RenderOptions(
      packageRoot: basicFixtureDir,
      fileExtension: 'md.expected',
    ),
  );

  _cleanDir(submoduleDir);
  await _initGitSubmodule();
  await _pubGet(pathPkgDir);
  _cleanDir(pathGoldenDir);
  await generateDocs(
    outputDir: pathGoldenDir,
    options: RenderOptions(
      packageRoot: pathPkgDir,
      fileExtension: 'md.expected',
    ),
  );
}

void _cleanDir(String path) {
  final dir = Directory(path);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
}

Future<void> _pubGet(String workingDirectory) {
  return _run(Platform.resolvedExecutable, [
    'pub',
    'get',
  ], workingDirectory: workingDirectory);
}

Future<void> _initGitSubmodule() {
  var repoRoot = Directory(p.dirname(Platform.script.toFilePath()));
  while (true) {
    if (Directory(p.join(repoRoot.path, '.git')).existsSync()) {
      break;
    }
    var parent = repoRoot.parent;
    if (parent.path != repoRoot.path) {
      repoRoot = parent;
    } else {
      throw StateError(
        'Reached filesystem root without finding .git directory.',
      );
    }
  }

  return _run('git', [
    'submodule',
    'update',
    '--init',
  ], workingDirectory: repoRoot.path);
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      '${result.stdout}${result.stderr}',
      result.exitCode,
    );
  }
}
