import type { Pool } from "pg";
import { toDecimal } from "../../lib/money.js";
import { requirePlan, requireScheme } from "../funds/repo.js";

type ImportResult = {
  runId: number;
  status: string;
  rowsInserted: number;
  rowsUpdated: number;
  errorMessage: string | null;
};

async function startRun(
  db: Pool,
  sourceType: string,
  sourceName: string,
  sourceDocumentId?: number,
): Promise<number> {
  const result = await db.query<{ id: string }>(
    `
    INSERT INTO ingestion_runs (source_type, source_name, source_document_id, status)
    VALUES ($1, $2, $3, 'STARTED')
    RETURNING id
    `,
    [sourceType, sourceName, sourceDocumentId ?? null],
  );
  return Number(result.rows[0]!.id);
}

async function finishRun(
  db: Pool,
  runId: number,
  status: string,
  inserted: number,
  updated: number,
  errorMessage: string | null,
): Promise<ImportResult> {
  await db.query(
    `
    UPDATE ingestion_runs
    SET finished_at = NOW(), status = $2, rows_inserted = $3, rows_updated = $4, error_message = $5
    WHERE id = $1
    `,
    [runId, status, inserted, updated, errorMessage],
  );
  return { runId, status, rowsInserted: inserted, rowsUpdated: updated, errorMessage };
}

export async function importNav(
  db: Pool,
  input: {
    planId: number;
    source: string;
    rows: { navDate: string; nav: string | number; repurchasePrice?: string | number; salePrice?: string | number }[];
  },
): Promise<ImportResult> {
  await requirePlan(db, input.planId);
  const runId = await startRun(db, "NAV", input.source);
  let inserted = 0;
  let updated = 0;
  const errors: string[] = [];
  const client = await db.connect();
  try {
    await client.query("BEGIN");
    for (const row of input.rows) {
      const nav = toDecimal(row.nav);
      if (!nav || nav.lte(0)) {
        errors.push(`${row.navDate}: NAV must be greater than zero`);
        continue;
      }
      const existing = await client.query<{ nav: string }>(
        "SELECT nav FROM nav_history WHERE scheme_plan_id = $1 AND nav_date = $2",
        [input.planId, row.navDate],
      );
      const current = existing.rows[0];
      if (current) {
        const currentNav = toDecimal(current.nav);
        if (currentNav && currentNav.equals(nav)) {
          continue;
        }
        errors.push(`${row.navDate}: conflicting NAV not overwritten`);
        continue;
      }
      await client.query(
        `
        INSERT INTO nav_history (scheme_plan_id, nav_date, nav, repurchase_price, sale_price, source)
        VALUES ($1, $2, $3, $4, $5, $6)
        `,
        [
          input.planId,
          row.navDate,
          nav.toString(),
          toDecimal(row.repurchasePrice)?.toString() ?? null,
          toDecimal(row.salePrice)?.toString() ?? null,
          input.source,
        ],
      );
      inserted += 1;
    }
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    const message = error instanceof Error ? error.message : "NAV import failed";
    return finishRun(db, runId, "FAILED", 0, 0, message);
  } finally {
    client.release();
  }
  const status = errors.length === 0 ? "SUCCESS" : inserted > 0 ? "PARTIAL" : "FAILED";
  return finishRun(db, runId, status, inserted, updated, errors.length ? errors.slice(0, 20).join("; ") : null);
}

export async function importAum(
  db: Pool,
  input: {
    schemeId: number;
    source: string;
    rows: {
      reportDate: string;
      periodType: string;
      closingAum?: string | number | null;
      averageAum?: string | number | null;
      unit: string;
    }[];
  },
): Promise<ImportResult> {
  await requireScheme(db, input.schemeId);
  const runId = await startRun(db, "AUM", input.source);
  let inserted = 0;
  let updated = 0;
  const client = await db.connect();
  try {
    await client.query("BEGIN");
    for (const row of input.rows) {
      const result = await client.query(
        `
        INSERT INTO aum_history (scheme_id, report_date, period_type, closing_aum, average_aum, unit, source)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (scheme_id, report_date, period_type)
        DO UPDATE SET
          closing_aum = EXCLUDED.closing_aum,
          average_aum = EXCLUDED.average_aum,
          unit = EXCLUDED.unit,
          source = EXCLUDED.source
        RETURNING (xmax = 0) AS inserted
        `,
        [
          input.schemeId,
          row.reportDate,
          row.periodType,
          toDecimal(row.closingAum)?.toString() ?? null,
          toDecimal(row.averageAum)?.toString() ?? null,
          row.unit,
          input.source,
        ],
      );
      if (result.rows[0]?.inserted) {
        inserted += 1;
      } else {
        updated += 1;
      }
    }
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    const message = error instanceof Error ? error.message : "AUM import failed";
    return finishRun(db, runId, "FAILED", 0, 0, message);
  } finally {
    client.release();
  }
  return finishRun(db, runId, "SUCCESS", inserted, updated, null);
}

