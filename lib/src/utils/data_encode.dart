import 'dart:io';

/// Encode a byte stream for socket communication.
Stream<List<int>> encode(Stream<List<int>> byteStream) {
  return gzip.encoder.bind(byteStream);
}

/// Encode some data for socket communication.
@Deprecated('Use streams')
List<int> encodeBytes(List<int> bytes) {
  return gzip.encode(bytes);
}

/// Decode a byte stream for socket communication.
Stream<List<int>> decode(Stream<List<int>> byteStream) {
  return gzip.decoder.bind(byteStream);
}

/// Encode some data for socket communication.
@Deprecated('Use streams')
List<int> decodeBytes(List<int> bytes) {
  return gzip.decode(bytes);
}
