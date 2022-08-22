import 'dart:io';

import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:stdlog/stdlog.dart';

/// Functionality for a server process responsible for forwarding input to
/// clients and handling the output.
class Server {
  /// Creates a new [Server] given an [inputQ].
  Server({
    required this.port,
    required this.inputQ,
    required this.outputDir,
  });

  /// The port to bind to.
  final int port;

  /// The input queue to use.
  final InputQ inputQ;

  /// The directory housing the output files.
  final Directory outputDir;

  /// The active server socket.
  ServerSocket? _serverSocket;

  /// The server start time.
  final _initTime = DateTime.now();

  /// The latest ID to use for the next transaction.
  int _transactionId = 0;

  /// Create a label for a client socket.
  String _clientId(Socket client) =>
      '${client.remoteAddress.address}:${client.remotePort}';

  /// Setup and start the server socket.
  Future<void> start() async {
    if (_serverSocket != null) throw StateError('Server has already started');

    debug('server: starting server');
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);

    debug('server: starting listener');
    _serverSocket!.listen(_handleConnection);
  }

  /// Stop the server socket.
  Future<void> stop() async {
    if (_serverSocket == null) throw StateError('Server is already stopped');

    debug('server: stopping server');
    await _serverSocket!.close();
    _serverSocket = null;
  }

  /// If the client is not yet registered, perform a handshake and send some
  /// input data. Return the working file.
  Future<File?> _serveInput(Socket client) async {
    final clientId = _clientId(client);

    await inputQ.scan();
    final file = await inputQ.pop();

    // If there is nothing to do, disconnect them.
    if (file == null) {
      debug('server: nothing to serve, closing: $clientId');
      await client.close();
    } else {
      // Take an ID to use for this transaction, then increment it.
      final transactionId = _transactionId++;

      info(
        'server: sending transaction to client: \n'
        '=====================================\n'
        'CLIENT: $clientId\n'
        'INIT-DATE: ${_initTime.toIso8601String()}\n'
        'ID: $transactionId\n'
        '=====================================',
      );

      await client.addStream(file.openRead());
      await client.flush();
    }

    return file;
  }

  /// Handle an incoming connection from a client.
  Future<void> _handleConnection(Socket client) async {
    final timeStart = DateTime.now();

    final clientId = _clientId(client);

    debug('server: client connected: $clientId');

    // Serve input file to this client if one exists.
    final workingFile = await _serveInput(client);
    if (workingFile == null) return;

    final splitStream = StreamSplitter(client);

    info('server: received transaction from client: $clientId');

    // Make sure we did not end in an error.
    // TODO(tytydraco): figure out if error or not without reading entire data
    final data = await splitStream.split().first;
    final hadError = data.length == 1 && data.first == 0;
    if (!hadError) {
      final outName =
          basename(workingFile.path).replaceFirst('.working', '.out');
      final outPath = join(outputDir.path, outName);

      // Write out the output file to the disk.
      debug('server: writing out to $outPath');
      final dataStream = splitStream.split().take(1);
      await File(outPath).openWrite().addStream(dataStream);

      debug('server: deleting original at ${workingFile.path}');
      await workingFile.delete();
    } else {
      warn('server: client processing failed: $clientId');
    }

    // We are done, disconnect the client.
    await client.close();

    final timeEnd = DateTime.now();
    final duration = timeEnd.difference(timeStart);
    info('server: connection duration: $duration for client: $clientId');
  }
}
