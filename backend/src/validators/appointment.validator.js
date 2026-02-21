import { z } from 'zod';

export const createAppointmentSchema = z.object({
  date: z.string().min(1, 'La fecha es requerida'),
  startTime: z.string().regex(/^\d{2}:\d{2}$/, 'Formato de hora inválido (HH:MM)'),
  endTime: z.string().regex(/^\d{2}:\d{2}$/, 'Formato de hora inválido (HH:MM)').optional().nullable(),
  reason: z.string().min(1, 'El motivo es requerido'),
  petId: z.string().uuid('ID de mascota inválido'),
  vetId: z.string().uuid('ID de veterinario inválido'),
  notes: z.string().optional().nullable(),
});

export const updateAppointmentSchema = z.object({
  date: z.string().optional(),
  startTime: z.string().regex(/^\d{2}:\d{2}$/).optional(),
  endTime: z.string().regex(/^\d{2}:\d{2}$/).optional().nullable(),
  reason: z.string().optional(),
  status: z.enum(['PENDIENTE', 'CONFIRMADA', 'ATENDIDA', 'CANCELADA']).optional(),
  notes: z.string().optional().nullable(),
  vetId: z.string().uuid().optional(),
});
