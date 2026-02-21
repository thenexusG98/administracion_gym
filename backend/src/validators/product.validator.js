import { z } from 'zod';

export const createProductSchema = z.object({
  name: z.string().min(1, 'El nombre es requerido'),
  description: z.string().optional().nullable(),
  sku: z.string().optional().nullable(),
  barcode: z.string().optional().nullable(),
  category: z.string().min(1, 'La categoría es requerida'),
  price: z.number().nonnegative('El precio debe ser positivo'),
  cost: z.number().nonnegative().optional(),
  stock: z.number().int().nonnegative().optional(),
  minStock: z.number().int().nonnegative().optional(),
  unit: z.string().optional(),
  isService: z.boolean().optional(),
  expiryDate: z.string().optional().nullable(),
  lot: z.string().optional().nullable(),
});

export const updateProductSchema = createProductSchema.partial();

export const createSaleSchema = z.object({
  clientId: z.string().uuid().optional().nullable(),
  items: z.array(z.object({
    productId: z.string().uuid('ID de producto inválido'),
    quantity: z.number().int().positive('La cantidad debe ser mayor a 0'),
    unitPrice: z.number().nonnegative(),
    discount: z.number().nonnegative().optional(),
  })).min(1, 'Debe incluir al menos un producto'),
  payments: z.array(z.object({
    amount: z.number().positive('El monto debe ser mayor a 0'),
    method: z.enum(['EFECTIVO', 'TARJETA', 'TRANSFERENCIA']),
    reference: z.string().optional().nullable(),
  })).min(1, 'Debe incluir al menos un pago'),
  discount: z.number().nonnegative().optional(),
  tax: z.number().nonnegative().optional(),
  notes: z.string().optional().nullable(),
});

export const inventoryMovementSchema = z.object({
  productId: z.string().uuid('ID de producto inválido'),
  type: z.enum(['ENTRADA', 'SALIDA', 'AJUSTE']),
  quantity: z.number().int().positive('La cantidad debe ser positiva'),
  reason: z.string().optional().nullable(),
  reference: z.string().optional().nullable(),
});
