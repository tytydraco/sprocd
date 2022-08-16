import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/model/encoded_transaction.dart';
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

  /// Setup and start the server socket.
  Future<void> start() async {
    debug('server: starting server');
    final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _startListener(serverSocket);
  }

  /// Return true if the data output signifies an error code.
  bool _dataIsError(List<int> data) => data.length == 1 && data.first == 0;

  /// If the client is not yet registered, perform a handshake and send some
  /// input data. Return the working file.
  Future<File?> _serveInput(Socket client) async {
    final file = await inputQ.pop();

    // If there is nothing to do, disconnect them.
    if (file == null) {
      debug(
        'server: nothing to serve, closing: '
        '${client.remoteAddress.address}',
      );

      await client.close();
    } else {
      debug(
        'server: sending ${file.path} to client: '
        '${client.remoteAddress.address}',
      );

      final inFileBytes = await file.readAsBytes();
      final transaction =
          EncodedTransaction(inFileBytes, header: 'hello world');
      client.add(transaction.toBytes());
    }

    return file;
  }

  /// Write out new data from the client to the output location given the
  /// [original] file and the output [data].
  Future<void> _writeOutput(File original, List<int> data) async {
    final inputPath = original.path;
    final outName = basename(inputPath).replaceFirst('.working', '.out');
    final outPath = join(outputDir.path, outName);

    debug('server: writing out to $outPath');
    await File(outPath).writeAsBytes(data);
    debug('server: deleting original at $inputPath');
    await File(inputPath).delete();
  }

  /// Handle an incoming connection from a client.
  Future<void> _handleConnection(Socket client) async {
    debug('server: client connected: ${client.remoteAddress.address}');

    // Serve input file to this client.
    final workingFile = await _serveInput(client);
    if (workingFile == null) return;

    // Write out the output file to the disk.
    await client.listen((data) async {
      info(
        'server: received ${data.length} bytes from client: '
        '${client.remoteAddress.address}',
      );

      final transaction = EncodedTransaction.fromBytes(data);
      info('server: transaction header: ${transaction.header}');

      // Make sure we did not end in an error.
      if (!_dataIsError(transaction.data)) {
        await _writeOutput(workingFile, transaction.data);
      } else {
        warn(
          'server: client processing failed: '
          '${client.remoteAddress.address}',
        );
      }

      await client.close();
    }).asFuture(null);
  }

  /// Start listening for connections from clients.
  void _startListener(ServerSocket serverSocket) {
    debug('server: starting listener');
    serverSocket.listen(_handleConnection);
  }
}
