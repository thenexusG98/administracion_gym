import prisma from '../config/database.js';

export const saleRepository = {
  async findAll(clinicId, { page = 1, limit = 20, startDate, endDate, status } = {}) {
    const where = {
      clinicId,
      ...(status && { status }),
      ...(startDate && endDate && {
        createdAt: {
          gte: new Date(startDate),
          lte: new Date(endDate),
        },
      }),
    };

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      prisma.sale.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          client: { select: { id: true, firstName: true, lastName: true } },
          user: { select: { id: true, firstName: true, lastName: true } },
          items: { include: { product: { select: { id: true, name: true, category: true } } } },
          payments: true,
        },
      }),
      prisma.sale.count({ where }),
    ]);

    return { data, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  },

  async findById(id, clinicId) {
    return prisma.sale.findFirst({
      where: { id, clinicId },
      include: {
        client: true,
        user: { select: { id: true, firstName: true, lastName: true } },
        items: { include: { product: true } },
        payments: true,
      },
    });
  },

  async create(saleData, items, payments, clinicId) {
    return prisma.$transaction(async (tx) => {
      // Generar folio
      const count = await tx.sale.count({ where: { clinicId } });
      const folio = `V-${String(count + 1).padStart(6, '0')}`;

      // Calcular totales
      let subtotal = 0;
      const processedItems = items.map(item => {
        const itemTotal = (item.unitPrice * item.quantity) - (item.discount || 0);
        subtotal += itemTotal;
        return { ...item, total: itemTotal };
      });

      const tax = saleData.tax || 0;
      const discount = saleData.discount || 0;
      const total = subtotal + tax - discount;

      // Crear venta
      const sale = await tx.sale.create({
        data: {
          folio,
          subtotal,
          tax,
          discount,
          total,
          notes: saleData.notes,
          clientId: saleData.clientId,
          userId: saleData.userId,
          clinicId,
          items: {
            create: processedItems.map(item => ({
              productId: item.productId,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              discount: item.discount || 0,
              total: item.total,
            })),
          },
          payments: {
            create: payments.map(p => ({
              amount: p.amount,
              method: p.method,
              reference: p.reference,
            })),
          },
        },
        include: {
          items: { include: { product: true } },
          payments: true,
          client: true,
          user: { select: { firstName: true, lastName: true } },
        },
      });

      // Actualizar stock de productos (no servicios)
      for (const item of items) {
        const product = await tx.product.findUnique({ where: { id: item.productId } });
        if (product && !product.isService) {
          await tx.product.update({
            where: { id: item.productId },
            data: { stock: { decrement: item.quantity } },
          });
          // Registrar movimiento de inventario
          await tx.inventoryMovement.create({
            data: {
              type: 'SALIDA',
              quantity: item.quantity,
              reason: `Venta ${folio}`,
              reference: sale.id,
              productId: item.productId,
              clinicId,
            },
          });
        }
      }

      return sale;
    });
  },

  async cancel(id, clinicId) {
    return prisma.$transaction(async (tx) => {
      const sale = await tx.sale.findFirst({
        where: { id, clinicId },
        include: { items: { include: { product: true } } },
      });

      if (!sale) throw new Error('Venta no encontrada');

      // Devolver stock
      for (const item of sale.items) {
        if (!item.product.isService) {
          await tx.product.update({
            where: { id: item.productId },
            data: { stock: { increment: item.quantity } },
          });
          await tx.inventoryMovement.create({
            data: {
              type: 'ENTRADA',
              quantity: item.quantity,
              reason: `Cancelación venta ${sale.folio}`,
              reference: sale.id,
              productId: item.productId,
              clinicId,
            },
          });
        }
      }

      return tx.sale.update({
        where: { id },
        data: { status: 'CANCELADA' },
      });
    });
  },

  // Corte de caja
  async cashCut(clinicId, startDate, endDate) {
    const sales = await prisma.sale.findMany({
      where: {
        clinicId,
        status: 'COMPLETADA',
        createdAt: { gte: new Date(startDate), lte: new Date(endDate) },
      },
      include: { payments: true },
    });

    const summary = {
      totalSales: sales.length,
      totalAmount: 0,
      byMethod: { EFECTIVO: 0, TARJETA: 0, TRANSFERENCIA: 0 },
    };

    sales.forEach(sale => {
      summary.totalAmount += sale.total;
      sale.payments.forEach(payment => {
        summary.byMethod[payment.method] += payment.amount;
      });
    });

    return summary;
  },
};
