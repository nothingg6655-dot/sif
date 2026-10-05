# API verification

Verified 2026-09-08 against `dynasif_api_spec.md`.

- All 39 specified routes exist and pass basic request tests with real PostgreSQL.
- 68 API integration tests and 9 analytics tests pass.
- All 29 public GET routes also returned HTTP 200 against the configured existing database (read-only).
- TypeScript build and lint pass.
- Test imports use a uniquely named schema populated from the setup SQL; cleanup completed, with no test schemas remaining.

## Running checks

`npm test` runs unit tests and skips database tests by default.

To enable the database suite in PowerShell:

```powershell
$env:API_INTEGRATION_TEST='1'
npm test
npm run build
npm run lint
```

The integration suite uses DATABASE_URL from the environment/.env and requires permission to create a test schema. It never imports fixtures into fund_analytics. It uses Fastify injection with real SQL queries; this does not test a deployed reverse proxy, TLS, or load capacity.

## Fixes made

- Reject reversed date ranges, malformed comparison IDs, and more than five IDs on all comparison routes.
- Preserve framework HTTP 4xx statuses, including malformed JSON.
- Preserve pagination totals on empty pages.
- Validate finite decimal input; require positive NAV and benchmark values.
- Distinguish inserted/updated rows for AUM, benchmark and risk-free imports; rolled-back imports report zero committed rows.
- Clamp month offsets to month-end and avoid calculating returns from one observation.
- Use the Vitest runner config loader to avoid the local esbuild config-loading access error.

## Remaining functional limitations

Passing requests does not establish full business-feature completeness:

- Risk recalculation implements volatility and maximum drawdown. Alpha, beta, Sharpe, Sortino, tracking error and information ratio remain null even if benchmark/risk-free data has been imported.
- Composite benchmark history can be read, but this application has no calculation job to populate it.
- Return/risk/rolling endpoints prefer stored metrics without checking whether newer NAV data has arrived; recalculation must be triggered explicitly after imports.
- API examples show percentage-style returns, while calculations emit fractional returns (0.05 for 5%). This contract needs standardization before client integration.
- The general comparison endpoint omits returns described in its spec; a separate comparison/returns route exists.
- BACKEND_API.md describes additional /api/v1 routes, documents, and data-quality workflows that are not implemented. The implemented contract follows dynasif_api_spec.md instead.
- Imports accept structured JSON, not uploaded Excel/PDF files, and recalculations execute synchronously.

The suite covers route availability, basic success responses, authentication, selected validation and missing-record cases, NAV retry/conflict behavior, portfolio exposures, and selected regressions. It does not prove every financial formula, concurrency scenario, response field, or failure-recovery path.
