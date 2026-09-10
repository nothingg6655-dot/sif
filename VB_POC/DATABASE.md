# Database implementation

## Database and schema

- Database name: `dynasif_db`
- PostgreSQL schema: `dynasif`
- Minimum PostgreSQL version: 15
- Required extension: `pgcrypto`

Run the initial schema as the database owner:

```powershell
createdb -U postgres dynasif_db
psql -U postgres -d dynasif_db -f database/migrations/0001_initial_schema.sql
```

## Functional table groups

- Lineage: `source_file`, `ingest_batch`, `raw_source_record`, `data_quality_issue`
- Master: `organization`, `scheme_category`, `scheme`, `scheme_name_alias`
- Plans/NAV identity: `nav_series`, `unit_class`, `nav_series_unit_class`
- Market facts: `nav_observation`, `benchmark_observation`, `aum_observation`
- Scheme facts: risk, managers, benchmark, allocations, rules, expenses and features
- Portfolio: `security`, `sector`, `portfolio_snapshot`, `portfolio_holding`, `portfolio_sector`, `portfolio_exposure`
- Documents: `scheme_document`, `document_extraction`
- Analytics: `metric_definition`, `analytics_run`, `reported_metric`, `scheme_metric`

## Migration rules

- One numbered migration per coherent change.
- Migrations are immutable after use outside local development.
- Apply migrations in CI before deploying application code that depends on them.
- Prefer backward-compatible expand/migrate/contract changes.
- Create large production indexes concurrently in a non-transactional migration.
- Every foreign key needs an intentional delete action.

## Seed order

1. Organizations
2. Scheme categories and asset classes
3. Metric definitions
4. DynaSIF strategy
5. Aliases, NAV series and unit classes
6. Managers and tenures
7. Benchmark and components
8. Allocation, expense, load and transaction rules
9. Documents and source files
10. NAV observations

Seed scripts must be idempotent using stable natural keys and `ON CONFLICT` clauses.

## Query rules

- Always qualify application tables with `dynasif.` or set `search_path` in the connection.
- Use transactions for multi-table normalization.
- Use keyset pagination for large NAV/holding lists.
- Query latest records using indexed date columns and deterministic tie-breaking.
- Never concatenate SQL. Use parameterized queries.
- Return decimal database values as strings or a decimal-library type.

## Backup and retention

- Daily automated backups with point-in-time recovery in production
- Quarterly restore drill
- Retain source-file metadata and raw records according to legal policy
- Never cascade-delete a source file referenced by canonical financial facts
