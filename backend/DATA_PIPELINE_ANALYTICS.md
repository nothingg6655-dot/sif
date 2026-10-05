# Data pipeline and analytics

## Ingestion lifecycle

1. Register file and SHA-256 in `source_file`.
2. Refuse an exact duplicate unless the request explicitly reprocesses it.
3. Create `ingest_batch` with `STARTED` status.
4. Parse each row/section into `raw_source_record`.
5. Normalize whitespace but preserve the original payload.
6. Validate identifiers, dates, numeric values and parent mappings.
7. Write canonical records in a transaction.
8. Record rejected or suspicious rows in `data_quality_issue`.
9. Mark the batch `SUCCEEDED`, `PARTIAL` or `FAILED`.
10. Trigger affected analytics only after successful commit.

## NAV validation

- Ignore structural header rows lacking code, numeric NAV or date.
- NAV must be greater than zero.
- ISIN must match the database constraint.
- Duplicate `(nav_series_id, nav_date)` with the same value is idempotent.
- A duplicate with a different value becomes a quality issue; do not silently overwrite it.
- Detect implausible one-day movements using a configurable threshold, but allow reviewed exceptions.

## Analytics methodology

Every run writes an `analytics_run` containing methodology version, parameters, code version and input cutoff date. Store results in `scheme_metric` and preserve AMC-published metrics separately in `reported_metric`.

Core formulas:

```text
simple return = ending NAV / starting NAV - 1
daily return = NAV(t) / NAV(t-1) - 1
annualized volatility = sample stddev(daily returns) * sqrt(trading days)
drawdown = NAV / running maximum NAV - 1
maximum drawdown = minimum drawdown
gross exposure = long exposure + absolute(short exposure)
net exposure = long exposure - absolute(short exposure)
active return = fund return - benchmark return
```

Use the closest valid NAV on or before each period boundary. Publish the exact boundary policy. Do not calculate CAGR for a period shorter than one year.

Sharpe, Sortino and VaR require explicit stored assumptions. Alpha, beta, tracking error, information ratio and capture ratios remain unavailable until aligned benchmark history exists.

## Scheduling

- NAV import: after source publication on each business day
- Data-quality scan: after every import
- Returns/risk: after new NAV commit
- Benchmark-relative analytics: after both NAV and benchmark data are available
- Portfolio/AUM: when official disclosures arrive

Jobs must be idempotent, retryable and protected against overlapping execution for the same source/date.
