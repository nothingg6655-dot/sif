import { Decimal } from "decimal.js";
import { describe, expect, it } from "vitest";
import {
  annualizedReturn,
  annualizedVolatility,
  computeMonthlyReturns,
  computePeriodReturn,
  daysBetween,
  maxDrawdown,
  simpleReturn,
  type NavPoint,
} from "./analytics.js";

function nav(date: string, value: number): NavPoint {
  return { date, nav: new Decimal(value) };
}

describe("analytics formulas", () => {
  it("computes simple return from NAV", () => {
    expect(simpleReturn(new Decimal(10), new Decimal(10.5)).toNumber()).toBeCloseTo(0.05);
  });

  it("does not annualize periods shorter than one year", () => {
    expect(annualizedReturn(new Decimal(0.05), "2026-03-01", "2026-06-01")).toBeNull();
  });

  it("annualizes returns of at least 365 days", () => {
    const result = annualizedReturn(new Decimal(0.1), "2025-03-01", "2026-03-01");
    expect(result).not.toBeNull();
    expect(result!.toNumber()).toBeCloseTo(0.1, 5);
  });

  it("computes maximum drawdown", () => {
    const points = [nav("2026-01-01", 10), nav("2026-01-02", 12), nav("2026-01-03", 9)];
    expect(maxDrawdown(points)?.toNumber()).toBeCloseTo(-0.25);
  });

  it("returns null volatility with fewer than 3 NAV points", () => {
    expect(annualizedVolatility([nav("2026-01-01", 10), nav("2026-01-02", 10.1)])).toBeNull();
  });

  it("uses closest NAV on or before a period boundary", () => {
    const points = [
      nav("2026-01-01", 10),
      nav("2026-03-01", 11),
      nav("2026-04-01", 12),
    ];
    const result = computePeriodReturn(points, "1M");
    expect(result?.startDate).toBe("2026-03-01");
    expect(result?.endDate).toBe("2026-04-01");
    expect(result?.absoluteReturn.toNumber()).toBeCloseTo(12 / 11 - 1);
  });

  it("counts calendar days between ISO dates", () => {
    expect(daysBetween("2026-01-01", "2026-01-31")).toBe(30);
  });

  it("computes monthly return matrix across years", () => {
    const points = [
      nav("2026-01-01", 100),
      nav("2026-01-31", 105), // Jan return +5%
      nav("2026-02-28", 110.25), // Feb return +5%
    ];
    const matrix = computeMonthlyReturns(points);
    expect(matrix["2026"]).toBeDefined();
    expect(matrix["2026"]![0]).toBeCloseTo(5.0);
    expect(matrix["2026"]![1]).toBeCloseTo(5.0);
    expect(matrix["2026"]![2]).toBeNull();
  });
});


// Month boundaries must clamp to the target month's final day.
describe('analytics boundaries', () => {
  it('uses February month-end for a March 31 one-month return', () => {
    const result = computePeriodReturn([nav('2026-02-28', 10), nav('2026-03-03', 15), nav('2026-03-31', 20)], '1M');
    expect(result?.startDate).toBe('2026-02-28');
    expect(result?.absoluteReturn.toNumber()).toBe(1);
  });
  it('does not publish a return from a single NAV observation', () => {
    expect(computePeriodReturn([nav('2026-03-01', 10)], 'SINCE_INCEPTION')).toBeNull();
  });
});
