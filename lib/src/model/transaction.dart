import 'dart:convert';

import 'package:stdlog/stdlog.dart';

/// A container holding some data with metadata.
class Transaction {
  /// Creates a new [Transaction] given some [data].
  Transaction(
    this.data, {
    this.header,
  });

  /// Creates a new [Transaction] from a list of [bytes].
  factory Transaction.fromBytes(List<int> bytes) {
    final encodedHeader = bytes.sublist(0, maxHeaderLength);
    final data = bytes.sublist(maxHeaderLength);

    // Decode the header if it does not only contain zeros.
    String? header;
    if (encodedHeader.any((e) => e != 0)) header = utf8.decode(encodedHeader);

    return Transaction(data, header: header);
  }

  /// The size in bytes of the header.
  static const maxHeaderLength = 32;

  /// A header that precedes the data section.
  final String? header;

  /// The data in bytes.
  final List<int> data;

  /// Return the byte representation of this transaction.
  List<int> toBytes() {
    // Fill header area with zeros to start.
    final bytes = <int>[]..fillRange(0, maxHeaderLength, 0);

    // Add header info if needed.
    if (header != null) {
      final encodedHeader = utf8.encode(header!);
      final headerLength = encodedHeader.length;

      if (headerLength > maxHeaderLength) {
        warn(
          'transaction: header exceeded maximum length of '
          '$maxHeaderLength',
        );
      }

      // Insert the byte data after.
      bytes.insertAll(
        maxHeaderLength,
        encodedHeader.sublist(0, maxHeaderLength),
      );
    }

    return bytes;
  }
}
