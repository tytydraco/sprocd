import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sprocd/src/data_encode.dart';
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

  /// The set of clients after a handshake that we are awaiting data from.
  /// The format is the client's remote IPV4 -> their working file path.
  final _clients = <String, String>{};

  /// Setup the server socket.
  Future<void> start() async {
    debug('server: starting server');
    final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _startListener(serverSocket);
  }

  /// Return true if this client has been seen before.
  bool _isRegistered(Socket client) =>
      _clients.containsKey(client.remoteAddress.address);

  /// Return true if the data output signifies an error code.
  bool _dataIsError(Uint8List data) => data.length == 1 && data.first == 0;

  // If the client is not yet registered, perform a handshake and send some
  // input data.
  void _serveInput(Socket client) {
    debug('server: registering client: ${client.remoteAddress.address}');
    final file = inputQ.pop();

    // If there is nothing to do, disconnect them.
    if (file == null) {
      debug(
        'server: nothing to serve, closing: '
        '${client.remoteAddress.address}',
      );

      client.close();
    } else {
      _clients[client.remoteAddress.address] = file.path;

      debug(
        'server: sending ${file.path} to client: '
        '${client.remoteAddress.address}',
      );

      final inFileStream = file.openRead();
      final encodedStream = inFileStream.transform(encodeStream);
      client.addStream(encodedStream);
    }
  }

  /// Handle incoming data from the client.
  void _handleReceiveData(Socket client, Uint8List data) {
    info(
      'server: received ${data.length} bytes from client: '
      '${client.remoteAddress.address}',
    );

    final decodedData = decode(data);

    // Make sure we did not end in an error.
    if (_dataIsError(data)) {
      warn(
        'server: client processing failed: '
        '${client.remoteAddress.address}',
      );
    } else {
      // Write out new data to output location.
      final inputPath = _clients[client.remoteAddress.address]!;
      final outName = basename(inputPath).replaceFirst(
        '.working',
        '.out',
      );
      final outPath = join(outputDir.path, outName);

      debug('server: writing out to $outPath');
      File(outPath).writeAsBytesSync(decodedData);
      debug('server: deleting original at $inputPath');
      File(inputPath).deleteSync();
    }
  }

  /// Handle an incoming connection from a client.
  Future<void> _handleConnection(Socket client) async {
    debug('server: client connected: ${client.remoteAddress.address}');

    if (!_isRegistered(client)) _serveInput(client);

    await client
        .listen((data) => _handleReceiveData(client, data))
        .asFuture(null);
  }

  /// Start listening for connections from clients.
  void _startListener(ServerSocket serverSocket) {
    debug('server: starting listener');
    serverSocket.listen(_handleConnection);
  }
}
