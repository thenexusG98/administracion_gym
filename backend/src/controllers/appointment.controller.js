import { appointmentService } from '../services/appointment.service.js';

export const appointmentController = {
  async getAll(req, res, next) {
    try {
      const result = await appointmentService.getAll(req.clinicId, req.query);
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  },

  async getById(req, res, next) {
    try {
      const appointment = await appointmentService.getById(req.params.id, req.clinicId);
      res.json({ success: true, data: appointment });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const appointment = await appointmentService.create(req.body, req.clinicId);
      res.status(201).json({ success: true, data: appointment });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const appointment = await appointmentService.update(req.params.id, req.clinicId, req.body);
      res.json({ success: true, data: appointment });
    } catch (error) {
      next(error);
    }
  },

  async cancel(req, res, next) {
    try {
      await appointmentService.cancel(req.params.id, req.clinicId);
      res.json({ success: true, message: 'Cita cancelada correctamente.' });
    } catch (error) {
      next(error);
    }
  },

  async getCalendar(req, res, next) {
    try {
      const { startDate, endDate, vetId } = req.query;
      const data = await appointmentService.getCalendar(req.clinicId, startDate, endDate, vetId);
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  },

  async getToday(req, res, next) {
    try {
      const data = await appointmentService.getToday(req.clinicId);
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  },
};