export async function importPortfolio(
  db: Pool,
  input: {
    schemeId: number;
    reportDate: string;
    sourceFile: string;
    positions: {
      instrumentName: string;
      instrumentType?: string;
      assetClass?: string;
      sector?: string;
      positionSide: "LONG" | "SHORT" | "HEDGED" | "OFFSET" | "NA";
      quantity?: string | number;
      marketValue?: string | number;
      navPercentage?: string | number;
      exposureValue?: string | number;
      exposurePercentage?: string | number;
      derivativeUnderlying?: string;
      derivativeType?: string;
      expiryDate?: string;
      contractIdentifier?: string;
      isin?: string;
    }[];
  },
): Promise<ImportResult> {
  await requireScheme(db, input.schemeId);
  const runId = await startRun(db, "PORTFOLIO", input.sourceFile);
  let inserted = 0;
  const client = await db.connect();
  try {
    await client.query("BEGIN");
    const disclosure = await client.query<{ id: string }>(
      `
      INSERT INTO portfolio_disclosures (scheme_id, report_date, source_file)
      VALUES ($1, $2, $3)
      ON CONFLICT (scheme_id, report_date)
      DO UPDATE SET source_file = EXCLUDED.source_file, imported_at = NOW()
      RETURNING id
      `,
      [input.schemeId, input.reportDate, input.sourceFile],
    );
    const disclosureId = disclosure.rows[0]!.id;
    await client.query("DELETE FROM portfolio_positions WHERE disclosure_id = $1", [disclosureId]);
    for (const [index, position] of input.positions.entries()) {
      let sectorId: string | null = null;
      if (position.sector) {
        const sector = await client.query<{ id: string }>(
          `
          INSERT INTO sectors (sector_name)
          VALUES ($1)
          ON CONFLICT (sector_name) DO UPDATE SET sector_name = EXCLUDED.sector_name
          RETURNING id
          `,
          [position.sector],
        );
        sectorId = sector.rows[0]!.id;
      }
      let securityId: string | null = null;
      if (position.isin) {
        const existing = await client.query<{ id: string }>(
          "SELECT id FROM securities WHERE isin = $1",
          [position.isin],
        );
        if (existing.rows[0]) {
          securityId = existing.rows[0].id;
          await client.query(
            `
            UPDATE securities
            SET security_name = $2, sector_id = COALESCE($3, sector_id), security_type = COALESCE($4, security_type)
            WHERE id = $1
            `,
            [securityId, position.instrumentName, sectorId, position.instrumentType ?? null],
          );
        } else {
          const created = await client.query<{ id: string }>(
            `
            INSERT INTO securities (security_name, isin, sector_id, security_type)
            VALUES ($1, $2, $3, $4)
            RETURNING id
            `,
            [position.instrumentName, position.isin, sectorId, position.instrumentType ?? null],
          );
          securityId = created.rows[0]!.id;
        }
      }
      await client.query(
        `
        INSERT INTO portfolio_positions (
          disclosure_id, security_id, instrument_name, instrument_type, asset_class, sector_id,
          position_side, quantity, market_value, nav_percentage, exposure_value, exposure_percentage,
          derivative_underlying, derivative_type, expiry_date, contract_identifier, source_row_number
        ) VALUES (
          $1, $2, $3, $4, $5, $6,
          $7, $8, $9, $10, $11, $12,
          $13, $14, $15, $16, $17
        )
        `,
        [
          disclosureId,
          securityId,
          position.instrumentName,
          position.instrumentType ?? null,
          position.assetClass ?? null,
          sectorId,
          position.positionSide,
          toDecimal(position.quantity)?.toString() ?? null,
          toDecimal(position.marketValue)?.toString() ?? null,
          toDecimal(position.navPercentage)?.toString() ?? null,
          toDecimal(position.exposureValue)?.toString() ?? null,
          toDecimal(position.exposurePercentage)?.toString() ?? null,
          position.derivativeUnderlying ?? null,
          position.derivativeType ?? null,
          position.expiryDate ?? null,
          position.contractIdentifier ?? null,
          index + 1,
        ],
      );
      inserted += 1;
    }
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    const message = error instanceof Error ? error.message : "Portfolio import failed";
    return finishRun(db, runId, "FAILED", 0, 0, message);
  } finally {
    client.release();
  }
  return finishRun(db, runId, "SUCCESS", inserted, 0, null);
}

