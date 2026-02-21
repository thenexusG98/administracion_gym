import { medicalRecordRepository } from '../repositories/medicalRecord.repository.js';
import { AppError } from '../middlewares/errorHandler.js';

export const medicalRecordService = {
  async getAll(clinicId, query) {
    return medicalRecordRepository.findAll(clinicId, {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      petId: query.petId,
      vetId: query.vetId,
    });
  },

  async getById(id, clinicId) {
    const record = await medicalRecordRepository.findById(id, clinicId);
    if (!record) throw new AppError('Expediente no encontrado.', 404);
    return record;
  },

  async create(data, vetId, clinicId) {
    const { prescriptions, ...recordData } = data;

    return medicalRecordRepository.createWithPrescriptions(
      {
        ...recordData,
        vetId,
        clinicId,
      },
      prescriptions
    );
  },

  async update(id, clinicId, data) {
    const record = await medicalRecordRepository.findById(id, clinicId);
    if (!record) throw new AppError('Expediente no encontrado.', 404);

    const { prescriptions, ...recordData } = data;
    return medicalRecordRepository.update(id, recordData);
  },

  async getByPet(petId, clinicId) {
    return medicalRecordRepository.findByPet(petId, clinicId);
  },
};
