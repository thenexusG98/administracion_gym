import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { medicalRecordsAPI, petsAPI } from '../api/endpoints';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlinePlus, HiOutlineEye, HiOutlineDocumentText } from 'react-icons/hi';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

export default function MedicalRecordsPage() {
  const [records, setRecords] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [modalOpen, setModalOpen] = useState(false);
  const [detailModal, setDetailModal] = useState(null);
  const [pets, setPets] = useState([]);
  const [form, setForm] = useState({ petId: '', symptoms: '', diagnosis: '', treatment: '', weight: '', notes: '', prescriptions: [] });
  const [newPrescription, setNewPrescription] = useState({ medication: '', dosage: '', frequency: '', duration: '', notes: '' });

  useEffect(() => { loadRecords(); }, [page, search]);
  useEffect(() => { loadPets(); }, []);

  const loadRecords = async () => {
    try {
      const { data } = await medicalRecordsAPI.getAll({ page, limit: 20, search });
      setRecords(data.data || []);
      setPagination(data.pagination);
    } catch {
      toast.error('Error al cargar registros');
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

  const addPrescription = () => {
    if (!newPrescription.medication || !newPrescription.dosage) return toast.error('Medicamento y dosis son requeridos');
    setForm({ ...form, prescriptions: [...form.prescriptions, { ...newPrescription }] });
    setNewPrescription({ medication: '', dosage: '', frequency: '', duration: '', notes: '' });
  };

  const removePrescription = (idx) => {
    setForm({ ...form, prescriptions: form.prescriptions.filter((_, i) => i !== idx) });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = { ...form, weight: form.weight ? parseFloat(form.weight) : undefined };
      await medicalRecordsAPI.create(payload);
      toast.success('Registro médico creado');
      setModalOpen(false);
      setForm({ petId: '', symptoms: '', diagnosis: '', treatment: '', weight: '', notes: '', prescriptions: [] });
      loadRecords();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al crear registro');
    }
  };

  const columns = [
    {
      key: 'date', label: 'Fecha',
      render: (row) => format(new Date(row.createdAt), 'd MMM yyyy', { locale: es }),
    },
    {
      key: 'pet', label: 'Mascota',
      render: (row) => (
        <Link to={`/pets/${row.pet?.id}`} className="font-medium text-vet-600 hover:text-vet-800">
          {row.pet?.name || '-'}
        </Link>
      ),
    },
    {
      key: 'client', label: 'Dueño',
      render: (row) => row.pet?.client ? `${row.pet.client.firstName} ${row.pet.client.lastName}` : '-',
    },
    { key: 'diagnosis', label: 'Diagnóstico', render: (row) => row.diagnosis || 'Consulta general' },
    {
      key: 'vet', label: 'Veterinario',
      render: (row) => row.veterinarian ? `Dr. ${row.veterinarian.firstName}` : '-',
    },
    {
      key: 'prescriptions', label: 'Rx',
      render: (row) => row.prescriptions?.length > 0 ? <span className="badge-blue">💊 {row.prescriptions.length}</span> : '-',
    },
    {
      key: 'actions', label: '',
      render: (row) => (
        <button onClick={() => setDetailModal(row)} className="p-1.5 hover:bg-gray-100 rounded-lg">
          <HiOutlineEye className="w-4 h-4 text-gray-500" />
        </button>
      ),
    },
  ];

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Historial Médico</h1>
          <p className="text-gray-500">Consultas, diagnósticos y tratamientos</p>
        </div>
      </div>

      <DataTable
        columns={columns}
        data={records}
        pagination={pagination}
        onPageChange={setPage}
        onSearch={setSearch}
        searchPlaceholder="Buscar por mascota, diagnóstico..."
        actions={
          <button onClick={() => setModalOpen(true)} className="btn-primary flex items-center gap-2">
            <HiOutlinePlus className="w-4 h-4" /> Nueva Consulta
          </button>
        }
      />

      {/* New Record Modal */}
      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Nueva Consulta Médica" size="lg">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Mascota *</label>
              <select className="input-field" value={form.petId} onChange={e => setForm({ ...form, petId: e.target.value })} required>
                <option value="">Seleccionar</option>
                {pets.map(p => <option key={p.id} value={p.id}>{p.name} ({p.client?.firstName} {p.client?.lastName})</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Peso actual (kg)</label>
              <input type="number" step="0.1" className="input-field" value={form.weight} onChange={e => setForm({ ...form, weight: e.target.value })} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Síntomas</label>
            <textarea className="input-field" rows={2} value={form.symptoms} onChange={e => setForm({ ...form, symptoms: e.target.value })} placeholder="Describe los síntomas observados..." />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Diagnóstico</label>
            <input className="input-field" value={form.diagnosis} onChange={e => setForm({ ...form, diagnosis: e.target.value })} placeholder="Diagnóstico" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Tratamiento</label>
            <textarea className="input-field" rows={2} value={form.treatment} onChange={e => setForm({ ...form, treatment: e.target.value })} placeholder="Plan de tratamiento..." />
          </div>

          {/* Prescriptions */}
          <div className="border rounded-lg p-4">
            <h4 className="font-medium text-gray-900 mb-3">💊 Prescripciones</h4>
            {form.prescriptions.length > 0 && (
              <div className="space-y-2 mb-3">
                {form.prescriptions.map((p, i) => (
                  <div key={i} className="flex items-center justify-between bg-blue-50 p-2 rounded-lg text-sm">
                    <span><strong>{p.medication}</strong> — {p.dosage} ({p.frequency || 'N/A'})</span>
                    <button type="button" onClick={() => removePrescription(i)} className="text-red-500 hover:text-red-700 text-xs">✕</button>
                  </div>
                ))}
              </div>
            )}
            <div className="grid grid-cols-5 gap-2">
              <input className="input-field col-span-1" placeholder="Medicamento" value={newPrescription.medication} onChange={e => setNewPrescription({ ...newPrescription, medication: e.target.value })} />
              <input className="input-field" placeholder="Dosis" value={newPrescription.dosage} onChange={e => setNewPrescription({ ...newPrescription, dosage: e.target.value })} />
              <input className="input-field" placeholder="Frecuencia" value={newPrescription.frequency} onChange={e => setNewPrescription({ ...newPrescription, frequency: e.target.value })} />
              <input className="input-field" placeholder="Duración" value={newPrescription.duration} onChange={e => setNewPrescription({ ...newPrescription, duration: e.target.value })} />
              <button type="button" onClick={addPrescription} className="btn-secondary text-sm">+ Agregar</button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Notas internas</label>
            <textarea className="input-field" rows={2} value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })} />
          </div>
          <div className="flex justify-end gap-3 pt-4 border-t">
            <button type="button" onClick={() => setModalOpen(false)} className="btn-secondary">Cancelar</button>
            <button type="submit" className="btn-primary">Guardar Consulta</button>
          </div>
        </form>
      </Modal>

      {/* Detail Modal */}
      <Modal isOpen={!!detailModal} onClose={() => setDetailModal(null)} title="Detalle de Consulta" size="lg">
        {detailModal && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div><p className="text-sm text-gray-500">Mascota</p><p className="font-medium">{detailModal.pet?.name}</p></div>
              <div><p className="text-sm text-gray-500">Fecha</p><p className="font-medium">{format(new Date(detailModal.createdAt), "d 'de' MMMM yyyy HH:mm", { locale: es })}</p></div>
              <div><p className="text-sm text-gray-500">Veterinario</p><p className="font-medium">Dr. {detailModal.veterinarian?.firstName} {detailModal.veterinarian?.lastName}</p></div>
              {detailModal.weight && <div><p className="text-sm text-gray-500">Peso</p><p className="font-medium">{detailModal.weight} kg</p></div>}
            </div>
            {detailModal.symptoms && <div><p className="text-sm text-gray-500 font-medium">Síntomas</p><p className="bg-gray-50 p-3 rounded-lg text-sm">{detailModal.symptoms}</p></div>}
            {detailModal.diagnosis && <div><p className="text-sm text-gray-500 font-medium">Diagnóstico</p><p className="bg-yellow-50 p-3 rounded-lg text-sm font-medium">{detailModal.diagnosis}</p></div>}
            {detailModal.treatment && <div><p className="text-sm text-gray-500 font-medium">Tratamiento</p><p className="bg-green-50 p-3 rounded-lg text-sm">{detailModal.treatment}</p></div>}
            {detailModal.prescriptions?.length > 0 && (
              <div>
                <p className="text-sm text-gray-500 font-medium mb-2">💊 Prescripciones</p>
                <div className="space-y-2">
                  {detailModal.prescriptions.map(p => (
                    <div key={p.id} className="bg-blue-50 p-3 rounded-lg">
                      <p className="font-medium">{p.medication}</p>
                      <p className="text-sm text-gray-600">Dosis: {p.dosage} | Frecuencia: {p.frequency || 'N/A'} | Duración: {p.duration || 'N/A'}</p>
                      {p.notes && <p className="text-sm text-gray-500 mt-1">{p.notes}</p>}
                    </div>
                  ))}
                </div>
              </div>
            )}
            {detailModal.notes && <div><p className="text-sm text-gray-500 font-medium">Notas</p><p className="text-sm">{detailModal.notes}</p></div>}
          </div>
        )}
      </Modal>
    </div>
  );
}
