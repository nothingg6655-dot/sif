import type { Pool } from 'pg';

export class Resolver {
  private db: Pool;

  constructor(db: Pool) {
    this.db = db;
  }

  async resolveSchemePlanId(amcName: string, schemeName: string, planType: string, optionType: string): Promise<number | null> {
    const query = `
      SELECT sp.id
      FROM fund_analytics.scheme_plans sp
      JOIN fund_analytics.schemes s ON s.id = sp.scheme_id
      JOIN fund_analytics.amcs a ON a.id = s.amc_id
      WHERE LOWER(s.scheme_name) = LOWER($1)
        AND LOWER(sp.plan_type) = LOWER($2)
        AND LOWER(sp.option_type) = LOWER($3)
        AND LOWER(a.name) = LOWER($4)
      LIMIT 1;
    `;
    const result = await this.db.query(query, [schemeName, planType, optionType, amcName]);
    if (result.rows.length > 0) {
      return result.rows[0].id;
    }
    return null;
  }

  async resolveSchemeId(schemeName: string): Promise<number | null> {
    const query = `
      SELECT id FROM fund_analytics.schemes
      WHERE LOWER(scheme_name) = LOWER($1)
      LIMIT 1;
    `;
    const result = await this.db.query(query, [schemeName]);
    if (result.rows.length > 0) {
      return result.rows[0].id;
    }
    return null;
  }

  async resolveAmcId(amcName: string): Promise<number | null> {
    const query = `
      SELECT id FROM fund_analytics.amcs
      WHERE LOWER(name) = LOWER($1)
      LIMIT 1;
    `;
    const result = await this.db.query(query, [amcName]);
    if (result.rows.length > 0) {
      return result.rows[0].id;
    }
    return null;
  }

  async createMissingMaster(amcName: string, schemeName: string, planType: string, optionType: string): Promise<number> {
    const client = await this.db.connect();
    try {
      await client.query('BEGIN');
      
      // 1. Resolve or Create AMC
      let amcId: number;
      const amcRes = await client.query('SELECT id FROM fund_analytics.amcs WHERE LOWER(name) = LOWER($1) LIMIT 1', [amcName]);
      if (amcRes.rows.length > 0) {
        amcId = amcRes.rows[0].id;
      } else {
        const insertAmc = await client.query('INSERT INTO fund_analytics.amcs (name) VALUES ($1) RETURNING id', [amcName]);
        amcId = insertAmc.rows[0].id;
      }

      // 2. Resolve or Create Scheme
      let schemeId: number;
      const schemeRes = await client.query('SELECT id FROM fund_analytics.schemes WHERE LOWER(scheme_name) = LOWER($1) AND amc_id = $2 LIMIT 1', [schemeName, amcId]);
      if (schemeRes.rows.length > 0) {
        schemeId = schemeRes.rows[0].id;
      } else {
        const insertScheme = await client.query('INSERT INTO fund_analytics.schemes (amc_id, scheme_name) VALUES ($1, $2) RETURNING id', [amcId, schemeName]);
        schemeId = insertScheme.rows[0].id;
      }

      // 3. Resolve or Create Plan
      let planId: number;
      const planRes = await client.query('SELECT id FROM fund_analytics.scheme_plans WHERE scheme_id = $1 AND LOWER(plan_type) = LOWER($2) AND LOWER(option_type) = LOWER($3) LIMIT 1', [schemeId, planType, optionType]);
      if (planRes.rows.length > 0) {
        planId = planRes.rows[0].id;
      } else {
        const insertPlan = await client.query('INSERT INTO fund_analytics.scheme_plans (scheme_id, plan_type, option_type) VALUES ($1, $2, $3) RETURNING id', [schemeId, planType, optionType]);
        planId = insertPlan.rows[0].id;
      }

      await client.query('COMMIT');
      return planId;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }
}
