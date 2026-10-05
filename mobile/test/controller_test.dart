import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sif_mobile/core/network/api_client.dart';
import 'package:sif_mobile/features/funds/data/fund_repository.dart';
import 'package:sif_mobile/features/funds/data/models.dart';
import 'package:sif_mobile/features/funds/fund_controller.dart';

void main() {
  test('Late search responses cannot replace newer results', () async {
    final old = Completer<http.Response>();
    final api = ApiClient('http://localhost', client: MockClient((r) async {
      if (r.url.queryParameters['q'] == 'old') return old.future;
      return http.Response('{"data":[],"page":1,"total":0}', 200);
    }));
    final controller = FundController(FundRepository(api))..query = 'old';
    final first = controller.load();
    controller.query = 'new';
    await controller.load();
    old.complete(http.Response('{"data":[],"page":1,"total":99}', 200));
    await first;
    expect(controller.total, 0);
    expect(controller.loading, isFalse);
    controller.dispose(); api.close();
  });
  test('Comparison selection is unique and capped at five', () {
    final api = ApiClient('http://localhost');
    final state = FundController(FundRepository(api));
    Fund fund(int id) => Fund.fromJson({'schemeId':id, 'schemeName':'Fund $id', 'amc':'AMC'});
    for (var i = 1; i <= 5; i++) { expect(state.toggle(fund(i)), isTrue); }
    expect(state.toggle(fund(6)), isFalse);
    state.toggle(fund(1));
    expect(state.selected.length, 4);
    state.dispose(); api.close();
  });
}
