import 'dart:io';

import 'package:path/path.dart';
import 'package:sprocd/src/client/blackbox.dart';
import 'package:sprocd/src/utils/data_encode.dart';
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
    info('client: handling transaction');

    final tempDir = await Directory.systemTemp.createTemp();
    final inputFile = File(join(tempDir.path, 'input'));
    await inputFile.create();

    info('server: writing out to ${inputFile.path}');
    await inputFile.openWrite().addStream(decode(server));
    debug('client: finished writing out to ${inputFile.path}');

    // Check if we got nothing back from the server.
    if (await inputFile.length() == 0) {
      info('client: nothing to process');
      await tempDir.delete(recursive: true);
      return false;
    }

    // Process the input file.
    final outFile = await Blackbox(command).process(inputFile);
    if (outFile != null) {
      info('client: responding to server');
      try {
        await server.addStream(encode(outFile.openRead()));
      } catch (e) {
        error('client: failed to respond to server');
        stderr.writeln(e.toString());
        await tempDir.delete(recursive: true);
        return false;
      }
    }

    await server.flush();
    await server.close();
    await tempDir.delete(recursive: true);

    if (outFile?.existsSync() == true) {
      debug('client: deleting output file at ${outFile!.path}');
      await outFile.delete();
    }

    info('client: processed successfully');
    return true;
  }

  /// Connect the socket to the server. Returns false if the server didn't have
  /// any data for us, and true if it did.
  Future<bool> connect() async {
    info('client: connecting to server');
    final Socket server;
    try {
      server = await Socket.connect(
        host,
        port,
        timeout: connectTimeout,
      );
    } catch (e) {
      error('client: failed to connect to server');
      return false;
    }
    info('client: connected');

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
