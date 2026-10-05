import type { DbClient } from "../../db.js";
import {
  annualizedVolatility,
  computeMonthlyReturns,
  computePeriodReturn,
  computeRollingReturns,
  drawdownSeries,
  maxDrawdown,
  parseNavPoints,
  type PeriodCode,
} from "../../lib/analytics.js";
import { requireIsoDate, toJsonNumber } from "../../lib/money.js";
import { requirePlan } from "../funds/repo.js";

type SqlRow = Record<string, unknown>;

async function loadNavRows(
  db: DbClient,
  planId: number,
  range?: { from?: string; to?: string },
): Promise<{ nav_date: Date | string; nav: string }[]> {
  const values: unknown[] = [planId];
  const conditions = ["scheme_plan_id = $1"];
  if (range?.from) {
    values.push(range.from);
    conditions.push(`nav_date >= $${values.length}`);
  }
  if (range?.to) {
    values.push(range.to);
    conditions.push(`nav_date <= $${values.length}`);
  }
  const result = await db.query<{ nav_date: Date | string; nav: string }>(
    `
    SELECT nav_date, nav
    FROM nav_history
    WHERE ${conditions.join(" AND ")}
    ORDER BY nav_date
    `,
    values,
  );
  return result.rows;
}

export async function getLatestNav(db: DbClient, planId: number) {
  await requirePlan(db, planId);
  const result = await db.query<SqlRow>(
    `
    SELECT scheme_plan_id, nav, nav_date
    FROM v_latest_nav
    WHERE scheme_plan_id = $1
    `,
    [planId],
  );
  const row = result.rows[0];
  if (!row) {
    return {
      planId,
      nav: null,
      navDate: null,
      status: "not_available",
      message: "NAV history not yet loaded",
    };
  }
  return {
    planId,
    nav: toJsonNumber(row.nav as string | null),
    navDate: requireIsoDate(row.nav_date as Date | string),
  };
}

export async function getNavHistory(
  db: DbClient,
  planId: number,
  range: { from?: string; to?: string },
) {
  await requirePlan(db, planId);
  const rows = await loadNavRows(db, planId, range);
  return {
    planId,
    data: rows.map((row) => ({
      date: requireIsoDate(row.nav_date),
      nav: toJsonNumber(row.nav),
    })),
  };
}

export async function getReturns(db: DbClient, planId: number, period: PeriodCode) {
  await requirePlan(db, planId);
  const stored = await db.query<SqlRow>(
    `
    SELECT period, absolute_return, annualized_return, benchmark_return
    FROM return_metrics
    WHERE scheme_plan_id = $1 AND period = $2
    ORDER BY calculation_date DESC
    LIMIT 1
    `,
    [planId, period],
  );
  const storedRow = stored.rows[0];
  if (storedRow) {
    return {
      period,
      absoluteReturn: toJsonNumber(storedRow.absolute_return as string | null),
      annualizedReturn: toJsonNumber(storedRow.annualized_return as string | null),
      benchmarkReturn: toJsonNumber(storedRow.benchmark_return as string | null),
    };
  }

  const points = parseNavPoints(await loadNavRows(db, planId));
  const computed = computePeriodReturn(points, period);
  if (!computed) {
    return {
      period,
      absoluteReturn: null,
      annualizedReturn: null,
      benchmarkReturn: null,
    };
  }
  return {
    period,
    absoluteReturn: toJsonNumber(computed.absoluteReturn),
    annualizedReturn: toJsonNumber(computed.annualizedReturn),
    benchmarkReturn: null,
  };
}

export async function getRollingReturns(
  db: DbClient,
  planId: number,
  period: "1M" | "3M" | "6M",
) {
  await requirePlan(db, planId);
  const stored = await db.query<SqlRow>(
    `
    SELECT observation_date, return_value
    FROM rolling_returns
    WHERE scheme_plan_id = $1 AND rolling_period = $2
    ORDER BY observation_date
    `,
    [planId, period],
  );
  if (stored.rows.length > 0) {
    return {
      rollingPeriod: period,
      data: stored.rows.map((row: any) => ({
        date: requireIsoDate(row.observation_date as Date | string),
        return: toJsonNumber(row.return_value as string | null),
      })),
    };
  }
  const computed = computeRollingReturns(parseNavPoints(await loadNavRows(db, planId)), period);
  return {
    rollingPeriod: period,
    data: computed.map((row) => ({
      date: row.date,
      return: toJsonNumber(row.returnValue),
    })),
  };
}

