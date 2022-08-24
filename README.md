# sprocd

The Smoothie processing daemon responsible for the forwarding and processing of input files.

# How it works

There are two components to `sprocd`: a server and a client. A server listens on a given port for a client to connect.
It listens or changes in an input directory. Once a file is created and automatically detected, the server sorts it into
a queue of input files, sorted based on latest modify time and then by name. Once a client connects, the server will pop
the topmost input file from the queue and serve it to the client. The client will execute a processing command, where
the path of this file (transferred and saved to a temporary location) will be passed as the last argument. This command
should return a file path for the processed output file. The client responds to the server with the contents of this new
file, and saves it to an output directory. The client and server both clean up their temporary files. Multiple clients
can request files and be served at the same time. Files are sent over using GZIP compression.

# Getting started

Install the program by navigating to the root directory of the project and using `dart pub global activate -s path .`.
Then, use `sprocd` to execute the program.

# Usage

```
-h, --help                      Show the program usage.
-p, --port                      The port to connect or bind to.
                                (defaults to "9900")
-H, --host                      The host to connect to.
                                (defaults to "localhost")
-i, --input-dir                 Directory that houses the input files for the server.
                                (defaults to "./input")
-o, --output-dir                Directory that houses the output files for the server.
                                (defaults to "./output")
-c, --command                   Command that the client will run when data is received from the server. The path to the input content will be appended to the end of the command.
                                (defaults to "echo")
-f, --[no-]forever              Keep reconnecting to the server, even if there is no work to be done.
                                (defaults to on)
-m, --mode                      What mode to use

          [client]              Connect to a central server for data processing.
          [server] (default)    Host a central server for facilitation.
```
