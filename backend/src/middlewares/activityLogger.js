import prisma from '../config/database.js';

export const logActivity = async ({ userId, clinicId, action, entity, entityId, details, ipAddress }) => {
  try {
    await prisma.activityLog.create({
      data: {
        userId,
        clinicId,
        action,
        entity,
        entityId,
        details: typeof details === 'object' ? JSON.stringify(details) : details,
        ipAddress,
      },
    });
  } catch (error) {
    console.error('Error al registrar actividad:', error);
  }
};

// Middleware para bitácora automática
export const activityLogger = (action, entity) => {
  return (req, res, next) => {
    // Guardar referencia original de res.json
    const originalJson = res.json.bind(res);
    res.json = (data) => {
      // Solo loguear si fue exitoso
      if (res.statusCode >= 200 && res.statusCode < 300 && req.user) {
        logActivity({
          userId: req.user.id,
          clinicId: req.user.clinicId,
          action,
          entity,
          entityId: data?.data?.id || req.params.id,
          details: { method: req.method, path: req.originalUrl },
          ipAddress: req.ip,
        });
      }
      return originalJson(data);
    };
    next();
  };
};
