import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/client/client.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:sprocd/src/server/server.dart';
import 'package:test/test.dart';

void main() {
  final tempDir = Directory.systemTemp.createTempSync();

  setUpAll(tempDir.createSync);
  tearDownAll(() => tempDir.deleteSync(recursive: true));

  group('Client and server file transfer', () {
    final inputQ = InputQ(tempDir);
    final server = Server(port: 1234, inputQ: inputQ);
    final client = Client(host: 'localhost', port: 1234);

    test('Initialize', () async {
      await server.start();
      await client.connect();
    });

    test('Send demo file', () async {
      final demoFile = File(join(tempDir.path, 'demo'))
        ..createSync()
        ..writeAsStringSync('hello world 12345');

      await client.sendFile(demoFile);

      demoFile.deleteSync();
    });

    test('Send large demo file', () async {
      final demoFile = File(join(tempDir.path, 'demo'))..createSync();
      List.generate(
        100000,
        (_) => demoFile.writeAsStringSync('Hello world', mode: FileMode.append),
      );

      await client.sendFile(demoFile);
    });
  });
}
