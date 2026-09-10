-- DynaSIF / Moneycontrol-like Fund Analytics Database
-- PostgreSQL single-file setup
-- Intended to be run with psql.
--
-- Usage:
--   psql -U postgres -f dynasif_moneycontrol_postgres.sql
--
-- This script:
--   1) Creates database dynasif_moneycontrol if it does not exist
--   2) Connects to it
--   3) Creates schema, tables, indexes, constraints, views, and data provenance tracking
--   4) Seeds verified, source-backed master data strictly for:
--      DynaSIF Active Asset Allocator Long-Short Fund
--
-- It does NOT fabricate missing portfolio holdings, benchmark history,
-- risk-free-rate history, or derived analytics.

\set ON_ERROR_STOP on

-- Create the database only if it does not already exist.
SELECT 'CREATE DATABASE dynasif_moneycontrol'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_database WHERE datname = 'dynasif_moneycontrol'
)\gexec

\connect dynasif_moneycontrol

BEGIN;

CREATE SCHEMA IF NOT EXISTS fund_analytics;
SET search_path TO fund_analytics, public;

-- ============================================================
-- 0. DATA PROVENANCE / SOURCE TRACKING
-- ============================================================

CREATE TABLE IF NOT EXISTS source_documents (
    id BIGSERIAL PRIMARY KEY,
    document_name VARCHAR(255) NOT NULL,
    document_type VARCHAR(100) NOT NULL, -- PORTFOLIO_DISCLOSURE, FACTSHEET, AUM_DISCLOSURE, NAV_DISCLOSURE, BENCHMARK_INDEX, RISK_FREE_RATE, SID
    source_url TEXT,
    file_type VARCHAR(50), -- XLSX, PDF, CSV, API, MANUAL
    publication_date DATE,
    reporting_date DATE,
    download_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    file_hash VARCHAR(128),
    extraction_status VARCHAR(50) NOT NULL DEFAULT 'EXTRACTED'
        CHECK (extraction_status IN ('EXTRACTED', 'PENDING', 'FAILED', 'VERIFIED')),
    parser_version VARCHAR(50) DEFAULT 'v1.0',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 1. AMC / MASTER DATA
-- ============================================================

CREATE TABLE IF NOT EXISTS amcs (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    website VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS benchmarks (
    id BIGSERIAL PRIMARY KEY,
    benchmark_name VARCHAR(255) NOT NULL UNIQUE,
    benchmark_code VARCHAR(100) UNIQUE,
    provider VARCHAR(255),
    benchmark_type VARCHAR(50),
    is_composite BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS schemes (
    id BIGSERIAL PRIMARY KEY,
    amc_id BIGINT NOT NULL REFERENCES amcs(id),
    scheme_name VARCHAR(255) NOT NULL,
    scheme_code VARCHAR(100) UNIQUE,
    category VARCHAR(255),
    fund_type TEXT,
    investment_objective TEXT,
    face_value NUMERIC(18,4) CHECK (face_value > 0),
    nfo_open_date DATE,
    nfo_close_date DATE,
    allotment_date DATE,
    reopen_date DATE,
    maturity_date DATE,
    minimum_investment NUMERIC(20,2) CHECK (minimum_investment >= 0),
    minimum_additional_investment NUMERIC(20,2) CHECK (minimum_additional_investment >= 0),
    exit_load TEXT,
    benchmark_id BIGINT REFERENCES benchmarks(id),
    listing_details TEXT,
    custodian VARCHAR(255),
    auditor VARCHAR(255),
    registrar VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (amc_id, scheme_name)
);

CREATE TABLE IF NOT EXISTS scheme_plans (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    sif_code VARCHAR(50),
    plan_type VARCHAR(50) NOT NULL,
    option_type VARCHAR(50) NOT NULL,
    isin_primary VARCHAR(20),
    isin_reinvestment VARCHAR(20),
    rta_code VARCHAR(50),
    expense_ratio_max NUMERIC(8,4) CHECK (expense_ratio_max IS NULL OR expense_ratio_max >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, plan_type, option_type, isin_primary)
);

CREATE TABLE IF NOT EXISTS fund_managers (
    id BIGSERIAL PRIMARY KEY,
    manager_name VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scheme_fund_managers (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    fund_manager_id BIGINT NOT NULL REFERENCES fund_managers(id),
    manager_role VARCHAR(100),
    from_date DATE,
    to_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, fund_manager_id, from_date)
);

CREATE TABLE IF NOT EXISTS scheme_risk_history (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    effective_date DATE,
    risk_band INTEGER NOT NULL CHECK (risk_band BETWEEN 1 AND 6),
    risk_type VARCHAR(50) NOT NULL DEFAULT 'STRATEGY',
    source_document_id BIGINT REFERENCES source_documents(id),
    source VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, effective_date, risk_type)
);

CREATE TABLE IF NOT EXISTS scheme_asset_allocation_limits (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    asset_class VARCHAR(100) NOT NULL,
    min_percentage NUMERIC(10,4) NOT NULL,
    max_percentage NUMERIC(10,4) NOT NULL,
    effective_from DATE,
    effective_to DATE,
    source_document_id BIGINT REFERENCES source_documents(id),
    source VARCHAR(255),
    CHECK (min_percentage >= 0),
    CHECK (max_percentage >= min_percentage),
    UNIQUE (scheme_id, asset_class, effective_from)
);

-- ============================================================
-- 2. BENCHMARK DATA
-- ============================================================

CREATE TABLE IF NOT EXISTS benchmark_components (
    id BIGSERIAL PRIMARY KEY,
    composite_benchmark_id BIGINT NOT NULL REFERENCES benchmarks(id) ON DELETE CASCADE,
    component_benchmark_id BIGINT NOT NULL REFERENCES benchmarks(id),
    weight_percentage NUMERIC(10,6) NOT NULL CHECK (weight_percentage > 0 AND weight_percentage <= 100),
    effective_from DATE,
    effective_to DATE,
    UNIQUE (composite_benchmark_id, component_benchmark_id, effective_from)
);

CREATE TABLE IF NOT EXISTS benchmark_values (
    id BIGSERIAL PRIMARY KEY,
    benchmark_id BIGINT NOT NULL REFERENCES benchmarks(id) ON DELETE CASCADE,
    value_date DATE NOT NULL,
    index_value NUMERIC(24,8) NOT NULL CHECK (index_value >= 0),
    source_document_id BIGINT REFERENCES source_documents(id),
    source VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (benchmark_id, value_date)
);

CREATE TABLE IF NOT EXISTS composite_benchmark_values (
    id BIGSERIAL PRIMARY KEY,
    benchmark_id BIGINT NOT NULL REFERENCES benchmarks(id) ON DELETE CASCADE,
    value_date DATE NOT NULL,
    index_value NUMERIC(24,8) CHECK (index_value >= 0),
    daily_return NUMERIC(24,12),
    methodology_version VARCHAR(50) NOT NULL DEFAULT 'v1',
    source_document_id BIGINT REFERENCES source_documents(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (benchmark_id, value_date, methodology_version)
);

-- ============================================================
-- 3. NAV / AUM / RISK-FREE DATA
-- ============================================================

CREATE TABLE IF NOT EXISTS nav_history (
    id BIGSERIAL PRIMARY KEY,
    scheme_plan_id BIGINT NOT NULL REFERENCES scheme_plans(id) ON DELETE CASCADE,
    nav_date DATE NOT NULL,
    nav NUMERIC(20,6) NOT NULL CHECK (nav > 0),
    repurchase_price NUMERIC(20,6) CHECK (repurchase_price IS NULL OR repurchase_price > 0),
    sale_price NUMERIC(20,6) CHECK (sale_price IS NULL OR sale_price > 0),
    source_document_id BIGINT REFERENCES source_documents(id),
    source VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_plan_id, nav_date)
);

CREATE TABLE IF NOT EXISTS aum_history (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    report_date DATE NOT NULL,
    period_type VARCHAR(30) NOT NULL DEFAULT 'MONTHLY',
    closing_aum NUMERIC(24,6) CHECK (closing_aum IS NULL OR closing_aum >= 0),
    average_aum NUMERIC(24,6) CHECK (average_aum IS NULL OR average_aum >= 0),
    unit VARCHAR(20) NOT NULL DEFAULT 'CRORE',
    source_document_id BIGINT REFERENCES source_documents(id),
    source VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, report_date, period_type)
);

CREATE TABLE IF NOT EXISTS risk_free_rates (
    id BIGSERIAL PRIMARY KEY,
    rate_date DATE NOT NULL,
    instrument VARCHAR(100) NOT NULL,
    annual_rate NUMERIC(16,10) NOT NULL,
    source_document_id BIGINT REFERENCES source_documents(id),
    source VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (rate_date, instrument)
);

-- ============================================================
-- 4. PORTFOLIO / HOLDINGS
-- ============================================================

CREATE TABLE IF NOT EXISTS sectors (
    id BIGSERIAL PRIMARY KEY,
    sector_name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS securities (
    id BIGSERIAL PRIMARY KEY,
    security_name VARCHAR(500) NOT NULL,
    isin VARCHAR(30),
    ticker VARCHAR(50),
    sector_id BIGINT REFERENCES sectors(id),
    security_type VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_securities_isin
ON securities(isin)
WHERE isin IS NOT NULL;

CREATE TABLE IF NOT EXISTS portfolio_disclosures (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    report_date DATE NOT NULL,
    source_document_id BIGINT REFERENCES source_documents(id),
    source_file VARCHAR(500),
    source_url TEXT,
    imported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, report_date)
);

CREATE TABLE IF NOT EXISTS portfolio_positions (
    id BIGSERIAL PRIMARY KEY,
    disclosure_id BIGINT NOT NULL REFERENCES portfolio_disclosures(id) ON DELETE CASCADE,
    security_id BIGINT REFERENCES securities(id),
    instrument_name VARCHAR(500) NOT NULL,
    instrument_type VARCHAR(100),
    asset_class VARCHAR(100),
    sector_id BIGINT REFERENCES sectors(id),
    position_side VARCHAR(20) NOT NULL DEFAULT 'NA'
        CHECK (position_side IN ('LONG','SHORT','HEDGED','OFFSET','NA')),
    quantity NUMERIC(28,8),
    market_value NUMERIC(28,8),
    nav_percentage NUMERIC(16,8),
    exposure_value NUMERIC(28,8),
    exposure_percentage NUMERIC(16,8),
    derivative_underlying VARCHAR(255),
    derivative_type VARCHAR(100),
    expiry_date DATE,
    contract_identifier VARCHAR(255),
    source_row_number INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scheme_exposure_history (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    report_date DATE NOT NULL,
    long_exposure NUMERIC(16,8),
    short_exposure NUMERIC(16,8),
    gross_exposure NUMERIC(16,8),
    net_exposure NUMERIC(16,8),
    derivative_exposure NUMERIC(16,8),
    equity_exposure NUMERIC(16,8),
    debt_exposure NUMERIC(16,8),
    invit_exposure NUMERIC(16,8),
    commodity_exposure NUMERIC(16,8),
    cash_exposure NUMERIC(16,8),
    source_type VARCHAR(30) NOT NULL DEFAULT 'CALCULATED'
        CHECK (source_type IN ('REPORTED','CALCULATED')),
    calculation_method VARCHAR(255),
    source_document_id BIGINT REFERENCES source_documents(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, report_date, source_type)
);

-- ============================================================
-- 5. ANALYTICS
-- ============================================================

CREATE TABLE IF NOT EXISTS return_metrics (
    id BIGSERIAL PRIMARY KEY,
    scheme_plan_id BIGINT NOT NULL REFERENCES scheme_plans(id) ON DELETE CASCADE,
    calculation_date DATE NOT NULL,
    period VARCHAR(30) NOT NULL,
    absolute_return NUMERIC(20,10),
    annualized_return NUMERIC(20,10),
    benchmark_return NUMERIC(20,10),
    methodology_version VARCHAR(50) NOT NULL DEFAULT 'v1',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_plan_id, calculation_date, period, methodology_version)
);

CREATE TABLE IF NOT EXISTS risk_metrics (
    id BIGSERIAL PRIMARY KEY,
    scheme_plan_id BIGINT NOT NULL REFERENCES scheme_plans(id) ON DELETE CASCADE,
    calculation_date DATE NOT NULL,
    period VARCHAR(30) NOT NULL,
    volatility NUMERIC(20,10),
    alpha NUMERIC(20,10),
    beta NUMERIC(20,10),
    sharpe_ratio NUMERIC(20,10),
    sortino_ratio NUMERIC(20,10),
    tracking_error NUMERIC(20,10),
    information_ratio NUMERIC(20,10),
    max_drawdown NUMERIC(20,10),
    methodology_version VARCHAR(50) NOT NULL DEFAULT 'v1_daily_252',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_plan_id, calculation_date, period, methodology_version)
);

CREATE TABLE IF NOT EXISTS rolling_returns (
    id BIGSERIAL PRIMARY KEY,
    scheme_plan_id BIGINT NOT NULL REFERENCES scheme_plans(id) ON DELETE CASCADE,
    observation_date DATE NOT NULL,
    rolling_period VARCHAR(20) NOT NULL,
    return_value NUMERIC(20,10),
    benchmark_return NUMERIC(20,10),
    methodology_version VARCHAR(50) NOT NULL DEFAULT 'v1',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_plan_id, observation_date, rolling_period, methodology_version)
);

