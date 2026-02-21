import { saleService, inventoryService } from '../services/sale.service.js';

export const saleController = {
  async getAll(req, res, next) {
    try {
      const result = await saleService.getAll(req.clinicId, req.query);
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  },

  async getById(req, res, next) {
    try {
      const sale = await saleService.getById(req.params.id, req.clinicId);
      res.json({ success: true, data: sale });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const sale = await saleService.create(req.body, req.user.id, req.clinicId);
      res.status(201).json({ success: true, data: sale });
    } catch (error) {
      next(error);
    }
  },

  async cancel(req, res, next) {
    try {
      await saleService.cancel(req.params.id, req.clinicId);
      res.json({ success: true, message: 'Venta cancelada correctamente.' });
    } catch (error) {
      next(error);
    }
  },

  async cashCut(req, res, next) {
    try {
      const { startDate, endDate } = req.query;
      const result = await saleService.cashCut(req.clinicId, startDate, endDate);
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },
};

export const inventoryController = {
  async createMovement(req, res, next) {
    try {
      const movement = await inventoryService.createMovement(req.body, req.clinicId);
      res.status(201).json({ success: true, data: movement });
    } catch (error) {
      next(error);
    }
  },

  async getMovements(req, res, next) {
    try {
      const result = await inventoryService.getMovements(req.clinicId, req.query);
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  },
};
