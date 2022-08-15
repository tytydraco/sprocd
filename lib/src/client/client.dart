import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sprocd/src/client/blackbox.dart';
import 'package:sprocd/src/data_encode.dart';
import 'package:stdlog/stdlog.dart';

/// Functionality for a client process responsible for receiving, processing,
/// and responding with new output.
class Client {
  /// Creates a new [Client] given a [host] and a [port].
  Client({
    required this.host,
    required this.port,
    required this.command,
  });

  /// The host to connect to.
  final String host;

  /// The port to connect to.
  final int port;

  /// The command to execute to process the input file. The input file path will
  /// be appended to the command.
  final String command;

  /// The file to write input data to.
  static final inputFilePath = join(Directory.systemTemp.path, 'input');

  /// Handle incoming data from the server.
  Future<void> _handleData(Socket socket, Uint8List data) async {
    info('client: received ${data.length} bytes');
    final decodedData = decode(data);

    final inFile = File(inputFilePath)
      ..createSync()
      ..writeAsBytesSync(decodedData);
    debug('client: wrote out to ${inFile.path}');
    final outFile = await Blackbox(command).process(inFile);

    if (outFile != null) {
      info('client: responding to server');
      final outFileBytes = await outFile.readAsBytes();
      final encodedBytes = encode(outFileBytes);
      socket.add(encodedBytes);
    } else {
      info('client: informing server of processing failure');
      socket.add([0]);
    }
  }

  /// Connect the socket to the server.
  Future<void> connect() async {
    info('client: connecting to server');
    final socket = await Socket.connect(host, port);
    info('client: connected');
    await socket.listen((data) => _handleData(socket, data)).asFuture(null);
    info('client: disconnected');
  }

  /// Connect the socket to the server. If the client gets disconnected, wait
  /// three seconds, then retry indefinitely.
  Future<void> connectPersistent() async {
    while (true) {
      await connect();
      info('client: waiting three seconds before reconnect');
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }
}
