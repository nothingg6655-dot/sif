import type { DbClient } from "../../db.js";
import { notFound } from "../../errors.js";
import { requireIsoDate, toJsonNumber } from "../../lib/money.js";

type SqlRow = Record<string, unknown>;

async function query<T extends SqlRow>(db: DbClient, text: string, values: unknown[] = []): Promise<T[]> {
  const result = await db.query<T>(text, values);
  return result.rows;
}

export async function requireScheme(db: DbClient, schemeId: number): Promise<void> {
  const rows = await query<{ id: string }>(db, "SELECT id FROM schemes WHERE id = $1", [schemeId]);
  if (rows.length === 0) {
    throw notFound("SCHEME_NOT_FOUND", "The requested scheme does not exist.");
  }
}

export async function requirePlan(db: DbClient, planId: number): Promise<{ scheme_id: string }> {
  const rows = await query<{ scheme_id: string }>(db, "SELECT scheme_id FROM scheme_plans WHERE id = $1", [planId]);
  const row = rows[0];
  if (!row) {
    throw notFound("PLAN_NOT_FOUND", "The requested plan does not exist.");
  }
  return row;
}

export async function listFunds(
  db: DbClient,
  filters: { q?: string; category?: string; amcId?: number; page: number; limit: number },
) {
  const conditions: string[] = ["s.is_active = TRUE"];
  const values: unknown[] = [];
  let i = 1;

  if (filters.q) {
    conditions.push(
      `(s.scheme_name ILIKE $${i} OR s.category ILIKE $${i} OR a.name ILIKE $${i} OR s.scheme_code ILIKE $${i} OR EXISTS (
          SELECT 1 FROM scheme_plans p
          WHERE p.scheme_id = s.id
            AND (p.sif_code ILIKE $${i} OR p.isin_primary ILIKE $${i} OR p.isin_reinvestment ILIKE $${i})
        ))`,
    );
    values.push(`%${filters.q}%`);
    i += 1;
  }
  if (filters.category) {
    conditions.push(`s.category = $${i}`);
    values.push(filters.category);
    i += 1;
  }
  if (filters.amcId) {
    conditions.push(`s.amc_id = $${i}`);
    values.push(filters.amcId);
    i += 1;
  }

  const where = conditions.join(" AND ");
  const offset = (filters.page - 1) * filters.limit;
  values.push(filters.limit, offset);

  const rows = await query<SqlRow>(
    db,
    `
    SELECT
      s.id AS scheme_id,
      s.scheme_name,
      s.category,
      a.name AS amc,
      (
        SELECT r.risk_band
        FROM scheme_risk_history r
        WHERE r.scheme_id = s.id
        ORDER BY r.effective_date DESC NULLS LAST, r.id DESC
        LIMIT 1
      ) AS risk_band,
      (
        SELECT n.nav
        FROM v_latest_nav n
        JOIN scheme_plans p ON p.id = n.scheme_plan_id
        WHERE p.scheme_id = s.id
        ORDER BY
          CASE WHEN p.plan_type ILIKE 'Direct%' AND p.option_type ILIKE 'Growth%' THEN 0 ELSE 1 END,
          p.id
        LIMIT 1
      ) AS latest_nav,
      (
        SELECT la.closing_aum
        FROM v_latest_aum la
        WHERE la.scheme_id = s.id
        LIMIT 1
      ) AS closing_aum,
      COUNT(*) OVER() AS total
    FROM schemes s
    JOIN amcs a ON a.id = s.amc_id
    WHERE ${where}
    ORDER BY s.scheme_name
    LIMIT $${i} OFFSET $${i + 1}
    `,
    values,
  );

  const total = rows.length ? Number(rows[0]!.total) : Number((await query<{ total: string }>(
    db, `SELECT COUNT(*) AS total FROM schemes s JOIN amcs a ON a.id = s.amc_id WHERE ${where}`,
    values.slice(0, -2),
  ))[0]!.total);
  return {
    data: rows.map((row) => ({
      schemeId: Number(row.scheme_id),
      schemeName: String(row.scheme_name),
      category: row.category === null ? null : String(row.category),
      amc: String(row.amc),
      riskBand: row.risk_band === null ? null : Number(row.risk_band),
      latestNav: toJsonNumber(row.latest_nav as string | null),
      closingAum: toJsonNumber(row.closing_aum as string | null),
    })),
    page: filters.page,
    limit: filters.limit,
    total,
  };
}

