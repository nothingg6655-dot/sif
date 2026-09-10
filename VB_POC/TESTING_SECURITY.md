# Testing, security and operations

## Test pyramid

- Unit tests: formulas, date selection, parsers and validators
- Repository tests: real PostgreSQL, constraints, transactions and queries
- API tests: authentication, validation, response shape and unavailable-data behavior
- Ingestion fixtures: each supplied workbook/PDF structure plus malformed variants
- End-to-end smoke test: seed → NAV import → analytics → API response

## Required financial test cases

- Duplicate NAV with same and conflicting values
- Missing dates and non-numeric NAV
- Growth versus IDCW payout/reinvestment mapping
- Period boundary on holiday/weekend
- Less than one year of data for CAGR
- Zero/negative starting values rejected
- Drawdown recovery and unrecovered drawdown duration
- Missing risk-free rate for Sharpe/Sortino
- Missing benchmark history
- Portfolio weights not reconciling within tolerance
- Market Value source not automatically treated as AUM

## Security

- Application role is not a PostgreSQL superuser and cannot create schemas/extensions.
- Migration role and runtime role use different credentials.
- Admin ingestion endpoints require strong authentication and authorization.
- Validate file size, MIME type and extension; store uploads outside the web root.
- Hash files and use generated storage keys; never trust client filenames as paths.
- Use parameterized queries and dependency-lockfile scanning.
- Encrypt database connections and backups in production.
- Rotate credentials and keep secrets in the deployment secret manager.
- Record administrative changes in an audit log.

## Observability

Track API latency/error rate, database pool saturation, import duration, rejected rows, latest NAV age, analytics job failures and document-storage failures. Alert when a normally active NAV series becomes stale.

## Definition of done

- Migration runs successfully against a fresh PostgreSQL instance.
- Unit, integration and API tests pass.
- No secrets or personal paths are committed.
- New endpoints have schemas and example responses.
- New source fields have lineage and validation.
- Calculated metrics document methodology and missing-input behavior.
