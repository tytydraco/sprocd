import 'dart:convert';

import 'package:async/async.dart';
import 'package:sprocd/src/utils/header.dart';
import 'package:test/test.dart';

void main() {
  group('Header', () {
    test('Add header to stream', () async {
      final data = [
        [
          1,
          2,
          3,
        ]
      ];
      final dataStream = Stream.fromIterable(data);
      final dataStreamWithHeader = addHeader(dataStream, 'test');

      final expectedHeader = [
        ...ascii.encode('test'),
        ...List.filled(28, 0),
      ];

      final actualStreamList = await dataStreamWithHeader.toList();

      expect(actualStreamList.first, expectedHeader);
      expect(actualStreamList[1], [1, 2, 3]);
    });

    test('Get header from stream', () async {
      final headerBytes = [
        ...ascii.encode('test'),
        ...List.filled(28, 0),
      ];

      final group = StreamGroup.merge<List<int>>(
        [
          Stream.fromIterable([headerBytes]),
          Stream.fromIterable([
            [
              1,
              2,
              3,
            ],
          ]),
        ],
      );

      final split = StreamSplitter(group);

      final header = await getHeader(split.split());
      expect(header, 'test');

      final data = await split.split().elementAt(1);
      expect(data, [1, 2, 3]);
    });
  });
}
