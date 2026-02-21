import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Crear clínica principal
  const clinic = await prisma.clinic.create({
    data: {
      name: 'VetClinic Centro',
      slug: 'vetclinic-centro',
      address: 'Av. Principal #123, Col. Centro',
      phone: '555-0100',
      email: 'contacto@vetclinic-centro.com',
      rfc: 'VCC230101ABC',
    },
  });

  // Crear segunda clínica (demo multi-tenant)
  const clinic2 = await prisma.clinic.create({
    data: {
      name: 'VetClinic Norte',
      slug: 'vetclinic-norte',
      address: 'Blvd. Norte #456, Col. Industrial',
      phone: '555-0200',
      email: 'contacto@vetclinic-norte.com',
    },
  });

  const hashedPassword = await bcrypt.hash('admin123', 12);

  // Usuarios clínica 1
  const admin = await prisma.user.create({
    data: {
      email: 'admin@vetclinic.com',
      password: hashedPassword,
      firstName: 'Carlos',
      lastName: 'Administrador',
      phone: '555-0001',
      role: 'ADMIN',
      clinicId: clinic.id,
    },
  });

  const vet1 = await prisma.user.create({
    data: {
      email: 'dra.garcia@vetclinic.com',
      password: hashedPassword,
      firstName: 'María',
      lastName: 'García López',
      phone: '555-0002',
      role: 'VETERINARIO',
      licenseNumber: 'CEDVET-2024-001',
      clinicId: clinic.id,
    },
  });

  const vet2 = await prisma.user.create({
    data: {
      email: 'dr.martinez@vetclinic.com',
      password: hashedPassword,
      firstName: 'Roberto',
      lastName: 'Martínez Sánchez',
      phone: '555-0003',
      role: 'VETERINARIO',
      licenseNumber: 'CEDVET-2024-002',
      clinicId: clinic.id,
    },
  });

  const receptionist = await prisma.user.create({
    data: {
      email: 'recepcion@vetclinic.com',
      password: hashedPassword,
      firstName: 'Laura',
      lastName: 'Hernández',
      phone: '555-0004',
      role: 'RECEPCION',
      clinicId: clinic.id,
    },
  });

  const cashier = await prisma.user.create({
    data: {
      email: 'caja@vetclinic.com',
      password: hashedPassword,
      firstName: 'Pedro',
      lastName: 'Ramírez',
      phone: '555-0005',
      role: 'CAJA',
      clinicId: clinic.id,
    },
  });

  // Clientes
  const client1 = await prisma.client.create({
    data: {
      firstName: 'Juan',
      lastName: 'Pérez Gómez',
      email: 'juan.perez@email.com',
      phone: '555-1001',
      address: 'Calle Robles #45, Col. Jardines',
      city: 'Ciudad de México',
      state: 'CDMX',
      zipCode: '01000',
      clinicId: clinic.id,
    },
  });

  const client2 = await prisma.client.create({
    data: {
      firstName: 'Ana',
      lastName: 'López Rivera',
      email: 'ana.lopez@email.com',
      phone: '555-1002',
      phone2: '555-1003',
      address: 'Av. Insurgentes #890',
      city: 'Ciudad de México',
      state: 'CDMX',
      notes: 'Clienta frecuente, preferencia por horarios matutinos',
      clinicId: clinic.id,
    },
  });

  const client3 = await prisma.client.create({
    data: {
      firstName: 'Miguel',
      lastName: 'Torres Vargas',
      email: 'miguel.torres@email.com',
      phone: '555-1004',
      address: 'Privada Cedros #12',
      clinicId: clinic.id,
    },
  });

  // Mascotas
  const pet1 = await prisma.pet.create({
    data: {
      name: 'Max',
      species: 'PERRO',
      breed: 'Golden Retriever',
      sex: 'MACHO',
      weight: 32.5,
      birthDate: new Date('2020-03-15'),
      color: 'Dorado',
      microchip: 'MC-2020-001',
      clientId: client1.id,
      clinicId: clinic.id,
    },
  });

  const pet2 = await prisma.pet.create({
    data: {
      name: 'Luna',
      species: 'GATO',
      breed: 'Siamés',
      sex: 'HEMBRA',
      weight: 4.2,
      birthDate: new Date('2021-07-20'),
      color: 'Crema con puntas oscuras',
      allergies: 'Alergia al pollo',
      clientId: client1.id,
      clinicId: clinic.id,
    },
  });

  const pet3 = await prisma.pet.create({
    data: {
      name: 'Rocky',
      species: 'PERRO',
      breed: 'Bulldog Francés',
      sex: 'MACHO',
      weight: 12.8,
      birthDate: new Date('2022-01-10'),
      color: 'Atigrado',
      microchip: 'MC-2022-003',
      clientId: client2.id,
      clinicId: clinic.id,
    },
  });

  const pet4 = await prisma.pet.create({
    data: {
      name: 'Mia',
      species: 'GATO',
      breed: 'Persa',
      sex: 'HEMBRA',
      weight: 3.8,
      birthDate: new Date('2023-05-01'),
      color: 'Blanco',
      clientId: client2.id,
      clinicId: clinic.id,
    },
  });

  const pet5 = await prisma.pet.create({
    data: {
      name: 'Thor',
      species: 'PERRO',
      breed: 'Pastor Alemán',
      sex: 'MACHO',
      weight: 38.0,
      birthDate: new Date('2019-11-22'),
      color: 'Negro y fuego',
      microchip: 'MC-2019-005',
      clientId: client3.id,
      clinicId: clinic.id,
    },
  });

  // Productos y Servicios
  const products = await Promise.all([
    prisma.product.create({
      data: { name: 'Consulta General', category: 'SERVICIO', price: 500, isService: true, clinicId: clinic.id },
    }),
    prisma.product.create({
      data: { name: 'Vacuna Séxtuple', category: 'SERVICIO', price: 750, cost: 200, isService: true, clinicId: clinic.id },
    }),
    prisma.product.create({
      data: { name: 'Vacuna Antirrábica', category: 'SERVICIO', price: 400, cost: 100, isService: true, clinicId: clinic.id },
    }),
    prisma.product.create({
      data: { name: 'Cirugía - Esterilización', category: 'SERVICIO', price: 3500, isService: true, clinicId: clinic.id },
    }),
    prisma.product.create({
      data: { name: 'Desparasitante Oral', category: 'MEDICAMENTO', price: 180, cost: 60, stock: 50, minStock: 10, clinicId: clinic.id },
    }),
    prisma.product.create({
      data: { name: 'Antibiótico Amoxicilina 250mg', category: 'MEDICAMENTO', price: 320, cost: 120, stock: 30, minStock: 10, lot: 'LOT-2025-A1', expiryDate: new Date('2026-06-30'), clinicId: clinic.id },
    }),
    prisma.product.create({
      data: { name: 'Croquetas Premium 10kg', category: 'ALIMENTO', price: 890, cost: 550, stock: 15, minStock: 5, clinicId: clinic.id },
    }),
    prisma.product.create({
      data: { name: 'Collar Antipulgas', category: 'ACCESORIO', price: 250, cost: 80, stock: 20, minStock: 5, clinicId: clinic.id },
    }),
    prisma.product.create({
      data: { name: 'Shampoo Medicado 500ml', category: 'ACCESORIO', price: 350, cost: 150, stock: 12, minStock: 3, clinicId: clinic.id },
    }),
    prisma.product.create({
      data: { name: 'Radiografía', category: 'SERVICIO', price: 800, isService: true, clinicId: clinic.id },
    }),
  ]);

  // Proveedores
  const supplier1 = await prisma.supplier.create({
    data: {
      name: 'Distribuidora Veterinaria Nacional',
      contactName: 'Fernando Ruiz',
      email: 'ventas@distvetnacional.com',
      phone: '555-8001',
      address: 'Zona Industrial #567',
      clinicId: clinic.id,
    },
  });

  const supplier2 = await prisma.supplier.create({
    data: {
      name: 'MediPet Laboratorios',
      contactName: 'Sandra Mora',
      email: 'contacto@medipet.com',
      phone: '555-8002',
      clinicId: clinic.id,
    },
  });

  // Citas
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  await prisma.appointment.createMany({
    data: [
      {
        date: today,
        startTime: '09:00',
        endTime: '09:30',
        reason: 'Consulta general - revisión anual',
        status: 'CONFIRMADA',
        petId: pet1.id,
        vetId: vet1.id,
        clinicId: clinic.id,
      },
      {
        date: today,
        startTime: '10:00',
        endTime: '10:30',
        reason: 'Vacunación - Refuerzo séxtuple',
        status: 'PENDIENTE',
        petId: pet3.id,
        vetId: vet1.id,
        clinicId: clinic.id,
      },
      {
        date: today,
        startTime: '11:00',
        endTime: '11:30',
        reason: 'Problemas digestivos',
        status: 'PENDIENTE',
        petId: pet2.id,
        vetId: vet2.id,
        clinicId: clinic.id,
      },
      {
        date: tomorrow,
        startTime: '09:30',
        endTime: '10:00',
        reason: 'Control post-operatorio',
        status: 'PENDIENTE',
        petId: pet5.id,
        vetId: vet2.id,
        clinicId: clinic.id,
      },
      {
        date: tomorrow,
        startTime: '12:00',
        endTime: '12:30',
        reason: 'Revisión dental',
        status: 'CONFIRMADA',
        petId: pet4.id,
        vetId: vet1.id,
        clinicId: clinic.id,
      },
    ],
  });

  // Expedientes médicos
  const record1 = await prisma.medicalRecord.create({
    data: {
      reason: 'Revisión anual de rutina',
      symptoms: 'Sin síntomas aparentes',
      diagnosis: 'Paciente sano, peso adecuado para la raza',
      treatment: 'Se aplicó vacuna séxtuple. Desparasitación interna.',
      weight: 32.5,
      temperature: 38.5,
      heartRate: 80,
      respiratoryRate: 20,
      observations: 'Buen estado general. Pelaje brillante.',
      petId: pet1.id,
      vetId: vet1.id,
      clinicId: clinic.id,
    },
  });

  await prisma.prescription.create({
    data: {
      medication: 'Desparasitante Oral',
      dosage: '1 tableta',
      frequency: 'Dosis única',
      duration: '1 día',
      instructions: 'Administrar con alimento. Repetir en 15 días.',
      medicalRecordId: record1.id,
      petId: pet1.id,
      vetId: vet1.id,
      clinicId: clinic.id,
    },
  });

  const record2 = await prisma.medicalRecord.create({
    data: {
      reason: 'Vómitos y diarrea',
      symptoms: 'Vómitos frecuentes por 2 días, diarrea acuosa, decaimiento',
      diagnosis: 'Gastroenteritis aguda',
      treatment: 'Hidratación subcutánea, antieméticos, dieta blanda',
      weight: 4.0,
      temperature: 39.2,
      heartRate: 140,
      respiratoryRate: 30,
      evolution: 'Mejoría después del tratamiento. Se programa revisión en 3 días.',
      petId: pet2.id,
      vetId: vet2.id,
      clinicId: clinic.id,
    },
  });

  await prisma.prescription.createMany({
    data: [
      {
        medication: 'Metoclopramida',
        dosage: '0.5ml',
        frequency: 'Cada 8 horas',
        duration: '3 días',
        instructions: 'Administrar vía oral con jeringa. No mezclar con alimento.',
        medicalRecordId: record2.id,
        petId: pet2.id,
        vetId: vet2.id,
        clinicId: clinic.id,
      },
      {
        medication: 'Probióticos',
        dosage: '1 sobre',
        frequency: 'Cada 12 horas',
        duration: '7 días',
        instructions: 'Mezclar con agua o alimento húmedo.',
        medicalRecordId: record2.id,
        petId: pet2.id,
        vetId: vet2.id,
        clinicId: clinic.id,
      },
    ],
  });

  // Ventas de ejemplo
  const sale1 = await prisma.sale.create({
    data: {
      folio: 'V-000001',
      subtotal: 1430,
      tax: 0,
      discount: 0,
      total: 1430,
      status: 'COMPLETADA',
      clientId: client1.id,
      userId: cashier.id,
      clinicId: clinic.id,
      items: {
        create: [
          { productId: products[0].id, quantity: 1, unitPrice: 500, total: 500 },
          { productId: products[1].id, quantity: 1, unitPrice: 750, total: 750 },
          { productId: products[4].id, quantity: 1, unitPrice: 180, total: 180 },
        ],
      },
      payments: {
        create: [
          { amount: 1430, method: 'EFECTIVO' },
        ],
      },
    },
  });

  const sale2 = await prisma.sale.create({
    data: {
      folio: 'V-000002',
      subtotal: 1390,
      tax: 0,
      discount: 100,
      total: 1290,
      status: 'COMPLETADA',
      clientId: client2.id,
      userId: cashier.id,
      clinicId: clinic.id,
      items: {
        create: [
          { productId: products[0].id, quantity: 1, unitPrice: 500, total: 500 },
          { productId: products[6].id, quantity: 1, unitPrice: 890, total: 890 },
        ],
      },
      payments: {
        create: [
          { amount: 1000, method: 'TARJETA', reference: 'VISA ****1234' },
          { amount: 290, method: 'EFECTIVO' },
        ],
      },
    },
  });

  // Recordatorios de vacunas
  const nextMonth = new Date();
  nextMonth.setMonth(nextMonth.getMonth() + 1);

  await prisma.vaccineReminder.createMany({
    data: [
      {
        vaccineName: 'Refuerzo Séxtuple',
        dueDate: nextMonth,
        petId: pet1.id,
        clinicId: clinic.id,
      },
      {
        vaccineName: 'Antirrábica Anual',
        dueDate: nextMonth,
        petId: pet3.id,
        clinicId: clinic.id,
      },
      {
        vaccineName: 'Triple Felina',
        dueDate: nextMonth,
        petId: pet2.id,
        clinicId: clinic.id,
      },
    ],
  });

  console.log('✅ Seed completado exitosamente');
  console.log('');
  console.log('📋 Credenciales de acceso:');
  console.log('  Admin:        admin@vetclinic.com / admin123');
  console.log('  Veterinario:  dra.garcia@vetclinic.com / admin123');
  console.log('  Veterinario:  dr.martinez@vetclinic.com / admin123');
  console.log('  Recepción:    recepcion@vetclinic.com / admin123');
  console.log('  Caja:         caja@vetclinic.com / admin123');
  console.log('');
  console.log('🏥 Clínicas:');
  console.log('  - VetClinic Centro (slug: vetclinic-centro)');
  console.log('  - VetClinic Norte (slug: vetclinic-norte)');
}

main()
  .catch((e) => {
    console.error('❌ Error en seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
