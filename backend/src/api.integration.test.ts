import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import pg from 'pg';
import { beforeAll, afterAll, describe, expect, it } from 'vitest';
import { buildApp } from './app.js';
import { loadConfig } from './config.js';

// Explicit opt-in: creates and removes a unique schema on the configured database.
const enabled = process.env.API_INTEGRATION_TEST === '1';
const spec = readFileSync('dynasif_api_spec.md', 'utf8');
const endpoints = [...spec.matchAll(/^### (GET|POST) (\/api\/\S+)/gm)].map(m => ({ method: m[1] as 'GET' | 'POST', path: m[2]! }));
describe.skipIf(!enabled)('API integration with isolated PostgreSQL schema', () => {
  const schema = `api_test_${randomUUID().replaceAll('-', '')}`;
  let app: Awaited<ReturnType<typeof buildApp>>;
  let owner: pg.Pool;
  let schemeId: number, planId: number, benchmarkId: number;
  const headers = { 'x-admin-key': 'integration-test-key' };
  beforeAll(async () => {
    const config = { ...loadConfig(), ADMIN_API_KEY: headers['x-admin-key'], LOG_LEVEL: 'fatal' as const, NODE_ENV: 'test' as const };
    owner = new pg.Pool({ connectionString: config.DATABASE_URL });
    const source = readFileSync('dynasif_moneycontrol_postgres.sql', 'utf8');
    await owner.query(source.slice(source.indexOf('BEGIN;')).replaceAll('fund_analytics', schema));
    const db = new pg.Pool({ connectionString: config.DATABASE_URL, options: `-c search_path=${schema},public` });
    app = await buildApp(config, db);
    schemeId = Number((await db.query('SELECT id FROM schemes ORDER BY id LIMIT 1')).rows[0].id);
    planId = Number((await db.query('SELECT id FROM scheme_plans ORDER BY id LIMIT 1')).rows[0].id);
    benchmarkId = Number((await db.query('SELECT id FROM benchmarks ORDER BY id LIMIT 1')).rows[0].id);
  }, 30000);
  afterAll(async () => {
    if (app) await app.close();
    if (owner) {
      if (!/^api_test_[a-f0-9]{32}$/.test(schema)) throw new Error('Unsafe cleanup schema');
      await owner.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`);
      await owner.end();
    }
  });
  function url(path: string) {
    let result = path.replace(':schemeId', String(schemeId)).replace(':planId', String(planId)).replace(':benchmarkId', String(benchmarkId)).replace(':id', '1');
    if (path.includes('/compare')) result += `?ids=${schemeId}`;
    if (path === '/api/search') result += '?q=DynaSIF';
    return result;
  }
  function payload(path: string) {
    if (path.endsWith('/nav')) return { planId, source: 'test fixture', rows: [{ navDate: '2026-01-01', nav: '10' }, {navDate: '2026-02-01', nav: '11'}, {navDate: '2026-03-01', nav: '10.5'}] };
    if (path.endsWith('/aum')) return { schemeId, source: 'test fixture', rows: [{ reportDate: '2026-01-31', closingAum: '100', averageAum: '99' }] };
    if (path.endsWith('/portfolio')) return { schemeId, reportDate: '2026-01-31', sourceFile: 'test fixture', positions: [{instrumentName: 'Test holding', assetClass: 'EQUITY', sector: 'Test sector', positionSide: 'LONG', navPercentage: '60', exposurePercentage: '60'}, {instrumentName: 'Test future', instrumentType: 'future', positionSide: 'SHORT', exposurePercentage: '10'}] };
    if (path.endsWith('/benchmark')) return { benchmarkId, source: 'test fixture', rows: [{valueDate: '2026-01-01', indexValue: '100'}] };
    if (path.endsWith('/risk-free-rate')) return { instrument: 'test', source: 'test fixture', rows: [{rateDate: '2026-01-01', annualRate: '0.06'}] };
    return undefined;
  }
  it('health checks PostgreSQL', async () => { expect((await app.inject('/health')).statusCode).toBe(200); });
  for (const endpoint of endpoints.filter(e => e.path.startsWith('/api/admin'))) {
    it(`requires authentication: ${endpoint.method} ${endpoint.path}`, async () => {
      const response = await app.inject({method: endpoint.method, url: url(endpoint.path)});
      expect(response.statusCode).toBe(401);
    });
  }
  // Imports precede reads so populated portfolio/exposure paths are exercised too.
  for (const endpoint of [...endpoints.filter(e => e.method === 'POST'), ...endpoints.filter(e => e.method === 'GET')]) {
    it(`${endpoint.method} ${endpoint.path}`, async () => {
      const response = await app.inject({method: endpoint.method, url: url(endpoint.path), headers, payload: payload(endpoint.path)});
      expect(response.statusCode, response.body).toBe(200);
      const body = response.json();
      expect(body.error).toBeFalsy();
      if (endpoint.method === 'POST' && endpoint.path.includes('/import/')) expect(body.status, response.body).toBe('SUCCESS');
    });
  }
  for (const path of ['/api/funds/0', '/api/plans/no/nav/latest', '/api/search', '/api/funds?limit=101', '/api/plans/1/nav/history?from=2026-05-01&to=2026-01-01', '/api/funds/compare?ids=1,bad', '/api/funds/compare/returns?ids=1,2,3,4,5,6', '/api/funds/compare/risk?ids=1,2,3,4,5,6']) {
    it(`rejects invalid input: ${path}`, async () => { const r = await app.inject(path); expect(r.statusCode, r.body).toBe(400); });
  }
  it('preserves malformed JSON status', async () => {
    const r = await app.inject({method: 'POST', url: '/api/admin/import/nav', headers: {...headers, 'content-type': 'application/json'}, payload: '{'});
    expect(r.statusCode).toBe(400);
  });
  it('keeps pagination total beyond last page', async () => {
    const r = await app.inject('/api/funds?page=100'); expect(r.json().total).toBe(1);
  });
  for (const path of ['/api/funds/999999', '/api/plans/999999/nav/latest', '/api/benchmarks/999999/history', '/api/admin/ingestion-runs/999999']) {
    it(`returns 404 for missing entity: ${path}`, async () => {
      const r = await app.inject({url: path, headers}); expect(r.statusCode, r.body).toBe(404);
    });
  }
  it('makes NAV retries idempotent and refuses conflicting values', async () => {
    const url = '/api/admin/import/nav';
    const repeated = await app.inject({method: 'POST', url, headers, payload: payload(url)});
    expect(repeated.json().rowsInserted).toBe(0);
    expect(repeated.json().status).toBe('SUCCESS');
    const conflict = await app.inject({method: 'POST', url, headers, payload: {planId, source: 'test', rows: [{navDate: '2026-01-01', nav: '999'}]}});
    expect(conflict.json().status).toBe('FAILED');
    const value = await app.db.query('SELECT nav FROM nav_history WHERE scheme_plan_id=$1 AND nav_date=$2', [planId, '2026-01-01']);
    expect(Number(value.rows[0].nav)).toBe(10);
  });
  it('computes portfolio exposures from imported positions', async () => {
    const r = await app.inject(`/api/funds/${schemeId}/exposure`);
    expect(r.json()).toMatchObject({longExposure: 60, shortExposure: 10, grossExposure: 70, netExposure: 50, derivativeExposure: 10});
  });
  it('counts updated AUM rows accurately', async () => {
    const path = '/api/admin/import/aum';
    const r = await app.inject({method: 'POST', url: path, headers, payload: payload(path)});
    expect(r.json()).toMatchObject({rowsInserted: 0, rowsUpdated: 1});
  });
  it('rejects invalid numeric imports', async () => {
    const r = await app.inject({method: 'POST', url: '/api/admin/import/benchmark', headers,
      payload: {benchmarkId, source: 'test', rows: [{valueDate: '2026-01-01', indexValue: 'garbage'}]}});
    expect(r.statusCode).toBe(400);
  });
});
