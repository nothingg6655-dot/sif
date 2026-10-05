# Cursor implementation plan

Use one phase per Cursor task. Ask Cursor to inspect the repository and relevant documents before changing files, keep each phase testable, and stop if a migration or test fails.

## Phase 1: scaffold

```text
Read docs/PRODUCT_REQUIREMENTS.md, docs/ARCHITECTURE.md and all .cursor/rules files. Scaffold a Node.js 22 TypeScript Fastify backend using strict TypeScript, Zod, Pino, Prisma, Vitest and Docker Compose with PostgreSQL 15. Add .env.example, health endpoint, graceful shutdown, linting and test scripts. Do not implement business modules yet. Run checks and summarize created files.
```

## Phase 2: database

```text
Read docs/DATABASE.md and database/migrations/0001_initial_schema.sql. Configure the PostgreSQL connection and migration workflow. Add an idempotent seed for 360 ONE/DynaSIF organizations, categories, asset classes and metric definitions. Add integration tests proving migrations and seeds work on an empty database. Preserve numeric values as decimals.
```

## Phase 3: scheme API

```text
Implement the schemes module following docs/BACKEND_API.md. Add list/detail endpoints, NAV-series and unit-class representations, repositories, Zod schemas and tests. Include source/as-of metadata. Do not return missing values as zero.
```

## Phase 4: ingestion

```text
Implement source-file registration, ingestion batches, raw-record persistence and NAV spreadsheet parsing following docs/DATA_PIPELINE_ANALYTICS.md. Ignore structural rows, map aliases safely, separate NAV series from ISIN unit classes, make retries idempotent and record quality issues. Add fixtures and integration tests before adding admin routes.
```

## Phase 5: NAV and analytics

```text
Implement latest/history/download NAV endpoints and the first analytics job. Calculate supported returns, volatility, drawdown, best/worst day and positive/negative-day percentages. Store analytics_run assumptions and scheme_metric results. Return unavailable state when history is insufficient. Add deterministic formula tests.
```

## Phase 6: documents and scheme facts

```text
Implement manager, benchmark, risk, expense, load, transaction-rule, allocation-limit, strategy-information and document queries. Seed facts extracted from the supplied DynaSIF summary and ISID with source lineage and effective dates. Add endpoint tests.
```

## Phase 7: future data modules

```text
Implement empty-but-functional AUM, portfolio, sector, exposure and benchmark-history modules. Endpoints should return structured unavailable responses until official records exist. Add import interfaces and validation without inventing data.
```

## Phase 8: hardening

```text
Apply docs/TESTING_SECURITY.md. Add authentication for admin endpoints, rate limiting, upload protections, audit events, request IDs, readiness checks, metrics, CI and backup/restore documentation. Run the complete test and migration suite and fix failures.
```

## Cursor working rules

- Give Cursor one phase at a time.
- Review migrations before executing them against shared databases.
- Require tests and a concise change summary after every phase.
- Do not ask Cursor to generate fake financial observations.
- Commit after each completed phase so changes remain reviewable.
