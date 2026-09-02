import 'package:flutter_core_project/core/formatters/vietnamese_currency_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats and parses Vietnamese currency input', () {
    expect(VietnameseCurrencyInputFormatter.formatDigits('1'), '1');
    expect(VietnameseCurrencyInputFormatter.formatDigits('1250'), '1.250');
    expect(
      VietnameseCurrencyInputFormatter.formatDigits('1250000'),
      '1.250.000',
    );
    expect(
      VietnameseCurrencyInputFormatter.parse('1.250.000 đ'),
      1250000,
    );
  });
}
