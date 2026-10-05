// Local-only integration harness. Creates an isolated schema; never imports into application tables.
import { readFileSync, mkdirSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import pg from 'pg';
import ExcelJS from 'exceljs';
import { buildApp } from './app.js';
import { loadConfig } from './config.js';

const config = loadConfig();
const schema = `mobile_test_${randomUUID().replaceAll('-', '')}`;
const owner = new pg.Pool({ connectionString: config.DATABASE_URL });
const source = readFileSync('dynasif_moneycontrol_postgres.sql', 'utf8');
await owner.query(source.slice(source.indexOf('BEGIN;')).replaceAll('fund_analytics', schema));
const db = new pg.Pool({ connectionString: config.DATABASE_URL, options: `-c search_path=${schema},public` });
const app = await buildApp({ ...config, ADMIN_API_KEY: 'local-mobile-test-only', LOG_LEVEL: 'fatal', NODE_ENV: 'test' }, db);
const workbook = new ExcelJS.Workbook();
const sheet = workbook.addWorksheet('NAV History');
sheet.addRow(['Scheme Name', 'Plan', 'Option', 'NAV Date', 'NAV']);
sheet.addRow(['Mobile integration fund', 'Direct', 'Growth', '2026-01-01', 10]);
sheet.addRow(['Mobile integration fund', 'Direct', 'Growth', '2026-02-01', 11]);
mkdirSync('../mobile/test/fixtures', { recursive: true });
await workbook.xlsx.writeFile('../mobile/test/fixtures/dynasif.xlsx');
let stopping = false;
async function stop() {
  if (stopping) return;
  stopping = true;
  await app.close();
  if (!/^mobile_test_[a-f0-9]{32}$/.test(schema)) throw new Error('Invalid test schema');
  await owner.query(`DROP SCHEMA ${schema} CASCADE`);
  await owner.end();
}
process.on('SIGINT', () => { void stop(); });
process.on('SIGTERM', () => { void stop(); });
// Bind only to loopback; this endpoint belongs exclusively to the test harness.
app.post('/test/shutdown', async (_request, reply) => {
  reply.send({ status: 'stopping' });
  setTimeout(() => { void stop(); }, 50);
});
await app.listen({ host: '127.0.0.1', port: 3101 });
console.log('Isolated mobile integration API ready on http://127.0.0.1:3101');
