import { productService } from '../services/product.service.js';

export const productController = {
  async getAll(req, res, next) {
    try {
      const result = await productService.getAll(req.clinicId, req.query);
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  },

  async getById(req, res, next) {
    try {
      const product = await productService.getById(req.params.id, req.clinicId);
      res.json({ success: true, data: product });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const product = await productService.create(req.body, req.clinicId);
      res.status(201).json({ success: true, data: product });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const product = await productService.update(req.params.id, req.clinicId, req.body);
      res.json({ success: true, data: product });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      await productService.delete(req.params.id, req.clinicId);
      res.json({ success: true, message: 'Producto eliminado correctamente.' });
    } catch (error) {
      next(error);
    }
  },

  async getLowStock(req, res, next) {
    try {
      const products = await productService.getLowStock(req.clinicId);
      res.json({ success: true, data: products });
    } catch (error) {
      next(error);
    }
  },

  async getExpiring(req, res, next) {
    try {
      const days = parseInt(req.query.days) || 30;
      const products = await productService.getExpiring(req.clinicId, days);
      res.json({ success: true, data: products });
    } catch (error) {
      next(error);
    }
  },
};
