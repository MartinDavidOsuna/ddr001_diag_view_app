import type { ErrorRequestHandler, RequestHandler } from 'express';
import { ZodError } from 'zod';

export class HttpError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
    public readonly details?: unknown,
  ) {
    super(message);
  }
}

export const notFound: RequestHandler = (_request, _response, next) => {
  next(new HttpError(404, 'NOT_FOUND', 'Ruta no encontrada.'));
};

export const errorHandler: ErrorRequestHandler = (error, _request, response, next) => {
  void next;
  if (error instanceof ZodError || (error instanceof Error && error.name === 'ZodError')) {
    const details = error instanceof ZodError ? error.issues : error.message;
    response.status(400).json({ error: { code: 'VALIDATION', message: 'Entrada inválida.', details } });
    return;
  }
  if (error instanceof HttpError) {
    response.status(error.status).json({ error: { code: error.code, message: error.message, details: error.details } });
    return;
  }
  response.status(500).json({ error: { code: 'SERVER', message: 'Error interno.' } });
};
