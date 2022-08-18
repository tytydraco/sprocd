/// A [Transaction] that implicitly encodes and decodes the content.
/*class EncodedTransaction extends Transaction {
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
}*/

class EncodedTransaction {
  EncodedTransaction(this.data, {
    this.header = '',
  });

  final List<int> data;
  final String header;

  List<int> toBytes() => [];

  factory EncodedTransaction.fromBytes(List<int> bytes) {
    return EncodedTransaction([], header: '',);
  }
}
