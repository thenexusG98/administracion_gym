import { medicalRecordService } from '../services/medicalRecord.service.js';

export const medicalRecordController = {
  async getAll(req, res, next) {
    try {
      const result = await medicalRecordService.getAll(req.clinicId, req.query);
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  },

  async getById(req, res, next) {
    try {
      const record = await medicalRecordService.getById(req.params.id, req.clinicId);
      res.json({ success: true, data: record });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const record = await medicalRecordService.create(req.body, req.user.id, req.clinicId);
      res.status(201).json({ success: true, data: record });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const record = await medicalRecordService.update(req.params.id, req.clinicId, req.body);
      res.json({ success: true, data: record });
    } catch (error) {
      next(error);
    }
  },

  async getByPet(req, res, next) {
    try {
      const records = await medicalRecordService.getByPet(req.params.petId, req.clinicId);
      res.json({ success: true, data: records });
    } catch (error) {
      next(error);
    }
  },
};
