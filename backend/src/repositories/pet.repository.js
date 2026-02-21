import prisma from '../config/database.js';

export const petRepository = {
  async findAll(clinicId, { page = 1, limit = 20, search, clientId } = {}) {
    const where = {
      clinicId,
      active: true,
      ...(clientId && { clientId }),
      ...(search && {
        OR: [
          { name: { contains: search, mode: 'insensitive' } },
          { microchip: { contains: search, mode: 'insensitive' } },
          { client: { firstName: { contains: search, mode: 'insensitive' } } },
          { client: { lastName: { contains: search, mode: 'insensitive' } } },
        ],
      }),
    };

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      prisma.pet.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          client: { select: { id: true, firstName: true, lastName: true, phone: true } },
        },
      }),
      prisma.pet.count({ where }),
    ]);

    return { data, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  },

  async findById(id, clinicId) {
    return prisma.pet.findFirst({
      where: { id, clinicId },
      include: {
        client: true,
        medicalRecords: {
          orderBy: { consultDate: 'desc' },
          take: 20,
          include: {
            vet: { select: { firstName: true, lastName: true } },
            prescriptions: true,
          },
        },
        appointments: {
          orderBy: { date: 'desc' },
          take: 10,
          include: { vet: { select: { firstName: true, lastName: true } } },
        },
        vaccineReminders: {
          orderBy: { dueDate: 'desc' },
        },
        hospitalizations: {
          orderBy: { admitDate: 'desc' },
          take: 5,
        },
      },
    });
  },

  async create(data) {
    return prisma.pet.create({
      data,
      include: {
        client: { select: { id: true, firstName: true, lastName: true } },
      },
    });
  },

  async update(id, clinicId, data) {
    return prisma.pet.update({
      where: { id },
      data,
    });
  },

  async delete(id, clinicId) {
    return prisma.pet.update({
      where: { id },
      data: { active: false },
    });
  },

  // Línea de tiempo médica
  async getTimeline(id, clinicId) {
    const [records, appointments, hospitalizations] = await Promise.all([
      prisma.medicalRecord.findMany({
        where: { petId: id, clinicId },
        orderBy: { consultDate: 'desc' },
        include: {
          vet: { select: { firstName: true, lastName: true } },
          prescriptions: true,
        },
      }),
      prisma.appointment.findMany({
        where: { petId: id, clinicId },
        orderBy: { date: 'desc' },
        include: { vet: { select: { firstName: true, lastName: true } } },
      }),
      prisma.hospitalization.findMany({
        where: { petId: id, clinicId },
        orderBy: { admitDate: 'desc' },
      }),
    ]);

    // Combinar y ordenar por fecha
    const timeline = [
      ...records.map(r => ({ type: 'CONSULTA', date: r.consultDate, data: r })),
      ...appointments.map(a => ({ type: 'CITA', date: a.date, data: a })),
      ...hospitalizations.map(h => ({ type: 'HOSPITALIZACION', date: h.admitDate, data: h })),
    ].sort((a, b) => new Date(b.date) - new Date(a.date));

    return timeline;
  },
};
