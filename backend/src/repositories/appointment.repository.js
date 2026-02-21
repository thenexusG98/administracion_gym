import prisma from '../config/database.js';

export const appointmentRepository = {
  async findAll(clinicId, { page = 1, limit = 20, date, vetId, status, startDate, endDate } = {}) {
    const where = {
      clinicId,
      ...(vetId && { vetId }),
      ...(status && { status }),
      ...(date && {
        date: {
          gte: new Date(`${date}T00:00:00`),
          lte: new Date(`${date}T23:59:59`),
        },
      }),
      ...(startDate && endDate && {
        date: {
          gte: new Date(startDate),
          lte: new Date(endDate),
        },
      }),
    };

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      prisma.appointment.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
        include: {
          pet: {
            select: { id: true, name: true, species: true },
            include: { client: { select: { id: true, firstName: true, lastName: true, phone: true } } },
          },
          vet: { select: { id: true, firstName: true, lastName: true } },
        },
      }),
      prisma.appointment.count({ where }),
    ]);

    return { data, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  },

  async findById(id, clinicId) {
    return prisma.appointment.findFirst({
      where: { id, clinicId },
      include: {
        pet: {
          include: { client: true },
        },
        vet: { select: { id: true, firstName: true, lastName: true, licenseNumber: true } },
        medicalRecord: true,
      },
    });
  },

  async create(data) {
    return prisma.appointment.create({
      data,
      include: {
        pet: { select: { id: true, name: true } },
        vet: { select: { id: true, firstName: true, lastName: true } },
      },
    });
  },

  async update(id, data) {
    return prisma.appointment.update({
      where: { id },
      data,
    });
  },

  async delete(id) {
    return prisma.appointment.update({
      where: { id },
      data: { status: 'CANCELADA' },
    });
  },

  async getByDateRange(clinicId, startDate, endDate, vetId) {
    return prisma.appointment.findMany({
      where: {
        clinicId,
        date: { gte: new Date(startDate), lte: new Date(endDate) },
        ...(vetId && { vetId }),
      },
      orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
      include: {
        pet: {
          select: { id: true, name: true, species: true },
          include: { client: { select: { firstName: true, lastName: true } } },
        },
        vet: { select: { id: true, firstName: true, lastName: true } },
      },
    });
  },

  async getTodayAppointments(clinicId) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    return prisma.appointment.findMany({
      where: {
        clinicId,
        date: { gte: today, lt: tomorrow },
      },
      orderBy: { startTime: 'asc' },
      include: {
        pet: {
          select: { id: true, name: true, species: true },
          include: { client: { select: { firstName: true, lastName: true, phone: true } } },
        },
        vet: { select: { firstName: true, lastName: true } },
      },
    });
  },
};
