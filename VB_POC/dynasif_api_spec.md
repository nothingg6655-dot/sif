# DynaSIF / Moneycontrol-like Fund Website API Specification

This file defines the recommended REST APIs for the fund analytics website built on the PostgreSQL schema created earlier.

Base URL example:

`/api`

---

## 1. Fund Master APIs

### GET /api/funds

**Use case:**  
List all funds available in the system. This powers the fund listing page, search results, dropdowns, and comparison selectors.

**Optional query params:**
- `q` — search by fund name, category, AMC, SIF code, ISIN
- `category`
- `amcId`
- `page`
- `limit`

**Example response:**
```json
{
  "data": [
    {
      "schemeId": 1,
      "schemeName": "DynaSIF Active Asset Allocator Long-Short Fund",
      "category": "Active Asset Allocator Long-Short Fund",
      "amc": "360 ONE Asset Management Limited",
      "riskBand": 3,
      "latestNav": 10.5376
    }
  ],
  "page": 1,
  "limit": 20,
  "total": 1
}
```

---

### GET /api/funds/:schemeId

**Use case:**  
Get the main overview of one fund. This powers the Moneycontrol-style overview tab.

**Returns:**
- Scheme name
- Category
- Fund type
- Objective
- AMC
- Benchmark
- Allotment date
- Minimum investment
- Exit load
- Custodian
- Auditor
- Registrar
- Current risk band

**Example response:**
```json
{
  "schemeId": 1,
  "schemeName": "DynaSIF Active Asset Allocator Long-Short Fund",
  "schemeCode": "DYNA/I/H/AALS/25/12/0002/360O",
  "category": "Active Asset Allocator Long-Short Fund",
  "fundType": "Interval investment strategy",
  "minimumInvestment": 1000000,
  "minimumAdditionalInvestment": 20000,
  "allotmentDate": "2026-03-25",
  "riskBand": 3
}
```

---

### GET /api/funds/:schemeId/plans

**Use case:**  
List all available Direct/Regular and Growth/IDCW plans.

**Useful for:**
- Plan selector
- NAV selector
- Comparing direct vs regular plans

**Example response:**
```json
{
  "schemeId": 1,
  "plans": [
    {
      "planId": 1,
      "sifCode": "SIF-88",
      "planType": "Direct Plan",
      "optionType": "Growth Option",
      "isin": "INF579M30109"
    }
  ]
}
```

---

### GET /api/funds/:schemeId/managers

**Use case:**  
Show fund managers and their roles.

**Example response:**
```json
{
  "schemeId": 1,
  "managers": [
    {
      "name": "Mr. Harsh Agarwal",
      "role": "Primary",
      "fromDate": "2026-03-25"
    }
  ]
}
```

---

### GET /api/funds/:schemeId/risk

**Use case:**  
Show current and historical risk band information.

**Example response:**
```json
{
  "currentRiskBand": 3,
  "history": [
    {
      "effectiveDate": "2026-03-25",
      "riskBand": 2
    },
    {
      "effectiveDate": "2026-09-07",
      "riskBand": 3
    }
  ]
}
```

---

### GET /api/funds/:schemeId/allocation-limits

**Use case:**  
Show the stated / permitted investment allocation ranges from the scheme document.

**Important:**  
This is NOT actual current portfolio allocation.

**Example response:**
```json
{
  "limits": [
    {
      "assetClass": "EQUITY_AND_EQUITY_RELATED",
      "minPercentage": 20,
      "maxPercentage": 50
    },
    {
      "assetClass": "DEBT_AND_MONEY_MARKET",
      "minPercentage": 20,
      "maxPercentage": 65
    }
  ]
}
```

---

## 2. NAV APIs

### GET /api/plans/:planId/nav/latest

**Use case:**  
Show the latest NAV for one plan.

**Example response:**
```json
{
  "planId": 1,
  "nav": 10.5376,
  "navDate": "2026-09-01"
}
```

---

### GET /api/plans/:planId/nav/history

**Use case:**  
Show historical NAV chart.

**Optional query params:**
- `from=2026-03-30`
- `to=2026-09-01`

**Example response:**
```json
{
  "planId": 1,
  "data": [
    {
      "date": "2026-03-30",
      "nav": 10.0209
    },
    {
      "date": "2026-03-31",
      "nav": 10.0217
    }
  ]
}
```

---

## 3. Return / Performance APIs

### GET /api/plans/:planId/returns

**Use case:**  
Display period-wise fund returns.

**Optional query params:**
- `period=1M`
- `period=3M`
- `period=6M`
- `period=1Y`
- `period=SINCE_INCEPTION`

**Returns:**
- Absolute return
- Annualized return
- Benchmark return if available

