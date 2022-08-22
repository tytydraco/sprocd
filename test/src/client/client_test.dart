import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/client/client.dart';
import 'package:test/test.dart';

// TODO(tytydraco): Add back encoding and decoding
void main() {
  group('Client', () {
    final tempDir = Directory.systemTemp.createTempSync();
    tearDownAll(() => tempDir.deleteSync(recursive: true));

    // Just creates a simple file that gets deleted before every test.
    final exampleBlackboxOutput = File(join(tempDir.path, 'test'));
    final exampleScript = File(join(tempDir.path, 'process.sh'))
      ..createSync()
      ..writeAsStringSync('touch ${exampleBlackboxOutput.path}');
    tearDown(() {
      if (exampleBlackboxOutput.existsSync()) {
        exampleBlackboxOutput.delete();
      }
    });

    test('Server is dead', () async {
      final client = Client(host: 'doesnotexist', port: 9999, command: 'echo');
      expect(client.connect, throwsA(isA<SocketException>()));
    });

    test('Server has nothing to serve', () async {
      final dummyServer =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 9999);
      final client = Client(
        host: 'localhost',
        port: 9999,
        command: 'bash ${exampleScript.path}',
      );
      dummyServer.listen((client) => client.close());
      await client.connect();
      await dummyServer.close();

      // Processing should not have occurred.
      expect(exampleBlackboxOutput.existsSync(), false);
    });

    test('Server serves us some data', () async {
      final dummyServer =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 9999);
      final client = Client(
        host: 'localhost',
        port: 9999,
        command: 'bash ${exampleScript.path}',
      );
      dummyServer.listen((client) async {
        await client.addStream(Stream.value([1, 2, 3, 4, 5]));
        await client.flush();
        await client.close();
      });
      await client.connect();
      await dummyServer.close();

      // Processing should have succeeded.
      expect(exampleBlackboxOutput.existsSync(), true);
    });

    test('Server serves us some data but bad blackbox command', () async {
      final dummyServer =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 9999);
      final client = Client(
        host: 'localhost',
        port: 9999,
        command: 'exit 1; bash ${exampleScript.path}',
      );
      dummyServer.listen((client) async {
        await client.addStream(Stream.value([1, 2, 3, 4, 5]));
        await client.flush();
        await client.close();
      });
      await client.connect();
      await dummyServer.close();

      // Processing should not have occurred.
      expect(exampleBlackboxOutput.existsSync(), false);
    });
  });
}
