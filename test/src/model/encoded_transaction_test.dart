import 'package:sprocd/src/model/encoded_transaction.dart';
import 'package:test/test.dart';

void main() {
  test('Encoded transaction encode and decode match', () {
    final encodedTransaction = EncodedTransaction([123], header: '456');
    final decodedTransaction =
        EncodedTransaction.fromBytes(encodedTransaction.toBytes());

    expect(encodedTransaction.header, decodedTransaction.header);
    expect(encodedTransaction.data, decodedTransaction.data);
  });
}
