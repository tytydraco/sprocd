import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:stdlog/stdlog.dart';

/// The fixed length to reserve for the header.
const maxHeaderLength = 32;

/// Get a header from a byte stream that contains one. This will consume the
/// stream. It may be desirable to use a [StreamSplitter].
Future<String?> getHeader(Stream<List<int>> byteStream) async {
  final encodedHeader = (await byteStream.first).take(maxHeaderLength).toList();

  // Decode the header up to the last non-null character.
  final headerLastNonNullIdx = encodedHeader.lastIndexWhere((e) => e != 0);
  if (headerLastNonNullIdx != -1) {
    final encodedHeaderTrimmed =
        encodedHeader.sublist(0, headerLastNonNullIdx + 1);
    return ascii.decode(encodedHeaderTrimmed);
  }

  return null;
}

/// Returns a new stream with a header event prepended to a byte stream.
Stream<List<int>> addHeader(Stream<List<int>> byteStream, String header) {
  // Fill header area with NULLs to start.
  final headerBytes = List.filled(maxHeaderLength, 0, growable: true);

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
    headerBytes.replaceRange(
      0,
      encodedHeader.length.clamp(0, maxHeaderLength),
      encodedHeader,
    );
  }

  final group = StreamGroup.merge([
    Stream.value(headerBytes),
    byteStream,
  ]);

  return group;
}
