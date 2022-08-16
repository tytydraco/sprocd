import 'package:sprocd/src/utils/data_encode.dart';
import 'package:test/test.dart';

void main() {
  test('Data encode and decode match', () {
    final data = List.generate(128, (index) => index);
    final encodedData = encode(data);
    final decodedData = decode(encodedData);
    expect(decodedData, data);
  });
}
