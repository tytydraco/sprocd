import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:test/test.dart';

void main() {
  final tempDir = Directory.systemTemp.createTempSync();

  group('InputQ', () {
    final inputQ = InputQ(tempDir);

    setUp(tempDir.createSync);
    setUp(inputQ.clear);
    tearDown(() => tempDir.deleteSync(recursive: true));

    test('Insert some demo files with difference in modify times', () async {
      final first = File(join(tempDir.path, 'first'))..createSync();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final second = File(join(tempDir.path, 'second'))..createSync();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final third = File(join(tempDir.path, 'third'))..createSync();

      inputQ.scan();

      expect(inputQ.numberOfInputs, 3);
      expect(inputQ.numberOfWorking, 0);

      expect(inputQ.pop().path, first.path);
      expect(inputQ.pop().path, second.path);
      expect(inputQ.pop().path, third.path);

      expect(inputQ.numberOfInputs, 0);
      expect(inputQ.numberOfWorking, 3);
    });

    test('Insert some demo files with same modify times', () async {
      final b = File(join(tempDir.path, 'b'))..createSync();
      final c = File(join(tempDir.path, 'c'))..createSync();
      final a = File(join(tempDir.path, 'a'))..createSync();

      inputQ.scan();

      expect(inputQ.numberOfInputs, 3);
      expect(inputQ.numberOfWorking, 0);

      expect(inputQ.pop().path, a.path);
      expect(inputQ.pop().path, b.path);
      expect(inputQ.pop().path, c.path);

      expect(inputQ.numberOfInputs, 0);
      expect(inputQ.numberOfWorking, 3);
    });
  });
}
