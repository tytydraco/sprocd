import 'dart:io';

import 'package:stdlog/stdlog.dart';

/// Encode some data for socket communication.
List<int> encode(List<int> bytes) {
  final result = gzip.encode(bytes);
  debug('data_encode: encoded size ${bytes.length} -> ${result.length}');
  return result;
}

/// Decode some data for socket communication.
List<int> decode(List<int> bytes) {
  final result = gzip.decode(bytes);
  debug('data_encode: decoded size ${bytes.length} -> ${result.length}');
  return result;
}
