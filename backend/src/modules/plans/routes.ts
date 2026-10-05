import type { FastifyInstance } from "fastify";
import { dateRangeQuery, periodQuery, planIdParam, rollingPeriodQuery } from "../../http/schemas.js";
import * as plans from "./service.js";

export async function registerPlanRoutes(app: FastifyInstance): Promise<void> {
  app.get("/api/plans/:planId/nav/latest", async (request) => {
    const { planId } = planIdParam.parse(request.params);
    return plans.getLatestNav(app.db, planId);
  });

  app.get("/api/plans/:planId/nav/history", async (request) => {
    const { planId } = planIdParam.parse(request.params);
    const range = dateRangeQuery.parse(request.query);
    return plans.getNavHistory(app.db, planId, range);
  });

  app.get("/api/plans/:planId/returns", async (request) => {
    const { planId } = planIdParam.parse(request.params);
    const { period } = periodQuery.parse(request.query);
    return plans.getReturns(app.db, planId, period ?? "SINCE_INCEPTION");
  });

  app.get("/api/plans/:planId/rolling-returns", async (request) => {
    const { planId } = planIdParam.parse(request.params);
    const { period } = rollingPeriodQuery.parse(request.query);
    return plans.getRollingReturns(app.db, planId, period ?? "3M");
  });

  app.get("/api/plans/:planId/drawdown", async (request) => {
    const { planId } = planIdParam.parse(request.params);
    return plans.getDrawdown(app.db, planId);
  });

  app.get("/api/plans/:planId/risk-metrics", async (request) => {
    const { planId } = planIdParam.parse(request.params);
    const { period } = periodQuery.parse(request.query);
    return plans.getRiskMetrics(app.db, planId, period ?? "SINCE_INCEPTION");
  });

  app.get("/api/plans/:planId/monthly-returns", async (request) => {
    const { planId } = planIdParam.parse(request.params);
    return plans.getMonthlyReturns(app.db, planId);
  });
}

