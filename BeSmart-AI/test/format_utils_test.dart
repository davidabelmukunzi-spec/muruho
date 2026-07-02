import 'package:flutter_test/flutter_test.dart';
import 'package:besmart_ai/core/utils/format_utils.dart';

void main() {
  test('formatBytes affiche Mo correctement', () {
    expect(FormatUtils.formatBytes(986_000_000), contains('Mo'));
  });

  test('formatPercent borne à 100', () {
    expect(FormatUtils.formatPercent(1.5), '100 %');
  });
}
