export enum RowStatus {
  VALID_NEW = 'VALID_NEW',
  VALID_UPDATE = 'VALID_UPDATE',
  VALID_UNCHANGED = 'VALID_UNCHANGED',
  WARNING = 'WARNING',
  ERROR = 'ERROR'
}

export interface ValidationResult {
  status: RowStatus;
  errors: string[];
  warnings: string[];
  parsedData: any; // the normalized data object
}

export function validateNavRow(data: any): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];
  
  if (!data.scheme_name) errors.push('Missing Scheme Name');
  if (!data.plan_type) errors.push('Missing Plan Type');
  if (!data.option_type) errors.push('Missing Option Type');
  if (data.nav === null || data.nav === undefined) errors.push('Missing NAV');
  if (!data.nav_date) errors.push('Missing NAV Date');

  if (data.nav !== null && data.nav <= 0) errors.push('NAV must be greater than 0');

  // Typically we'd check if it exists in DB here or later in importer to set VALID_NEW/UPDATE/UNCHANGED.
  // For basic validation without DB state, we can only set VALID_NEW or ERROR.
  // We'll let the importer refine VALID_NEW to UPDATE/UNCHANGED by querying the DB.
  
  const status = errors.length > 0 ? RowStatus.ERROR : RowStatus.VALID_NEW;

  return {
    status,
    errors,
    warnings,
    parsedData: data
  };
}
