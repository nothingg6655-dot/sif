import { DatasetType } from './classifier.js';

export interface FieldMappingConfig {
  targetField: string;
  aliases: string[];
  required?: boolean;
}

const NAV_HISTORY_MAPPING: FieldMappingConfig[] = [
  { targetField: 'scheme_name', aliases: ['scheme name', 'fund name', 'strategy name', 'sif name', 'scheme'] },
  { targetField: 'plan_type', aliases: ['plan', 'plan type'] },
  { targetField: 'option_type', aliases: ['option', 'option type'] },
  { targetField: 'nav', aliases: ['net asset value', 'nav', 'nav value', 'current nav'] },
  { targetField: 'nav_date', aliases: ['date', 'nav date', 'valuation date', 'date of nav', 'valuation dt', 'nav dt'] },
  { targetField: 'repurchase_price', aliases: ['repurchase price', 'repurchase'] },
  { targetField: 'sale_price', aliases: ['sale price', 'sale'] }
];

const SCHEME_MASTER_MAPPING: FieldMappingConfig[] = [
  { targetField: 'amc_name', aliases: ['amc', 'amc name', 'asset management company'] },
  { targetField: 'scheme_name', aliases: ['scheme name', 'fund name', 'scheme'] },
  { targetField: 'scheme_code', aliases: ['scheme code', 'fund code'] },
  { targetField: 'category', aliases: ['category'] },
  { targetField: 'fund_type', aliases: ['fund type'] }
];

export interface ColumnMappingResult {
  excelColumn: string;
  targetField: string | null;
  confidence: number;
}

export function mapColumns(headers: string[], datasetType: DatasetType): ColumnMappingResult[] {
  let mappingConfig: FieldMappingConfig[] = [];
  
  if (datasetType === DatasetType.NAV_HISTORY) mappingConfig = NAV_HISTORY_MAPPING;
  else if (datasetType === DatasetType.SCHEME_MASTER) mappingConfig = SCHEME_MASTER_MAPPING;
  
  if (mappingConfig.length === 0) {
    // If unknown dataset type, we can't map anything automatically
    return headers.map(header => ({
      excelColumn: header,
      targetField: null,
      confidence: 0
    }));
  }

  return headers.map(header => {
    const normalizedHeader = header.toLowerCase().replace(/[.,!?;:]/g, '').trim();

    let bestMatch: FieldMappingConfig | null = null;
    let highestConfidence = 0;

    for (const config of mappingConfig) {
      for (const alias of config.aliases) {
        const normalizedAlias = alias.toLowerCase().replace(/[.,!?;:]/g, '').trim();
        
        if (normalizedHeader === normalizedAlias) {
          return { excelColumn: header, targetField: config.targetField, confidence: 100 };
        }
        
        // Basic fuzzy matching via includes
        if (normalizedHeader.includes(normalizedAlias) || normalizedAlias.includes(normalizedHeader)) {
          if (highestConfidence < 80) {
            highestConfidence = 80;
            bestMatch = config;
          }
        }
      }
    }

    if (bestMatch) {
      return { excelColumn: header, targetField: bestMatch.targetField, confidence: highestConfidence };
    }

    return { excelColumn: header, targetField: null, confidence: 0 };
  });
}
