import 'package:flutter_test/flutter_test.dart';
import 'package:veritas_tennis/util/device.dart';

void main() {
  test('Nigerian numbers are converted for WhatsApp links', () {
    expect(internationalNumber('0803 123 4567'), '2348031234567');
    expect(internationalNumber('+234 803-123-4567'), '2348031234567');
    expect(internationalNumber('002348031234567'), '2348031234567');
    expect(internationalNumber('2348031234567'), '2348031234567');
  });
}
