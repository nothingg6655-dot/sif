import type { Pool } from 'pg';
import { Resolver } from '../resolver.js';
import { RowStatus } from '../validator.js';

export interface ImportResult {
  inserted: number;
  updated: number;
  skipped: number;
  failed: number;
  errors: string[];
  type?: string;
  provider?: string;
  schemeName?: string;
  planType?: string;
  optionType?: string;
  affectedRows?: number;
}

export async function importNavHistory(db: Pool, parsedRows: any[], sourceDocumentId: number | null): Promise<ImportResult> {
  const resolver = new Resolver(db);
  const result: ImportResult = { inserted: 0, updated: 0, skipped: 0, failed: 0, errors: [] };

  for (const [index, row] of parsedRows.entries()) {
    try {
      if (row.status === RowStatus.ERROR) {
        result.failed++;
        result.errors.push(`Row ${index + 1}: ${row.errors.join(', ')}`);
        continue;
      }

      const data = row.parsedData;
      // Use amc_name if provided, otherwise fallback to a generic provider name or 'Unknown AMC'
      const amcName = data.amc_name || 'Unknown AMC';
      
      const schemePlanId = await resolver.resolveSchemePlanId(amcName, data.scheme_name, data.plan_type, data.option_type);
      
      if (!schemePlanId) {
        // Return MISSING_MASTER_DATA special case to frontend
        return {
          inserted: 0, updated: 0, skipped: 0, failed: parsedRows.length, errors: [],
          type: 'MISSING_MASTER_DATA',
          provider: amcName,
          schemeName: data.scheme_name,
          planType: data.plan_type,
          optionType: data.option_type,
          affectedRows: parsedRows.length
        };
      }

      // Check if exact record exists to classify as skipped, updated, or new
      const checkQuery = `
        SELECT nav, repurchase_price, sale_price 
        FROM fund_analytics.nav_history 
        WHERE scheme_plan_id = $1 AND nav_date = $2
      `;
      const checkResult = await db.query(checkQuery, [schemePlanId, data.nav_date]);

      if (checkResult.rows.length > 0) {
        const existing = checkResult.rows[0];
        // If data is identical
        if (
          Number(existing.nav) === Number(data.nav) &&
          Number(existing.repurchase_price || 0) === Number(data.repurchase_price || 0) &&
          Number(existing.sale_price || 0) === Number(data.sale_price || 0)
        ) {
          result.skipped++;
          continue;
        } else {
          // Data changed, needs update
          const updateQuery = `
            UPDATE fund_analytics.nav_history
            SET nav = $1, repurchase_price = $2, sale_price = $3, source = $4
            WHERE scheme_plan_id = $5 AND nav_date = $6
          `;
          // Convert sourceDocumentId (number|null) to a string representation for 'source' column
          const sourceString = sourceDocumentId ? String(sourceDocumentId) : 'API';
          await db.query(updateQuery, [data.nav, data.repurchase_price, data.sale_price, sourceString, schemePlanId, data.nav_date]);
          result.updated++;
          continue;
        }
      }

      // Convert sourceDocumentId (number|null) to a string representation for 'source' column
      const sourceString = sourceDocumentId ? String(sourceDocumentId) : 'API';

      // Record is new, insert it
      const insertQuery = `
        INSERT INTO fund_analytics.nav_history 
          (scheme_plan_id, nav_date, nav, repurchase_price, sale_price, source)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (scheme_plan_id, nav_date) DO UPDATE 
        SET nav = EXCLUDED.nav, 
            repurchase_price = EXCLUDED.repurchase_price, 
            sale_price = EXCLUDED.sale_price,
            source = EXCLUDED.source
      `;
      await db.query(insertQuery, [
        schemePlanId,
        data.nav_date,
        data.nav,
        data.repurchase_price,
        data.sale_price,
        sourceString
      ]);
      result.inserted++;

    } catch (err: any) {
      result.failed++;
      result.errors.push(`Row ${index + 1}: DB Error - ${err.message}`);
    }
  }

  return result;
}
