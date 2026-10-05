import { FastifyReply, FastifyRequest } from "fastify";
import { unauthorized } from "../errors.js";

export async function requireAdmin(request: FastifyRequest, _reply: FastifyReply): Promise<void> {
  const header = request.headers["x-admin-key"];
  const provided = Array.isArray(header) ? header[0] : header;
  if (!provided || provided !== request.server.config.ADMIN_API_KEY) {
    throw unauthorized();
  }
}
