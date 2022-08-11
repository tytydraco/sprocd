import 'dart:io';

import 'package:sprocd/src/server/input_q.dart';

/// Functionality for a server process responsible for forwarding input to
/// clients and handling the output.
class Server {
  /// Creates a new [Server] given an [inputQ].
  Server({
    required this.port,
    required this.inputQ,
  });

  /// The port to bind to.
  final int port;

  /// The input queue to use.
  final InputQ inputQ;

  late final ServerSocket _serverSocket;

  /// Setup the server socket.
  Future<void> start() async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _startListener();
  }

  /// Start listening for connections from clients.
  void _startListener() {
    _serverSocket.listen((client) {
      client.listen((data) {
        print(data);
      });
    });
  }
}
