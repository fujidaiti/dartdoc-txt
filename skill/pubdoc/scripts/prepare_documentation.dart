import 'dart:convert';
import 'dart:io';

/// Prepares documentation for the given package names by:
///
/// 1. Running `dart pub get` to ensure dependencies are up-to-date.
/// 2. Running `pubdoc get` to generate documentation (if needed).
/// 3. Checking each package for a missing `OVERVIEW.md` to determine whether
///    enrichment is needed.
/// 4. If enrichment is needed, cleaning stale `example/` and `EXAMPLES.md`
///    from the documentation directory, then copying `example/` from the
///    package source so the enrichment agent can use it without needing the
///    source path.
///
/// Usage:
/// ```shell
/// dart prepare_documentation.dart [--project <path>] <pkg1> <pkg2> ...
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
void main(List<String> args) async {
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
  }

  final dartExecutable = File(Platform.resolvedExecutable);
  final dartSdkDir = dartExecutable.parent.parent;
  if (!dartSdkDir.existsSync()) {
    _exitWithError('Dart SDK directory not found at ${dartSdkDir.path}');
  }

  try {
    Process.runSync('pubdoc', ['--version']);
  } on ProcessException {
    _exitWithError('pubdoc is not installed or not on PATH.');
  }

  try {
    await Process.run(dartExecutable.path, [
      'pub',
      'get',
    ], workingDirectory: projectPath);
  } on ProcessException catch (e) {
    _exitWithError('Failed to run "dart pub get": $e');
  }

  final ProcessResult result;
  try {
    result = await Process.run('pubdoc', [
      'get',
      '--json=0',
      '--quiet',
      '--sdk-dir=${dartSdkDir.path}',
      if (projectPath != null) ...['--project', projectPath],
      ...packages,
    ]);
  } on ProcessException catch (e) {
    _exitWithError('Failed to run "pubdoc get": $e');
  }

  if (result.exitCode != 0) {
    final stderr = (result.stderr as String).trim();
    _exitWithError('pubdoc exited with code ${result.exitCode}: $stderr');
  }

  // Parse JSON output
  Map<String, dynamic> pubdocJson;
  try {
    pubdocJson = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  } on FormatException catch (e) {
    _exitWithError('Failed to parse pubdoc JSON output: $e');
  }

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
          await _copyDirectory(srcExampleDir, docExampleDir);
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

Never _exitWithError(String message) {
  stdout.writeln(
    jsonEncode({'packages': <String, dynamic>{}, 'error': message}),
  );
  exit(0);
}

Future<void> _copyDirectory(Directory src, Directory dst) async {
  dst.createSync(recursive: true);
  await for (final entity in src.list(recursive: false)) {
    final name = entity.path.split(Platform.pathSeparator).last;
    if (entity is Directory) {
      await _copyDirectory(entity, Directory('${dst.path}/$name'));
    } else if (entity is File) {
      entity.copySync('${dst.path}/$name');
    }
  }
}
