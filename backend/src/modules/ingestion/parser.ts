import ExcelJS from 'exceljs';

export interface SheetMetadata {
  provider?: string;
  schemeName?: string;
  planType?: string;
  optionType?: string;
}

export interface ParsedSheet {
  sheetName: string;
  rowCount: number;
  headers: string[];
  metadataRows: string[];
  sheetMetadata: SheetMetadata;
  sampleRows: any[][];
  rawRows: any[][]; // keeping raw rows for later processing
}

export interface ParsedWorkbook {
  fileName: string;
  sheets: ParsedSheet[];
}

function extractMetadata(metadataRows: string[]): SheetMetadata {
  const meta: SheetMetadata = {};
  for (const rowText of metadataRows) {
    const text = rowText.toLowerCase();
    
    // Provider detection from metadata text
    if (text.includes('qsif') || text.includes('q-sif')) meta.provider = 'QSIF';
    else if (text.includes('dynasif') || text.includes('dyna sif')) meta.provider = 'DYNASIF';
    else if (text.includes('isif') || text.includes('i-sif')) meta.provider = 'ISIF';

    // Scheme detection heuristic
    if (text.includes('fund') || text.includes('scheme') || text.includes('allocator')) {
      // Avoid descriptive titles
      if (!text.includes('historical nav data') && !text.includes('from ') && !text.includes('to ')) {
        // Prefer cleaner rows (without Plan/Option explicitly embedded if we already have one, or the shorter cleaner one)
        const isClean = !text.includes('plan') && !text.includes('option');
        
        if (!meta.schemeName) {
           meta.schemeName = rowText.trim();
        } else {
           // We already have a candidate. If the new one is cleaner (doesn't have 'plan'/'option'), we prefer it.
           // If both are clean or both are dirty, we could just take the shorter one as it's likely the base name.
           const currentIsClean = !meta.schemeName.toLowerCase().includes('plan') && !meta.schemeName.toLowerCase().includes('option');
           if (isClean && !currentIsClean) {
             meta.schemeName = rowText.trim();
           } else if (isClean === currentIsClean) {
             if (rowText.length < meta.schemeName.length) {
               meta.schemeName = rowText.trim();
             }
           }
        }
      }
    }

    // Plan & Option detection
    if (text.includes('direct')) meta.planType = 'Direct';
    if (text.includes('regular')) meta.planType = 'Regular';
    if (text.includes('idcw')) meta.optionType = 'IDCW';
    if (text.includes('growth')) meta.optionType = 'Growth';
  }

  // Refine scheme name if plan/option is embedded
  if (meta.schemeName) {
     meta.schemeName = (meta.schemeName.split(/- (?:IDCW|Growth|Direct|Regular)/)[0] ?? '').trim();
  }

  return meta;
}

export async function parseExcelBuffer(buffer: Buffer, fileName: string): Promise<ParsedWorkbook> {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(Uint8Array.from(buffer).buffer);

  const parsedSheets: ParsedSheet[] = [];

  // Known header keywords for scoring
  const headerKeywords = ['nav', 'net asset', 'date', 'price', 'scheme', 'plan', 'option', 'category', 'amc', 'fund'];

  workbook.eachSheet((worksheet, sheetId) => {
    if (worksheet.rowCount === 0) return;

    const allRows: any[][] = [];
    let maxCols = 0;

    worksheet.eachRow({ includeEmpty: false }, (row, rowNumber) => {
      const rowValues = row.values as any[];
      const normalizedRow = Array.isArray(rowValues) ? rowValues.slice(1) : [];
      if (normalizedRow.length > maxCols) maxCols = normalizedRow.length;
      allRows.push(normalizedRow);
    });

    if (allRows.length === 0) return;

    // Header Detection using Scoring
    let detectedHeaderRowIdx = 0;
    let maxScore = -1;

    // Check first 30 rows
    const searchLimit = Math.min(30, allRows.length);
    for (let i = 0; i < searchLimit; i++) {
      const row = allRows[i] ?? [];
      let score = 0;
      let stringColCount = 0;

      for (const cell of row) {
        if (typeof cell === 'string') {
          const val = cell.toLowerCase().trim();
          if (val) stringColCount++;
          
          if (headerKeywords.some(kw => val.includes(kw))) {
            score += 2; // high score for known keywords
          }
        }
      }
      
      // Bonus for having multiple text columns (typical of headers vs single merged title row)
      if (stringColCount >= 3) {
        score += stringColCount;
      }

      if (score > maxScore) {
        maxScore = score;
        detectedHeaderRowIdx = i;
      }
    }

    const headerRow = allRows[detectedHeaderRowIdx] ?? [];
    // We pad/truncate all rows to match the header length
    const effectiveColCount = headerRow.length;
    
    const headers = headerRow.map(v => v ? String(v).trim() : '');

    // Metadata extraction
    const metadataRowsRaw = allRows.slice(0, detectedHeaderRowIdx);
    const metadataStrings = metadataRowsRaw.map(r => r.filter(c => c).join(' ')).filter(s => s.trim().length > 0);
    const sheetMetadata = extractMetadata(metadataStrings);

    // Data rows
    const rawDataRows = allRows.slice(detectedHeaderRowIdx + 1).map(row => {
      const paddedRow = new Array(effectiveColCount).fill(undefined);
      for(let i=0; i<Math.min(row.length, effectiveColCount); i++) {
        paddedRow[i] = row[i];
      }
      return paddedRow;
    });

    parsedSheets.push({
      sheetName: worksheet.name,
      rowCount: rawDataRows.length,
      headers,
      metadataRows: metadataStrings,
      sheetMetadata,
      sampleRows: rawDataRows.slice(0, 5),
      rawRows: rawDataRows
    });
  });

  return {
    fileName,
    sheets: parsedSheets
  };
}
