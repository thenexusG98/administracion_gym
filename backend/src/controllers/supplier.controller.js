import { supplierRepository } from '../repositories/inventory.repository.js';
import { AppError } from '../middlewares/errorHandler.js';

export const supplierController = {
  async getAll(req, res, next) {
    try {
      const result = await supplierRepository.findAll(req.clinicId, {
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
      const supplier = await supplierRepository.findById(req.params.id, req.clinicId);
      if (!supplier) throw new AppError('Proveedor no encontrado.', 404);
      res.json({ success: true, data: supplier });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const supplier = await supplierRepository.create({ ...req.body, clinicId: req.clinicId });
      res.status(201).json({ success: true, data: supplier });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const supplier = await supplierRepository.update(req.params.id, req.body);
      res.json({ success: true, data: supplier });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      await supplierRepository.delete(req.params.id);
      res.json({ success: true, message: 'Proveedor eliminado correctamente.' });
    } catch (error) {
      next(error);
    }
  },
};
