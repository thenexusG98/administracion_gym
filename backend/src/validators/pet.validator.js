import { z } from 'zod';

export const createPetSchema = z.object({
  name: z.string().min(1, 'El nombre es requerido'),
  species: z.enum(['PERRO', 'GATO', 'AVE', 'REPTIL', 'ROEDOR', 'OTRO']),
  breed: z.string().optional().nullable(),
  sex: z.enum(['MACHO', 'HEMBRA']),
  weight: z.number().positive().optional().nullable(),
  birthDate: z.string().optional().nullable(),
  color: z.string().optional().nullable(),
  microchip: z.string().optional().nullable(),
  allergies: z.string().optional().nullable(),
  notes: z.string().optional().nullable(),
  clientId: z.string().uuid('ID de cliente inválido'),
});

export const updatePetSchema = createPetSchema.partial().omit({ clientId: true });
