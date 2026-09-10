# DynaSIF Backend Integration Gaps

## Summary

This document tracks frontend requirements that are not currently available from the DynaSIF (`dynasif-api`) backend. It outlines existing backend support, current frontend fallback behaviors, and suggested API endpoints for future implementation.

---

## Integration Status

| Feature | Backend Available | Frontend Source | Status |
|---|---|---|---|
| Schemes List | Yes | API | Fully connected via `GET /api/funds` |
| Scheme Overview | Yes | API | Connected via `GET /api/funds/:schemeId` |
| Fund Plans & ISINs | Yes | API | Connected via `GET /api/funds/:schemeId/plans` |
| Fund Managers | Yes | API | Connected via `GET /api/funds/:schemeId/managers` |
| NAV Latest & History | Yes | API | Connected via `GET /api/plans/:planId/nav/...` |
| AUM Latest & History | Yes | API | Connected via `GET /api/funds/:schemeId/aum/...` |
| Performance / Returns | Yes | API | Connected via `GET /api/plans/:planId/returns` |
| Risk Metrics & History | Yes | API | Connected via `GET /api/plans/:planId/risk-metrics` |
| Top Holdings | Yes | API | Connected via `GET /api/funds/:schemeId/top-holdings` |
| Sector Allocation | Yes | API | Connected via `GET /api/funds/:schemeId/sectors` |
| Asset Allocation | Yes | API | Connected via `GET /api/funds/:schemeId/asset-allocation` |
| Benchmark Details | Yes | API | Connected via `GET /api/funds/:schemeId/benchmark` |
| Multi-Fund Compare | Yes | API | Connected via `GET /api/funds/compare/...` |
| Scheme Search | Yes | API | Connected via `GET /api/search?q=...` |
| NFOs (Live Offers) | No | Mock | Frontend uses mock fallback |
| Upcoming Funds | No | Mock | Frontend uses mock fallback |
| Portfolio Turnover | No | Mock | Frontend uses mock fallback |
| Market Ticker Snapshot | No | Mock | Frontend uses mock fallback |
| Monthly Returns Matrix | No | Mock | Frontend uses mock fallback |
| Investor Watchlist | No | Local State | Managed via React context / client state |

---

## Missing Backend Features

### 1. NFOs & Upcoming Fund Offers

**Frontend requirement:**
Display active New Fund Offers (NFOs) and upcoming DynaSIF scheme launches in the Tracker section.

**Where used:**
- `src/pages/Tracker/LiveNfo.tsx`
- `src/pages/Tracker/UpcomingFunds.tsx`

**Backend status:**
Not available. The database currently only contains active schemes in `schemes` and `scheme_plans`.

**Current frontend behavior:**
Frontend continues using existing mock data in `src/data/nfos.ts` and `src/data/upcomingFunds.ts`.

**Required API/data:**
- `id`, `fundName`, `openDate`, `closeDate`, `baseNav`, `minInvestment`, `strategy`, `risk`, `status`

**Suggested endpoint:**
`GET /api/nfos` and `GET /api/upcoming-funds`

**Priority:**
Medium

---

### 2. Portfolio Turnover Metric

**Frontend requirement:**
Portfolio turnover ratio displayed in the fund factsheet analytics.

**Where used:**
- `src/components/ui/Modal.tsx` (`FundFactsheetModal`)

**Backend status:**
Not available in `schemes` or `portfolio_positions`.

**Current frontend behavior:**
Frontend uses calculated mock turnover value.

**Required API/data:**
- `turnoverRatio: number`

**Suggested endpoint:**
`GET /api/funds/:schemeId/analytics` or added to `GET /api/funds/:schemeId`

**Priority:**
Low

---

### 3. Monthly Returns Matrix (Calendar Returns)

**Frontend requirement:**
Monthly return breakdown grid (e.g. month-by-month return matrix for 2024, 2025, 2026).

**Where used:**
- `src/components/ui/Modal.tsx` (`FundFactsheetModal`)

**Backend status:**
Backend provides standard period returns (`1M`, `3M`, `6M`, `1Y`, `3Y`, `5Y`, `SINCE_INCEPTION`), but no calendar month grid endpoint.

**Current frontend behavior:**
Frontend uses generated monthly return matrix seed as fallback.

**Required API/data:**
- `monthlyReturns: Record<string, (number | null)[]>`

**Suggested endpoint:**
`GET /api/plans/:planId/monthly-returns`

**Priority:**
Medium

---

### 4. Market Ticker Snapshot

**Frontend requirement:**
Top market ticker bar showing key benchmark indices (e.g. Nifty 50, Sensex, DynaSIF Multi-Asset Index) with current NAV/Index value and % change.

**Where used:**
- `src/components/layout/MarketTicker.tsx`

**Backend status:**
Backend supports individual benchmark history (`GET /api/benchmarks/:id/history`), but no composite ticker snapshot endpoint.

**Current frontend behavior:**
Frontend uses static ticker seed data in `src/data/marketTicker.ts`.

**Required API/data:**
- `Array<{ name: string, nav: number, change: number }>`

**Suggested endpoint:**
`GET /api/benchmarks/ticker`

**Priority:**
Low

---

### 5. Tax Treatment & Detailed Investment Rules

**Frontend requirement:**
Specific tax implications (e.g. "Taxed as per income slab" or "Equity taxation LTCG 12.5%"), minimum SIP amount, and liquidity settlement rules (T+1 / T+2).

**Where used:**
- `src/components/ui/Modal.tsx` (`FundFactsheetModal`)

**Backend status:**
Backend schema includes `minimum_investment` and `exit_load`, but lacks structured `tax_treatment`, `min_sip`, and `liquidity_settlement` fields.

**Current frontend behavior:**
Frontend falls back to rule-based defaults or mock values.

**Required API/data:**
- `taxTreatment: string`, `minSip: number`, `liquidity: string`

**Suggested endpoint:**
Extended fields in `GET /api/funds/:schemeId`

**Priority:**
Low

---

## Known Limitations

1. **Database Seed Data Dependencies**: In local dev mode without an active PostgreSQL instance or populated database, the API layer catches fetch errors and gracefully falls back to mock data.
2. **ISIN vs Plan Selection**: Backend separates ISINs and Plans from Schemes. The frontend API adapter automatically queries preferred active Direct Growth plans for a given scheme ID to obtain NAV and return metrics.

---

## Future Backend Work

- Implement `/api/nfos` and `/api/upcoming-funds` endpoints.
- Add monthly return calculation job in backend analytics worker.
- Provide market ticker snapshot API for top benchmark indices.
