import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:test/test.dart';

void main() {
  final tempDir = Directory.systemTemp.createTempSync();

  setUp(tempDir.createSync);
  tearDown(
    () => tempDir.listSync().forEach((element) {
      element.deleteSync(recursive: true);
    }),
  );

  group('InputQ', () {
    final inputQ = InputQ(tempDir);

    test('Automatic scan', () async {
      final test1 = File(join(tempDir.path, 'test1'))..createSync();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final test2 = File(join(tempDir.path, 'test2'))..createSync();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return inputQ.numberOfInputs != 2;
      });

      expect(inputQ.numberOfInputs, 2);
      expect((await inputQ.pop())!.path, '${test1.path}.working');

      expect(inputQ.numberOfInputs, 1);
      expect((await inputQ.pop())!.path, '${test2.path}.working');

      expect(inputQ.numberOfInputs, 0);
    });

    test('Insert some demo files with difference in modify times', () async {
      final first = File(join(tempDir.path, 'first'))..createSync();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final second = File(join(tempDir.path, 'second'))..createSync();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final third = File(join(tempDir.path, 'third'))..createSync();

      await inputQ.scan();

      expect(inputQ.numberOfInputs, 3);
      expect((await inputQ.pop())!.path, '${first.path}.working');

      expect(inputQ.numberOfInputs, 2);
      expect((await inputQ.pop())!.path, '${second.path}.working');

      expect(inputQ.numberOfInputs, 1);
      expect((await inputQ.pop())!.path, '${third.path}.working');

      expect(inputQ.numberOfInputs, 0);
    });

    test('Insert some demo files with same modify times', () async {
      final forceTime = DateTime.now();

      final b = File(join(tempDir.path, 'b'))
        ..createSync()
        ..setLastModifiedSync(forceTime);
      final c = File(join(tempDir.path, 'c'))
        ..createSync()
        ..setLastModifiedSync(forceTime);
      final a = File(join(tempDir.path, 'a'))
        ..createSync()
        ..setLastModifiedSync(forceTime);

      await inputQ.scan();

      expect(inputQ.numberOfInputs, 3);
      expect((await inputQ.pop())!.path, '${a.path}.working');

      expect(inputQ.numberOfInputs, 2);
      expect((await inputQ.pop())!.path, '${b.path}.working');

      expect(inputQ.numberOfInputs, 1);
      expect((await inputQ.pop())!.path, '${c.path}.working');

      expect(inputQ.numberOfInputs, 0);
    });
  });
}