-- ============================================================
-- 6. SUPPLEMENTAL WEBSITE / BENCHMARK TABLES
-- ============================================================

-- Structured SIP / STP / SWP rules extracted from KIM / ISID documents.
CREATE TABLE IF NOT EXISTS scheme_systematic_plans (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    facility_type VARCHAR(20) NOT NULL CHECK (facility_type IN ('SIP','STP','SWP')),
    frequency VARCHAR(30),
    minimum_amount NUMERIC(20,2),
    minimum_installments INTEGER,
    default_date_rule TEXT,
    allowed BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    source_document VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, facility_type, frequency)
);

-- Scheme-specific subscription / redemption / liquidity rules.
CREATE TABLE IF NOT EXISTS scheme_liquidity_rules (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    subscription_frequency VARCHAR(100),
    redemption_frequency VARCHAR(255),
    notice_period VARCHAR(100),
    redemption_proceeds_timeline VARCHAR(255),
    listing_details TEXT,
    minimum_redemption_amount NUMERIC(20,2),
    source_document VARCHAR(500),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id)
);

-- Structured tax treatment. Values are source-backed and should be versioned
-- when tax rules change by adding a new row with a later effective_from date.
CREATE TABLE IF NOT EXISTS scheme_tax_rules (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    tax_category VARCHAR(50) NOT NULL,
    resident_dividend_tax TEXT,
    long_term_holding_rule TEXT,
    resident_ltcg_rate NUMERIC(10,6),
    short_term_holding_rule TEXT,
    resident_stcg_treatment TEXT,
    stt_note TEXT,
    source_document VARCHAR(500),
    tax_caveat TEXT,
    effective_from DATE,
    effective_to DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, effective_from)
);

