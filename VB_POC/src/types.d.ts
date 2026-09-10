import type { AppConfig } from "./config.js";
import type pg from "pg";

declare module "fastify" {
  interface FastifyInstance {
    config: AppConfig;
    db: pg.Pool;
  }
}
