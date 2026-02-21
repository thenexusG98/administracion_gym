import prisma from '../config/database.js';

// Base repository con operaciones comunes multi-tenant
export class BaseRepository {
  constructor(model) {
    this.model = model;
    this.prisma = prisma;
  }

  async findAll(clinicId, { page = 1, limit = 20, search, orderBy = { createdAt: 'desc' }, where = {} } = {}) {
    const skip = (page - 1) * limit;
    const finalWhere = { ...where, clinicId };

    const [data, total] = await Promise.all([
      this.prisma[this.model].findMany({
        where: finalWhere,
        skip,
        take: limit,
        orderBy,
      }),
      this.prisma[this.model].count({ where: finalWhere }),
    ]);

    return {
      data,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findById(id, clinicId) {
    return this.prisma[this.model].findFirst({
      where: { id, clinicId },
    });
  }

  async create(data) {
    return this.prisma[this.model].create({ data });
  }

  async update(id, clinicId, data) {
    return this.prisma[this.model].updateMany({
      where: { id, clinicId },
      data,
    });
  }

  async delete(id, clinicId) {
    return this.prisma[this.model].deleteMany({
      where: { id, clinicId },
    });
  }
}

export default BaseRepository;
