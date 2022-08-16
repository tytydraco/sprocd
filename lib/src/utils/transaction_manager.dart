import 'package:sprocd/src/model/encoded_transaction.dart';
import 'package:sprocd/src/model/metadata_header.dart';

/// Create [EncodedTransaction]s with server time and ID metadata.
class TransactionManager {
  /// The starting server time.
  final initTime = DateTime.now();

  /// The latest ID to use for the next transaction header.
  int id = 0;

  /// Generate a new [EncodedTransaction] given some [data].
  EncodedTransaction make(List<int> data) {
    final header = MetadataHeader(initTime: initTime, id: id++).toString();
    return EncodedTransaction(data, header: header);
  }
}
