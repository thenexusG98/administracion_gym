import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import config from '../config/index.js';
import { userRepository } from '../repositories/user.repository.js';
import { AppError } from '../middlewares/errorHandler.js';
import { logActivity } from '../middlewares/activityLogger.js';

export const authService = {
  async login(email, password, clinicSlug) {
    let user;
    if (clinicSlug) {
      const clinic = await userRepository.findClinicBySlug(clinicSlug);
      if (!clinic) throw new AppError('Clínica no encontrada.', 404);
      user = await userRepository.findByEmail(email, clinic.id);
    } else {
      user = await userRepository.findByEmailAnyClinic(email);
    }

    if (!user) throw new AppError('Credenciales inválidas.', 401);
    if (!user.active) throw new AppError('Usuario desactivado.', 403);
    if (!user.clinic.active) throw new AppError('Clínica desactivada.', 403);

    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) throw new AppError('Credenciales inválidas.', 401);

    const tokens = this.generateTokens(user);
    await userRepository.updateRefreshToken(user.id, tokens.refreshToken);

    await logActivity({
      userId: user.id,
      clinicId: user.clinicId,
      action: 'LOGIN',
      entity: 'User',
      entityId: user.id,
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
        clinic: user.clinic,
      },
      ...tokens,
    };
  },

  async register(userData, clinicId) {
    const existingUser = await userRepository.findByEmail(userData.email, clinicId);
    if (existingUser) throw new AppError('El email ya está registrado en esta clínica.', 409);

    const hashedPassword = await bcrypt.hash(userData.password, 12);

    const user = await userRepository.create({
      ...userData,
      password: hashedPassword,
      clinicId,
    });

    return user;
  },

  async refreshToken(refreshToken) {
    if (!refreshToken) throw new AppError('Refresh token requerido.', 401);

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, config.jwt.refreshSecret);
    } catch {
      throw new AppError('Refresh token inválido o expirado.', 401);
    }

    const user = await userRepository.findByRefreshToken(refreshToken);
    if (!user) throw new AppError('Refresh token inválido.', 401);

    const tokens = this.generateTokens(user);
    await userRepository.updateRefreshToken(user.id, tokens.refreshToken);

    return tokens;
  },

  async logout(userId) {
    await userRepository.updateRefreshToken(userId, null);
  },

  generateTokens(user) {
    const payload = {
      userId: user.id,
      email: user.email,
      role: user.role,
      clinicId: user.clinicId,
    };

    const accessToken = jwt.sign(payload, config.jwt.secret, {
      expiresIn: config.jwt.expiresIn,
    });

    const refreshToken = jwt.sign(payload, config.jwt.refreshSecret, {
      expiresIn: config.jwt.refreshExpiresIn,
    });

    return { accessToken, refreshToken };
  },

  async changePassword(userId, currentPassword, newPassword) {
    const user = await userRepository.findByEmail(userId); // Necesitamos el hash
    // Re-fetch with password
    const fullUser = await (await import('../config/database.js')).default.user.findUnique({
      where: { id: userId },
    });

    if (!fullUser) throw new AppError('Usuario no encontrado.', 404);

    const isValid = await bcrypt.compare(currentPassword, fullUser.password);
    if (!isValid) throw new AppError('Contraseña actual incorrecta.', 401);

    const hashedPassword = await bcrypt.hash(newPassword, 12);
    await userRepository.update(userId, { password: hashedPassword });

    return { message: 'Contraseña actualizada correctamente.' };
  },
};
