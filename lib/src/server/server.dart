import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/model/encoded_transaction.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:sprocd/src/utils/transaction_manager.dart';
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

  /// Manager to keep track of transactions.
  final _transactionManager = TransactionManager();

  /// Setup and start the server socket.
  Future<void> start() async {
    debug('server: starting server');
    final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);

    debug('server: starting listener');
    serverSocket.listen(_handleConnection);
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
      info(
        'server: sending transaction to client: \n'
        '=====================================\n'
        'CLIENT: ${client.remoteAddress.address}\n'
        'DATE: ${_transactionManager.initTime.toIso8601String()}\n'
        'ID: ${_transactionManager.id}\n'
        '=====================================',
      );

      final inFileBytes = await file.readAsBytes();
      final transaction = _transactionManager.make(inFileBytes);
      client.add(transaction.toBytes());
      await client.flush();
    }

    return file;
  }

  /// Handle an incoming connection from a client.
  Future<void> _handleConnection(Socket client) async {
    debug('server: client connected: ${client.remoteAddress.address}');

    // Serve input file to this client if one exists.
    final workingFile = await _serveInput(client);
    if (workingFile == null) return;

    // Write out the output file to the disk.
    final data = await client.first;
    info(
      'server: received ${data.length} bytes from client: '
      '${client.remoteAddress.address}',
    );

    final transaction = EncodedTransaction.fromBytes(data);

    // Make sure we did not end in an error.
    if (!_dataIsError(transaction.data)) {
      final outName =
          basename(workingFile.path).replaceFirst('.working', '.out');
      final outPath = join(outputDir.path, outName);

      debug('server: writing out to $outPath');
      await File(outPath).writeAsBytes(transaction.data);
      debug('server: deleting original at ${workingFile.path}');
      await workingFile.delete();
    } else {
      warn(
        'server: client processing failed: '
        '${client.remoteAddress.address}',
      );
    }

    // We are done, disconnect the client.
    await client.close();
  }
}