**Example response:**
```json
{
  "period": "3M",
  "absoluteReturn": 4.82,
  "annualizedReturn": null,
  "benchmarkReturn": null
}
```

---

### GET /api/plans/:planId/rolling-returns

**Use case:**  
Power the rolling-return chart.

**Optional query params:**
- `period=1M`
- `period=3M`
- `period=6M`

**Example response:**
```json
{
  "rollingPeriod": "3M",
  "data": [
    {
      "date": "2026-08-31",
      "return": 4.15
    }
  ]
}
```

---

### GET /api/plans/:planId/drawdown

**Use case:**  
Show maximum drawdown and drawdown history.

**Example response:**
```json
{
  "maxDrawdown": -3.42,
  "data": [
    {
      "date": "2026-07-15",
      "drawdown": -1.84
    }
  ]
}
```

---

## 4. AUM APIs

### GET /api/funds/:schemeId/aum/latest

**Use case:**  
Show the most recent available AUM / AAUM.

**Example response:**
```json
{
  "reportDate": "2026-06-30",
  "periodType": "QUARTERLY",
  "closingAum": 20712.94,
  "averageAum": 18129.36,
  "unit": "LAKH"
}
```

---

### GET /api/funds/:schemeId/aum/history

**Use case:**  
Show AUM growth over time.

**Example response:**
```json
{
  "data": [
    {
      "reportDate": "2026-04-30",
      "averageAum": 153.702389984,
      "unit": "CRORE"
    },
    {
      "reportDate": "2026-05-31",
      "averageAum": 188.393257042,
      "unit": "CRORE"
    }
  ]
}
```

---

## 5. Portfolio APIs

### GET /api/funds/:schemeId/portfolio/latest

**Use case:**  
Return the latest complete portfolio disclosure.

**Example response:**
```json
{
  "reportDate": "2026-08-31",
  "positions": []
}
```

If portfolio data is not loaded:
```json
{
  "status": "not_available",
  "message": "Portfolio disclosure data not yet loaded"
}
```

---

### GET /api/funds/:schemeId/portfolio

**Use case:**  
Get portfolio for a specific disclosure date.

**Query param:**
- `date=2026-08-31`

---

### GET /api/funds/:schemeId/top-holdings

**Use case:**  
Power the Top Holdings section.

**Optional query params:**
- `limit=10`

**Example response:**
```json
{
  "reportDate": "2026-08-31",
  "holdings": [
    {
      "securityName": "Example Ltd",
      "sector": "Financial Services",
      "navPercentage": 6.42
    }
  ]
}
```

---

### GET /api/funds/:schemeId/sectors

**Use case:**  
Power the Sector Allocation chart/table.

**Example response:**
```json
{
  "reportDate": "2026-08-31",
  "sectors": [
    {
      "sector": "Financial Services",
      "allocationPercentage": 24.6
    }
  ]
}
```

---

### GET /api/funds/:schemeId/asset-allocation

**Use case:**  
Power the actual asset-allocation section.

**Example response:**
```json
{
  "reportDate": "2026-08-31",
  "allocation": [
    {
      "assetClass": "EQUITY",
      "allocationPercentage": 42.3
    },
    {
      "assetClass": "DEBT",
      "allocationPercentage": 38.1
    }
  ]
}
```

---

## 6. Exposure / Derivatives APIs

### GET /api/funds/:schemeId/exposure

**Use case:**  
Show actual long/short/gross/net/derivative exposure.

**Example response:**
```json
{
  "reportDate": "2026-08-31",
  "longExposure": 72.4,
  "shortExposure": 18.6,
  "grossExposure": 91.0,
  "netExposure": 53.8,
  "derivativeExposure": 28.3
}
```

---

### GET /api/funds/:schemeId/exposure/history

**Use case:**  
Show how long/short exposure changes over time.

---

### GET /api/funds/:schemeId/derivatives

**Use case:**  
Show futures, options, and other derivative positions.

**Optional query param:**
- `date=2026-08-31`

**Example response:**
```json
{
  "reportDate": "2026-08-31",
  "positions": [
    {
      "instrumentName": "NIFTY Futures",
      "positionSide": "SHORT",
      "exposurePercentage": 8.5,
      "expiryDate": "2026-09-24"
    }
  ]
}
```

---

## 7. Benchmark APIs

### GET /api/funds/:schemeId/benchmark

**Use case:**  
Show benchmark definition and component weights.

**Example response:**
```json
{
  "benchmarkName": "25% BSE SENSEX TRI + 60% CRISIL Short Term Bond Fund Index + 15% iCOMDEX Composite Index",
  "components": [
    {
      "name": "BSE SENSEX TRI",
      "weight": 25
    },
    {
      "name": "CRISIL Short Term Bond Fund Index",
      "weight": 60
    },
    {
      "name": "iCOMDEX Composite Index",
      "weight": 15
    }
  ]
}
```

