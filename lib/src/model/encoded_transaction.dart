import 'package:sprocd/src/model/transaction.dart';
import 'package:sprocd/src/utils/data_encode.dart';

/// A [Transaction] that implicitly encodes and decodes the content.
class EncodedTransaction extends Transaction {
  /// Creates a new [EncodedTransaction] given some [data].
  EncodedTransaction(
    super.data, {
    super.header,
  });

  /// Creates a new [EncodedTransaction] from a list of [bytes].
  factory EncodedTransaction.fromBytes(List<int> bytes) {
    final transaction = Transaction.fromBytes(decodeBytes(bytes));

    return EncodedTransaction(
      transaction.data,
      header: transaction.header,
    );
  }

  @override
  List<int> toBytes() {
    return encodeBytes(super.toBytes());
  }
}
