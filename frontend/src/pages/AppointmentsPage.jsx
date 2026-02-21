import { useState, useEffect, useMemo } from 'react';
import { appointmentsAPI, petsAPI } from '../api/endpoints';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlinePlus, HiOutlineChevronLeft, HiOutlineChevronRight, HiOutlineClock, HiOutlineCheck, HiOutlineX } from 'react-icons/hi';
import { format, addDays, startOfWeek, endOfWeek, eachDayOfInterval, isToday, isSameDay, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';

const statusConfig = {
  SCHEDULED: { label: 'Programada', bg: 'bg-blue-100 text-blue-800', icon: HiOutlineClock },
  IN_PROGRESS: { label: 'En progreso', bg: 'bg-yellow-100 text-yellow-800', icon: HiOutlineClock },
  COMPLETED: { label: 'Completada', bg: 'bg-green-100 text-green-800', icon: HiOutlineCheck },
  CANCELLED: { label: 'Cancelada', bg: 'bg-red-100 text-red-800', icon: HiOutlineX },
  NO_SHOW: { label: 'No se presentó', bg: 'bg-gray-100 text-gray-800', icon: HiOutlineX },
};

const emptyForm = { petId: '', dateTime: '', endTime: '', reason: '', notes: '' };

export default function AppointmentsPage() {
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentDate, setCurrentDate] = useState(new Date());
  const [view, setView] = useState('week');
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState(emptyForm);
  const [pets, setPets] = useState([]);
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [detailModal, setDetailModal] = useState(null);

  useEffect(() => { loadAppointments(); }, [currentDate]);
  useEffect(() => { loadPets(); }, []);

  const loadAppointments = async () => {
    try {
      const { data } = await appointmentsAPI.getAll({ limit: 200 });
      setAppointments(data.data || []);
    } catch {
      toast.error('Error al cargar citas');
    } finally {
      setLoading(false);
    }
  };

  const loadPets = async () => {
    try {
      const { data } = await petsAPI.getAll({ limit: 500 });
      setPets(data.data || []);
    } catch { /* ignore */ }
  };

  const weekDays = useMemo(() => {
    const start = startOfWeek(currentDate, { weekStartsOn: 1 });
    const end = endOfWeek(currentDate, { weekStartsOn: 1 });
    return eachDayOfInterval({ start, end });
  }, [currentDate]);

  const appointmentsByDay = useMemo(() => {
    const map = {};
    const filtered = statusFilter === 'ALL' ? appointments : appointments.filter(a => a.status === statusFilter);
    filtered.forEach(apt => {
      const day = format(parseISO(apt.dateTime), 'yyyy-MM-dd');
      if (!map[day]) map[day] = [];
      map[day].push(apt);
    });
    // Sort each day by time
    Object.values(map).forEach(arr => arr.sort((a, b) => new Date(a.dateTime) - new Date(b.dateTime)));
    return map;
  }, [appointments, statusFilter]);

  const navigateWeek = (dir) => setCurrentDate(prev => addDays(prev, dir * 7));

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await appointmentsAPI.create(form);
      toast.success('Cita creada');
      setModalOpen(false);
      setForm(emptyForm);
      loadAppointments();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al crear cita');
    }
  };

  const handleStatusChange = async (id, status) => {
    try {
      await appointmentsAPI.update(id, { status });
      toast.success('Estado actualizado');
      setDetailModal(null);
      loadAppointments();
    } catch {
      toast.error('Error al actualizar');
    }
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Citas</h1>
          <p className="text-gray-500">Agenda de consultas y procedimientos</p>
        </div>
        <button onClick={() => { setForm(emptyForm); setModalOpen(true); }} className="btn-primary flex items-center gap-2">
          <HiOutlinePlus className="w-4 h-4" /> Nueva Cita
        </button>
      </div>

      {/* Status filter chips */}
      <div className="flex gap-2 flex-wrap">
        {['ALL', ...Object.keys(statusConfig)].map(s => (
          <button key={s} onClick={() => setStatusFilter(s)}
            className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${statusFilter === s ? 'bg-vet-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
            {s === 'ALL' ? `Todas (${appointments.length})` : `${statusConfig[s].label} (${appointments.filter(a => a.status === s).length})`}
          </button>
        ))}
      </div>

      {/* Week Navigation */}
      <div className="flex items-center justify-between bg-white rounded-xl shadow-sm border p-4">
        <button onClick={() => navigateWeek(-1)} className="p-2 hover:bg-gray-100 rounded-lg"><HiOutlineChevronLeft className="w-5 h-5" /></button>
        <div className="text-center">
          <p className="font-semibold text-gray-900">{format(weekDays[0], "d MMM", { locale: es })} — {format(weekDays[6], "d MMM yyyy", { locale: es })}</p>
          <button onClick={() => setCurrentDate(new Date())} className="text-sm text-vet-600 hover:text-vet-800">Hoy</button>
        </div>
        <button onClick={() => navigateWeek(1)} className="p-2 hover:bg-gray-100 rounded-lg"><HiOutlineChevronRight className="w-5 h-5" /></button>
      </div>

      {/* Week Grid */}
      <div className="grid grid-cols-7 gap-2">
        {weekDays.map(day => {
          const dayKey = format(day, 'yyyy-MM-dd');
          const dayApts = appointmentsByDay[dayKey] || [];
          return (
            <div key={dayKey} className={`bg-white rounded-xl border min-h-[200px] p-3 ${isToday(day) ? 'ring-2 ring-vet-500 border-vet-300' : ''}`}>
              <div className={`text-center mb-3 ${isToday(day) ? 'text-vet-700 font-bold' : 'text-gray-600'}`}>
                <p className="text-xs uppercase">{format(day, 'EEE', { locale: es })}</p>
                <p className={`text-lg ${isToday(day) ? 'bg-vet-600 text-white rounded-full w-8 h-8 flex items-center justify-center mx-auto' : ''}`}>{format(day, 'd')}</p>
              </div>
              <div className="space-y-1.5">
                {dayApts.map(apt => {
                  const cfg = statusConfig[apt.status] || statusConfig.SCHEDULED;
                  return (
                    <button key={apt.id} onClick={() => setDetailModal(apt)}
                      className={`w-full text-left p-2 rounded-lg text-xs ${cfg.bg} hover:opacity-80 transition-opacity`}>
                      <p className="font-semibold truncate">{format(parseISO(apt.dateTime), 'HH:mm')}</p>
                      <p className="truncate">{apt.pet?.name || 'Mascota'}</p>
                      <p className="truncate opacity-75">{apt.reason}</p>
                    </button>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>

      {/* Today's list */}
      <div className="card">
        <h3 className="font-semibold text-gray-900 mb-4">📋 Citas de Hoy ({(appointmentsByDay[format(new Date(), 'yyyy-MM-dd')] || []).length})</h3>
        {(appointmentsByDay[format(new Date(), 'yyyy-MM-dd')] || []).length > 0 ? (
          <div className="space-y-2">
            {(appointmentsByDay[format(new Date(), 'yyyy-MM-dd')] || []).map(apt => {
              const cfg = statusConfig[apt.status];
              return (
                <div key={apt.id} className="flex items-center gap-4 p-3 rounded-lg border hover:shadow-sm cursor-pointer" onClick={() => setDetailModal(apt)}>
                  <div className="text-center min-w-[60px]">
                    <p className="text-lg font-bold text-vet-600">{format(parseISO(apt.dateTime), 'HH:mm')}</p>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium">{apt.pet?.name} {apt.pet?.client ? `(${apt.pet.client.firstName} ${apt.pet.client.lastName})` : ''}</p>
                    <p className="text-sm text-gray-500 truncate">{apt.reason}</p>
                  </div>
                  <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${cfg.bg}`}>{cfg.label}</span>
                </div>
              );
            })}
          </div>
        ) : (
          <p className="text-center text-gray-400 py-6">No hay citas para hoy</p>
        )}
      </div>

      {/* New Appointment Modal */}
      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Nueva Cita" size="md">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Mascota *</label>
            <select className="input-field" value={form.petId} onChange={e => setForm({ ...form, petId: e.target.value })} required>
              <option value="">Seleccionar mascota</option>
              {pets.map(p => <option key={p.id} value={p.id}>{p.name} ({p.client?.firstName} {p.client?.lastName})</option>)}
            </select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Fecha y Hora *</label><input type="datetime-local" className="input-field" value={form.dateTime} onChange={e => setForm({ ...form, dateTime: e.target.value })} required /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Hora fin</label><input type="datetime-local" className="input-field" value={form.endTime} onChange={e => setForm({ ...form, endTime: e.target.value })} /></div>
          </div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Motivo *</label><input className="input-field" value={form.reason} onChange={e => setForm({ ...form, reason: e.target.value })} required placeholder="Ej: Vacunación, consulta general..." /></div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Notas</label><textarea className="input-field" rows={3} value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })} /></div>
          <div className="flex justify-end gap-3 pt-4 border-t"><button type="button" onClick={() => setModalOpen(false)} className="btn-secondary">Cancelar</button><button type="submit" className="btn-primary">Crear Cita</button></div>
        </form>
      </Modal>

      {/* Detail Modal */}
      <Modal isOpen={!!detailModal} onClose={() => setDetailModal(null)} title="Detalle de Cita" size="md">
        {detailModal && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div><p className="text-sm text-gray-500">Mascota</p><p className="font-medium">{detailModal.pet?.name}</p></div>
              <div><p className="text-sm text-gray-500">Dueño</p><p className="font-medium">{detailModal.pet?.client?.firstName} {detailModal.pet?.client?.lastName}</p></div>
              <div><p className="text-sm text-gray-500">Fecha</p><p className="font-medium">{format(parseISO(detailModal.dateTime), "d MMM yyyy 'a las' HH:mm", { locale: es })}</p></div>
              <div><p className="text-sm text-gray-500">Estado</p><p className={`inline-block px-2.5 py-1 rounded-full text-xs font-medium ${statusConfig[detailModal.status]?.bg}`}>{statusConfig[detailModal.status]?.label}</p></div>
            </div>
            <div><p className="text-sm text-gray-500">Motivo</p><p>{detailModal.reason}</p></div>
            {detailModal.notes && <div><p className="text-sm text-gray-500">Notas</p><p>{detailModal.notes}</p></div>}
            <div className="flex gap-2 pt-4 border-t">
              {detailModal.status === 'SCHEDULED' && (
                <>
                  <button onClick={() => handleStatusChange(detailModal.id, 'IN_PROGRESS')} className="btn-primary flex-1">Iniciar Consulta</button>
                  <button onClick={() => handleStatusChange(detailModal.id, 'CANCELLED')} className="btn-danger flex-1">Cancelar</button>
                </>
              )}
              {detailModal.status === 'IN_PROGRESS' && (
                <button onClick={() => handleStatusChange(detailModal.id, 'COMPLETED')} className="btn-primary flex-1">Marcar Completada</button>
              )}
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
