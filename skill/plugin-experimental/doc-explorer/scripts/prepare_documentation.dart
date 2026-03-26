import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// Prepares documentation for the given package names by:
///
/// 1. Running `dart pub add` to ensure the packages are included in
///    project's dependencies and they are up-to-date.
/// 2. Running `pubdoc get` to retrieve the documentation.
/// 3. Checking each package for a missing `OVERVIEW.md` to determine whether
///    enrichment is needed.
/// 4. If enrichment is needed, cleaning stale `example/` and `EXAMPLES.md`
///    from the documentation directory, then copying `example/` from the
///    package source so the enrichment agent can use it without needing the
///    source path.
///
/// Usage:
/// ```shell
/// dart prepare_documentation.dart --project <path> <pkg1> <pkg2> ...
/// ```
///
/// Output JSON (success):
///
/// ```json
/// {
///   "packages": {
///     "dio": {
///       "documentation": "/path/to/doc/dir",
///       "needsEnrichment": true
///     }
///   },
///   "error": null
/// }
/// ```
///
/// Output JSON (failure):
///
/// ```json
/// {
///   "packages": {},
///   "error": "<message>"
/// }
/// ```
///
/// Always exits with code 0; errors are reported in the JSON.
void main(List<String> args) {
  String? projectPath;
  final packages = <String>[];

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--project') {
      if (i + 1 >= args.length) {
        _exitWithError('--project requires a path argument');
      }
      projectPath = args[++i];
    } else {
      packages.add(args[i]);
    }
  }

  if (packages.isEmpty) {
    _exitWithError('No package names provided');
  } else if (projectPath == null) {
    _exitWithError('Project path not provided. Use --project <path>');
  }

  _ensurePubdocAvailable();
  final dartExecutable = File(Platform.resolvedExecutable);
  // TODO: Do this only if the packages aren't already included
  // in package_config.json.
  _pubAdd(dartExecutable, packages, projectPath);
  final pubdocJson = _pubdocGet(dartExecutable, packages, projectPath);

  // Check for errors in pubdoc output
  final errors = pubdocJson['errors'];
  if (errors is List && errors.isNotEmpty) {
    _exitWithError('pubdoc reported errors: ${errors.join(', ')}');
  }

  final output = pubdocJson['output'] as Map<String, dynamic>?;
  final pkgMap =
      (output?['packages'] as Map<String, dynamic>?) ?? <String, dynamic>{};

  final resultPackages = <String, Map<String, dynamic>>{};

  for (final entry in pkgMap.entries) {
    final pkgName = entry.key;
    final pkgData = entry.value as Map<String, dynamic>;
    final documentation = pkgData['documentation'] as String?;
    final source = pkgData['source'] as String?;

    if (documentation == null) {
      _exitWithError('Missing "documentation" for package $pkgName');
    }

    final overviewFile = File('$documentation/OVERVIEW.md');
    final needsEnrichment = !overviewFile.existsSync();

    if (needsEnrichment) {
      // Pre-stage example/ directory for the enrichment agent
      final docExampleDir = Directory('$documentation/example');
      final docExamplesFile = File('$documentation/EXAMPLES.md');

      // Clean up stale artifacts
      if (docExampleDir.existsSync()) {
        docExampleDir.deleteSync(recursive: true);
      }
      if (docExamplesFile.existsSync()) {
        docExamplesFile.deleteSync();
      }

      if (source != null) {
        // Copy source README.md as fallback if documentation dir lacks one
        final docReadme = File('$documentation/README.md');
        if (!docReadme.existsSync()) {
          final srcReadme = File('$source/README.md');
          if (srcReadme.existsSync()) {
            srcReadme.copySync(docReadme.path);
          }
        }

        // Copy source example/ if it exists
        final srcExampleDir = Directory('$source/example');
        if (srcExampleDir.existsSync()) {
          _copyDirectory(srcExampleDir, docExampleDir);
        }
      }
    }

    resultPackages[pkgName] = {
      'documentation': documentation,
      'needsEnrichment': needsEnrichment,
    };
  }

  stdout.writeln(jsonEncode({'packages': resultPackages, 'error': null}));
}

void _ensurePubdocAvailable() {
  bool available;
  try {
    available = Process.runSync('pubdoc', ['--version']).exitCode == 0;
  } on ProcessException {
    available = false;
  }
  if (!available) {
    _exitWithError('pubdoc does not exist or is not found in PATH.');
  }
}

void _pubAdd(File dartExecutable, List<String> packages, String? projectPath) {
  final result = Process.runSync(dartExecutable.path, [
    'pub',
    'add',
    ...packages,
  ], workingDirectory: projectPath);

  if (result.exitCode != 0) {
    if (packages.length == 1) {
      _exitWithError(
        'The specified package ${packages.single} was not found in pub.dev, '
        'or the package name is incorrect.',
      );
    } else {
      _exitWithError(
        'Some of the specified packages were not found in pub.dev, '
        'or the package names are incorrect.',
      );
    }
  }
}

Map<String, dynamic> _pubdocGet(
  File dartExecutable,
  List<String> packages,
  String? projectPath,
) {
  final dartSdkDir = dartExecutable.parent.parent;
  if (!dartSdkDir.existsSync()) {
    _exitWithError('Dart SDK directory not found at ${dartSdkDir.path}');
  }

  final result = Process.runSync('pubdoc', [
    'get',
    '--json=0',
    '--quiet',
    '--sdk-dir=${dartSdkDir.path}',
    if (projectPath != null) ...['--project', projectPath],
    ...packages,
  ]);

  try {
    return jsonDecode(result.stdout as String) as Map<String, dynamic>;
  } on FormatException {
    _exitWithError('Failed to parse pubdoc JSON output: ${result.stdout}');
  }
}

Never _exitWithError(String message) {
  stdout.writeln(
    jsonEncode({'packages': <String, dynamic>{}, 'error': message}),
  );
  exit(0);
}

void _copyDirectory(Directory src, Directory dst) {
  final queue = Queue<(Directory, Directory)>()..add((src, dst));
  while (queue.isNotEmpty) {
    final (s, d) = queue.removeFirst();
    d.createSync();
    for (final entity in s.listSync(recursive: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;
      if (entity is Directory) {
        queue.add((entity, Directory('${d.path}/$name')));
      } else if (entity is File) {
        entity.copySync('${d.path}/$name');
      }
    }
  }
}
