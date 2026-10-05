import { Decimal } from "decimal.js";
import { toDecimal } from "./money.js";

export const TRADING_DAYS = 252;
export const CAGR_MIN_DAYS = 365;

export type NavPoint = {
  date: string;
  nav: Decimal;
};

export type PeriodCode = "1M" | "3M" | "6M" | "1Y" | "SINCE_INCEPTION";

const PERIOD_MONTHS: Record<Exclude<PeriodCode, "SINCE_INCEPTION">, number> = {
  "1M": 1,
  "3M": 3,
  "6M": 6,
  "1Y": 12,
};

export function addMonths(isoDate: string, months: number): string {
  const [yearText, monthText, dayText] = isoDate.split("-");
  const year = Number(yearText);
  const month = Number(monthText);
  const day = Number(dayText);
  const utc = new Date(Date.UTC(year, month - 1 + months, 1));
  const lastDay = new Date(Date.UTC(utc.getUTCFullYear(), utc.getUTCMonth() + 1, 0)).getUTCDate();
  utc.setUTCDate(Math.min(day, lastDay));
  return utc.toISOString().slice(0, 10);
}

export function subtractMonths(isoDate: string, months: number): string {
  return addMonths(isoDate, -months);
}

export function daysBetween(fromIso: string, toIso: string): number {
  const from = Date.parse(`${fromIso}T00:00:00Z`);
  const to = Date.parse(`${toIso}T00:00:00Z`);
  return Math.round((to - from) / 86_400_000);
}

export function closestOnOrBefore(points: NavPoint[], targetDate: string): NavPoint | null {
  let match: NavPoint | null = null;
  for (const point of points) {
    if (point.date <= targetDate) {
      match = point;
    } else {
      break;
    }
  }
  return match;
}

export function simpleReturn(startNav: Decimal, endNav: Decimal): Decimal {
  if (startNav.lte(0)) {
    throw new Error("Starting NAV must be greater than zero");
  }
  return endNav.div(startNav).minus(1);
}

export function annualizedReturn(absolute: Decimal, startDate: string, endDate: string): Decimal | null {
  const days = daysBetween(startDate, endDate);
  if (days < CAGR_MIN_DAYS) {
    return null;
  }
  return absolute.plus(1).pow(365 / days).minus(1);
}

export function dailyReturns(points: NavPoint[]): Decimal[] {
  const result: Decimal[] = [];
  for (let i = 1; i < points.length; i += 1) {
    const previous = points[i - 1];
    const current = points[i];
    if (!previous || !current || previous.nav.lte(0)) {
      continue;
    }
    result.push(current.nav.div(previous.nav).minus(1));
  }
  return result;
}

export function sampleStdDev(values: Decimal[]): Decimal | null {
  if (values.length < 2) {
    return null;
  }
  const n = new Decimal(values.length);
  const mean = values.reduce((sum, value) => sum.plus(value), new Decimal(0)).div(n);
  const variance = values
    .reduce((sum, value) => sum.plus(value.minus(mean).pow(2)), new Decimal(0))
    .div(n.minus(1));
  return variance.sqrt();
}

export function annualizedVolatility(points: NavPoint[]): Decimal | null {
  const returns = dailyReturns(points);
  const std = sampleStdDev(returns);
  if (std === null) {
    return null;
  }
  return std.times(Math.sqrt(TRADING_DAYS));
}

export function drawdownSeries(points: NavPoint[]): { date: string; drawdown: Decimal }[] {
  let peak = new Decimal(0);
  return points.map((point) => {
    if (point.nav.gt(peak)) {
      peak = point.nav;
    }
    const drawdown = peak.gt(0) ? point.nav.div(peak).minus(1) : new Decimal(0);
    return { date: point.date, drawdown };
  });
}

export function maxDrawdown(points: NavPoint[]): Decimal | null {
  const series = drawdownSeries(points);
  if (series.length === 0) {
    return null;
  }
  return series.reduce((min, point) => (point.drawdown.lt(min) ? point.drawdown : min), series[0]!.drawdown);
}

