import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sif_mobile/core/network/api_client.dart';
import 'package:sif_mobile/features/funds/data/fund_repository.dart';
import 'package:sif_mobile/features/admin/import_repository.dart';

// Explicit opt-in: use only with backend/src/mobile-test-server.ts.
void main() {
  const enabled = bool.fromEnvironment('LIVE_API_TEST');
  test('Flutter repositories perform reads and Excel imports through Node/PostgreSQL', () async {
    final api = ApiClient('http://127.0.0.1:3101');
    addTearDown(api.close);
    expect((await api.get('/health'))['status'], 'ok');
    final repo = FundRepository(api);
    final page = await repo.list();
    expect(page.funds, isNotEmpty);
    for (final fund in page.funds) {
      final details = await repo.details(fund.id);
      expect(details.overview.fund.id, fund.id);
      for (final plan in details.plans) {
        for (final period in ['1M','3M','6M','1Y','SINCE_INCEPTION']) {
          await repo.analytics(plan.id, period);
        }
      }
    }
    await repo.compare(page.funds.take(5).map((f) => f.id).toList(), 'SINCE_INCEPTION');
    expect((await repo.list(query: 'no_such_scheme_57334')).funds, isEmpty);
    await expectLater(repo.details(99999999), throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)));
    await expectLater(api.post('/api/admin/import/excel/commit', body: {}, admin: true), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
    api.adminKey = 'local-mobile-test-only';
    await api.get('/api/admin/ingestion-runs', admin: true);
    final imports = ImportRepository(api);
    final book = await imports.analyze(await File('test/fixtures/dynasif.xlsx').readAsBytes(), 'dynasif.xlsx');
    expect(book.sheets.single.validation, isNull);
    final missing = await imports.commit(book, book.sheets.single);
    expect(missing.missing, isTrue);
    await imports.createMaster(missing);
    final result = await imports.commit(book, book.sheets.single);
    expect(result.inserted, 2);
    expect(result.failed, 0);
    final imported = (await repo.list(query: 'Mobile integration fund')).funds.single;
    final details = await repo.details(imported.id);
    final analytics = await repo.analytics(details.preferred!.id, 'SINCE_INCEPTION');
    expect(analytics.nav, 11);
    expect(analytics.returns.absolute, closeTo(.1, .000001));
    expect(analytics.history, hasLength(2));
    final repeated = await imports.commit(book, book.sheets.single);
    expect(repeated.skipped, 2);
  }, skip: !enabled, timeout: const Timeout(Duration(minutes: 2)));
}
