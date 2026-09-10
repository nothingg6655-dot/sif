import type { FastifyInstance } from "fastify";
import {
  aumImportBody,
  benchmarkImportBody,
  idParam,
  ingestionIdParam,
  navImportBody,
  portfolioImportBody,
  riskFreeImportBody,
} from "../../http/schemas.js";
import { requireAdmin } from "../../plugins/admin-auth.js";
import * as ingestion from "./ingestion.js";
import * as recalculate from "./recalculate.js";

export async function registerAdminRoutes(app: FastifyInstance): Promise<void> {
  app.addHook("preHandler", requireAdmin);

  app.post("/import/nav", async (request) => {
    const body = navImportBody.parse(request.body);
    return ingestion.importNav(app.db, body);
  });

  app.post("/import/aum", async (request) => {
    const body = aumImportBody.parse(request.body);
    return ingestion.importAum(app.db, body);
  });

  app.post("/import/portfolio", async (request) => {
    const body = portfolioImportBody.parse(request.body);
    return ingestion.importPortfolio(app.db, body);
  });

  app.post("/import/benchmark", async (request) => {
    const body = benchmarkImportBody.parse(request.body);
    return ingestion.importBenchmark(app.db, body);
  });

  app.post("/import/risk-free-rate", async (request) => {
    const body = riskFreeImportBody.parse(request.body);
    return ingestion.importRiskFreeRate(app.db, body);
  });

  app.post("/recalculate/returns/:schemeId", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return recalculate.recalculateReturns(app.db, schemeId);
  });

  app.post("/recalculate/portfolio/:schemeId", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return recalculate.recalculatePortfolio(app.db, schemeId);
  });

  app.post("/recalculate/risk/:schemeId", async (request) => {
    const { schemeId } = idParam.parse(request.params);
    return recalculate.recalculateRisk(app.db, schemeId);
  });

  app.get("/ingestion-runs", async () => ingestion.listIngestionRuns(app.db));

  app.get("/ingestion-runs/:id", async (request) => {
    const { id } = ingestionIdParam.parse(request.params);
    return ingestion.getIngestionRun(app.db, id);
  });
}
