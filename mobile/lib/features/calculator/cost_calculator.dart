import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/widgets/states.dart';

// The existing React CostCalculator is a client-side illustration, not a server metric.
double futureValue(double principal, int years, double annualReturn, double expense) =>
    principal * math.pow(1 + (annualReturn - expense) / 100, years);

class CostCalculator extends StatefulWidget {
  const CostCalculator({super.key});
  @override
  State<CostCalculator> createState() => _CostCalculatorState();
}
class _CostCalculatorState extends State<CostCalculator> {
  double principal = 100000, years = 10, expected = 15, direct = .75, regular = 1.75;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Cost impact calculator')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Explore how fees affect compounded growth. These are editable assumptions, not a forecast or scheme minimums.'),
      const SizedBox(height: 12), Section('Your assumptions', [
        slider('Investment (₹)', principal, 10000, 1000000, 99, (v) => principal = v),
        slider('Holding period (years)', years, 1, 30, 29, (v) => years = v),
        slider('Expected annual return (%)', expected, 5, 25, 40, (v) => expected = v),
        slider('Direct plan fee (%)', direct, 0, 5, 100, (v) => direct = v),
        slider('Regular plan fee (%)', regular, 0, 5, 100, (v) => regular = v),
      ]),
      Section('Illustrative future value', [
        Fact('Direct plan (₹)', amount(futureValue(principal, years.round(), expected, direct), decimals: 0)),
        Fact('Regular plan (₹)', amount(futureValue(principal, years.round(), expected, regular), decimals: 0)),
        Fact('Difference (₹)', amount(futureValue(principal, years.round(), expected, direct) - futureValue(principal, years.round(), expected, regular), decimals: 0)),
      ]),
      const Text('Uses annual compounding after the entered fees. Taxes, loads, and changes in returns or expenses are excluded.'),
    ])));
  Widget slider(String label, double value, double min, double max, int divisions, void Function(double) update) =>
    Column(children: [Fact(label, amount(value)), Slider(value: value, min: min, max: max, divisions: divisions,
      label: amount(value), onChanged: (v) => setState(() => update(v)))]);
}
