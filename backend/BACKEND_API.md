# Node.js backend and API contract

## Coding standards

- TypeScript strict mode; no implicit `any`
- ESM modules
- Validate environment and all HTTP inputs with Zod
- Fastify route handlers remain thin
- Business errors use stable codes and appropriate HTTP statuses
- Log request ID and entity IDs, never secrets or entire uploaded documents
- Use UTC internally; financial observation dates remain PostgreSQL `date`

## Configuration

Required environment variables:

```text
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://dynasif_app:password@localhost:5432/dynasif_db
LOG_LEVEL=info
DOCUMENT_STORAGE_ROOT=./storage
```

Commit `.env.example`; never commit `.env`.

## API endpoints

```text
GET  /health
GET  /api/v1/schemes
GET  /api/v1/schemes/:schemeId
GET  /api/v1/schemes/:schemeId/nav-series
GET  /api/v1/nav-series/:navSeriesId/nav/latest
GET  /api/v1/nav-series/:navSeriesId/nav?from=&to=&cursor=&limit=
GET  /api/v1/nav-series/:navSeriesId/performance?asOf=
GET  /api/v1/nav-series/:navSeriesId/risk?asOf=
GET  /api/v1/schemes/:schemeId/benchmark
GET  /api/v1/schemes/:schemeId/aum
GET  /api/v1/schemes/:schemeId/portfolio/latest
GET  /api/v1/schemes/:schemeId/documents
POST /api/v1/admin/ingestions
GET  /api/v1/admin/ingestions/:batchId
GET  /api/v1/admin/data-quality/issues
```

## Response envelope

```json
{
  "data": {},
  "meta": {
    "asOf": "2026-09-01",
    "sourceType": "REPORTED",
    "sourceName": "AMFI",
    "freshness": "CURRENT"
  },
  "error": null
}
```

Unavailable values return `null` with an explanation in metadata. They do not return zero.

## Error shape

```json
{
  "data": null,
  "meta": { "requestId": "..." },
  "error": {
    "code": "NAV_SERIES_NOT_FOUND",
    "message": "The requested NAV series does not exist."
  }
}
```

Do not expose stack traces or database messages outside development.

## Performance

- Cache public scheme metadata briefly at the API layer.
- Cache calculated metrics by series/as-of/methodology version.
- Do not cache ingestion/admin responses.
- Add rate limiting to public and upload endpoints.
- Stream CSV downloads instead of loading full history into memory.
