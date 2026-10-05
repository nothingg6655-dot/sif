import { beforeAll, afterAll, describe, expect, it } from 'vitest';
import ExcelJS from 'exceljs';
import { buildApp } from '../../app.js';
import { loadConfig } from '../../config.js';

describe('Excel import authorization and analysis', () => {
  let app: Awaited<ReturnType<typeof buildApp>>;
  beforeAll(async () => {
    app = await buildApp({ ...loadConfig(), ADMIN_API_KEY: 'test-admin-key', LOG_LEVEL: 'fatal' });
  });
  afterAll(async () => { await app.close(); });
  for (const endpoint of ['analyze', 'commit', 'create-master']) {
    it(`rejects anonymous ${endpoint} before processing`, async () => {
      const response = await app.inject({ method: 'POST', url: `/api/admin/import/excel/${endpoint}`, payload: {} });
      expect(response.statusCode).toBe(401);
    });
  }
  it('analyzes an actual workbook with an administrator key', async () => {
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('NAV History');
    sheet.addRow(['Scheme Name', 'Plan', 'Option', 'NAV Date', 'NAV']);
    sheet.addRow(['Mobile integration fund', 'Direct', 'Growth', '2026-01-01', 10]);
    const buffer = Buffer.from(await workbook.xlsx.writeBuffer());
    const boundary = 'mobile-test-boundary';
    const payload = Buffer.concat([
      Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="dynasif.xlsx"\r\nContent-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet\r\n\r\n`),
      buffer, Buffer.from(`\r\n--${boundary}--\r\n`),
    ]);
    const response = await app.inject({ method: 'POST', url: '/api/admin/import/excel/analyze', payload,
      headers: { 'x-admin-key': 'test-admin-key', 'content-type': `multipart/form-data; boundary=${boundary}` } });
    expect(response.statusCode, response.body).toBe(200);
    expect(response.json().sheets[0].datasetType).toBe('NAV_HISTORY');
    expect(response.json().sheets[0].rawRows).toHaveLength(1);
  });
});
