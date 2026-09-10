export class AppError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly statusCode: number,
  ) {
    super(message);
    this.name = "AppError";
  }
}

export function notFound(code: string, message: string): AppError {
  return new AppError(code, message, 404);
}

export function badRequest(code: string, message: string): AppError {
  return new AppError(code, message, 400);
}

export function unauthorized(message = "Admin authentication required."): AppError {
  return new AppError("UNAUTHORIZED", message, 401);
}
