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
    const res = await pool.query(`
      SELECT 
        s.scheme_name, 
        sp.plan_type,
        sp.option_type,
        COUNT(nh.id) as nav_count, 
        MAX(nh.nav_date) as latest_nav_date,
        MIN(nh.nav_date) as earliest_nav_date
      FROM fund_analytics.nav_history nh 
      JOIN fund_analytics.scheme_plans sp ON sp.id = nh.scheme_plan_id 
      JOIN fund_analytics.schemes s ON s.id = sp.scheme_id 
      JOIN fund_analytics.amcs a ON a.id = s.amc_id
      WHERE a.name ILIKE '%QSIF%'
      GROUP BY s.scheme_name, sp.plan_type, sp.option_type
      ORDER BY latest_nav_date DESC;
    `);
    console.log("QSIF NAV History Summary:");
    console.table(res.rows);
  } catch (err) {
    console.error(err);
  } finally {
    await pool.end();
  }
}

verify();
