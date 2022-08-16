import 'package:sprocd/src/model/metadata_header.dart';
import 'package:test/test.dart';

void main() {
  group('Metadata header', () {
    test('Bad string', () {
      expect(
        () => MetadataHeader.fromString('bad string'),
        throwsArgumentError,
      );
    });

    test('To string is valid', () {
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;
      final header = MetadataHeader(initTime: now, id: 0);
      expect(header.toString(), '$nowMs:0');
    });

    test('From string is valid', () {
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;
      final header = MetadataHeader.fromString('$nowMs:0');
      expect(
        header.initTime.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
      expect(header.id, 0);
    });
  });
}
