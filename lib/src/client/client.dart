import 'dart:io';

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

  /// Connect the socket to the server.
  Future<void> connect() async {
    _socket = await Socket.connect(host, port);
  }

  /// Send the contents of a file.
  Future<void> sendFile(File file) async {
    await _socket.addStream(file.openRead());
  }
}
