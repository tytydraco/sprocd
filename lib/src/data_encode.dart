import 'dart:async';
import 'dart:io';

/// Encode some data for socket communication.
List<int> encode(List<int> bytes) {
  return gzip.encode(bytes);
}

/// A [StreamTransformer] around [encode].
final encodeStream = StreamTransformer<List<int>, List<int>>.fromHandlers(
  handleData: (data, sink) {
    sink.add(encode(data));
  },
);

/// Decode some data for socket communication.
List<int> decode(List<int> bytes) {
  return gzip.decode(bytes);
}

/// A [StreamTransformer] around [decode].
final decodeStream = StreamTransformer<List<int>, List<int>>.fromHandlers(
  handleData: (data, sink) {
    sink.add(decode(data));
  },
);
