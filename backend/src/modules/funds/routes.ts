import type { FastifyInstance } from "fastify";
import {
  dateQuery,
  dateRangeQuery,
  idParam,
  paginationQuery,
  topHoldingsQuery,
} from "../../http/schemas.js";
import * as funds from "./repo.js";
import * as plans from "../plans/service.js";

export async function registerFundRoutes(app: FastifyInstance): Promise<void> {

  app.get("/api/funds", async (request) => {
    const query = paginationQuery.parse(request.query);
    return funds.listFunds(app.db, query);
  });

  app.get("/api/funds/:schemeId", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getFundOverview(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/plans", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getFundPlans(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/managers", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getFundManagers(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/risk", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getFundRisk(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/allocation-limits", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getAllocationLimits(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/aum/latest", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getLatestAum(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/aum/history", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getAumHistory(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/portfolio/latest", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getPortfolio(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/portfolio", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    const { date } = dateQuery.parse(request.query);
    return funds.getPortfolio(app.db, schemeId, date);
  });

  app.get("/api/funds/:schemeId/top-holdings", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    const { limit } = topHoldingsQuery.parse(request.query);
    return funds.getTopHoldings(app.db, schemeId, limit);
  });

  app.get("/api/funds/:schemeId/sectors", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getSectors(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/asset-allocation", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getAssetAllocation(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/exposure", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getExposure(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/exposure/history", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getExposureHistory(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/derivatives", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    const { date } = dateQuery.parse(request.query);
    return funds.getDerivatives(app.db, schemeId, date);
  });

  app.get("/api/funds/:schemeId/benchmark", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return funds.getBenchmark(app.db, schemeId);
  });

  app.get("/api/funds/:schemeId/benchmark/history", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    const range = dateRangeQuery.parse(request.query);
    return funds.getCompositeBenchmarkHistory(app.db, schemeId, range);
  });

  app.get("/api/funds/:schemeId/monthly-returns", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    await funds.requireScheme(app.db, schemeId);
    const planId = await funds.getPrimaryPlanId(app.db, schemeId);
    if (!planId) {
      return { schemeId, monthlyReturns: {} };
    }
    const result = await plans.getMonthlyReturns(app.db, planId);
    return {
      schemeId,
      planId,
      monthlyReturns: result.monthlyReturns,
    };
  });
}