export async function getFundOverview(db: DbClient, schemeId: number) {
  const rows = await query<SqlRow>(
    db,
    `
    SELECT
      s.id,
      s.scheme_name,
      s.scheme_code,
      s.category,
      s.fund_type,
      s.investment_objective,
      a.name AS amc,
      b.benchmark_name,
      s.allotment_date,
      s.minimum_investment,
      s.minimum_additional_investment,
      s.exit_load,
      s.custodian,
      s.auditor,
      s.registrar,
      (
        SELECT r.risk_band
        FROM scheme_risk_history r
        WHERE r.scheme_id = s.id
        ORDER BY r.effective_date DESC NULLS LAST, r.id DESC
        LIMIT 1
      ) AS risk_band
    FROM schemes s
    JOIN amcs a ON a.id = s.amc_id
    LEFT JOIN benchmarks b ON b.id = s.benchmark_id
    WHERE s.id = $1
    `,
    [schemeId],
  );
  const row = rows[0];
  if (!row) {
    throw notFound("SCHEME_NOT_FOUND", "The requested scheme does not exist.");
  }
  return {
    schemeId: Number(row.id),
    schemeName: String(row.scheme_name),
    schemeCode: row.scheme_code === null ? null : String(row.scheme_code),
    category: row.category === null ? null : String(row.category),
    fundType: row.fund_type === null ? null : String(row.fund_type),
    objective: row.investment_objective === null ? null : String(row.investment_objective),
    amc: String(row.amc),
    benchmark: row.benchmark_name === null ? null : String(row.benchmark_name),
    allotmentDate: toIso(row.allotment_date),
    minimumInvestment: toJsonNumber(row.minimum_investment as string | null),
    minimumAdditionalInvestment: toJsonNumber(row.minimum_additional_investment as string | null),
    exitLoad: row.exit_load === null ? null : String(row.exit_load),
    custodian: row.custodian === null ? null : String(row.custodian),
    auditor: row.auditor === null ? null : String(row.auditor),
    registrar: row.registrar === null ? null : String(row.registrar),
    riskBand: row.risk_band === null ? null : Number(row.risk_band),
  };
}

function toIso(value: unknown): string | null {
  if (value === null || value === undefined) {
    return null;
  }
  if (value instanceof Date) {
    return value.toISOString().slice(0, 10);
  }
  return String(value).slice(0, 10);
}

export async function getFundPlans(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const rows = await query<SqlRow>(
    db,
    `
    SELECT id, sif_code, plan_type, option_type, isin_primary, expense_ratio_max
    FROM scheme_plans
    WHERE scheme_id = $1 AND is_active = TRUE
    ORDER BY plan_type, option_type
    `,
    [schemeId],
  );
  return {
    schemeId,
    plans: rows.map((row) => ({
      planId: Number(row.id),
      sifCode: row.sif_code === null ? null : String(row.sif_code),
      planType: String(row.plan_type),
      optionType: String(row.option_type),
      isin: row.isin_primary === null ? null : String(row.isin_primary),
      expenseRatioMax: toJsonNumber(row.expense_ratio_max as string | null),
    })),
  };
}

export async function getFundManagers(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const rows = await query<SqlRow>(
    db,
    `
    SELECT fm.manager_name, sfm.manager_role, sfm.from_date, sfm.to_date
    FROM scheme_fund_managers sfm
    JOIN fund_managers fm ON fm.id = sfm.fund_manager_id
    WHERE sfm.scheme_id = $1
    ORDER BY sfm.from_date, fm.manager_name
    `,
    [schemeId],
  );
  return {
    schemeId,
    managers: rows.map((row) => ({
      name: String(row.manager_name),
      role: row.manager_role === null ? null : String(row.manager_role),
      fromDate: toIso(row.from_date),
      toDate: toIso(row.to_date),
    })),
  };
}

export async function getFundRisk(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const rows = await query<SqlRow>(
    db,
    `
    SELECT effective_date, risk_band
    FROM scheme_risk_history
    WHERE scheme_id = $1
    ORDER BY effective_date
    `,
    [schemeId],
  );
  const latest = rows[rows.length - 1];
  return {
    currentRiskBand: latest ? Number(latest.risk_band) : null,
    history: rows.map((row) => ({
      effectiveDate: toIso(row.effective_date),
      riskBand: Number(row.risk_band),
    })),
  };
}

