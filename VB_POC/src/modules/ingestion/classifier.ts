export enum DatasetType {
  SCHEME_MASTER = 'SCHEME_MASTER',
  PLAN_MASTER = 'PLAN_MASTER',
  NAV_HISTORY = 'NAV_HISTORY',
  AUM_HISTORY = 'AUM_HISTORY',
  PORTFOLIO_DISCLOSURE = 'PORTFOLIO_DISCLOSURE',
  PORTFOLIO_POSITIONS = 'PORTFOLIO_POSITIONS',
  RISKOMETER = 'RISKOMETER',
  BENCHMARK = 'BENCHMARK',
  BENCHMARK_HISTORY = 'BENCHMARK_HISTORY',
  EXPENSE_RATIO = 'EXPENSE_RATIO',
  PORTFOLIO_TURNOVER = 'PORTFOLIO_TURNOVER',
  DERIVATIVE_EXPOSURE = 'DERIVATIVE_EXPOSURE',
  ASSET_ALLOCATION = 'ASSET_ALLOCATION',
  FUND_MANAGER = 'FUND_MANAGER',
  SYSTEMATIC_PLAN = 'SYSTEMATIC_PLAN',
  LIQUIDITY_RULE = 'LIQUIDITY_RULE',
  TAX_RULE = 'TAX_RULE',
  MONTHLY_RETURN = 'MONTHLY_RETURN',
  UNKNOWN = 'UNKNOWN'
}

export interface ClassificationResult {
  datasetType: DatasetType;
  confidence: number; // 0 to 100
}

export function classifySheet(sheetName: string, headers: string[]): ClassificationResult {
  const normalizedSheetName = sheetName.toLowerCase();
  const normalizedHeaders = headers.map(h => h.toLowerCase());

  // 1. Check NAV_HISTORY
  if (
    normalizedSheetName.includes('nav') ||
    (normalizedHeaders.includes('net asset value') && normalizedHeaders.includes('date')) ||
    (normalizedHeaders.includes('nav') && normalizedHeaders.includes('nav date'))
  ) {
    let confidence = 80;
    if (normalizedSheetName.includes('nav')) confidence += 10;
    if (normalizedHeaders.includes('nav') || normalizedHeaders.includes('net asset value')) confidence += 5;
    if (normalizedHeaders.includes('date') || normalizedHeaders.includes('nav date')) confidence += 5;
    return { datasetType: DatasetType.NAV_HISTORY, confidence: Math.min(confidence, 100) };
  }

  // 2. Check SCHEME_MASTER
  if (
    normalizedSheetName.includes('scheme') ||
    normalizedSheetName.includes('fund details') ||
    (normalizedHeaders.includes('scheme name') && normalizedHeaders.includes('amc'))
  ) {
    let confidence = 80;
    if (normalizedSheetName.includes('scheme') || normalizedSheetName.includes('fund')) confidence += 10;
    if (normalizedHeaders.includes('scheme name')) confidence += 10;
    return { datasetType: DatasetType.SCHEME_MASTER, confidence: Math.min(confidence, 100) };
  }
  
  // 3. Check AUM_HISTORY
  if (
    normalizedSheetName.includes('aum') ||
    (normalizedHeaders.includes('aum') && normalizedHeaders.includes('date')) ||
    (normalizedHeaders.includes('assets under management'))
  ) {
    return { datasetType: DatasetType.AUM_HISTORY, confidence: 95 };
  }

  return { datasetType: DatasetType.UNKNOWN, confidence: 20 };
}
