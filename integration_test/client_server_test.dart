import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/client/client.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:sprocd/src/server/server.dart';
import 'package:test/test.dart';

void main() {
  group('Client and server integration', () {
    final tempDir = Directory.systemTemp.createTempSync();
    tearDownAll(() => tempDir.deleteSync(recursive: true));

    final serverInputDir = Directory(join(tempDir.path, 'input'))..createSync();
    final serverOutputDir = Directory(join(tempDir.path, 'output'))
      ..createSync();
    final serverInputFile = File(join(serverInputDir.path, 'input'));
    final serverOutputFile = File(join(serverOutputDir.path, 'input.out'));

    final clientOutputFile = File(join(tempDir.path, 'blackboxresult'));
    final clientScript = File(join(tempDir.path, 'process.sh'))
      ..createSync()
      ..writeAsStringSync(
        'touch ${clientOutputFile.path}; ' // Create output.
        'echo -n "output!" > ${clientOutputFile.path}; ' // Write output.
        'echo ${clientOutputFile.path}', // Echo output path.
      );

    final inputQ = InputQ(serverInputDir);
    final server = Server(
      port: 1234,
      inputQ: inputQ,
      outputDir: serverOutputDir,
    );
    final client = Client(
      host: 'localhost',
      port: 1234,
      command: 'bash ${clientScript.path}',
    );

    test('Start the server', () async {
      await expectLater(server.start(), completes);
    });

    test('Create demo input file', () async {
      expect(inputQ.numberOfInputs, 0);

      serverInputFile
        ..createSync()
        ..writeAsStringSync('hello world 12345');

      await inputQ.scan();

      expect(inputQ.numberOfInputs, 1);
    });

    test('Connect client', () async {
      await expectLater(client.connect(), completes);
    });

    test('Check if client produced output', () async {
      // Ensure client blackbox output is correct.
      expect(await clientOutputFile.readAsString(), 'output!');
    });

    test('Check if server received output', () async {
      // Input file on server should be gone.
      expect(serverInputFile.existsSync(), false);

      // Output file on server should exist now.
      expect(serverOutputFile.existsSync(), true);

      // Ensure server blackbox output is correct.
      expect(await serverOutputFile.readAsString(), 'output!');
    });
  });
}
