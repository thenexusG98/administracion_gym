import { userRepository } from '../repositories/user.repository.js';
import bcrypt from 'bcryptjs';
import { AppError } from '../middlewares/errorHandler.js';

export const userController = {
  async getAll(req, res, next) {
    try {
      const result = await userRepository.findAllByClinic(req.clinicId, {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
        search: req.query.search,
      });
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  },

  async getById(req, res, next) {
    try {
      const user = await userRepository.findById(req.params.id);
      if (!user || user.clinicId !== req.clinicId) {
        throw new AppError('Usuario no encontrado.', 404);
      }
      res.json({ success: true, data: user });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const { password, ...data } = req.body;
      if (password) {
        data.password = await bcrypt.hash(password, 12);
      }
      const user = await userRepository.update(req.params.id, data);
      res.json({ success: true, data: user });
    } catch (error) {
      next(error);
    }
  },

  async toggleActive(req, res, next) {
    try {
      const user = await userRepository.findById(req.params.id);
      if (!user) throw new AppError('Usuario no encontrado.', 404);

      const updated = await userRepository.update(req.params.id, { active: !user.active });
      res.json({ success: true, data: updated });
    } catch (error) {
      next(error);
    }
  },

  async getVets(req, res, next) {
    try {
      const vets = await userRepository.getVetsByClinic(req.clinicId);
      res.json({ success: true, data: vets });
    } catch (error) {
      next(error);
    }
  },
};