export async function getAllocationLimits(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const rows = await query<SqlRow>(
    db,
    `
    SELECT asset_class, min_percentage, max_percentage
    FROM scheme_asset_allocation_limits
    WHERE scheme_id = $1
      AND (effective_to IS NULL OR effective_to >= CURRENT_DATE)
    ORDER BY min_percentage DESC, asset_class
    `,
    [schemeId],
  );
  return {
    limits: rows.map((row) => ({
      assetClass: String(row.asset_class),
      minPercentage: toJsonNumber(row.min_percentage as string),
      maxPercentage: toJsonNumber(row.max_percentage as string),
    })),
  };
}

export async function getLatestAum(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const rows = await query<SqlRow>(
    db,
    `
    SELECT report_date, period_type, closing_aum, average_aum, unit
    FROM v_latest_aum
    WHERE scheme_id = $1
    `,
    [schemeId],
  );
  const row = rows[0];
  if (!row) {
    return {
      status: "not_available",
      message: "AUM data not yet loaded",
    };
  }
  return {
    reportDate: requireIsoDate(row.report_date as Date | string),
    periodType: String(row.period_type),
    closingAum: toJsonNumber(row.closing_aum as string | null),
    averageAum: toJsonNumber(row.average_aum as string | null),
    unit: String(row.unit),
  };
}

export async function getAumHistory(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const rows = await query<SqlRow>(
    db,
    `
    SELECT report_date, average_aum, closing_aum, unit, period_type
    FROM aum_history
    WHERE scheme_id = $1
    ORDER BY report_date
    `,
    [schemeId],
  );
  return {
    data: rows.map((row) => ({
      reportDate: requireIsoDate(row.report_date as Date | string),
      averageAum: toJsonNumber(row.average_aum as string | null),
      closingAum: toJsonNumber(row.closing_aum as string | null),
      unit: String(row.unit),
      periodType: String(row.period_type),
    })),
  };
}

export async function getBenchmark(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const head = await query<SqlRow>(
    db,
    `
    SELECT b.id, b.benchmark_name
    FROM schemes s
    JOIN benchmarks b ON b.id = s.benchmark_id
    WHERE s.id = $1
    `,
    [schemeId],
  );
  const benchmark = head[0];
  if (!benchmark) {
    return { benchmarkName: null, components: [] };
  }
  const components = await query<SqlRow>(
    db,
    `
    SELECT c.benchmark_name, bc.weight_percentage
    FROM benchmark_components bc
    JOIN benchmarks c ON c.id = bc.component_benchmark_id
    WHERE bc.composite_benchmark_id = $1
      AND (bc.effective_to IS NULL OR bc.effective_to >= CURRENT_DATE)
    ORDER BY bc.weight_percentage DESC
    `,
    [benchmark.id],
  );
  return {
    benchmarkId: Number(benchmark.id),
    benchmarkName: String(benchmark.benchmark_name),
    components: components.map((row) => ({
      name: String(row.benchmark_name),
      weight: toJsonNumber(row.weight_percentage as string),
    })),
  };
}

export async function getCompositeBenchmarkHistory(
  db: DbClient,
  schemeId: number,
  range: { from?: string; to?: string },
) {
  await requireScheme(db, schemeId);
  const values: unknown[] = [schemeId];
  const conditions = ["s.id = $1"];
  if (range.from) {
    values.push(range.from);
    conditions.push(`cbv.value_date >= $${values.length}`);
  }
  if (range.to) {
    values.push(range.to);
    conditions.push(`cbv.value_date <= $${values.length}`);
  }
  const rows = await query<SqlRow>(
    db,
    `
    SELECT cbv.value_date, cbv.index_value, cbv.daily_return
    FROM schemes s
    JOIN composite_benchmark_values cbv ON cbv.benchmark_id = s.benchmark_id
    WHERE ${conditions.join(" AND ")}
    ORDER BY cbv.value_date
    `,
    values,
  );
  return {
    data: rows.map((row) => ({
      date: requireIsoDate(row.value_date as Date | string),
      indexValue: toJsonNumber(row.index_value as string | null),
      dailyReturn: toJsonNumber(row.daily_return as string | null),
    })),
  };
}

export async function getBenchmarkHistory(
  db: DbClient,
  benchmarkId: number,
  range: { from?: string; to?: string },
) {
  const exists = await query<{ id: string }>(db, "SELECT id FROM benchmarks WHERE id = $1", [benchmarkId]);
  if (exists.length === 0) {
    throw notFound("BENCHMARK_NOT_FOUND", "The requested benchmark does not exist.");
  }
  const values: unknown[] = [benchmarkId];
  const conditions = ["benchmark_id = $1"];
  if (range.from) {
    values.push(range.from);
    conditions.push(`value_date >= $${values.length}`);
  }
  if (range.to) {
    values.push(range.to);
    conditions.push(`value_date <= $${values.length}`);
  }
  const rows = await query<SqlRow>(
    db,
    `
    SELECT value_date, index_value
    FROM benchmark_values
    WHERE ${conditions.join(" AND ")}
    ORDER BY value_date
    `,
    values,
  );
  return {
    benchmarkId,
    data: rows.map((row) => ({
      date: requireIsoDate(row.value_date as Date | string),
      indexValue: toJsonNumber(row.index_value as string | null),
    })),
  };
}

