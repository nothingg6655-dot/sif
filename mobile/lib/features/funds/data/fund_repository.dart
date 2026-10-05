import '../../../core/network/api_client.dart';
import 'models.dart';

class FundRepository {
  FundRepository(this.api);
  final ApiClient api;
  Future<FundPage> list({String query = '', String? category, int page = 1}) async =>
    FundPage.fromJson(await api.get('/api/funds', query: {
      'page': '$page', 'limit': '20', if (query.trim().isNotEmpty) 'q': query.trim(),
      if (category != null && category.isNotEmpty) 'category': category,
    }));

  Future<FundDetails> details(int id) async {
    final paths = ['', '/plans', '/managers', '/aum/latest', '/top-holdings', '/sectors', '/asset-allocation'];
    final data = await Future.wait(paths.map((p) => api.get('/api/funds/$id$p')));
    return FundDetails(overview: Overview.fromJson(data[0]),
      plans: objects(data[1]['plans']).map(Plan.fromJson).toList(),
      managers: objects(data[2]['managers']).map((m) => m['name'] as String).toList(),
      aum: number(data[3]['closingAum']), aumUnit: data[3]['unit'] as String?, aumDate: data[3]['reportDate'] as String?,
      holdings: objects(data[4]['holdings']).map((j) => Allocation.fromJson(j, 'securityName', 'navPercentage')).toList(),
      sectors: objects(data[5]['sectors']).map((j) => Allocation.fromJson(j, 'sector', 'allocationPercentage')).toList(),
      allocation: objects(data[6]['allocation']).map((j) => Allocation.fromJson(j, 'assetClass', 'allocationPercentage')).toList(),
      portfolioDate: data[4]['reportDate'] as String?);
  }

  Future<PlanAnalytics> analytics(int plan, String period) async {
    final prefix = '/api/plans/$plan';
    final data = await Future.wait([
      api.get('$prefix/nav/latest'), api.get('$prefix/nav/history'),
      api.get('$prefix/returns', query: {'period': period}),
      api.get('$prefix/risk-metrics', query: {'period': period}),
      api.get('$prefix/monthly-returns'),
      api.get('$prefix/rolling-returns', query: {'period': '3M'}), api.get('$prefix/drawdown'),
    ]);
    return PlanAnalytics(nav: number(data[0]['nav']), navDate: data[0]['navDate'] as String?,
      history: SeriesPoint.parse(data[1]['data'], 'nav'), returns: Returns.fromJson(data[2]), risk: Risk.fromJson(data[3]),
      monthly: object(data[4]['monthlyReturns'] ?? {}).map((k, v) => MapEntry(k, (v as List).map(number).toList())),
      rolling: SeriesPoint.parse(data[5]['data'], 'return'), drawdown: SeriesPoint.parse(data[6]['data'], 'drawdown'));
  }

  Future<List<Comparison>> compare(List<int> ids, String period) async {
    if (ids.isEmpty || ids.length > 5) throw const ApiException('Choose between one and five funds.');
    final data = await Future.wait([
      api.get('/api/funds/compare', query: {'ids': ids.join(',')}),
      api.get('/api/funds/compare/returns', query: {'ids': ids.join(','), 'period': period}),
      api.get('/api/funds/compare/risk', query: {'ids': ids.join(','), 'period': period}),
    ]);
    Json find(Json response, Object? id) => objects(response['funds']).firstWhere((j) => j['schemeId'] == id, orElse: () => {});
    return objects(data[0]['funds']).map((j) => Comparison(j, find(data[1], j['schemeId']), find(data[2], j['schemeId']))).toList();
  }

  Future<Map<String, List<double?>>> schemeMonthlyReturns(int schemeId) async {
    try {
      final res = await api.get('/api/funds/$schemeId/monthly-returns');
      return object(res['monthlyReturns'] ?? {}).map((k, v) => MapEntry(k, (v as List).map(number).toList()));
    } catch (_) {
      return {};
    }
  }

  Future<List<Plan>> fundPlans(int schemeId) async {
    try {
      final res = await api.get('/api/funds/$schemeId/plans');
      return objects(res['plans']).map(Plan.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SeriesPoint>> planNavHistory(int planId) async {
    try {
      final res = await api.get('/api/plans/$planId/nav/history');
      return SeriesPoint.parse(res['data'], 'nav');
    } catch (_) {
      return [];
    }
  }

  Future<List<SeriesPoint>> planRollingReturns(int planId, {String period = '1M'}) async {
    try {
      final res = await api.get('/api/plans/$planId/rolling-returns', query: {'period': period});
      return SeriesPoint.parse(res['data'], 'return');
    } catch (_) {
      return [];
    }
  }
}