export function periodWindow(
  points: NavPoint[],
  period: PeriodCode,
): { start: NavPoint; end: NavPoint } | null {
  if (points.length < 2) {
    return null;
  }
  const end = points[points.length - 1];
  if (!end) {
    return null;
  }
  if (period === "SINCE_INCEPTION") {
    const start = points[0];
    if (!start) {
      return null;
    }
    return { start, end };
  }
  const target = subtractMonths(end.date, PERIOD_MONTHS[period]);
  const start = closestOnOrBefore(points, target);
  if (!start) {
    return null;
  }
  return { start, end };
}

export function computePeriodReturn(
  points: NavPoint[],
  period: PeriodCode,
): {
  absoluteReturn: Decimal;
  annualizedReturn: Decimal | null;
  startDate: string;
  endDate: string;
} | null {
  const window = periodWindow(points, period);
  if (!window) {
    return null;
  }
  const absolute = simpleReturn(window.start.nav, window.end.nav);
  return {
    absoluteReturn: absolute,
    annualizedReturn: annualizedReturn(absolute, window.start.date, window.end.date),
    startDate: window.start.date,
    endDate: window.end.date,
  };
}

export function computeRollingReturns(
  points: NavPoint[],
  period: Exclude<PeriodCode, "SINCE_INCEPTION" | "1Y">,
): { date: string; returnValue: Decimal }[] {
  const months = PERIOD_MONTHS[period];
  const result: { date: string; returnValue: Decimal }[] = [];
  for (const end of points) {
    const start = closestOnOrBefore(points, subtractMonths(end.date, months));
    if (!start || start.date === end.date) {
      continue;
    }
    result.push({
      date: end.date,
      returnValue: simpleReturn(start.nav, end.nav),
    });
  }
  return result;
}

export function computeMonthlyReturns(
  points: NavPoint[],
): Record<string, (number | null)[]> {
  if (points.length < 2) return {};

  const monthMap = new Map<string, NavPoint[]>();
  for (const point of points) {
    const ym = point.date.slice(0, 7);
    if (!monthMap.has(ym)) {
      monthMap.set(ym, []);
    }
    monthMap.get(ym)!.push(point);
  }

  const sortedYM = Array.from(monthMap.keys()).sort();
  const result: Record<string, (number | null)[]> = {};

  for (let i = 0; i < sortedYM.length; i += 1) {
    const currentYM = sortedYM[i]!;
    const [yearStr, monthStr] = currentYM.split("-");
    const year = yearStr!;
    const monthIdx = Number(monthStr) - 1;

    const currentMonthPoints = monthMap.get(currentYM)!;
    const endNav = currentMonthPoints[currentMonthPoints.length - 1]!.nav;

    let startNav: Decimal | null = null;
    if (i > 0) {
      const prevYM = sortedYM[i - 1]!;
      const prevPoints = monthMap.get(prevYM)!;
      startNav = prevPoints[prevPoints.length - 1]!.nav;
    } else {
      startNav = currentMonthPoints[0]!.nav;
    }

    if (startNav && startNav.gt(0)) {
      const retDecimal = endNav.div(startNav).minus(1).times(100);
      const retVal = Number(retDecimal.toFixed(2));

      if (!result[year]) {
        result[year] = Array(12).fill(null);
      }
      result[year]![monthIdx] = retVal;
    }
  }

  return result;
}

export function parseNavPoints(
  rows: { nav_date: Date | string; nav: string | number }[],
): NavPoint[] {
  const points: NavPoint[] = [];
  for (const row of rows) {
    const date = typeof row.nav_date === "string" ? row.nav_date.slice(0, 10) : row.nav_date.toISOString().slice(0, 10);
    const nav = toDecimal(row.nav);
    if (nav && nav.gt(0)) {
      points.push({ date, nav });
    }
  }
  return points.sort((a, b) => a.date.localeCompare(b.date));
}

