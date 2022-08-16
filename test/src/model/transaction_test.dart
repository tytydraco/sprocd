import 'package:sprocd/src/model/transaction.dart';
import 'package:test/test.dart';

void main() {
  group('Transaction', () {
    test('To bytes with no header', () {
      final transaction = Transaction([0, 1, 2, 3]);
      final bytes = transaction.toBytes();
      expect(bytes, [...List.generate(32, (_) => 0), 0, 1, 2, 3]);
    });

    test('To bytes with header', () {
      final transaction = Transaction([0, 1, 2, 3], header: 'test header');
      final bytes = transaction.toBytes();
      expect(bytes, [
        116,
        101,
        115,
        116,
        32,
        104,
        101,
        97,
        100,
        101,
        114,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1,
        2,
        3,
      ]);
    });

    test('From bytes with no header', () {
      final transaction = Transaction.fromBytes(
        [...List.generate(32, (_) => 0), 0, 1, 2, 3],
      );
      expect(transaction.data, [0, 1, 2, 3]);
      expect(transaction.header, '');
    });

    test('From bytes with header', () {
      final transaction = Transaction.fromBytes(
        [
          116,
          101,
          115,
          116,
          32,
          104,
          101,
          97,
          100,
          101,
          114,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          1,
          2,
          3,
        ],
      );
      expect(transaction.data, [0, 1, 2, 3]);
      expect(transaction.header, 'test header');
    });
  });
}
