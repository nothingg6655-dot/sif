import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:sif_mobile/app/app.dart';
import 'package:sif_mobile/core/network/api_client.dart';
import 'package:sif_mobile/features/auth/session.dart';
import 'package:sif_mobile/features/funds/data/fund_repository.dart';
import 'package:sif_mobile/features/funds/fund_controller.dart';
import 'session_test.dart' show MemoryCredentials;

const fund = {'schemeId':1, 'schemeName':'DynaSIF Active Asset Allocator Long-Short Fund', 'amc':'360 ONE Asset Management Limited', 'category':'Hybrid', 'latestNav':11.25};

void main() {
  testWidgets('Phone navigation, comparison, factsheet and admin guard', (tester) async {
    const fontPath = String.fromEnvironment('SCREENSHOT_FONT');
    if (fontPath.isNotEmpty) {
      await tester.runAsync(() async {
        final loader = FontLoader('Roboto')..addFont(File(fontPath).readAsBytes().then((b) => ByteData.sublistView(b)));
        await loader.load();
      });
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient('http://localhost', client: MockClient((r) async {
      final p = r.url.path;
      Object response = {};
      if (p == '/api/funds') response = {'data':[fund], 'page':1, 'total':1};
      if (p == '/api/funds/1') response = fund;
      if (p == '/api/funds/1/plans') response = {'plans':[{'planId':1,'planType':'Direct','optionType':'Growth'}]};
      if (p.startsWith('/api/funds/compare')) response = {'funds':[fund]};
      if (p.endsWith('/nav/history')) response = {'data':[{'date':'2026-01-01','nav':10},{'date':'2026-02-01','nav':11.25}]};
      return http.Response(jsonEncode(response), 200);
    }));
    final repo = FundRepository(api);
    final controller = FundController(repo);
    final session = AdminSession(api, MemoryCredentials());
    await session.restore();
    await controller.load();
    final boundary = GlobalKey();
    await tester.pumpWidget(MultiProvider(providers: [
      Provider.value(value: api), Provider.value(value: repo),
      ChangeNotifierProvider.value(value: controller), ChangeNotifierProvider.value(value: session),
    ], child: RepaintBoundary(key: boundary, child: const SifApp())));
    await tester.pumpAndSettle();
    expect(find.text('Explore funds'), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('SCREENSHOTS')) {
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await render.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/screenshots').create(recursive: true);
        await File('build/screenshots/discover.png').writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    // Selection changes must update a hidden comparison tab without lifecycle errors.
    final add = find.widgetWithText(TextButton, 'Compare');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    expect(find.text('Compare funds'), findsOneWidget);
    expect(find.text('Absolute return'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Performance explorer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(NavigationDestination).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(fund['schemeName'] as String).first);
    await tester.pumpAndSettle();
    expect(find.text('Fund factsheet'), findsOneWidget);
    final detailScroll = find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Plan and option'), 400, scrollable: detailScroll);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Analysis period'), 200, scrollable: detailScroll);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Administrator'));
    await tester.pumpAndSettle();
    expect(find.text('Administrator key'), findsOneWidget);
    expect(find.text('Choose workbook'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose(); session.dispose(); api.close();
  });
}
