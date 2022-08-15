import 'dart:convert';

import 'package:stdlog/stdlog.dart';

/// A container holding some data with metadata.
class Transaction {
  /// Creates a new [Transaction] given some [data].
  Transaction(
    this.data, {
    this.header = '',
  });

  /// Creates a new [Transaction] from a list of [bytes].
  factory Transaction.fromBytes(List<int> bytes) {
    final encodedHeader = bytes.sublist(0, maxHeaderLength);
    final data = bytes.sublist(maxHeaderLength);

    // Decode the header and trim it to remove leading LFs.
    final header = utf8.decode(encodedHeader).trim();

    return Transaction(
      data,
      header: header,
    );
  }

  /// The size in bytes of the header.
  static const maxHeaderLength = 32;

  /// A header that precedes the data section.
  final String header;

  /// The data in bytes.
  final List<int> data;

  /// Return the byte representation of this transaction.
  List<int> toBytes() {
    // Fill header area with LFs to start.
    final bytes = List.filled(maxHeaderLength, 10, growable: true);

    // Add header info if needed.
    if (header.isNotEmpty) {
      final encodedHeader = utf8.encode(header!);
      final headerLength = encodedHeader.length;

      if (headerLength > maxHeaderLength) {
        warn(
          'transaction: header exceeded maximum length of '
          '$maxHeaderLength',
        );
      }

      // Overwrite the template header with the new header.
      bytes.replaceRange(0, encodedHeader.length, encodedHeader);
    }

    // Add data section.
    bytes.addAll(data);

    return bytes;
  }
}
