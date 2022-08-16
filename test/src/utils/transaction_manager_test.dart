import 'package:sprocd/src/model/encoded_transaction.dart';
import 'package:sprocd/src/utils/transaction_manager.dart';
import 'package:test/test.dart';

void main() {
  group('Transaction manager', () {
    test('Initial time is accurate', () {
      final manager = TransactionManager();
      final now = DateTime.now();

      // Check if within one second of accuracy.
      expect(
        now.difference(manager.initTime).inMilliseconds,
        closeTo(0, 1000),
      );
    });

    test('Increments ID', () {
      final manager = TransactionManager();
      expect(manager.id, 0);

      manager.make([]);
      expect(manager.id, 1);

      manager.make([]);
      expect(manager.id, 2);
    });

    test('Creates valid transactions', () {
      final manager = TransactionManager();
      final exampleTransaction = EncodedTransaction(
        [123],
        header: '${manager.initTime.millisecondsSinceEpoch}:${manager.id}',
      );
      final transaction = manager.make([123]);

      expect(exampleTransaction.header, transaction.header);
      expect(exampleTransaction.data, transaction.data);
    });
  });
}
