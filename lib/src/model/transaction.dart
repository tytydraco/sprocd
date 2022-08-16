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

    // Decode the header up to the last non-null character.
    var header = '';
    final headerLastNonNullIdx = encodedHeader.lastIndexWhere((e) => e != 0);
    if (headerLastNonNullIdx != -1) {
      final encodedHeaderTrimmed =
          encodedHeader.sublist(0, headerLastNonNullIdx + 1);
      header = ascii.decode(encodedHeaderTrimmed);
    }

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
    // Fill header area with NULLs to start.
    final bytes = List.filled(maxHeaderLength, 0, growable: true);

    // Add header info if needed.
    if (header.isNotEmpty) {
      final encodedHeader = ascii.encode(header);
      final headerLength = encodedHeader.length;

      if (headerLength > maxHeaderLength) {
        warn(
          'transaction: header exceeded maximum length of '
          '$maxHeaderLength',
        );
      }

      // Overwrite the template header with the new header.
      bytes.replaceRange(
        0,
        encodedHeader.length.clamp(0, maxHeaderLength),
        encodedHeader,
      );
    }

    // Add data section.
    bytes.addAll(data);

    return bytes;
  }
}
