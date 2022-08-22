import 'dart:io';

import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:sprocd/src/client/blackbox.dart';
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

  /// After this long, the connection has failed.
  static const connectTimeout = Duration(seconds: 10);

  /// Handle incoming connections from the server. Returns true if we processed
  /// data, and false otherwise.
  Future<bool> _handleConnection(Socket server) async {
    final splitStream = StreamSplitter(server);

    // TODO(tytydraco): figure out if error or not without reading entire data
    if (await splitStream.split().isEmpty) {
      info('client: nothing to process');
      return false;
    }

    info('client: handling transaction');

    final tempDir = await Directory.systemTemp.createTemp();
    final inputFile = File(join(tempDir.path, 'input'));
    await inputFile.create();

    final dataStream = splitStream.split().take(1);
    await inputFile.openWrite().addStream(dataStream);
    debug('client: wrote out to ${inputFile.path}');

    // Process the input file.
    final outFile = await Blackbox(command).process(inputFile);
    if (outFile != null) {
      info('client: responding to server');
      await server.addStream(outFile.openRead());
    } else {
      info('client: informing server of processing failure');
      server.add([0]);
    }

    await server.flush();
    await server.close();

    // Delete input file after we processed it.
    await tempDir.delete(recursive: true);

    info('client: processed successfully');
    return true;
  }

  /// Connect the socket to the server. Returns false if the server didn't have
  /// any data for us, and true if it did.
  Future<bool> connect() async {
    info('client: connecting to server');
    final server = await Socket.connect(
      host,
      port,
      timeout: connectTimeout,
    );
    info('client: connected');

    // Get the first chunk of data sent by the server. This should contain our
    // input file if we were given one.
    return _handleConnection(server);
  }

  /// Connect the socket to the server. If the client gets disconnected, wait
  /// three seconds, then retry indefinitely.
  Future<void> connectPersistent() async {
    while (true) {
      final processed = await connect();

      // Delay a reconnect if we didn't have any data.
      if (!processed) {
        info('client: waiting three seconds before reconnect');
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    }
  }
}
