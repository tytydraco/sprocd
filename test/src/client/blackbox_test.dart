import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/client/blackbox.dart';
import 'package:test/test.dart';

void main() {
  group('Blackbox', () {
    final tempDir = Directory.systemTemp.createTempSync();
    final testFile = File(join(tempDir.path, 'example'))
      ..createSync()
      ..writeAsStringSync('example file contents');

    tearDownAll(() => tempDir.deleteSync(recursive: true));

    test('Bad output path', () async {
      final outFile = await Blackbox('echo /nonexistent').process(testFile);
      expect(outFile, null);
    });

    test('Error in command', () async {
      final outFile = await Blackbox('bash -c "exit 1"').process(testFile);
      expect(outFile, null);
    });

    test('Real output path', () async {
      final testOutPath = join(tempDir.path, 'good');
      final testScript = File(join(tempDir.path, 'script.sh'))
        ..writeAsStringSync('touch $testOutPath; echo $testOutPath');
      final outFile =
          await Blackbox('bash ${testScript.path}').process(testFile);
      expect(outFile!.existsSync(), true);
    });
  });
}