-- Calendar-month returns derived from NAV history.
CREATE TABLE IF NOT EXISTS monthly_returns (
    id BIGSERIAL PRIMARY KEY,
    scheme_plan_id BIGINT NOT NULL REFERENCES scheme_plans(id) ON DELETE CASCADE,
    year INTEGER NOT NULL CHECK (year >= 1900),
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    period_end_date DATE NOT NULL,
    end_nav NUMERIC(20,6) NOT NULL,
    prior_month_end_nav NUMERIC(20,6),
    monthly_return NUMERIC(20,10),
    is_complete_month BOOLEAN NOT NULL DEFAULT TRUE,
    source VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_plan_id, year, month)
);

-- Reported portfolio turnover from monthly factsheets.
CREATE TABLE IF NOT EXISTS portfolio_turnover_history (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    report_date DATE NOT NULL,
    turnover_ratio NUMERIC(16,8) NOT NULL,
    source_document VARCHAR(500),
    source_page INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, report_date)
);

-- Historical Total/Base expense ratio by plan type and reporting date.
CREATE TABLE IF NOT EXISTS scheme_expense_ratio_history (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    report_date DATE NOT NULL,
    plan_type VARCHAR(50) NOT NULL,
    ratio_type VARCHAR(20) NOT NULL CHECK (ratio_type IN ('TOTAL','BASE','TER','OTHER')),
    expense_ratio_pct NUMERIC(10,6) NOT NULL,
    source_document VARCHAR(500),
    source_page INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, report_date, plan_type, ratio_type)
);

