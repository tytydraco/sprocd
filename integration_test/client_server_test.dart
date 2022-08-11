import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/client/client.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:sprocd/src/server/server.dart';
import 'package:test/test.dart';

void main() {
  final tempDir = Directory.systemTemp.createTempSync();

  tearDownAll(() => tempDir.deleteSync(recursive: true));

  test('Client and server file transfer', () async {
    final outputDir = Directory(join(tempDir.path, 'output'))..createSync();
    final demoFile = File(join(tempDir.path, 'demo'));

    final inputQ = InputQ(tempDir);
    final server = Server(
      port: 1234,
      inputQ: inputQ,
      outputDir: outputDir,
    );
    final client = Client(host: 'localhost', port: 1234);

    await expectLater(server.start(), completes);

    demoFile
      ..createSync()
      ..writeAsStringSync('hello world 12345');

    inputQ.scan();

    expect(inputQ.numberOfInputs, 1);
    expect(demoFile.existsSync(), true);

    await expectLater(client.connect(), completes);
    await Future<void>.delayed(const Duration(seconds: 1));

    expect(File(Client.inputFilePath).existsSync(), true);

    expect(demoFile.existsSync(), false);
    expect(File(join(outputDir.path, 'demo.out')).existsSync(), true);
  });
}
