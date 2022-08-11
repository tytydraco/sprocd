import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart';

/// A queue of input files that can be scanned for and popped.
class InputQ {
  /// Creates a new [InputQ] given an [inputDir].
  InputQ(this.inputDir);

  /// The directory housing the input files.
  final Directory inputDir;

  /// The list of input files.
  late final _inputs = SplayTreeSet<File>(_inputsCompare);

  /// Sort the input set based on file access time. Otherwise, compare based on
  /// file name.
  int _inputsCompare(File a, File b) {
    final aChanged = a.statSync().changed;
    final bChanged = b.statSync().changed;

    if (aChanged != bChanged) return aChanged.compareTo(bChanged);

    final aName = basenameWithoutExtension(a.path);
    final bName = basenameWithoutExtension(b.path);

    return aName.compareTo(bName);
  }

  /// The number of the input files.
  int get size => _inputs.length;

  /// Scan for new files in the [inputDir] and update the input list.
  void scan() {
    _inputs.clear();
    for (final entity in inputDir.listSync()) {
      if (entity is File) _inputs.add(entity);
    }
  }

  /// Returns the next input to be used in the set.
  File pop() {
    final file = _inputs.first;
    _inputs.remove(file);
    return file;
  }
}
