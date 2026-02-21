import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { clientsAPI, petsAPI } from '../api/endpoints';
import LoadingSpinner from '../components/LoadingSpinner';
import Modal from '../components/Modal';
import toast from 'react-hot-toast';
import { HiOutlineArrowLeft, HiOutlinePencil, HiOutlinePlus, HiOutlinePhone, HiOutlineMail, HiOutlineLocationMarker } from 'react-icons/hi';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

const speciesLabels = { DOG: '🐕 Perro', CAT: '🐱 Gato', BIRD: '🐦 Ave', REPTILE: '🦎 Reptil', RODENT: '🐹 Roedor', RABBIT: '🐇 Conejo', OTHER: '🐾 Otro' };
const sexLabels = { MALE: 'Macho', FEMALE: 'Hembra' };
const emptyPetForm = { name: '', species: 'DOG', breed: '', sex: 'MALE', color: '', birthDate: '', weight: '', microchipNumber: '', isNeutered: false, notes: '' };

export default function ClientDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [client, setClient] = useState(null);
  const [loading, setLoading] = useState(true);
  const [petModal, setPetModal] = useState(false);
  const [petForm, setPetForm] = useState(emptyPetForm);
  const [editModal, setEditModal] = useState(false);
  const [editForm, setEditForm] = useState({});

  useEffect(() => { loadClient(); }, [id]);

  const loadClient = async () => {
    try {
      const { data } = await clientsAPI.getById(id);
      setClient(data.data);
    } catch {
      toast.error('Error al cargar cliente');
      navigate('/clients');
    } finally {
      setLoading(false);
    }
  };

  const handleAddPet = async (e) => {
    e.preventDefault();
    try {
      await petsAPI.create({ ...petForm, clientId: id, weight: petForm.weight ? parseFloat(petForm.weight) : undefined });
      toast.success('Mascota registrada');
      setPetModal(false);
      setPetForm(emptyPetForm);
      loadClient();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al registrar mascota');
    }
  };

  const handleEditClient = async (e) => {
    e.preventDefault();
    try {
      await clientsAPI.update(id, editForm);
      toast.success('Cliente actualizado');
      setEditModal(false);
      loadClient();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al actualizar');
    }
  };

  const openEditModal = () => {
    setEditForm({ firstName: client.firstName, lastName: client.lastName, email: client.email || '', phone: client.phone, phone2: client.phone2 || '', address: client.address || '', city: client.city || '', state: client.state || '', zipCode: client.zipCode || '', notes: client.notes || '' });
    setEditModal(true);
  };

  if (loading) return <LoadingSpinner />;
  if (!client) return null;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button onClick={() => navigate('/clients')} className="p-2 hover:bg-gray-100 rounded-lg"><HiOutlineArrowLeft className="w-5 h-5" /></button>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-gray-900">{client.firstName} {client.lastName}</h1>
          <p className="text-gray-500">Cliente desde {format(new Date(client.createdAt), "d 'de' MMMM yyyy", { locale: es })}</p>
        </div>
        <button onClick={openEditModal} className="btn-secondary flex items-center gap-2"><HiOutlinePencil className="w-4 h-4" /> Editar</button>
      </div>

      {/* Info Cards */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Contact Info */}
        <div className="card">
          <h3 className="font-semibold text-gray-900 mb-4">Información de Contacto</h3>
          <div className="space-y-3">
            <div className="flex items-center gap-3"><HiOutlinePhone className="w-5 h-5 text-gray-400" /><span>{client.phone}</span></div>
            {client.phone2 && <div className="flex items-center gap-3"><HiOutlinePhone className="w-5 h-5 text-gray-400" /><span>{client.phone2}</span></div>}
            {client.email && <div className="flex items-center gap-3"><HiOutlineMail className="w-5 h-5 text-gray-400" /><span>{client.email}</span></div>}
            {client.address && <div className="flex items-center gap-3"><HiOutlineLocationMarker className="w-5 h-5 text-gray-400" /><span>{client.address}{client.city ? `, ${client.city}` : ''}{client.state ? `, ${client.state}` : ''} {client.zipCode || ''}</span></div>}
          </div>
          {client.notes && <div className="mt-4 pt-4 border-t"><p className="text-sm text-gray-500"><span className="font-medium">Notas:</span> {client.notes}</p></div>}
        </div>

        {/* Stats */}
        <div className="card col-span-2">
          <div className="flex justify-between items-center mb-4">
            <h3 className="font-semibold text-gray-900">Mascotas ({client.pets?.length || 0})</h3>
            <button onClick={() => { setPetForm(emptyPetForm); setPetModal(true); }} className="btn-primary flex items-center gap-2 text-sm"><HiOutlinePlus className="w-4 h-4" /> Agregar Mascota</button>
          </div>
          {client.pets?.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {client.pets.map(pet => (
                <Link key={pet.id} to={`/pets/${pet.id}`} className="flex items-center gap-4 p-3 rounded-lg border hover:border-vet-300 hover:shadow-sm transition-all">
                  <div className="w-12 h-12 rounded-full bg-vet-50 flex items-center justify-center text-2xl">
                    {pet.species === 'DOG' ? '🐕' : pet.species === 'CAT' ? '🐱' : '🐾'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-gray-900">{pet.name}</p>
                    <p className="text-sm text-gray-500 truncate">{speciesLabels[pet.species]?.split(' ')[1]} {pet.breed ? `• ${pet.breed}` : ''} {pet.sex ? `• ${sexLabels[pet.sex]}` : ''}</p>
                  </div>
                  {pet.weight && <span className="text-sm text-gray-400">{pet.weight} kg</span>}
                </Link>
              ))}
            </div>
          ) : (
            <p className="text-center text-gray-400 py-8">No tiene mascotas registradas</p>
          )}
        </div>
      </div>

      {/* Recent Appointments */}
      {client.pets?.some(p => p.appointments?.length > 0) && (
        <div className="card">
          <h3 className="font-semibold text-gray-900 mb-4">Citas Recientes</h3>
          <div className="space-y-2">
            {client.pets.flatMap(p => (p.appointments || []).map(a => ({ ...a, petName: p.name }))).sort((a, b) => new Date(b.dateTime) - new Date(a.dateTime)).slice(0, 5).map(apt => (
              <div key={apt.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <p className="font-medium">{apt.petName} — {apt.reason}</p>
                  <p className="text-sm text-gray-500">{format(new Date(apt.dateTime), "d MMM yyyy, HH:mm", { locale: es })}</p>
                </div>
                <span className={`badge-${apt.status === 'COMPLETED' ? 'green' : apt.status === 'SCHEDULED' ? 'blue' : apt.status === 'CANCELLED' ? 'red' : 'yellow'}`}>{apt.status}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Add Pet Modal */}
      <Modal isOpen={petModal} onClose={() => setPetModal(false)} title="Registrar Mascota" size="lg">
        <form onSubmit={handleAddPet} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Nombre *</label><input className="input-field" value={petForm.name} onChange={e => setPetForm({ ...petForm, name: e.target.value })} required /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Especie *</label><select className="input-field" value={petForm.species} onChange={e => setPetForm({ ...petForm, species: e.target.value })}>{Object.entries(speciesLabels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}</select></div>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Raza</label><input className="input-field" value={petForm.breed} onChange={e => setPetForm({ ...petForm, breed: e.target.value })} /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Sexo</label><select className="input-field" value={petForm.sex} onChange={e => setPetForm({ ...petForm, sex: e.target.value })}>{Object.entries(sexLabels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}</select></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Color</label><input className="input-field" value={petForm.color} onChange={e => setPetForm({ ...petForm, color: e.target.value })} /></div>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Fecha Nacimiento</label><input type="date" className="input-field" value={petForm.birthDate} onChange={e => setPetForm({ ...petForm, birthDate: e.target.value })} /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Peso (kg)</label><input type="number" step="0.1" className="input-field" value={petForm.weight} onChange={e => setPetForm({ ...petForm, weight: e.target.value })} /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Microchip</label><input className="input-field" value={petForm.microchipNumber} onChange={e => setPetForm({ ...petForm, microchipNumber: e.target.value })} /></div>
          </div>
          <div className="flex items-center gap-2"><input type="checkbox" checked={petForm.isNeutered} onChange={e => setPetForm({ ...petForm, isNeutered: e.target.checked })} className="rounded border-gray-300 text-vet-600" /><label className="text-sm text-gray-700">Esterilizado/a</label></div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Notas</label><textarea className="input-field" rows={2} value={petForm.notes} onChange={e => setPetForm({ ...petForm, notes: e.target.value })} /></div>
          <div className="flex justify-end gap-3 pt-4 border-t"><button type="button" onClick={() => setPetModal(false)} className="btn-secondary">Cancelar</button><button type="submit" className="btn-primary">Registrar Mascota</button></div>
        </form>
      </Modal>

      {/* Edit Client Modal */}
      <Modal isOpen={editModal} onClose={() => setEditModal(false)} title="Editar Cliente" size="lg">
        <form onSubmit={handleEditClient} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Nombre *</label><input className="input-field" value={editForm.firstName} onChange={e => setEditForm({ ...editForm, firstName: e.target.value })} required /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Apellido *</label><input className="input-field" value={editForm.lastName} onChange={e => setEditForm({ ...editForm, lastName: e.target.value })} required /></div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Teléfono *</label><input className="input-field" value={editForm.phone} onChange={e => setEditForm({ ...editForm, phone: e.target.value })} required /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Teléfono 2</label><input className="input-field" value={editForm.phone2} onChange={e => setEditForm({ ...editForm, phone2: e.target.value })} /></div>
          </div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Email</label><input type="email" className="input-field" value={editForm.email} onChange={e => setEditForm({ ...editForm, email: e.target.value })} /></div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Dirección</label><input className="input-field" value={editForm.address} onChange={e => setEditForm({ ...editForm, address: e.target.value })} /></div>
          <div className="grid grid-cols-3 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Ciudad</label><input className="input-field" value={editForm.city} onChange={e => setEditForm({ ...editForm, city: e.target.value })} /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Estado</label><input className="input-field" value={editForm.state} onChange={e => setEditForm({ ...editForm, state: e.target.value })} /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">C.P.</label><input className="input-field" value={editForm.zipCode} onChange={e => setEditForm({ ...editForm, zipCode: e.target.value })} /></div>
          </div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Notas</label><textarea className="input-field" rows={3} value={editForm.notes} onChange={e => setEditForm({ ...editForm, notes: e.target.value })} /></div>
          <div className="flex justify-end gap-3 pt-4 border-t"><button type="button" onClick={() => setEditModal(false)} className="btn-secondary">Cancelar</button><button type="submit" className="btn-primary">Actualizar</button></div>
        </form>
      </Modal>
    </div>
  );
}
