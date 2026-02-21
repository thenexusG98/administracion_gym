import { z } from 'zod';

export const createMedicalRecordSchema = z.object({
  reason: z.string().min(1, 'El motivo de consulta es requerido'),
  symptoms: z.string().optional().nullable(),
  diagnosis: z.string().optional().nullable(),
  treatment: z.string().optional().nullable(),
  observations: z.string().optional().nullable(),
  weight: z.number().positive().optional().nullable(),
  temperature: z.number().positive().optional().nullable(),
  heartRate: z.number().int().positive().optional().nullable(),
  respiratoryRate: z.number().int().positive().optional().nullable(),
  evolution: z.string().optional().nullable(),
  petId: z.string().uuid('ID de mascota inválido'),
  appointmentId: z.string().uuid().optional().nullable(),
  prescriptions: z.array(z.object({
    medication: z.string().min(1),
    dosage: z.string().min(1),
    frequency: z.string().min(1),
    duration: z.string().min(1),
    instructions: z.string().optional().nullable(),
  })).optional(),
});

export const updateMedicalRecordSchema = createMedicalRecordSchema
  .partial()
  .omit({ petId: true });
