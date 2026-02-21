import { petRepository } from '../repositories/pet.repository.js';
import { AppError } from '../middlewares/errorHandler.js';

export const petService = {
  async getAll(clinicId, query) {
    return petRepository.findAll(clinicId, {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      search: query.search,
      clientId: query.clientId,
    });
  },

  async getById(id, clinicId) {
    const pet = await petRepository.findById(id, clinicId);
    if (!pet) throw new AppError('Mascota no encontrada.', 404);
    return pet;
  },

  async create(data, clinicId) {
    return petRepository.create({
      ...data,
      clinicId,
      birthDate: data.birthDate ? new Date(data.birthDate) : null,
    });
  },

  async update(id, clinicId, data) {
    const pet = await petRepository.findById(id, clinicId);
    if (!pet) throw new AppError('Mascota no encontrada.', 404);

    return petRepository.update(id, clinicId, {
      ...data,
      ...(data.birthDate && { birthDate: new Date(data.birthDate) }),
    });
  },

  async delete(id, clinicId) {
    const pet = await petRepository.findById(id, clinicId);
    if (!pet) throw new AppError('Mascota no encontrada.', 404);
    return petRepository.delete(id, clinicId);
  },

  async getTimeline(id, clinicId) {
    return petRepository.getTimeline(id, clinicId);
  },
};
