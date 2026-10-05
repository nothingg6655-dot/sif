import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sif_mobile/core/widgets/states.dart';

void main() {
  testWidgets('Error state offers retry and displays the message', (tester) async {
    var retries = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatusView('Connection lost', onRetry: () => retries++))));
    expect(find.text('Connection lost'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });
}
