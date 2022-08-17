import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/model/encoded_transaction.dart';
import 'package:sprocd/src/model/metadata_header.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:sprocd/src/server/server.dart';
import 'package:test/test.dart';

void main() {
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
      expect(server.start(), throwsStateError);
      await server.stop();
    });

    test('Stop server when it is already dead', () {
      final inputQ = InputQ(serverInputDir);
      final server = Server(
        port: 5555,
        inputQ: inputQ,
        outputDir: serverOutputDir,
      );

      expect(server.stop(), throwsStateError);
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

      File(join(serverInputDir.path, 'dummyInput'))
        ..createSync()
        ..writeAsStringSync('hello world');

      await server.start();

      // Server will provide dummy client with bytes.
      final dummyClient = await Socket.connect('localhost', 5555);
      final dummyClientData = await dummyClient.first;
      final dummyClientTransaction =
      EncodedTransaction.fromBytes(dummyClientData);

      // Ensure the server sent the correct data.
      final dummyInputWorkingFile =
      File(join(serverInputDir.path, 'dummyInput.working'));
      expect(
        dummyClientTransaction.data,
        await dummyInputWorkingFile.readAsBytes(),
      );

      // Simulate processing, reply back with output bytes.
      final transaction = EncodedTransaction(
        [1, 2, 3, 4, 5],
        header: MetadataHeader(
          id: 0,
          initTime: DateTime.now(),
        ).toString(),
      );
      dummyClient.add(transaction.toBytes());
      await dummyClient.flush();
      await dummyClient.close();

      await server.stop();

      // Ensure server received the new data.
      final outputFile = File(join(serverOutputDir.path, 'dummyInput.out'));
      expect(outputFile.existsSync(), true);

      // Ensure the output is what we expect from the processed client data.
      expect(await outputFile.readAsBytes(), [1, 2, 3, 4, 5]);
    });

    test('Three inputs and three clients', () async {
      final inputQ = InputQ(serverInputDir);
      final server = Server(
        port: 5555,
        inputQ: inputQ,
        outputDir: serverOutputDir,
      );

      // Create several input files.
      for (var i = 0; i < 3; i++) {
        File(join(serverInputDir.path, 'dummyInput$i'))
          ..createSync()
          ..writeAsStringSync('hello world $i');
      }

      await server.start();

      // Create equally as many clients as there are input files.
      for (var i = 0; i < 3; i++) {
        // Server will provide dummy client with bytes.
        final dummyClient = await Socket.connect('localhost', 5555);
        final dummyClientData = await dummyClient.first;
        final dummyClientTransaction =
        EncodedTransaction.fromBytes(dummyClientData);

        // Ensure the server sent the correct data.
        final dummyInputWorkingFile =
        File(join(serverInputDir.path, 'dummyInput$i.working'));
        expect(
          dummyClientTransaction.data,
          await dummyInputWorkingFile.readAsBytes(),
        );

        // Simulate processing, reply back with output bytes.
        final transaction = EncodedTransaction(
          [1, 2, 3, 4, 5, i],
          header: MetadataHeader(
            id: i,
            initTime: DateTime.now(),
          ).toString(),
        );
        dummyClient.add(transaction.toBytes());
        await dummyClient.flush();
        await dummyClient.close();
      }

      await server.stop();

      // Ensure server received the new data.
      for (var i = 0; i < 3; i++) {
        final outputFile = File(join(serverOutputDir.path, 'dummyInput$i.out'));
        expect(outputFile.existsSync(), true);

        // Ensure the output is what we expect from the processed client data.
        expect(await outputFile.readAsBytes(), [1, 2, 3, 4, 5, i]);
      }
    });
  });
}
