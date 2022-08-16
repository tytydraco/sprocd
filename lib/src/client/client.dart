import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sprocd/src/client/blackbox.dart';
import 'package:sprocd/src/model/encoded_transaction.dart';
import 'package:sprocd/src/model/metadata_header.dart';
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
  static final inputFile = File(join(Directory.systemTemp.path, 'input'));

  /// Handle incoming data from the server.
  Future<void> _handleData(Socket server, Uint8List data) async {
    info('client: received ${data.length} bytes');
    final receivedTransaction = EncodedTransaction.fromBytes(data);
    final metadataHeader =
        MetadataHeader.fromString(receivedTransaction.header);

    info(
      'client: handling transaction for session: \n'
      '=====================================\n'
      'DATE: ${metadataHeader.initTime.toIso8601String()}\n'
      'ID: ${metadataHeader.id}\n'
      '=====================================',
    );

    await inputFile.create();
    await inputFile.writeAsBytes(receivedTransaction.data);
    debug('client: wrote out to ${inputFile.path}');

    // Process the input file.
    final outFile = await Blackbox(command).process(inputFile);
    if (outFile != null) {
      // Processing succeeded.
      info('client: responding to server');
      final outFileBytes = await outFile.readAsBytes();
      final outTransaction = EncodedTransaction(outFileBytes);
      server.add(outTransaction.toBytes());
    } else {
      // Processing failed.
      info('client: informing server of processing failure');
      final outTransaction = EncodedTransaction(Uint8List.fromList([0]));
      server.add(outTransaction.toBytes());
    }

    await server.flush();
    await server.close();

    // Delete input file after we processed it.
    await inputFile.delete();
  }

  /// Connect the socket to the server.
  Future<void> connect() async {
    info('client: connecting to server');
    final server = await Socket.connect(host, port);
    info('client: connected');

    // Get the first chunk of data sent by the server. This should contain our
    // input file if we were given one.

    //TODO(tytydraco): catch error if cancels early (error from .first), use single in server side
    final data = await server.first;
    await _handleData(server, data);
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
