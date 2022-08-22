import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:sprocd/src/server/server.dart';
import 'package:test/test.dart';

void main() {
  /// How many clients to create for the multi-client test.
  const multiClientCount = 10;

  group('Server', () {
    final tempDir = Directory.systemTemp.createTempSync();
    tearDownAll(() => tempDir.deleteSync(recursive: true));

    final serverInputDir = Directory(join(tempDir.path, 'input'))
      ..createSync();
    final serverOutputDir = Directory(join(tempDir.path, 'output'))
      ..createSync();

    // Delete all input and output files for each test.
    tearDown(() {
      for (final file in [
        ...serverInputDir.listSync(),
        ...serverOutputDir.listSync()
      ]) {
        file.deleteSync(recursive: true);
      }
    });

    test('Start server when it has already started', () async {
      final inputQ = InputQ(serverInputDir);
      final server = Server(
        port: 5555,
        inputQ: inputQ,
        outputDir: serverOutputDir,
      );

      await server.start();
      await expectLater(server.start(), throwsStateError);
      await server.stop();
    });

    test('Stop server when it is already dead', () async {
      final inputQ = InputQ(serverInputDir);
      final server = Server(
        port: 5555,
        inputQ: inputQ,
        outputDir: serverOutputDir,
      );

      await expectLater(server.stop(), throwsStateError);
    });

    test('No inputs', () async {
      final inputQ = InputQ(serverInputDir);
      final server = Server(
        port: 5555,
        inputQ: inputQ,
        outputDir: serverOutputDir,
      );

      await server.start();
      await Socket.connect('localhost', 5555);
      await server.stop();

      // Nothing should have been written out.
      expect(
        await serverOutputDir
            .list()
            .isEmpty,
        true,
      );
    });

    test('One input and one client', () async {
      final inputQ = InputQ(serverInputDir);
      final server = Server(
        port: 5555,
        inputQ: inputQ,
        outputDir: serverOutputDir,
      );

      final dummyInput = File(join(serverInputDir.path, 'dummyInput'));
      await dummyInput.create();
      await dummyInput.writeAsString('hello world');

      await server.start();

      // Server will provide dummy client with bytes.
      final dummyClient = await Socket.connect('localhost', 5555);
      await dummyClient.first;

      // Simulate processing, reply back with output bytes.
      await dummyClient.addStream(Stream.value([1, 2, 3, 4, 5]));
      await dummyClient.flush();
      await dummyClient.close();

      await server.stop();

      // Ensure server received the new data.
      final outputFile = File(join(serverOutputDir.path, 'dummyInput.out'));
      expect(outputFile.existsSync(), true);

      // Ensure the output is what we expect from the processed client data.
      expect(await outputFile.readAsBytes(), [1, 2, 3, 4, 5]);
    });

    test('Several inputs and clients', () async {
      final inputQ = InputQ(serverInputDir);
      final server = Server(
        port: 5555,
        inputQ: inputQ,
        outputDir: serverOutputDir,
      );

      // Create several input files.
      for (var i = 0; i < multiClientCount; i++) {
        final dummyInput = File(join(serverInputDir.path, 'dummyInput$i'));
        await dummyInput.create();
        await dummyInput.writeAsString('hello world $i');
      }

      await server.start();

      Future<void> createClients(int i) async {
        // Server will provide dummy client with bytes.
        final dummyClient = await Socket.connect('localhost', 5555);
        await dummyClient.first;

        // Simulate processing, reply back with output bytes.
        await dummyClient.addStream(Stream.value([1, 2, 3, 4, 5, i]));
        await dummyClient.flush();
        await dummyClient.close();
      }

      // Create equally as many clients as there are input files.
      for (var i = 0; i < multiClientCount; i++) {
        await createClients(i);
      }

      await server.stop();

      // Ensure server received the new data.
      for (var i = 0; i < multiClientCount; i++) {
        final outputFile = File(join(serverOutputDir.path, 'dummyInput$i.out'));
        expect(outputFile.existsSync(), true);

        // Ensure the output is what we expect from the processed client data.
        expect(await outputFile.readAsBytes(), [1, 2, 3, 4, 5, i]);
      }
    });
  });
}
