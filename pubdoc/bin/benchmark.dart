// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class BenchmarkResult {
  const BenchmarkResult({
    required this.label,
    required this.iterations,
    required this.avgMicros,
    required this.minMicros,
  });

  final String label;
  final int iterations;
  final double avgMicros;
  final int minMicros;
}

// ---------------------------------------------------------------------------
// Benchmark runners
// ---------------------------------------------------------------------------

BenchmarkResult runSyncBenchmark(
  String label,
  void Function() body, {
  int warmup = 5,
  int iterations = 50,
}) {
  for (var i = 0; i < warmup; i++) {
    body();
  }
  final times = <int>[];
  final sw = Stopwatch();
  for (var i = 0; i < iterations; i++) {
    sw
      ..reset()
      ..start();
    body();
    sw.stop();
    times.add(sw.elapsedMicroseconds);
  }
  final total = times.fold(0, (a, b) => a + b);
  return BenchmarkResult(
    label: label,
    iterations: iterations,
    avgMicros: total / iterations,
    minMicros: times.reduce((a, b) => a < b ? a : b),
  );
}

Future<BenchmarkResult> runAsyncBenchmark(
  String label,
  Future<void> Function() body, {
  int warmup = 5,
  int iterations = 50,
}) async {
  for (var i = 0; i < warmup; i++) {
    await body();
  }
  final times = <int>[];
  final sw = Stopwatch();
  for (var i = 0; i < iterations; i++) {
    sw
      ..reset()
      ..start();
    await body();
    sw.stop();
    times.add(sw.elapsedMicroseconds);
  }
  final total = times.fold(0, (a, b) => a + b);
  return BenchmarkResult(
    label: label,
    iterations: iterations,
    avgMicros: total / iterations,
    minMicros: times.reduce((a, b) => a < b ? a : b),
  );
}

// ---------------------------------------------------------------------------
// Old (full-parse) implementations
// ---------------------------------------------------------------------------

Version oldGetPackageVersion(File pubspecLock, String packageName) {
  final content = pubspecLock.readAsStringSync();
  final yaml = loadYaml(content) as YamlMap;
  final packages = yaml['packages'] as YamlMap;
  final pkg = packages[packageName] as YamlMap?;
  if (pkg == null) {
    throw StateError("Package '$packageName' not found in pubspec.lock.");
  }
  return Version.parse(pkg['version'] as String);
}

Directory oldGetPackageSourceDir(File packageConfig, String packageName) {
  final content = packageConfig.readAsStringSync();
  final json = jsonDecode(content) as Map<String, dynamic>;
  final packages = json['packages'] as List<dynamic>;
  for (final entry in packages) {
    final map = entry as Map<String, dynamic>;
    if (map['name'] == packageName) {
      final uriStr = map['rootUri'] as String;
      final rootUri = Uri.parse(uriStr);
      final resolved =
          Uri.file('${packageConfig.parent.path}/').resolveUri(rootUri);
      return Directory(resolved.toFilePath());
    }
  }
  throw StateError("Package '$packageName' not found in package_config.json.");
}

// ---------------------------------------------------------------------------
// New (streaming) implementations
// ---------------------------------------------------------------------------

Future<Version> newGetPackageVersion(
  File pubspecLock,
  String packageName,
) async {
  final lines = pubspecLock
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  var inPackage = false;
  await for (final line in lines) {
    if (!inPackage) {
      if (line == '  $packageName:') {
        inPackage = true;
      }
    } else {
      if (line.startsWith('    version: ')) {
        final versionStr = line
            .substring('    version: '.length)
            .trim()
            .replaceAll('"', '');
        return Version.parse(versionStr);
      }
      // A new 2-space-indented key means we've left the package section.
      if (line.length >= 3 &&
          line[0] == ' ' &&
          line[1] == ' ' &&
          line[2] != ' ' &&
          line.trim().isNotEmpty) {
        break;
      }
    }
  }
  throw StateError("Package '$packageName' not found in pubspec.lock.");
}

Future<Directory> newGetPackageSourceDir(
  File packageConfig,
  String packageName,
) async {
  final lines = packageConfig
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  var inPackage = false;
  await for (final line in lines) {
    final trimmed = line.trim();
    if (!inPackage) {
      if (trimmed == '"name": "$packageName"' ||
          trimmed == '"name": "$packageName",') {
        inPackage = true;
      }
    } else {
      if (trimmed == '}' || trimmed == '},') {
        inPackage = false;
        continue;
      }
      if (trimmed.startsWith('"rootUri": "')) {
        final uriStr = trimmed
            .substring('"rootUri": "'.length)
            .replaceAll(RegExp(r'",?$'), '');
        final rootUri = Uri.parse(uriStr);
        final resolved =
            Uri.file('${packageConfig.parent.path}/').resolveUri(rootUri);
        return Directory(resolved.toFilePath());
      }
    }
  }
  throw StateError(
    "Package '$packageName' not found in package_config.json.",
  );
}

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

