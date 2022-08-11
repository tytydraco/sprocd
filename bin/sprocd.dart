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
      abbr: 'h',
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
    final port = options['port'] as int;
    final host = options['host'] as String;
    final inputDir = options['input-dir'] as String;
    final outputDir = options['output-dir'] as String;
    final forever = options['forever'] as bool;
    final mode = options['mode'] as String;

    if (mode == 'server') {
      final server = Server(
        port: port,
        inputQ: InputQ(Directory(inputDir)),
        outputDir: Directory(outputDir),
      );

      info('Starting in server mode');
      await server.start();
    } else {
      final client = Client(
        host: host,
        port: port,
      );

      if (forever) {
        info('Starting in client mode (persistent)');
        await client.connectPersistent();
      } else {
        info('Starting in client mode (oneshot)');
        await client.connect();
      }
    }
  } catch (e) {
    error(e.toString());
    exit(1);
  }
}
