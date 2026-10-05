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
    const cols = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = 'fund_analytics' AND table_name = 'nav_history'
      ORDER BY ordinal_position;
    `);
    console.log("COLUMNS:");
    console.table(cols.rows);

    const constrs = await pool.query(`
      SELECT tc.constraint_name, tc.constraint_type, kcu.column_name
      FROM information_schema.table_constraints tc
      LEFT JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
      WHERE tc.table_schema = 'fund_analytics'
        AND tc.table_name = 'nav_history';
    `);
    console.log("\nCONSTRAINTS:");
    console.table(constrs.rows);
  } catch (err) {
    console.error(err);
  } finally {
    await pool.end();
  }
}

verify();
