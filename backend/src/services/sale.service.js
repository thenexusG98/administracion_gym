import { saleRepository } from '../repositories/sale.repository.js';
import { inventoryRepository } from '../repositories/inventory.repository.js';
import { AppError } from '../middlewares/errorHandler.js';

export const saleService = {
  async getAll(clinicId, query) {
    return saleRepository.findAll(clinicId, {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      startDate: query.startDate,
      endDate: query.endDate,
      status: query.status,
    });
  },

  async getById(id, clinicId) {
    const sale = await saleRepository.findById(id, clinicId);
    if (!sale) throw new AppError('Venta no encontrada.', 404);
    return sale;
  },

  async create(data, userId, clinicId) {
    return saleRepository.create(
      { ...data, userId },
      data.items,
      data.payments,
      clinicId
    );
  },

  async cancel(id, clinicId) {
    return saleRepository.cancel(id, clinicId);
  },

  async cashCut(clinicId, startDate, endDate) {
    return saleRepository.cashCut(clinicId, startDate, endDate);
  },
};

export const inventoryService = {
  async createMovement(data, clinicId) {
    return inventoryRepository.createMovement({ ...data, clinicId });
  },

  async getMovements(clinicId, query) {
    return inventoryRepository.getMovements(clinicId, {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      productId: query.productId,
      type: query.type,
    });
  },
};