async function getDisclosure(
  db: DbClient,
  schemeId: number,
  date?: string,
): Promise<{ id: string; report_date: Date | string } | null> {
  if (date) {
    const rows = await query<{ id: string; report_date: Date | string }>(
      db,
      "SELECT id, report_date FROM portfolio_disclosures WHERE scheme_id = $1 AND report_date = $2",
      [schemeId, date],
    );
    return rows[0] ?? null;
  }
  const rows = await query<{ id: string; report_date: Date | string }>(
    db,
    "SELECT disclosure_id AS id, report_date FROM v_latest_portfolio_disclosure WHERE scheme_id = $1",
    [schemeId],
  );
  return rows[0] ?? null;
}

export async function getPortfolio(db: DbClient, schemeId: number, date?: string) {
  await requireScheme(db, schemeId);
  const disclosure = await getDisclosure(db, schemeId, date);
  if (!disclosure) {
    return {
      status: "not_available",
      message: "Portfolio disclosure data not yet loaded",
    };
  }
  const rows = await query<SqlRow>(
    db,
    `
    SELECT
      pp.instrument_name,
      pp.instrument_type,
      pp.asset_class,
      pp.position_side,
      pp.nav_percentage,
      pp.exposure_percentage,
      pp.market_value,
      sec.sector_name,
      s.isin
    FROM portfolio_positions pp
    LEFT JOIN sectors sec ON sec.id = pp.sector_id
    LEFT JOIN securities s ON s.id = pp.security_id
    WHERE pp.disclosure_id = $1
    ORDER BY pp.nav_percentage DESC NULLS LAST, pp.instrument_name
    `,
    [disclosure.id],
  );
  return {
    reportDate: requireIsoDate(disclosure.report_date),
    positions: rows.map((row) => ({
      instrumentName: String(row.instrument_name),
      instrumentType: row.instrument_type === null ? null : String(row.instrument_type),
      assetClass: row.asset_class === null ? null : String(row.asset_class),
      positionSide: String(row.position_side),
      sector: row.sector_name === null ? null : String(row.sector_name),
      isin: row.isin === null ? null : String(row.isin),
      navPercentage: toJsonNumber(row.nav_percentage as string | null),
      exposurePercentage: toJsonNumber(row.exposure_percentage as string | null),
      marketValue: toJsonNumber(row.market_value as string | null),
    })),
  };
}

export async function getTopHoldings(db: DbClient, schemeId: number, limit: number) {
  await requireScheme(db, schemeId);
  const disclosure = await getDisclosure(db, schemeId);
  if (!disclosure) {
    return {
      status: "not_available",
      message: "Portfolio disclosure data not yet loaded",
    };
  }
  const rows = await query<SqlRow>(
    db,
    `
    SELECT pp.instrument_name, sec.sector_name, pp.nav_percentage
    FROM portfolio_positions pp
    LEFT JOIN sectors sec ON sec.id = pp.sector_id
    WHERE pp.disclosure_id = $1
      AND pp.nav_percentage IS NOT NULL
    ORDER BY pp.nav_percentage DESC
    LIMIT $2
    `,
    [disclosure.id, limit],
  );
  return {
    reportDate: requireIsoDate(disclosure.report_date),
    holdings: rows.map((row) => ({
      securityName: String(row.instrument_name),
      sector: row.sector_name === null ? null : String(row.sector_name),
      navPercentage: toJsonNumber(row.nav_percentage as string | null),
    })),
  };
}

export async function getSectors(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const rows = await query<SqlRow>(
    db,
    `
    SELECT report_date, sector_name, allocation_percentage
    FROM v_latest_sector_allocation
    WHERE scheme_id = $1
    ORDER BY allocation_percentage DESC NULLS LAST
    `,
    [schemeId],
  );
  const first = rows[0];
  if (!first) {
    return {
      status: "not_available",
      message: "Portfolio disclosure data not yet loaded",
    };
  }
  return {
    reportDate: requireIsoDate(first.report_date as Date | string),
    sectors: rows.map((row) => ({
      sector: String(row.sector_name),
      allocationPercentage: toJsonNumber(row.allocation_percentage as string | null),
    })),
  };
}

