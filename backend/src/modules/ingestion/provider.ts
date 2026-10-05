export enum ProviderType {
  DYNASIF = 'DYNASIF',
  QSIF = 'QSIF',
  ISIF = 'ISIF',
  UNKNOWN = 'UNKNOWN'
}

export function detectProvider(fileName: string, sheetNames: string[], extractedProviders: (string | undefined)[]): ProviderType {
  // 1. Check extracted metadata first (most reliable if found)
  for (const p of extractedProviders) {
    if (p) {
       if (p.toUpperCase() === 'QSIF') return ProviderType.QSIF;
       if (p.toUpperCase() === 'ISIF') return ProviderType.ISIF;
       if (p.toUpperCase() === 'DYNASIF') return ProviderType.DYNASIF;
    }
  }

  const normalizedFileName = fileName.toLowerCase();
  
  if (normalizedFileName.includes('dynasif')) return ProviderType.DYNASIF;
  if (normalizedFileName.includes('qsif')) return ProviderType.QSIF;
  if (normalizedFileName.includes('isif')) return ProviderType.ISIF;
  
  // Fallback to inspecting sheet names
  const allSheets = sheetNames.join(' ').toLowerCase();
  if (allSheets.includes('dynasif')) return ProviderType.DYNASIF;
  if (allSheets.includes('qsif')) return ProviderType.QSIF;
  if (allSheets.includes('isif')) return ProviderType.ISIF;

  return ProviderType.UNKNOWN;
}