export async function getDrawdown(db: DbClient, planId: number) {
  await requirePlan(db, planId);
  const points = parseNavPoints(await loadNavRows(db, planId));
  const series = drawdownSeries(points);
  return {
    maxDrawdown: toJsonNumber(maxDrawdown(points)),
    data: series.map((row) => ({
      date: row.date,
      drawdown: toJsonNumber(row.drawdown),
    })),
  };
}

export async function getRiskMetrics(db: DbClient, planId: number, period: PeriodCode) {
  await requirePlan(db, planId);
  const stored = await db.query<SqlRow>(
    `
    SELECT volatility, alpha, beta, sharpe_ratio, sortino_ratio,
           tracking_error, information_ratio, max_drawdown
    FROM risk_metrics
    WHERE scheme_plan_id = $1 AND period = $2
    ORDER BY calculation_date DESC
    LIMIT 1
    `,
    [planId, period],
  );
  const row = stored.rows[0];
  if (row) {
    return {
      period,
      volatility: toJsonNumber(row.volatility as string | null),
      alpha: toJsonNumber(row.alpha as string | null),
      beta: toJsonNumber(row.beta as string | null),
      sharpeRatio: toJsonNumber(row.sharpe_ratio as string | null),
      sortinoRatio: toJsonNumber(row.sortino_ratio as string | null),
      trackingError: toJsonNumber(row.tracking_error as string | null),
      informationRatio: toJsonNumber(row.information_ratio as string | null),
      maxDrawdown: toJsonNumber(row.max_drawdown as string | null),
    };
  }

  const points = parseNavPoints(await loadNavRows(db, planId));
  const computed = computePeriodReturn(points, period);
  if (!computed) {
    return emptyRisk(period);
  }
  const windowPoints = points.filter((point) => point.date >= computed.startDate && point.date <= computed.endDate);
  return {
    period,
    volatility: toJsonNumber(annualizedVolatility(windowPoints)),
    alpha: null,
    beta: null,
    sharpeRatio: null,
    sortinoRatio: null,
    trackingError: null,
    informationRatio: null,
    maxDrawdown: toJsonNumber(maxDrawdown(windowPoints)),
  };
}

export async function getMonthlyReturns(db: DbClient, planId: number) {
  await requirePlan(db, planId);
  try {
    const stored = await db.query<SqlRow>(
      `
      SELECT year, month, monthly_return
      FROM monthly_returns
      WHERE scheme_plan_id = $1
      ORDER BY year DESC, month ASC
      `,
      [planId],
    );

    if (stored.rows.length > 0) {
      const monthlyReturns: Record<string, (number | null)[]> = {};
      for (const row of stored.rows) {
        const year = String(row.year);
        const month = Number(row.month);
        const retVal = toJsonNumber(row.monthly_return as string | null);
        if (!monthlyReturns[year]) {
          monthlyReturns[year] = Array(12).fill(null);
        }
        if (month >= 1 && month <= 12) {
          monthlyReturns[year][month - 1] = retVal;
        }
      }
      return {
        planId,
        monthlyReturns,
      };
    }
  } catch (err) {
    // If monthly_returns table does not exist or fails, fallback to dynamic NAV computation
  }

  const points = parseNavPoints(await loadNavRows(db, planId));
  const computed = computeMonthlyReturns(points);
  return {
    planId,
    monthlyReturns: computed,
  };
}

function emptyRisk(period: PeriodCode) {
  return {
    period,
    volatility: null,
    alpha: null,
    beta: null,
    sharpeRatio: null,
    sortinoRatio: null,
    trackingError: null,
    informationRatio: null,
    maxDrawdown: null,
  };
}