---

### GET /api/benchmarks/:benchmarkId/history

**Use case:**  
Provide benchmark chart data.

**Optional query params:**
- `from`
- `to`

---

### GET /api/funds/:schemeId/benchmark/history

**Use case:**  
Return the calculated composite benchmark series for the fund.

---

## 8. Risk Analytics APIs

### GET /api/plans/:planId/risk-metrics

**Use case:**  
Return all important Moneycontrol-style risk metrics in one API.

**Optional query param:**
- `period=3M`
- `period=6M`
- `period=1Y`
- `period=SINCE_INCEPTION`

**Example response:**
```json
{
  "period": "6M",
  "volatility": 8.21,
  "alpha": null,
  "beta": null,
  "sharpeRatio": null,
  "sortinoRatio": null,
  "trackingError": null,
  "informationRatio": null,
  "maxDrawdown": -3.42
}
```

`null` should be returned when the required benchmark or risk-free-rate data is not yet available.

---

## 9. Search APIs

### GET /api/search

**Use case:**  
Global fund search.

**Query param:**
- `q=active asset`

**Search against:**
- Scheme name
- AMC
- Category
- SIF code
- ISIN
- Scheme code

---

## 10. Fund Comparison APIs

### GET /api/funds/compare

**Use case:**  
Compare multiple funds side by side.

**Query param:**
- `ids=1,2,3`

**Returns:**
- Latest NAV
- AUM
- Risk band
- Returns
- Expense ratio
- Inception date

---

### GET /api/funds/compare/returns

**Use case:**  
Compare returns of multiple funds.

**Query params:**
- `ids=1,2`
- `period=3M`

---

### GET /api/funds/compare/risk

**Use case:**  
Compare volatility, alpha, beta, Sharpe, Sortino, etc.

---

## 11. Admin / Data Ingestion APIs

These should NOT be public website APIs.

### POST /api/admin/import/nav

**Use case:**  
Upload or import historical NAV data into `nav_history`.

---

### POST /api/admin/import/aum

**Use case:**  
Import monthly/quarterly AUM or AAUM disclosures.

---

### POST /api/admin/import/portfolio

**Use case:**  
Import monthly portfolio disclosure files and populate:
- `portfolio_disclosures`
- `securities`
- `sectors`
- `portfolio_positions`

---

### POST /api/admin/import/benchmark

**Use case:**  
Insert official historical benchmark values.

---

### POST /api/admin/import/risk-free-rate

**Use case:**  
Insert risk-free-rate history for Sharpe/Sortino calculations.

---

## 12. Analytics Recalculation APIs

### POST /api/admin/recalculate/returns/:schemeId

**Use case:**  
Recalculate:
- Absolute returns
- Annualized returns
- Rolling returns
- Drawdown

---

### POST /api/admin/recalculate/portfolio/:schemeId

**Use case:**  
Recalculate:
- Top holdings
- Sector allocation
- Asset allocation
- Long exposure
- Short exposure
- Gross exposure
- Net exposure
- Derivative exposure

---

### POST /api/admin/recalculate/risk/:schemeId

**Use case:**  
Recalculate:
- Volatility
- Alpha
- Beta
- Sharpe
- Sortino
- Tracking error
- Information ratio
- Maximum drawdown

---

## 13. Ingestion Monitoring APIs

### GET /api/admin/ingestion-runs

**Use case:**  
Show import-job history and errors.

---

### GET /api/admin/ingestion-runs/:id

**Use case:**  
Inspect one specific import operation.

---

# Recommended APIs to Build First

For the first working version, prioritize these:

1. `GET /api/funds`
2. `GET /api/funds/:schemeId`
3. `GET /api/funds/:schemeId/plans`
4. `GET /api/plans/:planId/nav/latest`
5. `GET /api/plans/:planId/nav/history`
6. `GET /api/plans/:planId/returns`
7. `GET /api/funds/:schemeId/aum/latest`
8. `GET /api/funds/:schemeId/aum/history`
9. `GET /api/funds/:schemeId/top-holdings`
10. `GET /api/funds/:schemeId/sectors`
11. `GET /api/funds/:schemeId/asset-allocation`
12. `GET /api/funds/:schemeId/exposure`
13. `GET /api/plans/:planId/risk-metrics`
14. `GET /api/funds/:schemeId/benchmark`

These are enough to build a strong Moneycontrol-like fund detail page while allowing the remaining analytics and data-ingestion features to be added incrementally.
