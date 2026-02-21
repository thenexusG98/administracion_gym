import { authService } from '../services/auth.service.js';

export const authController = {
  async login(req, res, next) {
    try {
      const { email, password, clinicSlug } = req.body;
      const result = await authService.login(email, password, clinicSlug);
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  async register(req, res, next) {
    try {
      const user = await authService.register(req.body, req.clinicId);
      res.status(201).json({ success: true, data: user });
    } catch (error) {
      next(error);
    }
  },

  async refreshToken(req, res, next) {
    try {
      const { refreshToken } = req.body;
      const tokens = await authService.refreshToken(refreshToken);
      res.json({ success: true, data: tokens });
    } catch (error) {
      next(error);
    }
  },

  async logout(req, res, next) {
    try {
      await authService.logout(req.user.id);
      res.json({ success: true, message: 'Sesión cerrada correctamente.' });
    } catch (error) {
      next(error);
    }
  },

  async me(req, res, next) {
    try {
      res.json({ success: true, data: req.user });
    } catch (error) {
      next(error);
    }
  },

  async changePassword(req, res, next) {
    try {
      const { currentPassword, newPassword } = req.body;
      const result = await authService.changePassword(req.user.id, currentPassword, newPassword);
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  },
};
