import prisma from '../config/database.js';

export const inventoryRepository = {
  async createMovement(data) {
    return prisma.$transaction(async (tx) => {
      const movement = await tx.inventoryMovement.create({ data });

      // Actualizar stock
      let stockChange = data.quantity;
      if (data.type === 'SALIDA') stockChange = -data.quantity;
      // AJUSTE puede ser positivo o negativo, pero lo tratamos como valor absoluto para ajustar

      if (data.type === 'AJUSTE') {
        // Para ajuste, establecer el stock al valor indicado
        const product = await tx.product.findUnique({ where: { id: data.productId } });
        await tx.product.update({
          where: { id: data.productId },
          data: { stock: data.quantity },
        });
      } else {
        await tx.product.update({
          where: { id: data.productId },
          data: { stock: { increment: stockChange } },
        });
      }

      return movement;
    });
  },

  async getMovements(clinicId, { page = 1, limit = 20, productId, type } = {}) {
    const where = {
      clinicId,
      ...(productId && { productId }),
      ...(type && { type }),
    };

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      prisma.inventoryMovement.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          product: { select: { id: true, name: true, sku: true } },
        },
      }),
      prisma.inventoryMovement.count({ where }),
    ]);

    return { data, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  },
};

export const supplierRepository = {
  async findAll(clinicId, { page = 1, limit = 20, search } = {}) {
    const where = {
      clinicId,
      active: true,
      ...(search && {
        OR: [
          { name: { contains: search, mode: 'insensitive' } },
          { contactName: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      prisma.supplier.findMany({ where, skip, take: limit, orderBy: { name: 'asc' } }),
      prisma.supplier.count({ where }),
    ]);

    return { data, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  },

  async findById(id, clinicId) {
    return prisma.supplier.findFirst({
      where: { id, clinicId },
      include: {
        supplierProducts: {
          include: { product: { select: { id: true, name: true, price: true } } },
        },
      },
    });
  },

  async create(data) { return prisma.supplier.create({ data }); },
  async update(id, data) { return prisma.supplier.update({ where: { id }, data }); },
  async delete(id) { return prisma.supplier.update({ where: { id }, data: { active: false } }); },
};
