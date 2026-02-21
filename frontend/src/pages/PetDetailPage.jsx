import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { petsAPI, medicalRecordsAPI, appointmentsAPI } from '../api/endpoints';
import LoadingSpinner from '../components/LoadingSpinner';
import Modal from '../components/Modal';
import toast from 'react-hot-toast';
import { HiOutlineArrowLeft, HiOutlinePencil, HiOutlineCalendar, HiOutlineClipboardList, HiOutlineScale } from 'react-icons/hi';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

const speciesLabels = { DOG: '🐕 Perro', CAT: '🐱 Gato', BIRD: '🐦 Ave', REPTILE: '🦎 Reptil', RODENT: '🐹 Roedor', RABBIT: '🐇 Conejo', OTHER: '🐾 Otro' };
const sexLabels = { MALE: 'Macho', FEMALE: 'Hembra' };
const statusColors = { SCHEDULED: 'badge-blue', IN_PROGRESS: 'badge-yellow', COMPLETED: 'badge-green', CANCELLED: 'badge-red', NO_SHOW: 'badge-red' };

export default function PetDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [pet, setPet] = useState(null);
  const [records, setRecords] = useState([]);
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editModal, setEditModal] = useState(false);
  const [editForm, setEditForm] = useState({});
  const [tab, setTab] = useState('records');

  useEffect(() => { loadData(); }, [id]);

  const loadData = async () => {
    try {
      const [petRes, recordsRes, aptsRes] = await Promise.all([
        petsAPI.getById(id),
        medicalRecordsAPI.getAll({ petId: id, limit: 50 }).catch(() => ({ data: { data: [] } })),
        appointmentsAPI.getAll({ petId: id, limit: 50 }).catch(() => ({ data: { data: [] } })),
      ]);
      setPet(petRes.data.data);
      setRecords(recordsRes.data.data || []);
      setAppointments(aptsRes.data.data || []);
    } catch {
      toast.error('Error al cargar datos');
      navigate('/pets');
    } finally {
      setLoading(false);
    }
  };

  const getAge = (birthDate) => {
    if (!birthDate) return 'Desconocida';
    const diff = Date.now() - new Date(birthDate).getTime();
    const years = Math.floor(diff / (365.25 * 24 * 60 * 60 * 1000));
    const months = Math.floor((diff % (365.25 * 24 * 60 * 60 * 1000)) / (30.44 * 24 * 60 * 60 * 1000));
    if (years > 0) return `${years} año${years > 1 ? 's' : ''} ${months > 0 ? `y ${months} mes${months > 1 ? 'es' : ''}` : ''}`;
    return `${months} mes${months !== 1 ? 'es' : ''}`;
  };

  const handleEdit = async (e) => {
    e.preventDefault();
    try {
      await petsAPI.update(id, { ...editForm, weight: editForm.weight ? parseFloat(editForm.weight) : undefined });
      toast.success('Mascota actualizada');
      setEditModal(false);
      loadData();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al actualizar');
    }
  };

  const openEditModal = () => {
    setEditForm({
      name: pet.name, species: pet.species, breed: pet.breed || '', sex: pet.sex || 'MALE', color: pet.color || '',
      birthDate: pet.birthDate ? format(new Date(pet.birthDate), 'yyyy-MM-dd') : '', weight: pet.weight || '',
      microchipNumber: pet.microchipNumber || '', isNeutered: pet.isNeutered || false, notes: pet.notes || '',
    });
    setEditModal(true);
  };

  if (loading) return <LoadingSpinner />;
  if (!pet) return null;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button onClick={() => navigate('/pets')} className="p-2 hover:bg-gray-100 rounded-lg"><HiOutlineArrowLeft className="w-5 h-5" /></button>
        <div className="w-16 h-16 rounded-full bg-vet-50 flex items-center justify-center text-3xl">
          {pet.species === 'DOG' ? '🐕' : pet.species === 'CAT' ? '🐱' : '🐾'}
        </div>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-gray-900">{pet.name}</h1>
          <p className="text-gray-500">{speciesLabels[pet.species]} {pet.breed ? `• ${pet.breed}` : ''}</p>
        </div>
        <button onClick={openEditModal} className="btn-secondary flex items-center gap-2"><HiOutlinePencil className="w-4 h-4" /> Editar</button>
      </div>

      {/* Info Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="card text-center">
          <p className="text-sm text-gray-500">Edad</p>
          <p className="text-lg font-semibold">{getAge(pet.birthDate)}</p>
        </div>
        <div className="card text-center">
          <p className="text-sm text-gray-500">Peso</p>
          <p className="text-lg font-semibold">{pet.weight ? `${pet.weight} kg` : '-'}</p>
        </div>
        <div className="card text-center">
          <p className="text-sm text-gray-500">Sexo</p>
          <p className="text-lg font-semibold">{sexLabels[pet.sex] || '-'}</p>
        </div>
        <div className="card text-center">
          <p className="text-sm text-gray-500">Esterilizado</p>
          <p className="text-lg font-semibold">{pet.isNeutered ? '✅ Sí' : '❌ No'}</p>
        </div>
      </div>

      {/* Owner */}
      {pet.client && (
        <div className="card">
          <p className="text-sm text-gray-500 mb-1">Dueño</p>
          <Link to={`/clients/${pet.client.id}`} className="font-medium text-vet-600 hover:text-vet-800">
            {pet.client.firstName} {pet.client.lastName} — {pet.client.phone}
          </Link>
        </div>
      )}

      {/* Tabs */}
      <div className="border-b">
        <nav className="flex gap-6">
          {[
            { id: 'records', label: 'Historial Médico', icon: HiOutlineClipboardList },
            { id: 'appointments', label: 'Citas', icon: HiOutlineCalendar },
            { id: 'weight', label: 'Registro de Peso', icon: HiOutlineScale },
          ].map(t => (
            <button key={t.id} onClick={() => setTab(t.id)}
              className={`flex items-center gap-2 py-3 px-1 border-b-2 text-sm font-medium transition-colors ${tab === t.id ? 'border-vet-600 text-vet-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}>
              <t.icon className="w-4 h-4" /> {t.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      {tab === 'records' && (
        <div className="space-y-4">
          {records.length > 0 ? records.map(r => (
            <div key={r.id} className="card border-l-4 border-l-vet-500">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <p className="font-semibold text-gray-900">{r.diagnosis || 'Consulta general'}</p>
                  <p className="text-sm text-gray-500">{format(new Date(r.createdAt), "d 'de' MMMM yyyy", { locale: es })} — Dr. {r.veterinarian?.firstName} {r.veterinarian?.lastName}</p>
                </div>
                {r.weight && <span className="text-sm text-gray-400">{r.weight} kg</span>}
              </div>
              {r.symptoms && <p className="text-sm"><span className="font-medium">Síntomas:</span> {r.symptoms}</p>}
              {r.treatment && <p className="text-sm"><span className="font-medium">Tratamiento:</span> {r.treatment}</p>}
              {r.prescriptions?.length > 0 && (
                <div className="mt-2 pt-2 border-t">
                  <p className="text-sm font-medium mb-1">Prescripciones:</p>
                  {r.prescriptions.map(p => (
                    <p key={p.id} className="text-sm text-gray-600">💊 {p.medication} — {p.dosage} ({p.frequency})</p>
                  ))}
                </div>
              )}
            </div>
          )) : <p className="text-center text-gray-400 py-8">No hay registros médicos</p>}
        </div>
      )}

      {tab === 'appointments' && (
        <div className="space-y-3">
          {appointments.length > 0 ? appointments.map(a => (
            <div key={a.id} className="card flex items-center justify-between">
              <div>
                <p className="font-medium">{a.reason}</p>
                <p className="text-sm text-gray-500">{format(new Date(a.dateTime), "d MMM yyyy 'a las' HH:mm", { locale: es })}</p>
              </div>
              <span className={statusColors[a.status] || 'badge-gray'}>{a.status}</span>
            </div>
          )) : <p className="text-center text-gray-400 py-8">No hay citas registradas</p>}
        </div>
      )}

      {tab === 'weight' && (
        <div className="card">
          <p className="text-sm text-gray-500 mb-4">Historial de peso basado en registros médicos</p>
          {records.filter(r => r.weight).length > 0 ? (
            <div className="space-y-2">
              {records.filter(r => r.weight).map(r => (
                <div key={r.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <span className="text-sm text-gray-500">{format(new Date(r.createdAt), 'd MMM yyyy', { locale: es })}</span>
                  <span className="font-semibold">{r.weight} kg</span>
                </div>
              ))}
            </div>
          ) : <p className="text-center text-gray-400 py-4">No hay registros de peso</p>}
        </div>
      )}

      {/* Edit Modal */}
      <Modal isOpen={editModal} onClose={() => setEditModal(false)} title="Editar Mascota" size="lg">
        <form onSubmit={handleEdit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Nombre *</label><input className="input-field" value={editForm.name} onChange={e => setEditForm({ ...editForm, name: e.target.value })} required /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Especie</label><select className="input-field" value={editForm.species} onChange={e => setEditForm({ ...editForm, species: e.target.value })}>{Object.entries(speciesLabels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}</select></div>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Raza</label><input className="input-field" value={editForm.breed} onChange={e => setEditForm({ ...editForm, breed: e.target.value })} /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Sexo</label><select className="input-field" value={editForm.sex} onChange={e => setEditForm({ ...editForm, sex: e.target.value })}>{Object.entries(sexLabels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}</select></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Color</label><input className="input-field" value={editForm.color} onChange={e => setEditForm({ ...editForm, color: e.target.value })} /></div>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Nacimiento</label><input type="date" className="input-field" value={editForm.birthDate} onChange={e => setEditForm({ ...editForm, birthDate: e.target.value })} /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Peso (kg)</label><input type="number" step="0.1" className="input-field" value={editForm.weight} onChange={e => setEditForm({ ...editForm, weight: e.target.value })} /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Microchip</label><input className="input-field" value={editForm.microchipNumber} onChange={e => setEditForm({ ...editForm, microchipNumber: e.target.value })} /></div>
          </div>
          <div className="flex items-center gap-2"><input type="checkbox" checked={editForm.isNeutered} onChange={e => setEditForm({ ...editForm, isNeutered: e.target.checked })} className="rounded border-gray-300 text-vet-600" /><label className="text-sm text-gray-700">Esterilizado/a</label></div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Notas</label><textarea className="input-field" rows={2} value={editForm.notes} onChange={e => setEditForm({ ...editForm, notes: e.target.value })} /></div>
          <div className="flex justify-end gap-3 pt-4 border-t"><button type="button" onClick={() => setEditModal(false)} className="btn-secondary">Cancelar</button><button type="submit" className="btn-primary">Actualizar</button></div>
        </form>
      </Modal>
    </div>
  );
}
