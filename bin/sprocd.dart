import 'dart:io';

import 'package:args/args.dart';
import 'package:sprocd/src/client/client.dart';
import 'package:sprocd/src/server/input_q.dart';
import 'package:sprocd/src/server/server.dart';
import 'package:stdlog/stdlog.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser();
  parser
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show the program usage.',
      negatable: false,
      callback: (value) {
        if (value) {
          stdout.writeln(parser.usage);
          exit(0);
        }
      },
    )
    ..addOption(
      'port',
      abbr: 'p',
      help: 'The port to connect or bind to.',
      defaultsTo: '9900',
    )
    ..addOption(
      'host',
      abbr: 'H',
      help: 'The host to connect to.',
      defaultsTo: 'localhost',
    )
    ..addOption(
      'input-dir',
      abbr: 'i',
      help: 'Directory that houses the input files for the server.',
      defaultsTo: './input',
    )
    ..addOption(
      'output-dir',
      abbr: 'o',
      help: 'Directory that houses the output files for the server.',
      defaultsTo: './output',
    )
    ..addFlag(
      'forever',
      abbr: 'f',
      help: 'Keep reconnecting to the server, even if there is no work to be '
          'done.',
      defaultsTo: true,
    )
    ..addOption(
      'mode',
      abbr: 'm',
      help: 'What mode to use',
      allowed: ['server', 'client'],
      allowedHelp: {
        'server': 'Host a central server for facilitation.',
        'client': 'Connect to a central server for data processing.',
      },
      defaultsTo: 'server',
    );

  final options = parser.parse(args);
  try {
    final portStr = options['port'] as String;
    final host = options['host'] as String;
    final inputDirStr = options['input-dir'] as String;
    final outputDirStr = options['output-dir'] as String;
    final forever = options['forever'] as bool;
    final mode = options['mode'] as String;

    final port = int.tryParse(portStr);
    if (port == null || port.isNegative) {
      error('main: port must be a non-negative integer');
      exit(1);
    }

    if (mode == 'server') {
      final inputDir = Directory(inputDirStr);
      final outputDir = Directory(outputDirStr);

      if (!inputDir.existsSync()) {
        debug('main: input directory does not exist; creating one');
        inputDir.createSync();
      }

      if (!outputDir.existsSync()) {
        debug('main: output directory does not exist; creating one');
        outputDir.createSync();
      }

      final server = Server(
        port: port,
        inputQ: InputQ(inputDir),
        outputDir: outputDir,
      );

      info('Starting in server mode');
      await server.start();
    } else {
      final client = Client(
        host: host,
        port: port,
      );

      if (forever) {
        info('main: starting in client mode (persistent)');
        await client.connectPersistent();
      } else {
        info('main: starting in client mode (oneshot)');
        await client.connect();
      }
    }
  } catch (e) {
    error(e.toString());
    exit(1);
  }
}
