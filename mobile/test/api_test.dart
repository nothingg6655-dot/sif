import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sif_mobile/core/config/api_config.dart';
import 'package:sif_mobile/core/network/api_client.dart';
import 'package:sif_mobile/core/widgets/states.dart';
import 'package:sif_mobile/features/funds/data/fund_repository.dart';
import 'package:sif_mobile/features/funds/data/models.dart';
import 'package:sif_mobile/features/admin/import_repository.dart';

void main() {
  test('Configuration validates URLs and enforces HTTPS for release', () {
    ApiConfig.validate('http://10.0.2.2:3000');
    expect(() => ApiConfig.validate('http://host:3000', release: true), throwsFormatException);
    expect(() => ApiConfig.validate('https://secret@host'), throwsFormatException);
    ApiConfig.validate('https://example.test', release: true);
  });
  test('Repository sends search and pagination without losing null values', () async {
    final api = ApiClient('http://localhost', client: MockClient((r) async {
      expect(r.url.path, '/api/funds');
      expect(r.url.queryParameters['q'], 'A&B');
      expect(r.url.queryParameters['page'], '2');
      return http.Response(jsonEncode({'data': [{'schemeId': 7, 'schemeName': 'Fund', 'amc': 'AMC', 'latestNav': null, 'riskBand': null}], 'page': 2, 'total': 21}), 200);
    }));
    final page = await FundRepository(api).list(query: 'A&B', page: 2);
    expect(page.funds.single.nav, isNull);
    expect(page.total, 21);
    api.close();
  });
  test('Admin key is sent only to explicitly protected calls; 401 invalidates session', () async {
    var expired = false;
    final api = ApiClient('http://localhost', client: MockClient((r) async {
      if (r.url.path == '/public') {
        expect(r.headers['x-admin-key'], isNull);
        return http.Response('{}', 200);
      }
      expect(r.headers['x-admin-key'], 'test-key');
      return http.Response('{"error":{"message":"private details"}}', 401);
    }))..adminKey = 'test-key';
    api.onUnauthorized = () => expired = true;
    await api.get('/public');
    await expectLater(api.get('/admin', admin: true), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
    expect(expired, isTrue);
    api.close();
  });
  for (final code in [400, 403, 404, 409, 422, 500]) {
    test('HTTP $code does not expose raw server errors', () async {
      final api = ApiClient('http://localhost', client: MockClient((_) async => http.Response('secret stack trace', code)));
      await expectLater(api.get('/'), throwsA(isA<ApiException>().having((e) => e.message.contains('secret'), 'sanitized', false)));
      api.close();
    });
  }
  test('Timeout and malformed JSON become user-friendly errors', () async {
    final api = ApiClient('http://localhost', timeout: const Duration(milliseconds: 1), client: MockClient((_) => Completer<http.Response>().future));
    await expectLater(api.get('/'), throwsA(isA<ApiException>()));
    api.close();
    final malformed = ApiClient('http://localhost', client: MockClient((_) async => http.Response('<html>', 200)));
    await expectLater(malformed.get('/'), throwsA(isA<ApiException>()));
    malformed.close();
  });
  test('Return ratios format as percentages and zero is not missing', () {
    expect(percent(.05), '5.00%');
    expect(percent(0), '0.00%');
    expect(percent(null), 'Unavailable');
    expect(Returns.fromJson({'absoluteReturn': '0.05'}).absolute, .05);
  });
  test('File validation and duplicate mappings block invalid imports', () {
    expect(ImportRepository.validateFile('sample.xls', 100), isNotNull);
    expect(ImportRepository.validateFile('sample.xlsx', 51 * 1024 * 1024), isNotNull);
    expect(ImportRepository.validateFile('sample.xlsx', 100), isNull);
    final sheet = ImportSheet.fromJson({'sheetName':'NAV', 'datasetType':'NAV_HISTORY', 'rowCount':1,
      'rawRows': [[10, '2026-01-01']], 'mappings': [
        {'excelColumn':'NAV','targetField':'nav'}, {'excelColumn':'Date','targetField':'nav_date'}]});
    expect(sheet.validation, isNull);
    sheet.mappings[1].target = 'nav';
    expect(sheet.validation, isNotNull);
  });
}
