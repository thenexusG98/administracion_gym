import prisma from '../config/database.js';

export const reportService = {
  async getIncomeReport(clinicId, startDate, endDate) {
    const sales = await prisma.sale.findMany({
      where: {
        clinicId,
        status: 'COMPLETADA',
        createdAt: { gte: new Date(startDate), lte: new Date(endDate) },
      },
      include: {
        items: { include: { product: true } },
        payments: true,
      },
    });

    const totalIncome = sales.reduce((sum, s) => sum + s.total, 0);
    const totalDiscount = sales.reduce((sum, s) => sum + s.discount, 0);

    // Agrupado por día
    const byDay = {};
    sales.forEach(s => {
      const day = s.createdAt.toISOString().split('T')[0];
      byDay[day] = (byDay[day] || 0) + s.total;
    });

    // Agrupado por método de pago
    const byMethod = { EFECTIVO: 0, TARJETA: 0, TRANSFERENCIA: 0 };
    sales.forEach(s => {
      s.payments.forEach(p => {
        byMethod[p.method] += p.amount;
      });
    });

    return {
      totalIncome,
      totalDiscount,
      totalSales: sales.length,
      byDay: Object.entries(byDay).map(([date, total]) => ({ date, total })),
      byMethod,
    };
  },

  async getTopServices(clinicId, startDate, endDate, limit = 10) {
    const items = await prisma.saleItem.findMany({
      where: {
        sale: {
          clinicId,
          status: 'COMPLETADA',
          createdAt: { gte: new Date(startDate), lte: new Date(endDate) },
        },
        product: { isService: true },
      },
      include: { product: true },
    });

    const grouped = {};
    items.forEach(item => {
      if (!grouped[item.productId]) {
        grouped[item.productId] = {
          product: item.product.name,
          totalQuantity: 0,
          totalRevenue: 0,
        };
      }
      grouped[item.productId].totalQuantity += item.quantity;
      grouped[item.productId].totalRevenue += item.total;
    });

    return Object.values(grouped)
      .sort((a, b) => b.totalRevenue - a.totalRevenue)
      .slice(0, limit);
  },

  async getTopProducts(clinicId, startDate, endDate, limit = 10) {
    const items = await prisma.saleItem.findMany({
      where: {
        sale: {
          clinicId,
          status: 'COMPLETADA',
          createdAt: { gte: new Date(startDate), lte: new Date(endDate) },
        },
        product: { isService: false },
      },
      include: { product: true },
    });

    const grouped = {};
    items.forEach(item => {
      if (!grouped[item.productId]) {
        grouped[item.productId] = {
          product: item.product.name,
          totalQuantity: 0,
          totalRevenue: 0,
        };
      }
      grouped[item.productId].totalQuantity += item.quantity;
      grouped[item.productId].totalRevenue += item.total;
    });

    return Object.values(grouped)
      .sort((a, b) => b.totalQuantity - a.totalQuantity)
      .slice(0, limit);
  },

  async getPatientsReport(clinicId, startDate, endDate) {
    const records = await prisma.medicalRecord.findMany({
      where: {
        clinicId,
        consultDate: { gte: new Date(startDate), lte: new Date(endDate) },
      },
      include: {
        pet: { select: { name: true, species: true } },
        vet: { select: { firstName: true, lastName: true } },
      },
    });

    const bySpecies = {};
    const byVet = {};
    records.forEach(r => {
      bySpecies[r.pet.species] = (bySpecies[r.pet.species] || 0) + 1;
      const vetName = `${r.vet.firstName} ${r.vet.lastName}`;
      byVet[vetName] = (byVet[vetName] || 0) + 1;
    });

    return {
      totalConsults: records.length,
      bySpecies,
      byVet,
    };
  },

  async getDashboardStats(clinicId) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);

    const [
      totalClients,
      totalPets,
      todayAppointments,
      monthSales,
      pendingAppointments,
      lowStockProducts,
      activeHospitalizations,
      recentActivity,
    ] = await Promise.all([
      prisma.client.count({ where: { clinicId, active: true } }),
      prisma.pet.count({ where: { clinicId, active: true } }),
      prisma.appointment.count({
        where: { clinicId, date: { gte: today, lt: tomorrow } },
      }),
      prisma.sale.aggregate({
        where: { clinicId, status: 'COMPLETADA', createdAt: { gte: monthStart } },
        _sum: { total: true },
        _count: true,
      }),
      prisma.appointment.count({
        where: { clinicId, status: 'PENDIENTE', date: { gte: today } },
      }),
      prisma.product.findMany({
        where: { clinicId, active: true, isService: false },
      }).then(products => products.filter(p => p.stock <= p.minStock).length),
      prisma.hospitalization.count({
        where: { clinicId, status: 'ACTIVA' },
      }),
      prisma.activityLog.findMany({
        where: { clinicId },
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: { user: { select: { firstName: true, lastName: true } } },
      }),
    ]);

    return {
      totalClients,
      totalPets,
      todayAppointments,
      monthRevenue: monthSales._sum.total || 0,
      monthSalesCount: monthSales._count || 0,
      pendingAppointments,
      lowStockProducts,
      activeHospitalizations,
      recentActivity,
    };
  },
};
