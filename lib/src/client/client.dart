import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sprocd/src/client/blackbox.dart';
import 'package:stdlog/stdlog.dart';

/// Functionality for a client process responsible for receiving, processing,
/// and responding with new output.
class Client {
  /// Creates a new [Client] given a [host] and a [port].
  Client({
    required this.host,
    required this.port,
  });

  /// The host to connect to.
  final String host;

  /// The port to connect to.
  final int port;

  late final Socket _socket;

  /// The file to write input data to.
  static final inputFilePath = join(Directory.systemTemp.path, 'input');

  void _handleData(Uint8List data) {
    debug('client: received ${data.length} bytes');
    final inFile = File(inputFilePath)
      ..createSync()
      ..writeAsBytes(data);
    debug('client: wrote out to ${inFile.path}');
    final outFile = Blackbox(inFile).process();
    debug('client: responding to server');
    _socket.addStream(outFile.openRead());
  }

  /// Connect the socket to the server.
  Future<void> connect() async {
    debug('client: connecting to server');
    _socket = await Socket.connect(host, port)
      ..listen(
        _handleData,
        cancelOnError: true,
        onError: error,
      );
  }

  /// Connect the socket to the server. If the client gets disconnected, wait
  /// three seconds, then retry indefinitely.
  Future<void> connectPersistent() async {
    debug('client: connecting to server');
    _socket = await Socket.connect(host, port);
    while (true) {
      final sub = _socket.listen(_handleData);
      await sub.asFuture<void>().catchError(error);
      await sub.cancel();

      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }
}
