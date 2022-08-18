import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:stdlog/stdlog.dart';

/// The fixed length to reserve for the header.
const maxHeaderLength = 32;

/// Get a header from a byte stream that contains one.
Future<String?> getHeader(Stream<List<int>> byteStream) async {
  final splitStream = StreamSplitter(byteStream);
  final headerStream = splitStream.split().take(32);
  final encodedHeader = await headerStream.single;

  // Decode the header up to the last non-null character.
  final headerLastNonNullIdx = encodedHeader.lastIndexWhere((e) => e != 0);
  if (headerLastNonNullIdx != -1) {
    final encodedHeaderTrimmed =
        encodedHeader.sublist(0, headerLastNonNullIdx + 1);
    return ascii.decode(encodedHeaderTrimmed);
  }

  return null;
}

/// Returns a new stream with a header prepended to a byte stream.
Stream<List<int>> addHeader(Stream<List<int>> byteStream, String header) {
  final controller = StreamController<List<int>>();

  // Fill header area with NULLs to start.
  final headerBytes = List.filled(maxHeaderLength, 0);

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

  controller
    ..add(headerBytes)
    ..addStream(byteStream);

  return controller.stream;
}
