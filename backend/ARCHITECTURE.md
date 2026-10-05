# Architecture

## System boundaries

```text
AMC / AMFI / SEBI files
          |
          v
 Ingestion and validation
          |
          v
 PostgreSQL source + canonical data
          |
          +----> Analytics jobs ----> calculated metrics
          |
          v
       REST API
          |
          v
 Web/mobile clients
```

## Backend modules

- `schemes`: strategy identity, plans/options, ISINs and current facts
- `nav`: current/history queries and downloadable data
- `performance`: reported and calculated returns
- `risk`: volatility, drawdown and ratio metrics
- `benchmarks`: definitions, components and index history
- `portfolio`: holdings, sectors and exposures
- `aum`: AUM history, flows and folios
- `documents`: metadata, storage links and extracted fields
- `ingestion`: source registration, parsing, validation and normalization
- `admin`: mappings, issue review and reprocessing

Each module should contain route, schema, service, repository and test files. Route handlers validate and authorize; services contain business logic; repositories contain database queries.

## Data layers

1. Source layer: immutable files, batches and raw records.
2. Canonical layer: validated schemes, NAV, AUM, portfolio and benchmark facts.
3. Analytics layer: reproducible calculated metrics.
4. API layer: stable response models optimized for clients.

## Key decisions

- A NAV series is separate from an ISIN because payout and reinvestment ISINs may share a published NAV row.
- PostgreSQL `numeric` is used for financial values; JavaScript floating-point values must not be used for storage math.
- Long-running imports and analytics execute as jobs, not HTTP request work.
- Raw source records are append-only. Corrections produce new canonical revisions or effective-dated records.
- Files live in object storage in production; PostgreSQL stores their hash, URI, metadata and extracted facts.

## Environments

- Local: Docker PostgreSQL and local file storage
- Test: isolated PostgreSQL database reset per suite
- Staging: production-like storage and scheduled jobs with non-production credentials
- Production: managed PostgreSQL, object storage, backups, monitoring and least-privilege roles
