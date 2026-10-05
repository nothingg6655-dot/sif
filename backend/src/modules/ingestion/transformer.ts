export function normalizeNumber(value: any): number | null {
  if (value === null || value === undefined || value === '') return null;
  if (typeof value === 'number') return value;

  let strVal = String(value).trim();
  if (strVal.toLowerCase() === 'na' || strVal.toLowerCase() === 'n/a' || strVal === '-') {
    return null;
  }

  // Handle percentages, commas, currencies
  strVal = strVal.replace(/[₹$,%\s]/g, '');
  
  // Handle parentheses for negatives
  if (strVal.startsWith('(') && strVal.endsWith(')')) {
    strVal = '-' + strVal.slice(1, -1);
  }

  const num = parseFloat(strVal);
  if (isNaN(num)) return null;

  // Handle Cr / Lakh if present (simple heuristic, could be expanded)
  if (String(value).toLowerCase().includes('cr')) return num * 10000000;
  if (String(value).toLowerCase().includes('lakh')) return num * 100000;

  return num;
}

export function normalizeDate(value: any): string | null {
  if (!value) return null;

  // If it's already a JS Date object (ExcelJS parses some dates this way)
  if (value instanceof Date) {
    if (isNaN(value.getTime())) return null;
    return value.toISOString().split('T')[0]!;
  }

  if (typeof value === 'number') {
    // Excel Serial Date (days since 1900-01-01)
    const excelEpoch = new Date(1899, 11, 30); // Excel has a bug with leap year 1900
    const jsDate = new Date(excelEpoch.getTime() + value * 86400000);
    return jsDate.toISOString().split('T')[0]!;
  }

  // If string, try to parse common formats
  const strVal = String(value).trim();
  
  // Try DD-MM-YYYY or DD/MM/YYYY
  const dmMatch = strVal.match(/^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$/);
  if (dmMatch) {
    const [_, d, m, y] = dmMatch;
    const date = new Date(Number(y), Number(m) - 1, Number(d));
    if (!isNaN(date.getTime())) return date.toISOString().split('T')[0]!;
  }

  // Try standard Date parsing for "31-Aug-2026"
  const date = new Date(strVal);
  if (!isNaN(date.getTime())) return date.toISOString().split('T')[0]!;

  return null;
}

export function normalizeText(value: any): string | null {
  if (value === null || value === undefined) return null;
  const strVal = String(value).trim();
  if (strVal === '') return null;
  
  // Remove accidental line breaks and extra spaces
  let cleaned = strVal.replace(/\s+/g, ' ');
  
  // Strip trailing "Plan" and "Option"
  if (cleaned.toLowerCase().endsWith(' plan') && cleaned.length > 5) {
    cleaned = cleaned.slice(0, -5).trim();
  }
  if (cleaned.toLowerCase().endsWith(' option') && cleaned.length > 7) {
    cleaned = cleaned.slice(0, -7).trim();
  }
  
  return cleaned;
}

export function normalizeProvider(provider: any): string | null {
  if (!provider) return null;
  const str = normalizeText(provider)?.toUpperCase() || '';
  if (str.includes('QSIF') || str.includes('Q-SIF')) return 'QSIF';
  if (str.includes('DYNASIF') || str.includes('DYNA SIF')) return 'DYNASIF';
  if (str.includes('ISIF') || str.includes('I-SIF')) return 'ISIF';
  return str;
}

export function normalizeSchemeName(scheme: any): string | null {
  return normalizeText(scheme);
}

export function normalizePlanType(plan: any): string | null {
  if (!plan) return null;
  let cleaned = normalizeText(plan);
  if (cleaned && cleaned.toLowerCase() === 'direct plan') return 'Direct';
  if (cleaned && cleaned.toLowerCase() === 'regular plan') return 'Regular';
  return cleaned;
}

export function normalizeOptionType(option: any): string | null {
  if (!option) return null;
  let cleaned = normalizeText(option);
  if (cleaned && cleaned.toLowerCase() === 'idcw option') return 'IDCW';
  if (cleaned && cleaned.toLowerCase() === 'growth option') return 'Growth';
  return cleaned;
}