-- Exposure calculated ONLY from signed derivative position weights in factsheets.
-- This table must not be interpreted as official total-fund gross/net exposure.
CREATE TABLE IF NOT EXISTS derivative_exposure_history (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    report_date DATE NOT NULL,
    long_derivative_pct NUMERIC(16,8),
    short_derivative_pct NUMERIC(16,8),
    gross_derivative_pct NUMERIC(16,8),
    net_derivative_pct NUMERIC(16,8),
    source_document VARCHAR(500),
    calculation_method TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scheme_id, report_date)
);

-- Official BSE index code/name reference list.
CREATE TABLE IF NOT EXISTS index_master_reference (
    sr_no INTEGER PRIMARY KEY,
    benchmark_code VARCHAR(50) NOT NULL UNIQUE,
    benchmark_name VARCHAR(255) NOT NULL,
    provider VARCHAR(255),
    source_document VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Monthly/index-date risk-o-meter snapshot supplied by BSE.
CREATE TABLE IF NOT EXISTS index_riskometer_history (
    id BIGSERIAL PRIMARY KEY,
    as_of_month DATE NOT NULL,
    index_name VARCHAR(255) NOT NULL,
    risk_value NUMERIC(12,6),
    risk_o_meter_level VARCHAR(50),
    index_category VARCHAR(100),
    benchmark_code VARCHAR(50),
    source_document VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (as_of_month, index_name)
);

-- Maps source-index risk values to benchmark records used by DynaSIF schemes.
CREATE TABLE IF NOT EXISTS benchmark_risk_history (
    id BIGSERIAL PRIMARY KEY,
    benchmark_id BIGINT NOT NULL REFERENCES benchmarks(id) ON DELETE CASCADE,
    as_of_date DATE NOT NULL,
    source_index_name VARCHAR(255) NOT NULL,
    risk_value NUMERIC(12,6),
    risk_o_meter_level VARCHAR(50),
    index_category VARCHAR(100),
    source_document VARCHAR(500),
    mapping_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (benchmark_id, as_of_date, source_index_name)
);

-- Descriptive benchmark facts such as base date, constituents, weighting method.
CREATE TABLE IF NOT EXISTS benchmark_facts (
    id BIGSERIAL PRIMARY KEY,
    benchmark_id BIGINT REFERENCES benchmarks(id) ON DELETE CASCADE,
    source_index_code VARCHAR(50),
    index_name VARCHAR(255) NOT NULL,
    return_series VARCHAR(50),
    launch_date DATE,
    first_value_date DATE,
    base_value NUMERIC(20,6),
    constituent_count INTEGER,
    reconstitution_frequency VARCHAR(255),
    weighting_method VARCHAR(255),
    index_universe VARCHAR(255),
    calculation_currencies VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (index_name, return_series)
);

-- Dated performance snapshot from an official index factsheet.
CREATE TABLE IF NOT EXISTS benchmark_performance_snapshot (
    id BIGSERIAL PRIMARY KEY,
    benchmark_id BIGINT REFERENCES benchmarks(id) ON DELETE CASCADE,
    as_of_date DATE NOT NULL,
    return_series VARCHAR(50) NOT NULL,
    index_level NUMERIC(24,8),
    return_1m_pct NUMERIC(16,8),
    return_3m_pct NUMERIC(16,8),
    return_ytd_pct NUMERIC(16,8),
    return_1y_pct NUMERIC(16,8),
    return_3y_ann_pct NUMERIC(16,8),
    return_5y_ann_pct NUMERIC(16,8),
    return_10y_ann_pct NUMERIC(16,8),
    source_document VARCHAR(500),
    source_page INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (benchmark_id, as_of_date, return_series)
);

-- Dated benchmark risk and risk-adjusted-return snapshot.
CREATE TABLE IF NOT EXISTS benchmark_risk_snapshot (
    id BIGSERIAL PRIMARY KEY,
    benchmark_id BIGINT REFERENCES benchmarks(id) ON DELETE CASCADE,
    as_of_date DATE NOT NULL,
    return_series VARCHAR(50) NOT NULL,
    risk_1y_pct NUMERIC(16,8),
    risk_3y_pct NUMERIC(16,8),
    risk_5y_pct NUMERIC(16,8),
    risk_10y_pct NUMERIC(16,8),
    risk_adj_1y NUMERIC(16,8),
    risk_adj_3y NUMERIC(16,8),
    risk_adj_5y NUMERIC(16,8),
    risk_adj_10y NUMERIC(16,8),
    source_document VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (benchmark_id, as_of_date, return_series)
);

-- Dated benchmark valuation/fundamental snapshot.
CREATE TABLE IF NOT EXISTS benchmark_fundamentals_snapshot (
    id BIGSERIAL PRIMARY KEY,
    benchmark_id BIGINT NOT NULL REFERENCES benchmarks(id) ON DELETE CASCADE,
    as_of_date DATE NOT NULL,
    pe NUMERIC(16,6),
    pb NUMERIC(16,6),
    dividend_yield_pct NUMERIC(16,6),
    source_document VARCHAR(500),
    source_page INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (benchmark_id, as_of_date)
);

-- Top constituents/weights of a benchmark on a date.
CREATE TABLE IF NOT EXISTS benchmark_constituent_weights (
    id BIGSERIAL PRIMARY KEY,
    benchmark_id BIGINT NOT NULL REFERENCES benchmarks(id) ON DELETE CASCADE,
    as_of_date DATE NOT NULL,
    rank INTEGER,
    constituent_name VARCHAR(500) NOT NULL,
    weight_pct NUMERIC(16,8),
    source_document VARCHAR(500),
    source_page INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (benchmark_id, as_of_date, constituent_name)
);

-- Sector weights of a benchmark on a date.
CREATE TABLE IF NOT EXISTS benchmark_sector_weights (
    id BIGSERIAL PRIMARY KEY,
    benchmark_id BIGINT NOT NULL REFERENCES benchmarks(id) ON DELETE CASCADE,
    as_of_date DATE NOT NULL,
    sector_name VARCHAR(255) NOT NULL,
    weight_pct NUMERIC(16,8),
    source_document VARCHAR(500),
    source_page INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (benchmark_id, as_of_date, sector_name)
);

-- Dated benchmark characteristics such as constituent market-cap statistics.
CREATE TABLE IF NOT EXISTS benchmark_characteristics_snapshot (
    id BIGSERIAL PRIMARY KEY,
    benchmark_id BIGINT NOT NULL REFERENCES benchmarks(id) ON DELETE CASCADE,
    as_of_date DATE NOT NULL,
    mean_market_cap_cr NUMERIC(24,6),
    largest_market_cap_cr NUMERIC(24,6),
    smallest_market_cap_cr NUMERIC(24,6),
    median_market_cap_cr NUMERIC(24,6),
    largest_constituent_weight_pct NUMERIC(16,8),
    top10_weight_pct NUMERIC(16,8),
    bloomberg_ticker VARCHAR(100),
    reuters_ticker VARCHAR(100),
    source_document VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (benchmark_id, as_of_date)
);

-- Human-readable benchmark/index methodology notes retained for reference.
CREATE TABLE IF NOT EXISTS benchmark_methodology_notes (
    id BIGSERIAL PRIMARY KEY,
    index_name VARCHAR(255) NOT NULL,
    topic VARCHAR(100) NOT NULL,
    rule_or_description TEXT NOT NULL,
    effective_reference VARCHAR(255),
    source_document VARCHAR(500),
    source_page INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (index_name, topic, rule_or_description)
);

-- ============================================================
-- 7. INGESTION AUDIT
-- ============================================================

CREATE TABLE IF NOT EXISTS ingestion_runs (
    id BIGSERIAL PRIMARY KEY,
    source_type VARCHAR(100) NOT NULL,
    source_name VARCHAR(500),
    source_document_id BIGINT REFERENCES source_documents(id),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL DEFAULT 'STARTED'
        CHECK (status IN ('STARTED','SUCCESS','FAILED','PARTIAL')),
    rows_inserted INTEGER NOT NULL DEFAULT 0,
    rows_updated INTEGER NOT NULL DEFAULT 0,
    error_message TEXT
);

-- ============================================================
-- 8. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_nav_history_plan_date
    ON nav_history(scheme_plan_id, nav_date DESC);

CREATE INDEX IF NOT EXISTS idx_aum_history_scheme_date
    ON aum_history(scheme_id, report_date DESC);

CREATE INDEX IF NOT EXISTS idx_benchmark_values_benchmark_date
    ON benchmark_values(benchmark_id, value_date DESC);

CREATE INDEX IF NOT EXISTS idx_portfolio_disclosures_scheme_date
    ON portfolio_disclosures(scheme_id, report_date DESC);

CREATE INDEX IF NOT EXISTS idx_portfolio_positions_disclosure
    ON portfolio_positions(disclosure_id);

CREATE INDEX IF NOT EXISTS idx_portfolio_positions_asset_class
    ON portfolio_positions(asset_class);

CREATE INDEX IF NOT EXISTS idx_portfolio_positions_sector
    ON portfolio_positions(sector_id);

CREATE INDEX IF NOT EXISTS idx_portfolio_positions_nav_pct
    ON portfolio_positions(nav_percentage DESC);

CREATE INDEX IF NOT EXISTS idx_return_metrics_plan_date
    ON return_metrics(scheme_plan_id, calculation_date DESC);

CREATE INDEX IF NOT EXISTS idx_risk_metrics_plan_date
    ON risk_metrics(scheme_plan_id, calculation_date DESC);

CREATE INDEX IF NOT EXISTS idx_source_documents_type_date
    ON source_documents(document_type, reporting_date DESC);


CREATE INDEX IF NOT EXISTS idx_monthly_returns_plan_period
    ON monthly_returns(scheme_plan_id, year DESC, month DESC);

CREATE INDEX IF NOT EXISTS idx_portfolio_turnover_scheme_date
    ON portfolio_turnover_history(scheme_id, report_date DESC);

CREATE INDEX IF NOT EXISTS idx_expense_ratio_scheme_date
    ON scheme_expense_ratio_history(scheme_id, report_date DESC);

CREATE INDEX IF NOT EXISTS idx_derivative_exposure_scheme_date
    ON derivative_exposure_history(scheme_id, report_date DESC);

CREATE INDEX IF NOT EXISTS idx_riskometer_name_date
    ON index_riskometer_history(index_name, as_of_month DESC);

CREATE INDEX IF NOT EXISTS idx_benchmark_risk_date
    ON benchmark_risk_history(benchmark_id, as_of_date DESC);

CREATE INDEX IF NOT EXISTS idx_benchmark_performance_date
    ON benchmark_performance_snapshot(benchmark_id, as_of_date DESC);

CREATE INDEX IF NOT EXISTS idx_benchmark_constituent_date
    ON benchmark_constituent_weights(benchmark_id, as_of_date DESC, rank);

CREATE INDEX IF NOT EXISTS idx_benchmark_sector_date
    ON benchmark_sector_weights(benchmark_id, as_of_date DESC);

-- ============================================================
-- 9. USEFUL VIEWS
-- ============================================================

CREATE OR REPLACE VIEW v_latest_nav AS
SELECT DISTINCT ON (nh.scheme_plan_id)
    nh.scheme_plan_id,
    sp.scheme_id,
    sp.sif_code,
    sp.plan_type,
    sp.option_type,
    sp.isin_primary,
    nh.nav_date,
    nh.nav,
    nh.repurchase_price,
    nh.sale_price
FROM nav_history nh
JOIN scheme_plans sp ON sp.id = nh.scheme_plan_id
ORDER BY nh.scheme_plan_id, nh.nav_date DESC;

CREATE OR REPLACE VIEW v_latest_aum AS
SELECT DISTINCT ON (ah.scheme_id)
    ah.scheme_id,
    ah.report_date,
    ah.period_type,
    ah.closing_aum,
    ah.average_aum,
    ah.unit,
    ah.source
FROM aum_history ah
ORDER BY ah.scheme_id, ah.report_date DESC;

CREATE OR REPLACE VIEW v_latest_portfolio_disclosure AS
SELECT DISTINCT ON (pd.scheme_id)
    pd.id AS disclosure_id,
    pd.scheme_id,
    pd.report_date,
    pd.source_file,
    pd.source_url
FROM portfolio_disclosures pd
ORDER BY pd.scheme_id, pd.report_date DESC;

CREATE OR REPLACE VIEW v_latest_top_holdings AS
WITH latest AS (
    SELECT * FROM v_latest_portfolio_disclosure
),
ranked AS (
    SELECT
        l.scheme_id,
        l.report_date,
        pp.instrument_name,
        pp.asset_class,
        pp.instrument_type,
        pp.nav_percentage,
        ROW_NUMBER() OVER (
            PARTITION BY l.scheme_id
            ORDER BY pp.nav_percentage DESC NULLS LAST
        ) AS rank_no
    FROM latest l
    JOIN portfolio_positions pp
      ON pp.disclosure_id = l.disclosure_id
    WHERE pp.nav_percentage IS NOT NULL
)
SELECT *
FROM ranked
WHERE rank_no <= 10;

CREATE OR REPLACE VIEW v_latest_sector_allocation AS
WITH latest AS (
    SELECT * FROM v_latest_portfolio_disclosure
)
SELECT
    l.scheme_id,
    l.report_date,
    s.sector_name,
    SUM(pp.nav_percentage) AS allocation_percentage
FROM latest l
JOIN portfolio_positions pp
  ON pp.disclosure_id = l.disclosure_id
JOIN sectors s
  ON s.id = pp.sector_id
WHERE pp.nav_percentage IS NOT NULL
GROUP BY l.scheme_id, l.report_date, s.sector_name;

CREATE OR REPLACE VIEW v_latest_asset_allocation AS
WITH latest AS (
    SELECT * FROM v_latest_portfolio_disclosure
)
SELECT
    l.scheme_id,
    l.report_date,
    pp.asset_class,
    SUM(pp.nav_percentage) AS allocation_percentage
FROM latest l
JOIN portfolio_positions pp
  ON pp.disclosure_id = l.disclosure_id
WHERE pp.nav_percentage IS NOT NULL
GROUP BY l.scheme_id, l.report_date, pp.asset_class;

-- ============================================================
-- 9. SOURCE-BACKED SEED DATA & PROVENANCE METADATA
-- ============================================================

-- Seed Data Provenance Entries
INSERT INTO source_documents (
    document_name,
    document_type,
    source_url,
    file_type,
    publication_date,
    reporting_date,
    extraction_status,
    notes
)
VALUES
(
    'DynaSIF Scheme Information Document / Summary',
    'SID',
    'https://www.360.one/dyna-sif',
    'PDF',
    DATE '2026-03-01',
    DATE '2026-03-01',
    'VERIFIED',
    'Official Scheme Summary disclosure for DynaSIF Active Asset Allocator Long-Short Fund'
),
(
    'Uploaded Active Asset Allocator NAV File',
    'NAV_DISCLOSURE',
    'https://www.360.one/dyna-sif/nav',
    'XLSX',
    DATE '2026-09-01',
    DATE '2026-09-01',
    'VERIFIED',
    'Official NAV snapshot dated 2026-09-01'
),
(
    'Uploaded June AUM Report',
    'AUM_DISCLOSURE',
    'https://www.360.one/dyna-sif/aum',
    'PDF',
    DATE '2026-06-30',
    DATE '2026-06-30',
    'VERIFIED',
    'Official quarter-end AUM disclosure for June 2026'
)
ON CONFLICT DO NOTHING;

-- AMC Master
INSERT INTO amcs (name, website)
VALUES ('360 ONE Asset Management Limited', 'https://www.360.one/dyna-sif')
ON CONFLICT (name) DO UPDATE
SET website = EXCLUDED.website;

-- Benchmarks Master
INSERT INTO benchmarks (benchmark_name, benchmark_code, provider, benchmark_type, is_composite)
VALUES
('BSE SENSEX TRI', 'SENSEX_TRI', 'BSE', 'TRI', FALSE),
('CRISIL Short Term Bond Fund Index', 'CRISIL_STBFI', 'CRISIL', 'BOND_INDEX', FALSE),
('iCOMDEX Composite Index', 'ICOMDEX_COMP', 'MCX / iCOMDEX', 'COMMODITY_INDEX', FALSE),
('25% BSE SENSEX TRI + 60% CRISIL Short Term Bond Fund Index + 15% iCOMDEX Composite Index',
 'DYNA_COMPOSITE_BM1', 'Composite', 'COMPOSITE', TRUE)
ON CONFLICT (benchmark_name) DO UPDATE
SET benchmark_code = EXCLUDED.benchmark_code;

-- Scheme Master
INSERT INTO schemes (
    amc_id,
    scheme_name,
    scheme_code,
    category,
    fund_type,
    investment_objective,
    face_value,
    nfo_open_date,
    nfo_close_date,
    allotment_date,
    reopen_date,
    minimum_investment,
    minimum_additional_investment,
    exit_load,
    benchmark_id,
    listing_details,
    custodian,
    auditor,
    registrar
)
SELECT
    a.id,
    'DynaSIF Active Asset Allocator Long-Short Fund',
    'DYNA/I/H/AALS/25/12/0002/360O',
    'Active Asset Allocator Long-Short Fund',
    'Interval investment strategy dynamically investing across equity, debt, equity and debt derivatives, InVITs and commodity derivatives, including limited short exposure on permitted instruments through derivatives.',
    'To generate capital appreciation and income generation with dynamic allocation to different asset classes like equities, InVITs, commodities and fixed income layered with derivatives long-short trading strategies.',
    10.00,
    DATE '2026-03-06',
    DATE '2026-03-20',
    DATE '2026-03-25',
    DATE '2026-03-30',
    1000000.00,
    20000.00,
    '0.5% if redeemed within 3 months from date of allotment of units; no exit load after 3 months.',
    b.id,
    'Not Listed',
    'Deutsche Bank AG',
    'PricewaterhouseCoopers Pvt Ltd',
    'Computer Age Management Services Limited (CAMS)'
FROM amcs a
JOIN benchmarks b
  ON b.benchmark_name = '25% BSE SENSEX TRI + 60% CRISIL Short Term Bond Fund Index + 15% iCOMDEX Composite Index'
WHERE a.name = '360 ONE Asset Management Limited'
ON CONFLICT (scheme_code) DO NOTHING;

-- Benchmark Component Weights
INSERT INTO benchmark_components (
    composite_benchmark_id,
    component_benchmark_id,
    weight_percentage,
    effective_from
)
SELECT cb.id, c.id, x.weight, DATE '2026-03-25'
FROM benchmarks cb
JOIN (
    VALUES
      ('BSE SENSEX TRI', 25.0::NUMERIC),
      ('CRISIL Short Term Bond Fund Index', 60.0::NUMERIC),
      ('iCOMDEX Composite Index', 15.0::NUMERIC)
) AS x(component_name, weight) ON TRUE
JOIN benchmarks c ON c.benchmark_name = x.component_name
WHERE cb.benchmark_name =
'25% BSE SENSEX TRI + 60% CRISIL Short Term Bond Fund Index + 15% iCOMDEX Composite Index'
ON CONFLICT (composite_benchmark_id, component_benchmark_id, effective_from)
DO NOTHING;

-- Scheme Plans / Options
INSERT INTO scheme_plans (
    scheme_id, sif_code, plan_type, option_type,
    isin_primary, isin_reinvestment, rta_code, expense_ratio_max
)
SELECT s.id, v.sif_code, v.plan_type, v.option_type,
       v.isin_primary, v.isin_reinvestment, v.rta_code, v.expense_ratio_max
FROM schemes s
CROSS JOIN (
    VALUES
      ('SIF-88','Direct Plan','Growth Option','INF579M30109',NULL,'ALSDG',0.53::NUMERIC),
      ('SIF-86','Direct Plan','IDCW Option','INF579M30117','INF579M30125','ALSDP',0.53::NUMERIC),
      ('SIF-87','Regular Plan','Growth Option','INF579M30075',NULL,'ALSRG',1.63::NUMERIC),
      ('SIF-89','Regular Plan','IDCW Option','INF579M30083','INF579M30091','ALSRP',1.63::NUMERIC)
) AS v(sif_code, plan_type, option_type, isin_primary, isin_reinvestment, rta_code, expense_ratio_max)
WHERE s.scheme_code = 'DYNA/I/H/AALS/25/12/0002/360O'
ON CONFLICT (scheme_id, plan_type, option_type, isin_primary)
DO NOTHING;

-- Risk History
INSERT INTO scheme_risk_history (
    scheme_id, effective_date, risk_band, risk_type, source_document_id, source
)
SELECT s.id, DATE '2026-03-25', 2, 'STRATEGY', sd.id, 'Scheme Summary / ISID'
FROM schemes s
LEFT JOIN source_documents sd ON sd.document_name = 'DynaSIF Scheme Information Document / Summary'
WHERE s.scheme_code = 'DYNA/I/H/AALS/25/12/0002/360O'
ON CONFLICT DO NOTHING;

INSERT INTO scheme_risk_history (
    scheme_id, effective_date, risk_band, risk_type, source_document_id, source
)
SELECT s.id, DATE '2026-09-07', 3, 'STRATEGY', sd.id, 'Scheme Summary as uploaded'
FROM schemes s
LEFT JOIN source_documents sd ON sd.document_name = 'DynaSIF Scheme Information Document / Summary'
WHERE s.scheme_code = 'DYNA/I/H/AALS/25/12/0002/360O'
ON CONFLICT DO NOTHING;

-- Asset Allocation Stated Limits
INSERT INTO scheme_asset_allocation_limits (
    scheme_id, asset_class, min_percentage, max_percentage,
    effective_from, source_document_id, source
)
SELECT s.id, v.asset_class, v.min_pct, v.max_pct, DATE '2026-03-25', sd.id, 'S-14 / Scheme Summary'
FROM schemes s
LEFT JOIN source_documents sd ON sd.document_name = 'DynaSIF Scheme Information Document / Summary'
CROSS JOIN (
    VALUES
      ('EQUITY_AND_EQUITY_RELATED',20.0::NUMERIC,50.0::NUMERIC),
      ('DEBT_AND_MONEY_MARKET',20.0::NUMERIC,65.0::NUMERIC),
      ('UNHEDGED_SHORT_EQUITY_DEBT_DERIVATIVES',0.0::NUMERIC,25.0::NUMERIC),
      ('INVITS',0.0::NUMERIC,20.0::NUMERIC),
      ('COMMODITY_DERIVATIVES',0.0::NUMERIC,25.0::NUMERIC)
) AS v(asset_class, min_pct, max_pct)
WHERE s.scheme_code = 'DYNA/I/H/AALS/25/12/0002/360O'
ON CONFLICT (scheme_id, asset_class, effective_from)
DO NOTHING;

-- Fund Managers
INSERT INTO fund_managers (manager_name)
VALUES
('Mr. Harsh Agarwal'),
('Mr. Milan Mody'),
('Mr. Rahul Khetawat'),
('Mr. Pranav Mise')
ON CONFLICT (manager_name) DO NOTHING;

INSERT INTO scheme_fund_managers (
    scheme_id, fund_manager_id, manager_role, from_date
)
SELECT s.id, fm.id, v.manager_role, v.from_date
FROM schemes s
JOIN (
    VALUES
      ('Mr. Harsh Agarwal','Primary',DATE '2026-03-25'),
      ('Mr. Milan Mody','Co-manager',DATE '2026-03-25'),
      ('Mr. Rahul Khetawat','Co-manager',DATE '2026-03-25'),
      ('Mr. Pranav Mise','Co-manager',DATE '2026-04-24')
) AS v(manager_name, manager_role, from_date) ON TRUE
JOIN fund_managers fm ON fm.manager_name = v.manager_name
WHERE s.scheme_code = 'DYNA/I/H/AALS/25/12/0002/360O'
ON CONFLICT (scheme_id, fund_manager_id, from_date)
DO NOTHING;

-- Latest NAV snapshot linked to source document
INSERT INTO nav_history (scheme_plan_id, nav_date, nav, source_document_id, source)
SELECT sp.id, DATE '2026-09-01', v.nav, sd.id, 'Uploaded active asset allocator.xlsx'
FROM scheme_plans sp
JOIN schemes s ON s.id = sp.scheme_id
LEFT JOIN source_documents sd ON sd.document_name = 'Uploaded Active Asset Allocator NAV File'
JOIN (
    VALUES
      ('SIF-88',10.5376::NUMERIC),
      ('SIF-86',10.5376::NUMERIC),
      ('SIF-87',10.4777::NUMERIC),
      ('SIF-89',10.4777::NUMERIC)
) AS v(sif_code, nav)
ON sp.sif_code = v.sif_code
WHERE s.scheme_code = 'DYNA/I/H/AALS/25/12/0002/360O'
ON CONFLICT (scheme_plan_id, nav_date)
DO UPDATE SET nav = EXCLUDED.nav, source_document_id = EXCLUDED.source_document_id, source = EXCLUDED.source;

-- Quarter-end AUM snapshot linked to source document
INSERT INTO aum_history (
    scheme_id, report_date, period_type,
    closing_aum, average_aum, unit, source_document_id, source
)
SELECT
    s.id,
    DATE '2026-06-30',
    'QUARTERLY',
    20712.94,
    18129.36,
    'LAKH',
    sd.id,
    'Uploaded June - AUM.pdf'
FROM schemes s
LEFT JOIN source_documents sd ON sd.document_name = 'Uploaded June AUM Report'
WHERE s.scheme_code = 'DYNA/I/H/AALS/25/12/0002/360O'
ON CONFLICT (scheme_id, report_date, period_type)
DO UPDATE SET
    closing_aum = EXCLUDED.closing_aum,
    average_aum = EXCLUDED.average_aum,
    unit = EXCLUDED.unit,
    source_document_id = EXCLUDED.source_document_id,
    source = EXCLUDED.source;

COMMIT;

-- ============================================================
-- 10. QUICK VERIFICATION QUERIES
-- ============================================================
-- SELECT * FROM fund_analytics.source_documents;
-- SELECT * FROM fund_analytics.schemes;
-- SELECT * FROM fund_analytics.scheme_plans ORDER BY id;
-- SELECT * FROM fund_analytics.v_latest_nav ORDER BY scheme_plan_id;
-- SELECT * FROM fund_analytics.v_latest_aum;
