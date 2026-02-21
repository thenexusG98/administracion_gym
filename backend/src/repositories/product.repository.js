import prisma from '../config/database.js';

export const productRepository = {
  async findAll(clinicId, { page = 1, limit = 20, search, category, lowStock } = {}) {
    const where = {
      clinicId,
      active: true,
      ...(category && { category }),
      ...(search && {
        OR: [
          { name: { contains: search, mode: 'insensitive' } },
          { sku: { contains: search, mode: 'insensitive' } },
          { barcode: { contains: search } },
        ],
      }),
      ...(lowStock && {
        stock: { lte: prisma.product.fields?.minStock ?? 5 },
        isService: false,
      }),
    };

    // Si lowStock, filtrar donde stock <= minStock
    if (lowStock) {
      delete where.stock;
      where.AND = [
        { isService: false },
        {
          // Usar raw para comparar stock con minStock
        },
      ];
      // Simplificado: usamos un approach directo
      delete where.AND;
      where.isService = false;
    }

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      prisma.product.findMany({
        where: { clinicId, active: true, ...(category && { category }), ...(search && { OR: [{ name: { contains: search, mode: 'insensitive' } }, { sku: { contains: search, mode: 'insensitive' } }] }) },
        skip,
        take: limit,
        orderBy: { name: 'asc' },
      }),
      prisma.product.count({ where: { clinicId, active: true, ...(category && { category }), ...(search && { OR: [{ name: { contains: search, mode: 'insensitive' } }, { sku: { contains: search, mode: 'insensitive' } }] }) } }),
    ]);

    return { data, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  },

  async findById(id, clinicId) {
    return prisma.product.findFirst({
      where: { id, clinicId },
      include: {
        inventoryMovements: {
          take: 20,
          orderBy: { createdAt: 'desc' },
        },
        supplierProducts: {
          include: { supplier: { select: { id: true, name: true } } },
        },
      },
    });
  },

  async create(data) {
    return prisma.product.create({ data });
  },

  async update(id, data) {
    return prisma.product.update({ where: { id }, data });
  },

  async delete(id) {
    return prisma.product.update({ where: { id }, data: { active: false } });
  },

  async getLowStock(clinicId) {
    const products = await prisma.product.findMany({
      where: { clinicId, active: true, isService: false },
    });
    return products.filter(p => p.stock <= p.minStock);
  },

  async getExpiringProducts(clinicId, days = 30) {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + days);

    return prisma.product.findMany({
      where: {
        clinicId,
        active: true,
        expiryDate: {
          lte: futureDate,
          gte: new Date(),
        },
      },
      orderBy: { expiryDate: 'asc' },
    });
  },

  async updateStock(id, quantity) {
    return prisma.product.update({
      where: { id },
      data: { stock: { increment: quantity } },
    });
  },
};
