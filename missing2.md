# DynaSIF Missing Financial Data & Feature Inventory (`missing2.md`)

This document records all frontend-requested financial metrics, tables, and features that cannot currently be populated from available official DynaSIF disclosures.

In accordance with strict financial data integrity rules:
- Unavailable scalar metrics are stored as `NULL` in the database and rendered as `"—"` (or `null`) in the frontend.
- Unavailable collections remain empty arrays (`[]`) and display explicit empty state components.
- **No mock data, zero-fill defaults, or fabricated sample numbers are used anywhere.**

---

## Data Availability Matrix

| Metric / Feature | Frontend Location | Required DB Table & Column | Why It Is Missing | Potential Official Source | How It Could Be Obtained |
|---|---|---|---|---|---|
| New Fund Offers (NFO Live Offers) | `Tracker / LiveNfo.tsx` | `schemes` (or `nfo_disclosures`) | Database tracks registered active schemes; no live/active NFO window is open for DynaSIF at present. | AMC NFO Disclosures / CAMS NFO Portal | Ingest live NFO feed from AMC/CAMS API or insert active NFO disclosure records when launched. |
| Upcoming Scheme Launches | `Tracker / UpcomingFunds.tsx` | `upcoming_schemes` / `schemes` | No future/unreleased DynaSIF variant scheme files are published in official disclosures. | SEBI Draft Offer Documents / AMC Filings | Ingest SEBI draft offer document filings for upcoming DynaSIF interval schemes. |
| Portfolio Turnover Ratio | Scheme Factsheet Modal (`Modal.tsx`) | `scheme_analytics.portfolio_turnover` | Portfolio turnover percentage is not disclosed in monthly interval factsheets prior to 1-year trading history. | Monthly Factsheets / Half-Yearly Disclosures | Calculate from 12-month rolling buy/sell transaction disclosures once available. |
| Monthly Calendar Returns Grid | Scheme Factsheet Modal (`Modal.tsx`) | `return_metrics` (monthly breakdown matrix) | Fund was allotted on 2026-03-25; insufficient monthly return history exists to render a multi-year 12-month grid. | Daily NAV History (`nav_history`) | Compute month-by-month return matrix automatically from daily `nav_history` as trading history accumulates. |
| Market Ticker Snapshot Bar | Navigation Bar (`MarketTicker.tsx`) | `composite_benchmark_values`, `benchmark_values` | Backend provides individual benchmark endpoints (`/api/benchmarks/:id/history`), but no aggregated multi-index ticker snapshot API exists. | Real-time / Daily Index Feed (BSE, CRISIL, MCX) | Implement `GET /api/benchmarks/ticker` endpoint returning daily index level changes for Sensex, CRISIL, and iCOMDEX. |
| Expense Ratio (Plan-Level) | Scheme Factsheet Modal, `CompareHub.tsx` | `scheme_plans.expense_ratio_max` | Actual total expense ratio (TER) figures are reported separately from maximum TER limits in semi-annual disclosures. | AMC Monthly TER Disclosures / AMFI Portal | Ingest daily/monthly TER disclosures published by 360 ONE AMC into `scheme_plans.expense_ratio_max`. |
| Minimum SIP Amount | Scheme Factsheet Modal (`Modal.tsx`) | `schemes.minimum_sip` | DynaSIF is an interval scheme with lumpsum allotment terms (Min Rs 10,00,000); SIP terms are not applicable or disclosed. | Scheme Information Document (SID) | Add `minimum_sip` column to `schemes` table if SIP facility is introduced in future disclosures. |
| Tax Treatment Classification | Scheme Factsheet Modal (`Modal.tsx`) | `schemes.tax_treatment` | Structured tax status classification code is not stored as a dedicated column in the current schema. | Scheme Information Document (SID) / Tax Advisor Disclosure | Add `tax_treatment TEXT` column to `schemes` table (e.g., "Specified Mutual Fund / Non-Equity Tax Rules"). |
| Settlement Liquidity Terms | Scheme Factsheet Modal (`Modal.tsx`) | `schemes.liquidity_terms` | Interval window redemption liquidity schedules are currently stored as prose in `fund_type` rather than structured columns. | Scheme Information Document (SID) | Add structured `specified_transaction_period` and `liquidity_settlement` fields to `schemes` table. |

