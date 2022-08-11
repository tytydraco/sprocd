import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/client/client.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:sprocd/src/server/server.dart';
import 'package:test/test.dart';

void main() {
  final tempDir = Directory.systemTemp.createTempSync();
  final demoFile = File(join(tempDir.path, 'demo'));

  tearDownAll(() => tempDir.deleteSync(recursive: true));

  group('Client and server file transfer', () {
    final inputQ = InputQ(tempDir);
    final server = Server(port: 1234, inputQ: inputQ);
    final client = Client(host: 'localhost', port: 1234);

    test('Start the server', () async {
      await expectLater(server.start(), completes);
    });

    test('Create demo file in input queue', () {
      demoFile
        ..createSync()
        ..writeAsStringSync('hello world 12345');

      inputQ.scan();

      expect(inputQ.numberOfInputs, 1);
    });

    test('Connect the client', () async {
      await expectLater(client.connect(), completes);
    });
  });
}
