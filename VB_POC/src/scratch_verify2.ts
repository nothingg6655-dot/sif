import { Pool } from 'pg';
import { config } from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

config({ path: path.resolve(__dirname, '../.env') });

async function verify() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL
  });

  try {
    const amcs = await pool.query('SELECT id, name FROM fund_analytics.amcs;');
    console.log("AMCs:");
    console.table(amcs.rows);

    const schemes = await pool.query('SELECT id, amc_id, scheme_name FROM fund_analytics.schemes;');
    console.log("\nSchemes:");
    console.table(schemes.rows);

    const plans = await pool.query('SELECT id, scheme_id, plan_type, option_type, isin FROM fund_analytics.scheme_plans;');
    console.log("\nPlans:");
    console.table(plans.rows);
  } catch (err) {
    console.error(err);
  } finally {
    await pool.end();
  }
}

verify();
