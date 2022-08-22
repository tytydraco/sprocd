import 'dart:io';

/// Encode a byte stream for socket communication.
Stream<List<int>> encode(Stream<List<int>> byteStream) {
  return gzip.encoder.bind(byteStream);
}

/// Decode a byte stream for socket communication.
Stream<List<int>> decode(Stream<List<int>> byteStream) {
  return gzip.decoder.bind(byteStream);
}
