import '../../../core/network/api_client.dart';

class Fund {
  Fund.fromJson(Json j)
      : id = (j['schemeId'] as num).toInt(), name = j['schemeName'] as String,
        amc = j['amc'] as String? ?? '', category = j['category'] as String?,
        nav = number(j['latestNav']), riskBand = (j['riskBand'] as num?)?.toInt(),
        closingAum = number(j['closingAum']);
  final int id;
  final String name, amc;
  final String? category;
  final double? nav, closingAum;
  final int? riskBand;
}

class FundPage {
  FundPage.fromJson(Json j) : funds = objects(j['data']).map(Fund.fromJson).toList(),
      total = (j['total'] as num).toInt(), page = (j['page'] as num).toInt();
  final List<Fund> funds;
  final int total, page;
}

class Overview {
  Overview.fromJson(Json j) : fund = Fund.fromJson(j), code = j['schemeCode'] as String?,
    objective = j['objective'] as String?, benchmark = j['benchmark'] as String?,
    allotment = j['allotmentDate'] as String?, minimum = number(j['minimumInvestment']),
    additional = number(j['minimumAdditionalInvestment']), exitLoad = j['exitLoad'] as String?,
    custodian = j['custodian'] as String?, registrar = j['registrar'] as String?, auditor = j['auditor'] as String?;
  final Fund fund;
  final String? code, objective, benchmark, allotment, exitLoad, custodian, registrar, auditor;
  final double? minimum, additional;
}

class Plan {
  Plan.fromJson(Json j) : id = (j['planId'] as num).toInt(), type = j['planType'] as String,
    option = j['optionType'] as String, isin = j['isin'] as String?, sifCode = j['sifCode'] as String?, expense = number(j['expenseRatioMax']);
  final int id;
  final String type, option;
  final String? isin, sifCode;
  final double? expense;
  String get label => '$type · $option${sifCode == null ? '' : ' · $sifCode'}';
}

class SeriesPoint {
  const SeriesPoint(this.date, this.value);
  final DateTime date;
  final double value;
  static List<SeriesPoint> parse(Object? rows, String field) => objects(rows)
    .where((j) => DateTime.tryParse('${j['date']}') != null && number(j[field]) != null)
    .map((j) => SeriesPoint(DateTime.parse(j['date'] as String), number(j[field])!)).toList();
}

class Returns {
  Returns.fromJson(Json j) : absolute = number(j['absoluteReturn']), annualized = number(j['annualizedReturn']), benchmark = number(j['benchmarkReturn']);
  final double? absolute, annualized, benchmark;
}

class Risk {
  Risk.fromJson(Json j) : volatility = number(j['volatility']), alpha = number(j['alpha']),
    beta = number(j['beta']), sharpe = number(j['sharpeRatio']), sortino = number(j['sortinoRatio']), drawdown = number(j['maxDrawdown']);
  final double? volatility, alpha, beta, sharpe, sortino, drawdown;
}

class Allocation {
  Allocation.fromJson(Json j, String nameKey, String valueKey) : name = j[nameKey] as String? ?? 'Unclassified', value = number(j[valueKey]);
  final String name;
  final double? value;
}

class FundDetails {
  FundDetails({required this.overview, required this.plans, required this.managers,
    required this.aum, required this.aumUnit, required this.aumDate, required this.holdings,
    required this.sectors, required this.allocation, required this.portfolioDate});
  final Overview overview;
  final List<Plan> plans;
  final List<String> managers;
  final double? aum;
  final String? aumUnit, aumDate, portfolioDate;
  final List<Allocation> holdings, sectors, allocation;
  Plan? get preferred {
    if (plans.isEmpty) return null;
    return plans.firstWhere((p) => p.type.toLowerCase().startsWith('direct') && p.option.toLowerCase().startsWith('growth'), orElse: () => plans.first);
  }
}

class PlanAnalytics {
  PlanAnalytics({required this.nav, required this.navDate, required this.history,
    required this.returns, required this.risk, required this.monthly,
    required this.rolling, required this.drawdown});
  final double? nav;
  final String? navDate;
  final List<SeriesPoint> history, rolling, drawdown;
  final Returns returns;
  final Risk risk;
  final Map<String, List<double?>> monthly;
}

class Comparison {
  Comparison(Json j, Json returns, Json risk) : id = (j['schemeId'] as num).toInt(),
    name = j['schemeName'] as String, category = j['category'] as String?,
    nav = number(j['latestNav']), aum = number(j['aum']), unit = j['aumUnit'] as String?,
    expense = number(j['expenseRatio']), returns = Returns.fromJson(returns), risk = Risk.fromJson(risk);
  final int id;
  final String name;
  final String? category, unit;
  final double? nav, aum, expense;
  final Returns returns;
  final Risk risk;
}
