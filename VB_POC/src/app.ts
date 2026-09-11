import cors from "@fastify/cors";
import rateLimit from "@fastify/rate-limit";
import Fastify, { type FastifyInstance } from "fastify";
import type { AppConfig } from "./config.js";
import { createPool } from "./db.js";
import { registerAdminRoutes } from "./modules/admin/routes.js";
import { registerBenchmarkRoutes } from "./modules/benchmarks/routes.js";
import { registerCompareRoutes } from "./modules/compare/routes.js";
import { registerFundRoutes } from "./modules/funds/routes.js";
import { registerPlanRoutes } from "./modules/plans/routes.js";
import { registerSearchRoutes } from "./modules/search/routes.js";
import { registerIngestionRoutes } from "./modules/ingestion/routes.js";
import { registerErrorHandler } from "./plugins/error-handler.js";

export async function buildApp(config: AppConfig, database = createPool(config.DATABASE_URL)): Promise<FastifyInstance> {
  const app = Fastify({
    logger: {
      level: config.LOG_LEVEL,
    },
    genReqId: () => crypto.randomUUID(),
    requestIdHeader: "x-request-id",
  });

  const db = database;
  app.decorate("config", config);
  app.decorate("db", db);

  await app.register(cors, { origin: true });
  await app.register(rateLimit, {
    max: 1000,
    timeWindow: "1 minute",
  });

  registerErrorHandler(app);

  app.get("/", async () => {
    return { name: "DynaSIF Backend API", status: "online", health: "/health", funds: "/api/funds" };
  });

  app.get("/health", async () => {
    await db.query("SELECT 1");
    return { status: "ok" };
  });

  await app.register(registerSearchRoutes);
  await app.register(registerCompareRoutes);
  await app.register(registerFundRoutes);
  await app.register(registerPlanRoutes);
  await app.register(registerBenchmarkRoutes);
  await app.register(registerAdminRoutes, { prefix: "/api/admin" });
  await app.register(registerIngestionRoutes, { prefix: "/api/admin/import" });

  app.addHook("onClose", async () => {
    await db.end();
  });

  return app;
}
