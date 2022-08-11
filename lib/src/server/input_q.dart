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

  /// The set of working files that are already being handled.
  final _working = <File>{};

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

  /// The number of input files.
  int get numberOfInputs => _inputs.length;

  /// The number of working files.
  int get numberOfWorking => _working.length;

  /// Clear all current lists of input and working files.
  void clear() {
    _inputs.clear();
    _working.clear();
  }

  /// Scan for new files in the [inputDir] and update the input list.
  /// Do not add any files that are already marked as working files.
  void scan() {
    for (final entity in inputDir.listSync()) {
      if (entity is File &&
          _working.where((file) => file.path == entity.path).isEmpty) {
        _inputs.add(entity);
      }
    }
  }

  /// Returns the next input to be used in the set. Remove it from being
  /// accessible in the set.
  File pop() {
    final file = _inputs.first;
    _inputs.remove(file);
    _working.add(file);
    return file;
  }
}
