import { productRepository } from '../repositories/product.repository.js';
import { AppError } from '../middlewares/errorHandler.js';

export const productService = {
  async getAll(clinicId, query) {
    return productRepository.findAll(clinicId, {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      search: query.search,
      category: query.category,
      lowStock: query.lowStock === 'true',
    });
  },

  async getById(id, clinicId) {
    const product = await productRepository.findById(id, clinicId);
    if (!product) throw new AppError('Producto no encontrado.', 404);
    return product;
  },

  async create(data, clinicId) {
    return productRepository.create({
      ...data,
      clinicId,
      ...(data.expiryDate && { expiryDate: new Date(data.expiryDate) }),
    });
  },

  async update(id, clinicId, data) {
    const product = await productRepository.findById(id, clinicId);
    if (!product) throw new AppError('Producto no encontrado.', 404);
    return productRepository.update(id, {
      ...data,
      ...(data.expiryDate && { expiryDate: new Date(data.expiryDate) }),
    });
  },

  async delete(id, clinicId) {
    const product = await productRepository.findById(id, clinicId);
    if (!product) throw new AppError('Producto no encontrado.', 404);
    return productRepository.delete(id);
  },

  async getLowStock(clinicId) {
    return productRepository.getLowStock(clinicId);
  },

  async getExpiring(clinicId, days) {
    return productRepository.getExpiringProducts(clinicId, days);
  },
};
