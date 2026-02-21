import prisma from '../config/database.js';

export const medicalRecordRepository = {
  async findAll(clinicId, { page = 1, limit = 20, petId, vetId } = {}) {
    const where = {
      clinicId,
      ...(petId && { petId }),
      ...(vetId && { vetId }),
    };

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      prisma.medicalRecord.findMany({
        where,
        skip,
        take: limit,
        orderBy: { consultDate: 'desc' },
        include: {
          pet: { select: { id: true, name: true, species: true },
            include: { client: { select: { firstName: true, lastName: true } } } },
          vet: { select: { id: true, firstName: true, lastName: true } },
          prescriptions: true,
        },
      }),
      prisma.medicalRecord.count({ where }),
    ]);

    return { data, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  },

  async findById(id, clinicId) {
    return prisma.medicalRecord.findFirst({
      where: { id, clinicId },
      include: {
        pet: { include: { client: true } },
        vet: { select: { id: true, firstName: true, lastName: true, licenseNumber: true, digitalSignature: true } },
        prescriptions: true,
        appointment: true,
      },
    });
  },

  async create(data) {
    return prisma.medicalRecord.create({
      data,
      include: {
        pet: { select: { id: true, name: true } },
        vet: { select: { firstName: true, lastName: true } },
        prescriptions: true,
      },
    });
  },

  async createWithPrescriptions(recordData, prescriptions) {
    return prisma.$transaction(async (tx) => {
      const record = await tx.medicalRecord.create({
        data: recordData,
      });

      if (prescriptions && prescriptions.length > 0) {
        await tx.prescription.createMany({
          data: prescriptions.map(p => ({
            ...p,
            medicalRecordId: record.id,
            petId: recordData.petId,
            vetId: recordData.vetId,
            clinicId: recordData.clinicId,
          })),
        });
      }

      // Actualizar peso de la mascota si se proporcionó
      if (recordData.weight) {
        await tx.pet.update({
          where: { id: recordData.petId },
          data: { weight: recordData.weight },
        });
      }

      return tx.medicalRecord.findUnique({
        where: { id: record.id },
        include: {
          prescriptions: true,
          pet: { select: { id: true, name: true } },
          vet: { select: { firstName: true, lastName: true } },
        },
      });
    });
  },

  async update(id, data) {
    return prisma.medicalRecord.update({
      where: { id },
      data,
      include: { prescriptions: true },
    });
  },

  async findByPet(petId, clinicId) {
    return prisma.medicalRecord.findMany({
      where: { petId, clinicId },
      orderBy: { consultDate: 'desc' },
      include: {
        vet: { select: { firstName: true, lastName: true } },
        prescriptions: true,
      },
    });
  },
};