export async function importBenchmark(
  db: Pool,
  input: { benchmarkId: number; source: string; rows: { valueDate: string; indexValue: string | number }[] },
): Promise<ImportResult> {
  const exists = await db.query("SELECT id FROM benchmarks WHERE id = $1", [input.benchmarkId]);
  if (exists.rowCount === 0) {
    const { notFound } = await import("../../errors.js");
    throw notFound("BENCHMARK_NOT_FOUND", "The requested benchmark does not exist.");
  }
  const runId = await startRun(db, "BENCHMARK", input.source);
  let inserted = 0;
  let updated = 0;
  const client = await db.connect();
  try {
    await client.query("BEGIN");
    for (const row of input.rows) {
      const value = toDecimal(row.indexValue);
      if (!value) {
        continue;
      }
      const result = await client.query(
        `
        INSERT INTO benchmark_values (benchmark_id, value_date, index_value, source)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (benchmark_id, value_date)
        DO UPDATE SET index_value = EXCLUDED.index_value, source = EXCLUDED.source
        RETURNING (xmax = 0) AS inserted
        `,
        [input.benchmarkId, row.valueDate, value.toString(), input.source],
      );
      if (result.rows[0]?.inserted) {
        inserted += 1;
      } else {
        updated += 1;
      }
    }
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    const message = error instanceof Error ? error.message : "Benchmark import failed";
    return finishRun(db, runId, "FAILED", 0, 0, message);
  } finally {
    client.release();
  }
  return finishRun(db, runId, "SUCCESS", inserted, updated, null);
}

export async function importRiskFreeRate(
  db: Pool,
  input: { instrument: string; source: string; rows: { rateDate: string; annualRate: string | number }[] },
): Promise<ImportResult> {
  const runId = await startRun(db, "RISK_FREE_RATE", input.source);
  let inserted = 0;
  let updated = 0;
  const client = await db.connect();
  try {
    await client.query("BEGIN");
    for (const row of input.rows) {
      const rate = toDecimal(row.annualRate);
      if (!rate) {
        continue;
      }
      const result = await client.query(
        `
        INSERT INTO risk_free_rates (rate_date, instrument, annual_rate, source)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (rate_date, instrument)
        DO UPDATE SET annual_rate = EXCLUDED.annual_rate, source = EXCLUDED.source
        RETURNING (xmax = 0) AS inserted
        `,
        [row.rateDate, input.instrument, rate.toString(), input.source],
      );
      if (result.rows[0]?.inserted) {
        inserted += 1;
      } else {
        updated += 1;
      }
    }
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    const message = error instanceof Error ? error.message : "Risk-free rate import failed";
    return finishRun(db, runId, "FAILED", 0, 0, message);
  } finally {
    client.release();
  }
  return finishRun(db, runId, "SUCCESS", inserted, updated, null);
}

export async function listIngestionRuns(db: Pool) {
  const result = await db.query(
    `
    SELECT id, source_type, source_name, started_at, finished_at, status, rows_inserted, rows_updated, error_message
    FROM ingestion_runs
    ORDER BY started_at DESC
    LIMIT 100
    `,
  );
  return { data: result.rows };
}

export async function getIngestionRun(db: Pool, id: number) {
  const result = await db.query(
    `
    SELECT id, source_type, source_name, started_at, finished_at, status, rows_inserted, rows_updated, error_message
    FROM ingestion_runs
    WHERE id = $1
    `,
    [id],
  );
  const row = result.rows[0];
  if (!row) {
    const { notFound } = await import("../../errors.js");
    throw notFound("INGESTION_RUN_NOT_FOUND", "The requested ingestion run does not exist.");
  }
  return row;
}
