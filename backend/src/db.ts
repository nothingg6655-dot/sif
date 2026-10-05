import pg from "pg";

const { Pool } = pg;

export function createPool(databaseUrl: string): pg.Pool {
  const isRemote =
    !databaseUrl.includes("localhost") &&
    !databaseUrl.includes("127.0.0.1") &&
    !databaseUrl.includes("::1");

  return new Pool({
    connectionString: databaseUrl,
    max: 10,
    options: "-c search_path=fund_analytics,public",
    ...(isRemote ? { ssl: { rejectUnauthorized: false } } : {}),
  });
}

export type DbClient = pg.Pool | pg.PoolClient;

