import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart';
import 'package:stdlog/stdlog.dart';

/// A queue of input files that can be scanned for and popped.
class InputQ {
  /// Creates a new [InputQ] given an [inputDir].
  InputQ(this.inputDir) {
    _watchForNewInputs();
  }

  /// The directory housing the input files.
  final Directory inputDir;

  /// The list of input files sorted by modify time, and then by name.
  late final _inputs = SplayTreeSet<File>(_inputsCompare);

  /// Perform a scan whenever a file gets added.
  void _watchForNewInputs() {
    inputDir.watch(events: FileSystemEvent.create).listen((event) async {
      debug('input_q: new file added: ${event.path}');
      if (inputDir.existsSync()) await scan();
    });
  }

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

  /// Scan for new files in the [inputDir] and update the input list.
  /// Do not add any files that are already marked as working files.
  Future<void> scan() async {
    _inputs.clear();
    await for (final entity in inputDir.list()) {
      if (entity is File && !entity.path.endsWith('.working')) {
        debug('input_q: scanned ${entity.path}');
        _inputs.add(entity);
      }
    }

    debug('input_q: discovered ${_inputs.length} inputs');
  }

  /// Returns the next input to be used in the set. Remove it from being
  /// accessible in the set. Rename it to indicate that it is now a working
  /// file.
  Future<File?> pop() async {
    if (_inputs.isEmpty) {
      debug('input_q: pop requested but nothing to serve');
      return null;
    }

    final file = _inputs.first;
    _inputs.remove(file);

    debug('input_q: popped ${file.path}');

    final newName = '${basename(file.path)}.working';
    final newPath = join(file.parent.path, newName);
    await file.rename(newPath);

    debug('input_q: moved original to $newPath');

    return File(newPath);
  }
}
