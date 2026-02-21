import { clientService } from '../services/client.service.js';

export const clientController = {
  async getAll(req, res, next) {
    try {
      const result = await clientService.getAll(req.clinicId, req.query);
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  },

  async getById(req, res, next) {
    try {
      const client = await clientService.getById(req.params.id, req.clinicId);
      res.json({ success: true, data: client });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const client = await clientService.create(req.body, req.clinicId);
      res.status(201).json({ success: true, data: client });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const client = await clientService.update(req.params.id, req.clinicId, req.body);
      res.json({ success: true, data: client });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      await clientService.delete(req.params.id, req.clinicId);
      res.json({ success: true, message: 'Cliente eliminado correctamente.' });
    } catch (error) {
      next(error);
    }
  },
};
