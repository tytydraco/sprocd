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

  /// The file to write input data to.
  static final inputFilePath = join(Directory.systemTemp.path, 'input');

  void _handleData(Socket socket, Uint8List data) {
    info('client: received ${data.length} bytes');
    final inFile = File(inputFilePath)
      ..createSync()
      ..writeAsBytes(data);
    debug('client: wrote out to ${inFile.path}');
    final outFile = Blackbox(inFile).process();
    info('client: responding to server');
    socket.addStream(outFile.openRead());
  }

  /// Connect the socket to the server.
  Future<void> connect() async {
    info('client: connecting to server');
    final socket = await Socket.connect(host, port);
    socket.listen(
      (data) => _handleData(socket, data),
      cancelOnError: true,
      onError: error,
    );
  }

  /// Connect the socket to the server. If the client gets disconnected, wait
  /// three seconds, then retry indefinitely.
  Future<void> connectPersistent() async {
    debug('client: connecting to server');
    while (true) {
      final socket = await Socket.connect(host, port);
      info('client: connected');

      final sub = socket.listen((data) => _handleData(socket, data));
      await sub.asFuture<void>().catchError(error);

      info('client: disconnected');

      debug('client: closing connections');
      await sub.cancel();
      await socket.close();

      info('client: waiting three seconds before reconnect');
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }
}
