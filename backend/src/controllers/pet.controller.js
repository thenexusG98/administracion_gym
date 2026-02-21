import { petService } from '../services/pet.service.js';

export const petController = {
  async getAll(req, res, next) {
    try {
      const result = await petService.getAll(req.clinicId, req.query);
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  },

  async getById(req, res, next) {
    try {
      const pet = await petService.getById(req.params.id, req.clinicId);
      res.json({ success: true, data: pet });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const pet = await petService.create(req.body, req.clinicId);
      res.status(201).json({ success: true, data: pet });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const pet = await petService.update(req.params.id, req.clinicId, req.body);
      res.json({ success: true, data: pet });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      await petService.delete(req.params.id, req.clinicId);
      res.json({ success: true, message: 'Mascota eliminada correctamente.' });
    } catch (error) {
      next(error);
    }
  },

  async getTimeline(req, res, next) {
    try {
      const timeline = await petService.getTimeline(req.params.id, req.clinicId);
      res.json({ success: true, data: timeline });
    } catch (error) {
      next(error);
    }
  },
};
