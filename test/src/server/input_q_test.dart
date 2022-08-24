import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:test/test.dart';

void main() {
  group('InputQ', () {
    final tempDir = Directory.systemTemp.createTempSync();

    tearDown(
      () => tempDir.listSync().forEach((element) {
        element.deleteSync(recursive: true);
      }),
    );
    tearDownAll(() => tempDir.deleteSync(recursive: true));

    final inputQ = InputQ(tempDir);

    test('Automatic scan', () async {
      final test1 = File(join(tempDir.path, 'test1'));
      await test1.create();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final test2 = File(join(tempDir.path, 'test2'));
      await test2.create();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return inputQ.numberOfInputs != 2;
      });

      expect(inputQ.numberOfInputs, 2);
      expect(
        (await inputQ.pop())!.path,
        '${test1.path}${InputQ.workingFileSuffix}',
      );

      expect(inputQ.numberOfInputs, 1);
      expect(
        (await inputQ.pop())!.path,
        '${test2.path}${InputQ.workingFileSuffix}',
      );

      expect(inputQ.numberOfInputs, 0);
    });

    test('Insert some demo files with difference in modify times', () async {
      final first = File(join(tempDir.path, 'first'));
      await first.create();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final second = File(join(tempDir.path, 'second'));
      await second.create();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final third = File(join(tempDir.path, 'third'));
      await third.create();

      await inputQ.scan();

      expect(inputQ.numberOfInputs, 3);
      expect(
        (await inputQ.pop())!.path,
        '${first.path}${InputQ.workingFileSuffix}',
      );

      expect(inputQ.numberOfInputs, 2);
      expect(
        (await inputQ.pop())!.path,
        '${second.path}${InputQ.workingFileSuffix}',
      );

      expect(inputQ.numberOfInputs, 1);
      expect(
        (await inputQ.pop())!.path,
        '${third.path}${InputQ.workingFileSuffix}',
      );

      expect(inputQ.numberOfInputs, 0);
    });

    test('Insert some demo files with same modify times', () async {
      final forceTime = DateTime.now();

      final b = File(join(tempDir.path, 'b'));
      await b.create();
      await b.setLastModified(forceTime);
      final c = File(join(tempDir.path, 'c'));
      await c.create();
      await c.setLastModified(forceTime);
      final a = File(join(tempDir.path, 'a'));
      await a.create();
      await a.setLastModified(forceTime);

      await inputQ.scan();

      expect(inputQ.numberOfInputs, 3);
      expect(
        (await inputQ.pop())!.path,
        '${a.path}${InputQ.workingFileSuffix}',
      );

      expect(inputQ.numberOfInputs, 2);
      expect(
        (await inputQ.pop())!.path,
        '${b.path}${InputQ.workingFileSuffix}',
      );

      expect(inputQ.numberOfInputs, 1);
      expect(
        (await inputQ.pop())!.path,
        '${c.path}${InputQ.workingFileSuffix}',
      );

      expect(inputQ.numberOfInputs, 0);
    });

    test('File to working file', () {
      const dummyPath = '/dummy/file';
      final dummyFile = File(dummyPath);
      final workingFile = inputQ.toWorkingFile(dummyFile);
      expect(workingFile.path, dummyPath + InputQ.workingFileSuffix);
    });

    test('Working file to file', () {
      const dummyPath = '/dummy/file';
      const dummyWorkingPath = dummyPath + InputQ.workingFileSuffix;
      final dummyWorkingFile = File(dummyWorkingPath);
      final file = inputQ.toUnWorkingFile(dummyWorkingFile);
      expect(file.path, dummyPath);
    });
  });
}
