import 'package:sprocd/src/utils/data_encode.dart';
import 'package:test/test.dart';

void main() {
  test('Data encode and decode match as streams', () async {
    final data = List.generate(128, (index) => index);
    final dataStream = Stream.value(data);
    final encodedData = encode(dataStream);
    final decodedData = decode(encodedData);
    expect(await decodedData.single, data);
  });
}
