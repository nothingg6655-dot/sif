import type { FastifyInstance } from "fastify";
import { dateRangeQuery, benchmarkIdParam } from "../../http/schemas.js";
import { getBenchmarkHistory } from "../funds/repo.js";

export async function registerBenchmarkRoutes(app: FastifyInstance): Promise<void> {
  app.get("/api/benchmarks/:benchmarkId/history", async (request) => {
    const { benchmarkId } = benchmarkIdParam.parse(request.params);
    const range = dateRangeQuery.parse(request.query);
    return getBenchmarkHistory(app.db, benchmarkId, range);
  });
}
