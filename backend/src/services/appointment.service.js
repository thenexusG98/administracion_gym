import { appointmentRepository } from '../repositories/appointment.repository.js';
import { AppError } from '../middlewares/errorHandler.js';

export const appointmentService = {
  async getAll(clinicId, query) {
    return appointmentRepository.findAll(clinicId, {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 50,
      date: query.date,
      vetId: query.vetId,
      status: query.status,
      startDate: query.startDate,
      endDate: query.endDate,
    });
  },

  async getById(id, clinicId) {
    const appointment = await appointmentRepository.findById(id, clinicId);
    if (!appointment) throw new AppError('Cita no encontrada.', 404);
    return appointment;
  },

  async create(data, clinicId) {
    return appointmentRepository.create({
      ...data,
      clinicId,
      date: new Date(data.date),
    });
  },

  async update(id, clinicId, data) {
    const appointment = await appointmentRepository.findById(id, clinicId);
    if (!appointment) throw new AppError('Cita no encontrada.', 404);

    return appointmentRepository.update(id, {
      ...data,
      ...(data.date && { date: new Date(data.date) }),
    });
  },

  async cancel(id, clinicId) {
    const appointment = await appointmentRepository.findById(id, clinicId);
    if (!appointment) throw new AppError('Cita no encontrada.', 404);
    return appointmentRepository.delete(id);
  },

  async getCalendar(clinicId, startDate, endDate, vetId) {
    return appointmentRepository.getByDateRange(clinicId, startDate, endDate, vetId);
  },

  async getToday(clinicId) {
    return appointmentRepository.getTodayAppointments(clinicId);
  },
};
