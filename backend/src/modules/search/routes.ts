import type { FastifyInstance } from "fastify";
import { searchQuery } from "../../http/schemas.js";
import { listFunds } from "../funds/repo.js";

export async function registerSearchRoutes(app: FastifyInstance): Promise<void> {
  app.get("/api/search", async (request) => {
    const query = searchQuery.parse(request.query);
    return listFunds(app.db, {
      q: query.q,
      page: query.page,
      limit: query.limit,
    });
  });
}
