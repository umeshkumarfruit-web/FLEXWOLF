import 'dart:io';

bool isTrackedByGit(String path) {
  final result = Process.runSync('git', ['ls-files', '--cached', '--', path]);
  if (result.exitCode != 0) {
    throw StateError('Could not inspect the Git index: ${result.stderr}');
  }
  return (result.stdout as String).trim().isNotEmpty;
}
