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

  /// The set of clients after a handshake that we are awaiting data from.
  /// The format is the client's remote IPV4 -> their working file path.
  final _clients = <String, String>{};

  /// Setup the server socket.
  Future<void> start() async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _startListener();
  }

  bool _isRegistered(Socket client) =>
      _clients.containsKey(client.remoteAddress.address);

  /// Start listening for connections from clients.
  void _startListener() {
    _serverSocket.listen((client) {
      // If the client is not yet registered, perform a handshake and send some
      // input data.
      if (!_isRegistered(client)) {
        final file = inputQ.pop();
        if (file == null) {
          client.close();
          return;
        }

        _clients[client.remoteAddress.address] = file.path;
        client.addStream(file.openRead());
      }

      client.listen((data) {
        // If already registered, write this data to the output.
        if (_isRegistered(client)) {
          print('OUTPUT: $data');
        }
      });
    });
  }
}
