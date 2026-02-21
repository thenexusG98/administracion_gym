import prisma from '../config/database.js';

export const userRepository = {
  async findByEmail(email, clinicId) {
    return prisma.user.findFirst({
      where: { email, clinicId },
      include: { clinic: { select: { id: true, name: true, slug: true, active: true } } },
    });
  },

  async findByEmailAnyClinic(email) {
    return prisma.user.findFirst({
      where: { email },
      include: { clinic: { select: { id: true, name: true, slug: true, active: true } } },
    });
  },

  async findById(id) {
    return prisma.user.findUnique({
      where: { id },
      select: {
        id: true, email: true, firstName: true, lastName: true,
        phone: true, role: true, active: true, licenseNumber: true,
        clinicId: true, createdAt: true,
        clinic: { select: { id: true, name: true, slug: true } },
      },
    });
  },

  async create(data) {
    return prisma.user.create({
      data,
      select: {
        id: true, email: true, firstName: true, lastName: true,
        role: true, clinicId: true, createdAt: true,
      },
    });
  },

  async updateRefreshToken(id, refreshToken) {
    return prisma.user.update({
      where: { id },
      data: { refreshToken },
    });
  },

  async findByRefreshToken(refreshToken) {
    return prisma.user.findFirst({
      where: { refreshToken },
      include: { clinic: { select: { id: true, name: true, slug: true } } },
    });
  },

  async findAllByClinic(clinicId, { page = 1, limit = 20, search } = {}) {
    const where = {
      clinicId,
      ...(search && {
        OR: [
          { firstName: { contains: search, mode: 'insensitive' } },
          { lastName: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true, email: true, firstName: true, lastName: true,
          phone: true, role: true, active: true, licenseNumber: true,
          createdAt: true,
        },
      }),
      prisma.user.count({ where }),
    ]);

    return { data, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  },

  async update(id, data) {
    return prisma.user.update({
      where: { id },
      data,
      select: {
        id: true, email: true, firstName: true, lastName: true,
        phone: true, role: true, active: true, licenseNumber: true,
      },
    });
  },

  async getVetsByClinic(clinicId) {
    return prisma.user.findMany({
      where: { clinicId, role: 'VETERINARIO', active: true },
      select: { id: true, firstName: true, lastName: true, licenseNumber: true },
    });
  },

  async findClinicBySlug(slug) {
    return prisma.clinic.findUnique({ where: { slug } });
  },
};
