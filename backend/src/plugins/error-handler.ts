import { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import { ZodError } from "zod";
import { AppError } from "../errors.js";

export function registerErrorHandler(app: FastifyInstance): void {
  app.setErrorHandler((error: unknown, request: FastifyRequest, reply: FastifyReply) => {
    if (error instanceof ZodError) {
      return reply.status(400).send({
        data: null,
        meta: { requestId: request.id },
        error: {
          code: "VALIDATION_ERROR",
          message: error.issues.map((issue) => issue.message).join("; "),
        },
      });
    }

    if (error instanceof AppError) {
      return reply.status(error.statusCode).send({
        data: null,
        meta: { requestId: request.id },
        error: {
          code: error.code,
          message: error.message,
        },
      });
    }

    if (error instanceof Error && "statusCode" in error && typeof error.statusCode === "number"
      && error.statusCode >= 400 && error.statusCode < 500) {
      return reply.status(error.statusCode).send({
        data: null,
        meta: { requestId: request.id },
        error: { code: "code" in error ? error.code : "BAD_REQUEST", message: error.message },
      });
    }

    request.log.error({ err: error }, "unhandled_error");
    const expose = app.config.NODE_ENV === "development";
    const message =
      expose && error instanceof Error ? error.message : "An unexpected error occurred.";
    return reply.status(500).send({
      data: null,
      meta: { requestId: request.id },
      error: {
        code: "INTERNAL_ERROR",
        message,
      },
    });
  });
}
