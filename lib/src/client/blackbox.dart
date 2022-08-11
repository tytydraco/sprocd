import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart';
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
  Future<File> process(File file) async {
    debug('blackbox: processing input file');

    // TODO(tytydraco): get output as output file path, pass file back, check exists
    await Process.start(_exec, [..._args, file.path]);

    final outFile = File(join(Directory.systemTemp.path, 'exOut'))
      ..createSync()
      ..writeAsStringSync('Here is an output');

    debug('blackbox: done');
    return outFile;
  }
}
