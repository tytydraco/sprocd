import 'dart:io';

import 'package:path/path.dart';
import 'package:stdlog/stdlog.dart';

/// Process a file into some output.
class Blackbox {
  /// Creates a new [Blackbox] given a [file].
  Blackbox(this.file);

  /// The input file to work on.
  final File file;

  /// Process the input [file] into some output.
  File process() {
    debug('blackbox: processing input file');
    // TODO(tytydraco): actual file processing.
    final outFile = File(join(Directory.systemTemp.path, 'exOut'))
      ..createSync()
      ..writeAsStringSync('Here is an output');
    debug('blackbox: done');
    return outFile;
  }
}
