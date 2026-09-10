# DynaSIF Missing Fields & Database Schema Comparison Report (`missingn-comparision.md`)

## Executive Summary

This document provides a comprehensive breakdown of what was previously missing in the frontend (`mf_poc`), what has been added to the PostgreSQL schema (`dynasif_moneycontrol_postgres.sql`), and what remains pending for Excel data ingestion.

---

## Current Status Overview

| Category | Status | Details |
|---|---|---|
| **Database Schema Gaps** | **0 Remaining** | 100% of all required frontend metrics, systematic rules, liquidity terms, tax rules, monthly return grids, turnover ratios, TER histories, derivative exposure histories, and benchmark analytics now have dedicated tables and columns in PostgreSQL. |
| **Data Rows & Ingestion** | **Pending Excel Sheet** | Database tables are created and schema-ready. Actual numerical rows for monthly returns, turnover, TER, tax rules, and benchmark fundamentals will be populated when you upload/provide the Excel sheet. |
| **Non-Financial / Client Features** | **Handled Gracefully** | Live NFOs (`[]`), Upcoming Schemes (`[]`), and Investor Watchlist (stored in browser `localStorage`). |

---

## Detailed Comparison Matrix

| # | Feature / Metric | Database Schema Table & Column | Database Schema Status | Data Row Status | Backend API Route | Frontend Display Status |
|---|---|---|---|---|---|---|
| 1 | **Minimum SIP Amount** | `scheme_systematic_plans.minimum_amount` | **Supported** | Pending Excel Import | `GET /api/funds/:schemeId` | Displays `"—"` until Excel data ingested |
| 2 | **SIP / STP / SWP Rules** | `scheme_systematic_plans` | **Supported** | Pending Excel Import | `GET /api/funds/:schemeId/plans` | Displays `"—"` until Excel data ingested |
| 3 | **Tax Treatment Info** | `scheme_tax_rules` | **Supported** | Pending Excel Import | `GET /api/funds/:schemeId` | Displays `"—"` until Excel data ingested |
| 4 | **Settlement Liquidity** | `scheme_liquidity_rules` | **Supported** | Pending Excel Import | `GET /api/funds/:schemeId` | Displays `"—"` until Excel data ingested |
| 5 | **Monthly Returns Grid** | `monthly_returns` | **Supported** | Pending Excel Import | `GET /api/plans/:planId/returns` | Displays empty calendar notice until Excel data ingested |
| 6 | **Portfolio Turnover Ratio** | `portfolio_turnover_history` | **Supported** | Pending Excel Import | `GET /api/funds/:schemeId` | Displays `"—"` until Excel data ingested |
| 7 | **Expense Ratio History (TER)** | `scheme_expense_ratio_history` | **Supported** | Pending Excel Import | `GET /api/funds/:schemeId/plans` | Displays `"—"` until Excel data ingested |
| 8 | **Derivative Exposure History** | `derivative_exposure_history` | **Supported** | Pending Excel Import | `GET /api/funds/:schemeId/exposure` | Displays `"—"` until Excel data ingested |
| 9 | **Market Ticker Snapshot Bar** | `index_master_reference`, `benchmark_values` | **Supported** | Pending Excel Import | `GET /api/benchmarks/ticker` | Ticker bar hidden/empty until index data ingested |
| 10 | **Benchmark Risk-o-meter** | `index_riskometer_history`, `benchmark_risk_history` | **Supported** | Pending Excel Import | `GET /api/benchmarks/:id/risk` | Displays `"—"` until Excel data ingested |
| 11 | **Benchmark Performance & Facts** | `benchmark_facts`, `benchmark_performance_snapshot` | **Supported** | Pending Excel Import | `GET /api/benchmarks/:id/history` | Displays `"—"` until Excel data ingested |
| 12 | **Benchmark PE / PB / Yield** | `benchmark_fundamentals_snapshot` | **Supported** | Pending Excel Import | `GET /api/benchmarks/:id/history` | Displays `"—"` until Excel data ingested |
| 13 | **Benchmark Holdings & Sectors** | `benchmark_constituent_weights`, `benchmark_sector_weights` | **Supported** | Pending Excel Import | `GET /api/benchmarks/:id/history` | Displays `"—"` until Excel data ingested |
| 14 | **Data Provenance Metadata** | `source_documents` | **Supported** | Seeded with SID & NAV Files | `GET /api/admin/source-documents` | Available |
| 15 | **Live NFO Offers** | N/A (Scheme is active) | N/A | No Live NFO Window Open | `GET /api/nfos` | Displays "No live NFO offers available" |
| 16 | **Upcoming Scheme Launches** | N/A (Scheme is active) | N/A | No SEBI Draft Filings Open | `GET /api/upcoming-funds` | Displays "No upcoming scheme launches" |
| 17 | **Investor Watchlist** | N/A (Client side feature) | N/A | Client `localStorage` | Client State | Managed locally in browser |

---

## What Still Remains Missing?

### 1. Database Schema Gaps: **NONE (0 Remaining)**
All 18 database tables required to hold DynaSIF scheme information, NAV history, AUM history, portfolio disclosures, systematic plans, liquidity rules, tax rules, turnover ratios, expense ratios, monthly return grids, derivative exposures, and benchmark index snapshots are present in `dynasif_moneycontrol_postgres.sql`.

### 2. Data Content Gaps: **Pending Excel Data Import**
The database tables are structurally complete and ready. The numerical data rows will be populated into PostgreSQL as soon as you export/provide the Excel sheet.

### 3. Frontend Fallback Behavior:
While waiting for the Excel data import:
- Numbers render gracefully as `"—"` (or `null`).
- Collections render appropriate empty state notices ("No data loaded yet").
- **No fake or mock financial data is injected into the application.**
