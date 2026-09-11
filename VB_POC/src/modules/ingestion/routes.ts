import type { FastifyInstance } from 'fastify';
import multipart from '@fastify/multipart';
import { parseExcelBuffer } from './parser.js';
import { detectProvider } from './provider.js';
import { classifySheet, DatasetType } from './classifier.js';
import { randomUUID } from 'crypto';
import { mapColumns } from './mapper.js';
import { validateNavRow, RowStatus } from './validator.js';
import { normalizeDate, normalizeNumber, normalizeText } from './transformer.js';
import { importNavHistory } from './importers/navImporter.js';

export async function registerIngestionRoutes(app: FastifyInstance) {
  // Register multipart to handle file uploads
  await app.register(multipart, {
    limits: {
      fileSize: 50 * 1024 * 1024 // 50MB max file size
    }
  });

  app.post('/excel/analyze', async (request, reply) => {
    const data = await request.file();
    if (!data) {
      return reply.status(400).send({ error: 'No file uploaded' });
    }

    const buffer = await data.toBuffer();
    const fileName = data.filename;

    try {
      // 1. Parse Excel
      const parsedWorkbook = await parseExcelBuffer(buffer, fileName);

      // 2. Detect Provider
      const sheetNames = parsedWorkbook.sheets.map(s => s.sheetName);
      const extractedProviders = parsedWorkbook.sheets.map(s => s.sheetMetadata?.provider);
      const provider = detectProvider(fileName, sheetNames, extractedProviders);

      // 3. Classify Sheets
      const classifiedSheets = parsedWorkbook.sheets.map(sheet => {
        const classification = classifySheet(sheet.sheetName, sheet.headers);
        const mappings = mapColumns(sheet.headers, classification.datasetType);
        return {
          sheetName: sheet.sheetName,
          rowCount: sheet.rowCount,
          headers: sheet.headers,
          sampleRows: sheet.sampleRows,
          rawRows: sheet.rawRows, // included for POC
          datasetType: classification.datasetType,
          confidence: classification.confidence,
          sheetMetadata: sheet.sheetMetadata,
          mappings
        };
      });

      // 4. Generate Session ID
      const sessionId = randomUUID();

      // We'd typically store this session data (buffer or parsed sheets) 
      // in a temp file or Redis for the next steps. For POC, we just return it.

      return {
        sessionId,
        fileName,
        provider,
        sheets: classifiedSheets
      };
    } catch (err: any) {
      request.log.error(err);
      return reply.status(500).send({ error: 'Failed to analyze Excel file', details: err.message });
    }
  });

  app.post('/excel/commit', async (request, reply) => {
    const { datasetType, provider, mappings, rawRows, sheetMetadata } = request.body as any;

    if (!datasetType || !rawRows || !mappings) {
      return reply.status(400).send({ error: 'Missing required parameters' });
    }

    try {
      // 1. Transform & Validate
      const parsedRows = rawRows
        .map((row: any[]) => {
          const parsedData: any = {};
          if (provider) {
            parsedData.amc_name = provider; // For scheme resolution
          }

          mappings.forEach((mapping: any, i: number) => {
            if (mapping.targetField && row[i] !== undefined) {
              let val = row[i];
              if (mapping.targetField.includes('date')) val = normalizeDate(val);
              else if (['nav', 'repurchase_price', 'sale_price'].includes(mapping.targetField)) val = normalizeNumber(val);
              else val = normalizeText(val);

              parsedData[mapping.targetField] = val;
            }
          });

          // Metadata fallback
          if (!parsedData.scheme_name && sheetMetadata?.schemeName) {
            parsedData.scheme_name = sheetMetadata.schemeName;
          }
          if (!parsedData.plan_type && sheetMetadata?.planType) {
            parsedData.plan_type = sheetMetadata.planType;
          }
          if (!parsedData.option_type && sheetMetadata?.optionType) {
            parsedData.option_type = sheetMetadata.optionType;
          }

          return parsedData;
        })
        .filter((parsedData: any) => {
           // Filter out rows without numeric NAV or valid Date
           if (datasetType === DatasetType.NAV_HISTORY) {
              return parsedData.nav !== null && parsedData.nav !== undefined && parsedData.nav_date !== null;
           }
           return true;
        })
        .map((parsedData: any) => {
          // Validation for NAV specifically
          if (datasetType === DatasetType.NAV_HISTORY) {
            return validateNavRow(parsedData);
          }
          
          // For other datasets, just return a generic valid status (POC)
          return { status: RowStatus.VALID_NEW, errors: [], warnings: [], parsedData };
        });

      // 2. Import
      let result = { inserted: 0, updated: 0, skipped: 0, failed: 0, errors: [] as string[] };
      
      if (datasetType === DatasetType.NAV_HISTORY) {
        result = await importNavHistory(app.db, parsedRows, null);
      } else {
        result.failed = rawRows.length;
        result.errors.push(`Importer for ${datasetType} not implemented yet`);
      }

      return result;

    } catch (err: any) {
      request.log.error(err);
      return reply.status(500).send({ error: 'Failed to commit data', details: err.message });
    }
  });

  app.post('/excel/create-master', async (request, reply) => {
    const { provider, schemeName, planType, optionType } = request.body as any;
    if (!provider || !schemeName || !planType || !optionType) {
      return reply.status(400).send({ error: 'Missing required master data parameters' });
    }

    try {
      const resolver = new (await import('./resolver.js')).Resolver(app.db);
      const planId = await resolver.createMissingMaster(provider, schemeName, planType, optionType);
      return { success: true, planId };
    } catch (err: any) {
      request.log.error(err);
      return reply.status(500).send({ error: 'Failed to create missing master data', details: err.message });
    }
  });
}
