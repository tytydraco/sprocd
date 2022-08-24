import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:sprocd/src/utils/data_encode.dart';
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
  Future<File?> _serveInput(Socket client, int id) async {
    final clientId = _clientId(client);

    await inputQ.scan();
    final file = await inputQ.pop();

    // If there is nothing to do, disconnect them.
    if (file == null) {
      debug('server[$id]: nothing to serve, closing: $clientId');
      await client.close();
    } else {
      info(
        'server[$id]: sending transaction to client: \n'
            '=====================================\n'
            'CLIENT: $clientId\n'
            'INIT-DATE: ${_initTime.toIso8601String()}\n'
            'ID: $id\n'
            'FILE: ${file.path}\n'
            '=====================================',
      );

      try {
        await client.addStream(encode(file.openRead()));
        await client.flush();
        await client.close();
        info('server[$id]: finished sending data to client: $clientId');
        return file;
      } catch (e) {
        error('server[$id]: failed to send data to client: $clientId');
        stderr.writeln(e.toString());
      }
    }

    return null;
  }

  /// Handle an incoming connection from a client.
  Future<void> _handleConnection(Socket client) async {
    // Take an ID to use for this transaction, then increment it.
    final id = _transactionId++;

    final timeStart = DateTime.now();

    final clientId = _clientId(client);

    info('server[$id]: client connected: $clientId');

    // Serve input file to this client if one exists.
    final workingFile = await _serveInput(client, id);
    if (workingFile == null) return;

    // Write out the output file to the disk.
    info('server[$id]: received transaction from client: $clientId');
    final tempDir = await Directory.systemTemp.createTemp();
    final outName = basename(workingFile.path).replaceFirst(
      InputQ.workingFileSuffix,
      '.out',
    );
    final tmpFile = File(join(tempDir.path, outName));
    debug('server[$id]: writing out to ${tmpFile.path}');
    await tmpFile.openWrite().addStream(decode(client));

    // Check if we got nothing back from the client.
    if (await tmpFile.length() == 0) {
      error('server[$id]: received failure from client: $clientId');
      await tmpFile.delete();

      info('server[$id]: adding failed input back to queue');
      final unWorkingFile = inputQ.toUnWorkingFile(workingFile);
      await workingFile.rename(unWorkingFile.path);
    } else {
      final outFile = File(join(outputDir.path, outName));
      debug('server[$id]: moving ${tmpFile.path} to ${outFile.path}');
      await tmpFile.copy(outFile.path);
      await tmpFile.delete();

      debug('server[$id]: deleting original at ${workingFile.path}');
      await workingFile.delete();
    }

    // We are done, disconnect the client.
    await client.close();
    await tempDir.delete(recursive: true);

    final timeEnd = DateTime.now();
    final duration = timeEnd.difference(timeStart);
    info('server[$id]: connection duration: $duration for client: $clientId');
  }
}
