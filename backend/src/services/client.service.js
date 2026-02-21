import { clientRepository } from '../repositories/client.repository.js';
import { AppError } from '../middlewares/errorHandler.js';

export const clientService = {
  async getAll(clinicId, query) {
    return clientRepository.findAll(clinicId, {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      search: query.search,
    });
  },

  async getById(id, clinicId) {
    const client = await clientRepository.findById(id, clinicId);
    if (!client) throw new AppError('Cliente no encontrado.', 404);
    return client;
  },

  async create(data, clinicId) {
    return clientRepository.create({ ...data, clinicId });
  },

  async update(id, clinicId, data) {
    const client = await clientRepository.findById(id, clinicId);
    if (!client) throw new AppError('Cliente no encontrado.', 404);
    return clientRepository.update(id, clinicId, data);
  },

  async delete(id, clinicId) {
    const client = await clientRepository.findById(id, clinicId);
    if (!client) throw new AppError('Cliente no encontrado.', 404);
    return clientRepository.delete(id, clinicId);
  },
};
