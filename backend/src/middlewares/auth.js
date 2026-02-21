import jwt from 'jsonwebtoken';
import config from '../config/index.js';
import prisma from '../config/database.js';
import { AppError } from './errorHandler.js';

// Verificar JWT
export const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('No se proporcionó token de autenticación.', 401);
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, config.jwt.secret);

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        active: true,
        clinicId: true,
        clinic: {
          select: { id: true, name: true, slug: true, active: true }
        },
      },
    });

    if (!user || !user.active) {
      throw new AppError('Usuario no encontrado o inactivo.', 401);
    }

    if (!user.clinic.active) {
      throw new AppError('La clínica está desactivada.', 403);
    }

    req.user = user;
    next();
  } catch (error) {
    if (error instanceof AppError) {
      return next(error);
    }
    next(new AppError('Token inválido o expirado.', 401));
  }
};

// Autorización por roles
export const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(new AppError('No autenticado.', 401));
    }
    if (!roles.includes(req.user.role)) {
      return next(new AppError('No tienes permisos para esta acción.', 403));
    }
    next();
  };
};

// Asegurar que opera dentro de su clínica (multi-tenant)
export const ensureClinic = (req, res, next) => {
  // Inyectar clinicId del usuario autenticado en el body/query
  if (req.body) {
    req.body.clinicId = req.user.clinicId;
  }
  req.clinicId = req.user.clinicId;
  next();
};