---

## Detailed Gap Descriptions & Remediation Steps

### 1. New Fund Offers (NFOs)
- **Metric / Feature:** Live NFO Offers Listing
- **Frontend Location:** `Tracker/LiveNfo.tsx`
- **Required Database Field:** `nfo_disclosures` or `schemes` with status `NFO_OPEN`
- **Why Missing:** DynaSIF Active Asset Allocator Long-Short Fund was allotted on 2026-03-25. No active NFO is currently open.
- **Potential Official Source:** 360 ONE AMC Official NFO Portal & AMFI NFO Directory.
- **How Obtained:** Create an admin endpoint `POST /api/admin/import/nfo` or ingest live AMFI NFO API feeds into database.

### 2. Upcoming Scheme Launches
- **Metric / Feature:** Upcoming Funds Directory
- **Frontend Location:** `Tracker/UpcomingFunds.tsx`
- **Required Database Field:** `upcoming_schemes` table (`name`, `category`, `expected_launch_date`, `strategy_summary`)
- **Why Missing:** No official SEBI draft offer documents for new DynaSIF scheme variants are currently registered.
- **Potential Official Source:** SEBI Draft Offer Documents archive.
- **How Obtained:** Parse SEBI draft filing RSS feed and populate `upcoming_schemes` table.

### 3. Portfolio Turnover Ratio
- **Metric / Feature:** Portfolio Turnover (%)
- **Frontend Location:** Factsheet Modal (`Modal.tsx`)
- **Required Database Field:** `return_metrics.portfolio_turnover` or `scheme_analytics.portfolio_turnover`
- **Why Missing:** Scheme has less than 1 year of active portfolio trading history required for standard turnover calculation.
- **Potential Official Source:** Monthly Factsheet / Half-Yearly Financial Statements.
- **How Obtained:** Compute `Min(Total Purchases, Total Sales) / Average AUM` once 12 full months of portfolio disclosure data are ingested.

### 4. Monthly Returns Matrix
- **Metric / Feature:** Monthly Calendar Return Breakdown (`Record<year, month_returns[]>`)
- **Frontend Location:** Factsheet Modal (`Modal.tsx`)
- **Required Database Field:** Derived array from `nav_history` aggregated per calendar month.
- **Why Missing:** Short historical duration since allotment (2026-03-25).
- **Potential Official Source:** Calculated from daily `nav_history`.
- **How Obtained:** Implement backend helper `getMonthlyReturnsMatrix(planId)` that calculates `(Nav_month_end / Nav_month_start) - 1` for each calendar month.

### 5. Market Ticker Snapshot Bar
- **Metric / Feature:** Benchmark Live Ticker Bar
- **Frontend Location:** Top Navigation Bar (`MarketTicker.tsx`)
- **Required Database Field:** Latest index value and daily change for benchmark indices in `benchmark_values`.
- **Why Missing:** Frontend currently checks local array; backend endpoint `/api/benchmarks/ticker` not yet registered.
- **Potential Official Source:** BSE / CRISIL / MCX daily index feeds.
- **How Obtained:** Add endpoint `GET /api/benchmarks/ticker` querying `v_latest_benchmark_values`.

### 6. Expense Ratio (TER)
- **Metric / Feature:** Scheme Plan Total Expense Ratio (%)
- **Frontend Location:** `Modal.tsx`, `CompareHub.tsx`
- **Required Database Field:** `scheme_plans.expense_ratio_max`
- **Why Missing:** Stated maximum TER limits (Direct: 0.53%, Regular: 1.63%) are seeded in `scheme_plans`, but daily TER disclosures require ongoing ingestion.
- **Potential Official Source:** AMFI Daily/Monthly TER Disclosure Files.
- **How Obtained:** Update ingestion pipeline to parse AMFI TER files and update `expense_ratio_max` or `expense_ratio_actual`.

---

## Null Handling Verification

All components in the frontend are configured to gracefully display missing values:
- Number fields: `null` renders as `"—"`
- List fields: `null` or `[]` renders empty state illustrations or notices
- Charts: `null` or empty series renders "No historical data available"

No mock or fallback values are injected.
