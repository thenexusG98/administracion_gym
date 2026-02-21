import prisma from '../config/database.js';

export const clientRepository = {
  async findAll(clinicId, { page = 1, limit = 20, search } = {}) {
    const where = {
      clinicId,
      active: true,
      ...(search && {
        OR: [
          { firstName: { contains: search, mode: 'insensitive' } },
          { lastName: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } },
          { phone: { contains: search } },
        ],
      }),
    };

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      prisma.client.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          _count: { select: { pets: true } },
        },
      }),
      prisma.client.count({ where }),
    ]);

    return { data, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  },

  async findById(id, clinicId) {
    return prisma.client.findFirst({
      where: { id, clinicId },
      include: {
        pets: {
          where: { active: true },
          orderBy: { createdAt: 'desc' },
        },
        sales: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: { items: { include: { product: true } } },
        },
      },
    });
  },

  async create(data) {
    return prisma.client.create({ data });
  },

  async update(id, clinicId, data) {
    return prisma.client.update({
      where: { id },
      data,
    });
  },

  async delete(id, clinicId) {
    return prisma.client.update({
      where: { id },
      data: { active: false },
    });
  },

  async updateBalance(id, amount) {
    return prisma.client.update({
      where: { id },
      data: { balance: { increment: amount } },
    });
  },
};
