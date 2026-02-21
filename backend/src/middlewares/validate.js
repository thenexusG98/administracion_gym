import { AppError } from './errorHandler.js';

// Middleware genérico para validar con Zod
export const validate = (schema) => {
  return (req, res, next) => {
    try {
      const result = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      // Reemplazar con datos parseados/transformados
      req.body = result.body ?? req.body;
      req.query = result.query ?? req.query;
      req.params = result.params ?? req.params;
      next();
    } catch (error) {
      next(error); // Se captura en errorHandler como ZodError
    }
  };
};

// Validar solo body
export const validateBody = (schema) => {
  return (req, res, next) => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      next(error);
    }
  };
};

// Validar solo params
export const validateParams = (schema) => {
  return (req, res, next) => {
    try {
      req.params = schema.parse(req.params);
      next();
    } catch (error) {
      next(error);
    }
  };
};
