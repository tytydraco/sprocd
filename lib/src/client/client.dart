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

  /// Start listening for data from the server.
  void _startListener() {
    _socket.listen((data) {
      // TODO(tytydraco): process data
      print('CLIENT GOT: $data');
      _socket.write('new out data new out data etc etc etc');
    });
  }

  /// Connect the socket to the server.
  Future<void> connect() async {
    _socket = await Socket.connect(host, port);
    _startListener();
  }

  /// Send the contents of a file.
  Future<void> sendFile(File file) async {
    await _socket.addStream(file.openRead());
  }
}
