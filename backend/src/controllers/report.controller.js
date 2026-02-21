import { reportService } from '../services/report.service.js';

export const reportController = {
  async getIncome(req, res, next) {
    try {
      const { startDate, endDate } = req.query;
      const result = await reportService.getIncomeReport(req.clinicId, startDate, endDate);
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  async getTopServices(req, res, next) {
    try {
      const { startDate, endDate, limit } = req.query;
      const result = await reportService.getTopServices(req.clinicId, startDate, endDate, parseInt(limit) || 10);
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  async getTopProducts(req, res, next) {
    try {
      const { startDate, endDate, limit } = req.query;
      const result = await reportService.getTopProducts(req.clinicId, startDate, endDate, parseInt(limit) || 10);
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  async getPatients(req, res, next) {
    try {
      const { startDate, endDate } = req.query;
      const result = await reportService.getPatientsReport(req.clinicId, startDate, endDate);
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },
};

export const dashboardController = {
  async getStats(req, res, next) {
    try {
      const stats = await reportService.getDashboardStats(req.clinicId);
      res.json({ success: true, data: stats });
    } catch (error) {
      next(error);
    }
  },
};
