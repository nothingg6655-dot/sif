import type { FastifyInstance } from "fastify";
import { compareQuery, compareReturnsQuery } from "../../http/schemas.js";
import { badRequest } from "../../errors.js";
import { getFundOverview, getLatestAum } from "../funds/repo.js";
import { getLatestNav, getReturns, getRiskMetrics } from "../plans/service.js";

async function preferredPlanId(app: FastifyInstance, schemeId: number): Promise<number | null> {
  const result = await app.db.query<{ id: string }>(
    `
    SELECT id
    FROM scheme_plans
    WHERE scheme_id = $1 AND is_active = TRUE
    ORDER BY
      CASE WHEN plan_type ILIKE 'Direct%' AND option_type ILIKE 'Growth%' THEN 0 ELSE 1 END,
      id
    LIMIT 1
    `,
    [schemeId],
  );
  const row = result.rows[0];
  return row ? Number(row.id) : null;
}

export async function registerCompareRoutes(app: FastifyInstance): Promise<void> {
  app.get("/api/funds/compare", async (request) => {
    const { ids } = compareQuery.parse(request.query);
    if (ids.length > 5) {
      throw badRequest("TOO_MANY_FUNDS", "Compare at most 5 funds at a time.");
    }
    const funds = [];
    for (const schemeId of ids) {
      const overview = await getFundOverview(app.db, schemeId);
      const aum = await getLatestAum(app.db, schemeId);
      const planId = await preferredPlanId(app, schemeId);
      const nav = planId ? await getLatestNav(app.db, planId) : { nav: null, navDate: null };
      const expense = planId
        ? await app.db.query<{ expense_ratio_max: string | null }>(
            "SELECT expense_ratio_max FROM scheme_plans WHERE id = $1",
            [planId],
          )
        : { rows: [] };
      funds.push({
        schemeId,
        schemeName: overview.schemeName,
        category: overview.category,
        riskBand: overview.riskBand,
        allotmentDate: overview.allotmentDate,
        latestNav: "nav" in nav ? nav.nav : null,
        aum: "closingAum" in aum ? aum.closingAum : null,
        aumUnit: "unit" in aum ? aum.unit : null,
        expenseRatio: expense.rows[0]?.expense_ratio_max
          ? Number(expense.rows[0].expense_ratio_max)
          : null,
      });
    }
    return { funds };
  });

  app.get("/api/funds/compare/returns", async (request) => {
    const { ids, period } = compareReturnsQuery.parse(request.query);
    const funds = [];
    for (const schemeId of ids) {
      const overview = await getFundOverview(app.db, schemeId);
      const planId = await preferredPlanId(app, schemeId);
      const returns = planId
        ? await getReturns(app.db, planId, period)
        : { period, absoluteReturn: null, annualizedReturn: null, benchmarkReturn: null };
      funds.push({
        schemeId,
        schemeName: overview.schemeName,
        ...returns,
      });
    }
    return { period, funds };
  });

  app.get("/api/funds/compare/risk", async (request) => {
    const { ids, period } = compareReturnsQuery.parse(request.query);
    const funds = [];
    for (const schemeId of ids) {
      const overview = await getFundOverview(app.db, schemeId);
      const planId = await preferredPlanId(app, schemeId);
      const metrics = planId
        ? await getRiskMetrics(app.db, planId, period)
        : {
            period,
            volatility: null,
            alpha: null,
            beta: null,
            sharpeRatio: null,
            sortinoRatio: null,
            trackingError: null,
            informationRatio: null,
            maxDrawdown: null,
          };
      funds.push({
        schemeId,
        schemeName: overview.schemeName,
        ...metrics,
      });
    }
    return { period, funds };
  });
}