void printResults(
  String title,
  BenchmarkResult oldResult,
  BenchmarkResult newResult,
) {
  final speedup = oldResult.avgMicros / newResult.avgMicros;
  print('=== $title ===');
  print(
    '  ${'Method'.padRight(14)} ${'Iters'.padLeft(5)}  '
    '${'Avg (µs)'.padLeft(9)}   ${'Min (µs)'.padLeft(9)}   Speedup',
  );
  print('  ${''.padRight(14, '-')} ${''.padLeft(5, '-')}  '
      '${''.padLeft(9, '-')}   ${''.padLeft(9, '-')}   ${''.padLeft(7, '-')}');
  print(
    '  ${'old (sync)'.padRight(14)} ${oldResult.iterations.toString().padLeft(5)}  '
    '${oldResult.avgMicros.toStringAsFixed(1).padLeft(9)}   '
    '${oldResult.minMicros.toString().padLeft(9)}',
  );
  print(
    '  ${'new (stream)'.padRight(14)} ${newResult.iterations.toString().padLeft(5)}  '
    '${newResult.avgMicros.toStringAsFixed(1).padLeft(9)}   '
    '${newResult.minMicros.toString().padLeft(9)}   '
    'x${speedup.toStringAsFixed(2)}',
  );
  print('');
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  final scriptDir = File(Platform.script.toFilePath()).parent.path;

  final packageName = args.isNotEmpty ? args[0] : 'yaml';
  final pubspecLockPath =
      args.length >= 2 ? args[1] : '$scriptDir/pubspec.lock';
  final packageConfigPath =
      args.length >= 3 ? args[2] : '$scriptDir/package_config.json';

  final pubspecLock = File(pubspecLockPath);
  final packageConfig = File(packageConfigPath);

  // Validate files exist.
  if (!pubspecLock.existsSync()) {
    stderr.writeln('Error: pubspec.lock not found at $pubspecLockPath');
    stderr.writeln(
      'Tip: copy your project\'s pubspec.lock to pubdoc/bin/pubspec.lock',
    );
    exit(1);
  }
  if (!packageConfig.existsSync()) {
    stderr.writeln(
      'Error: package_config.json not found at $packageConfigPath',
    );
    stderr.writeln(
      'Tip: copy your project\'s .dart_tool/package_config.json '
      'to pubdoc/bin/package_config.json',
    );
    exit(1);
  }

  print('Benchmarking package: "$packageName"');
  print('  pubspec.lock:        $pubspecLockPath');
  print('  package_config.json: $packageConfigPath');
  print('');

  // Correctness checks before timing.
  try {
    oldGetPackageVersion(pubspecLock, packageName);
  } catch (e) {
    stderr.writeln('Correctness check failed (old getPackageVersion): $e');
    exit(1);
  }
  try {
    await newGetPackageVersion(pubspecLock, packageName);
  } catch (e) {
    stderr.writeln('Correctness check failed (new getPackageVersion): $e');
    exit(1);
  }
  try {
    oldGetPackageSourceDir(packageConfig, packageName);
  } catch (e) {
    stderr.writeln('Correctness check failed (old getPackageSourceDir): $e');
    exit(1);
  }
  try {
    await newGetPackageSourceDir(packageConfig, packageName);
  } catch (e) {
    stderr.writeln('Correctness check failed (new getPackageSourceDir): $e');
    exit(1);
  }

  // Run benchmarks: old first, then new (warmup primes cache equally).
  final oldVersionResult = runSyncBenchmark(
    'old (sync)',
    () => oldGetPackageVersion(pubspecLock, packageName),
  );
  final newVersionResult = await runAsyncBenchmark(
    'new (stream)',
    () => newGetPackageVersion(pubspecLock, packageName),
  );

  final oldSourceDirResult = runSyncBenchmark(
    'old (sync)',
    () => oldGetPackageSourceDir(packageConfig, packageName),
  );
  final newSourceDirResult = await runAsyncBenchmark(
    'new (stream)',
    () => newGetPackageSourceDir(packageConfig, packageName),
  );

  printResults('getPackageVersion', oldVersionResult, newVersionResult);
  printResults('getPackageSourceDir', oldSourceDirResult, newSourceDirResult);
}
