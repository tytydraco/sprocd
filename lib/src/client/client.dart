import 'dart:io';
import 'dart:typed_data';

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
    this.inputFilePath = '.tmp',
  });

  /// The host to connect to.
  final String host;

  /// The port to connect to.
  final int port;

  /// The command to execute to process the input file. The input file path will
  /// be appended to the command.
  final String command;

  /// After this long, the connection has failed.
  static const connectTimeout = Duration(seconds: 10);

  /// The file path to write input from the server to.
  final String inputFilePath;

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

    final inputFile = File(inputFilePath);
    await inputFile.create();
    await inputFile.writeAsBytes(receivedTransaction.data);
    debug('client: wrote out to ${inputFile.path}');

    // Process the input file.
    final outFile = await Blackbox(command).process(inputFile);
    if (outFile != null) {
      // Processing succeeded.
      info('client: responding to server');
      final outFileBytes = await outFile.readAsBytes();
      final outTransaction = EncodedTransaction(
        outFileBytes,
        header: receivedTransaction.header,
      );
      server.add(outTransaction.toBytes());
    } else {
      // Processing failed.
      info('client: informing server of processing failure');
      final outTransaction = EncodedTransaction(
        Uint8List.fromList([0]),
        header: receivedTransaction.header,
      );
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
    final server = await Socket.connect(
      host,
      port,
      timeout: connectTimeout,
    );
    info('client: connected');

    // Get the first chunk of data sent by the server. This should contain our
    // input file if we were given one.
    //
    // Only take the first event. Store this first as a list so that we can
    // perform multiple operations on the data without draining.
    final data = await server.take(1).toList();
    if (data.isNotEmpty) {
      await _handleData(server, data.first);
    } else {
      info('client: nothing to process');
    }
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
