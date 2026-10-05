import 'package:flutter_test/flutter_test.dart';
import 'package:sif_mobile/features/calculator/cost_calculator.dart';

void main() {
  test('Calculator matches web compounding and treats zero net return correctly', () {
    expect(futureValue(100000, 1, 15, .75), closeTo(114250, .001));
    expect(futureValue(100000, 10, 5, 5), 100000);
    expect(futureValue(100000, 10, 15, .75), greaterThan(futureValue(100000, 10, 15, 1.75)));
  });
}
