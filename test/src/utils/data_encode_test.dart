import 'package:sprocd/src/utils/data_encode.dart';
import 'package:test/test.dart';

void main() {
  test('Data encode and decode match as streams', () async {
    final data = [List.generate(128, (index) => index)];
    final dataStream = Stream.fromIterable(data);
    final encodedData = encode(dataStream);
    final decodedData = decode(encodedData);
    expect(await decodedData.single, data.single);
  });

  test('Data encode and decode match as bytes', () {
    final data = List.generate(128, (index) => index);
    final encodedData = encodeBytes(data);
    final decodedData = decodeBytes(encodedData);
    expect(decodedData, data);
  });
}
