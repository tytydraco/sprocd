import 'dart:io';

import 'package:io/io.dart';
import 'package:stdlog/stdlog.dart';

/// Process a file into some output.
class Blackbox {
  /// Creates a new [Blackbox] given a [command].
  Blackbox(this.command);

  /// The command to use to process the file. The input file path will be
  /// appended after it.
  final String command;

  late final _split = shellSplit(command);
  late final _exec = _split.first;
  late final _args = _split.sublist(1);

  /// Process the input [file] into some output.
  Future<File?> process(File file) async {
    debug('blackbox: processing input file');

    debug('blackbox: running command:  $_exec ${_args.join(' ')} ${file.path}');
    final process = await Process.run(
      _exec,
      [..._args, file.path],
      runInShell: true,
    );

    final exitCode = process.exitCode;
    if (exitCode != 0) {
      error('blackbox: processing finished with non-zero exit code');
      return null;
    }

    final output = process.stdout.toString().trim().split('\n').last;
    info('blackbox: processor gave output path: $output');

    final outFile = File(output);
    if (!outFile.existsSync()) {
      error('blackbox: output path does not exist: $output');
      return null;
    }

    debug('blackbox: done');
    return outFile;
  }
}
