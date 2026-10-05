import { Decimal } from "decimal.js";
import type { DbClient } from "../../db.js";
import {
  annualizedVolatility,
  computePeriodReturn,
  computeRollingReturns,
  maxDrawdown,
  parseNavPoints,
  type PeriodCode,
} from "../../lib/analytics.js";
import { toDecimal } from "../../lib/money.js";
import { requireScheme } from "../funds/repo.js";

const PERIODS: PeriodCode[] = ["1M", "3M", "6M", "1Y", "SINCE_INCEPTION"];
const ROLLING: Array<"1M" | "3M" | "6M"> = ["1M", "3M", "6M"];

export async function recalculateReturns(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const plans = await db.query<{ id: string }>("SELECT id FROM scheme_plans WHERE scheme_id = $1", [schemeId]);
  let written = 0;
  for (const plan of plans.rows) {
    const planId = Number(plan.id);
    const navRows = await db.query<{ nav_date: Date | string; nav: string }>(
      "SELECT nav_date, nav FROM nav_history WHERE scheme_plan_id = $1 ORDER BY nav_date",
      [planId],
    );
    const points = parseNavPoints(navRows.rows);
    if (points.length === 0) {
      continue;
    }
    const asOf = points[points.length - 1]!.date;
    for (const period of PERIODS) {
      const computed = computePeriodReturn(points, period);
      await db.query(
        `
        INSERT INTO return_metrics (
          scheme_plan_id, calculation_date, period, absolute_return, annualized_return, benchmark_return, methodology_version
        ) VALUES ($1, $2, $3, $4, $5, NULL, 'v1')
        ON CONFLICT (scheme_plan_id, calculation_date, period, methodology_version)
        DO UPDATE SET
          absolute_return = EXCLUDED.absolute_return,
          annualized_return = EXCLUDED.annualized_return,
          benchmark_return = NULL
        `,
        [
          planId,
          asOf,
          period,
          computed ? computed.absoluteReturn.toString() : null,
          computed?.annualizedReturn ? computed.annualizedReturn.toString() : null,
        ],
      );
      written += 1;
    }
    for (const period of ROLLING) {
      const series = computeRollingReturns(points, period);
      for (const point of series) {
        await db.query(
          `
          INSERT INTO rolling_returns (
            scheme_plan_id, observation_date, rolling_period, return_value, benchmark_return, methodology_version
          ) VALUES ($1, $2, $3, $4, NULL, 'v1')
          ON CONFLICT (scheme_plan_id, observation_date, rolling_period, methodology_version)
          DO UPDATE SET return_value = EXCLUDED.return_value, benchmark_return = NULL
          `,
          [planId, point.date, period, point.returnValue.toString()],
        );
        written += 1;
      }
    }
  }
  return { schemeId, metricRowsWritten: written };
}

export async function recalculateRisk(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const plans = await db.query<{ id: string }>("SELECT id FROM scheme_plans WHERE scheme_id = $1", [schemeId]);
  let written = 0;
  for (const plan of plans.rows) {
    const planId = Number(plan.id);
    const navRows = await db.query<{ nav_date: Date | string; nav: string }>(
      "SELECT nav_date, nav FROM nav_history WHERE scheme_plan_id = $1 ORDER BY nav_date",
      [planId],
    );
    const points = parseNavPoints(navRows.rows);
    if (points.length === 0) {
      continue;
    }
    const asOf = points[points.length - 1]!.date;
    for (const period of PERIODS) {
      const computed = computePeriodReturn(points, period);
      const windowPoints = computed
        ? points.filter((point) => point.date >= computed.startDate && point.date <= computed.endDate)
        : [];
      await db.query(
        `
        INSERT INTO risk_metrics (
          scheme_plan_id, calculation_date, period,
          volatility, alpha, beta, sharpe_ratio, sortino_ratio,
          tracking_error, information_ratio, max_drawdown, methodology_version
        ) VALUES ($1, $2, $3, $4, NULL, NULL, NULL, NULL, NULL, NULL, $5, 'v1_daily_252')
        ON CONFLICT (scheme_plan_id, calculation_date, period, methodology_version)
        DO UPDATE SET
          volatility = EXCLUDED.volatility,
          alpha = NULL,
          beta = NULL,
          sharpe_ratio = NULL,
          sortino_ratio = NULL,
          tracking_error = NULL,
          information_ratio = NULL,
          max_drawdown = EXCLUDED.max_drawdown
        `,
        [
          planId,
          asOf,
          period,
          annualizedVolatility(windowPoints)?.toString() ?? null,
          maxDrawdown(windowPoints)?.toString() ?? null,
        ],
      );
      written += 1;
    }
  }
  return { schemeId, metricRowsWritten: written };
}

export async function recalculatePortfolio(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const disclosures = await db.query<{ id: string; report_date: Date | string }>(
    "SELECT id, report_date FROM portfolio_disclosures WHERE scheme_id = $1 ORDER BY report_date",
    [schemeId],
  );
  let written = 0;
  for (const disclosure of disclosures.rows) {
    const positions = await db.query<{
      position_side: string;
      exposure_percentage: string | null;
      nav_percentage: string | null;
      asset_class: string | null;
      derivative_type: string | null;
      instrument_type: string | null;
    }>(
      `
      SELECT position_side, exposure_percentage, nav_percentage, asset_class, derivative_type, instrument_type
      FROM portfolio_positions
      WHERE disclosure_id = $1
      `,
      [disclosure.id],
    );

    let longExp = new Decimal(0);
    let shortExp = new Decimal(0);
    let derivativeExp = new Decimal(0);
    const byAsset = new Map<string, Decimal>();

    for (const position of positions.rows) {
      const exposure = toDecimal(position.exposure_percentage) ?? toDecimal(position.nav_percentage);
      if (!exposure) {
        continue;
      }
      if (position.position_side === "SHORT") {
        shortExp = shortExp.plus(exposure.abs());
      } else if (position.position_side === "LONG") {
        longExp = longExp.plus(exposure);
      }
      if (position.derivative_type || /future|option|derivative/i.test(position.instrument_type ?? "")) {
        derivativeExp = derivativeExp.plus(exposure.abs());
      }
      if (position.asset_class) {
        const current = byAsset.get(position.asset_class) ?? new Decimal(0);
        byAsset.set(position.asset_class, current.plus(toDecimal(position.nav_percentage) ?? new Decimal(0)));
      }
    }

    await db.query(
      `
      INSERT INTO scheme_exposure_history (
        scheme_id, report_date, long_exposure, short_exposure, gross_exposure, net_exposure,
        derivative_exposure, source_type, calculation_method
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, 'CALCULATED', 'sum of position exposure/nav percentages')
      ON CONFLICT (scheme_id, report_date, source_type)
      DO UPDATE SET
        long_exposure = EXCLUDED.long_exposure,
        short_exposure = EXCLUDED.short_exposure,
        gross_exposure = EXCLUDED.gross_exposure,
        net_exposure = EXCLUDED.net_exposure,
        derivative_exposure = EXCLUDED.derivative_exposure,
        calculation_method = EXCLUDED.calculation_method
      `,
      [
        schemeId,
        disclosure.report_date,
        longExp.toString(),
        shortExp.toString(),
        longExp.plus(shortExp).toString(),
        longExp.minus(shortExp).toString(),
        derivativeExp.toString(),
      ],
    );
    written += 1;
  }
  return { schemeId, exposureRowsWritten: written };
}