export async function getAssetAllocation(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const rows = await query<SqlRow>(
    db,
    `
    SELECT report_date, asset_class, allocation_percentage
    FROM v_latest_asset_allocation
    WHERE scheme_id = $1
    ORDER BY allocation_percentage DESC NULLS LAST
    `,
    [schemeId],
  );
  const first = rows[0];
  if (!first) {
    return {
      status: "not_available",
      message: "Portfolio disclosure data not yet loaded",
    };
  }
  return {
    reportDate: requireIsoDate(first.report_date as Date | string),
    allocation: rows.map((row) => ({
      assetClass: row.asset_class === null ? null : String(row.asset_class),
      allocationPercentage: toJsonNumber(row.allocation_percentage as string | null),
    })),
  };
}

export async function getExposure(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const rows = await query<SqlRow>(
    db,
    `
    SELECT report_date, long_exposure, short_exposure, gross_exposure, net_exposure, derivative_exposure
    FROM scheme_exposure_history
    WHERE scheme_id = $1
    ORDER BY report_date DESC, id DESC
    LIMIT 1
    `,
    [schemeId],
  );
  const row = rows[0];
  if (!row) {
    return {
      status: "not_available",
      message: "Exposure data not yet loaded",
    };
  }
  return {
    reportDate: requireIsoDate(row.report_date as Date | string),
    longExposure: toJsonNumber(row.long_exposure as string | null),
    shortExposure: toJsonNumber(row.short_exposure as string | null),
    grossExposure: toJsonNumber(row.gross_exposure as string | null),
    netExposure: toJsonNumber(row.net_exposure as string | null),
    derivativeExposure: toJsonNumber(row.derivative_exposure as string | null),
  };
}

export async function getExposureHistory(db: DbClient, schemeId: number) {
  await requireScheme(db, schemeId);
  const rows = await query<SqlRow>(
    db,
    `
    SELECT report_date, long_exposure, short_exposure, gross_exposure, net_exposure, derivative_exposure
    FROM scheme_exposure_history
    WHERE scheme_id = $1
    ORDER BY report_date
    `,
    [schemeId],
  );
  return {
    data: rows.map((row) => ({
      reportDate: requireIsoDate(row.report_date as Date | string),
      longExposure: toJsonNumber(row.long_exposure as string | null),
      shortExposure: toJsonNumber(row.short_exposure as string | null),
      grossExposure: toJsonNumber(row.gross_exposure as string | null),
      netExposure: toJsonNumber(row.net_exposure as string | null),
      derivativeExposure: toJsonNumber(row.derivative_exposure as string | null),
    })),
  };
}

export async function getDerivatives(db: DbClient, schemeId: number, date?: string) {
  await requireScheme(db, schemeId);
  const disclosure = await getDisclosure(db, schemeId, date);
  if (!disclosure) {
    return {
      status: "not_available",
      message: "Portfolio disclosure data not yet loaded",
    };
  }
  const rows = await query<SqlRow>(
    db,
    `
    SELECT instrument_name, position_side, exposure_percentage, expiry_date, derivative_type
    FROM portfolio_positions
    WHERE disclosure_id = $1
      AND (
        derivative_type IS NOT NULL
        OR instrument_type ILIKE '%future%'
        OR instrument_type ILIKE '%option%'
        OR instrument_type ILIKE '%derivative%'
      )
    ORDER BY exposure_percentage DESC NULLS LAST, instrument_name
    `,
    [disclosure.id],
  );
  return {
    reportDate: requireIsoDate(disclosure.report_date),
    positions: rows.map((row) => ({
      instrumentName: String(row.instrument_name),
      positionSide: String(row.position_side),
      exposurePercentage: toJsonNumber(row.exposure_percentage as string | null),
      expiryDate: toIso(row.expiry_date),
      derivativeType: row.derivative_type === null ? null : String(row.derivative_type),
    })),
  };
}

export async function getPrimaryPlanId(db: DbClient, schemeId: number): Promise<number | null> {
  const rows = await query<{ id: string }>(
    db,
    `
    SELECT id
    FROM scheme_plans
    WHERE scheme_id = $1
    ORDER BY
      CASE WHEN plan_type ILIKE 'Direct%' AND option_type ILIKE 'Growth%' THEN 0 ELSE 1 END,
      id
    LIMIT 1
    `,
    [schemeId],
  );
  return rows[0] ? Number(rows[0].id) : null;
}

