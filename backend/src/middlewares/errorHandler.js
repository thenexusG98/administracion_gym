export class AppError extends Error {
  constructor(message, statusCode, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
    this.isOperational = true;
  }
}

export const notFoundHandler = (req, res, next) => {
  const error = new AppError(`Ruta no encontrada: ${req.originalUrl}`, 404);
  next(error);
};

export const errorHandler = (err, req, res, _next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Error interno del servidor';

  // Prisma errors
  if (err.code === 'P2002') {
    statusCode = 409;
    message = 'Ya existe un registro con esos datos únicos.';
  }
  if (err.code === 'P2025') {
    statusCode = 404;
    message = 'Registro no encontrado.';
  }

  // Zod validation errors
  if (err.name === 'ZodError') {
    statusCode = 400;
    message = 'Error de validación';
    return res.status(statusCode).json({
      success: false,
      message,
      errors: err.errors.map(e => ({
        field: e.path.join('.'),
        message: e.message,
      })),
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Token inválido.';
  }
  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Token expirado.';
  }

  if (process.env.NODE_ENV === 'development') {
    console.error('❌ Error:', err);
  }

  res.status(statusCode).json({
    success: false,
    message,
    ...(err.details && { details: err.details }),
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};
