import pg from "pg";

const { Pool } = pg;

export function createPool(databaseUrl: string): pg.Pool {
  return new Pool({
    connectionString: databaseUrl,
    max: 10,
    options: "-c search_path=fund_analytics,public",
  });
}

export type DbClient = pg.Pool | pg.PoolClient;
