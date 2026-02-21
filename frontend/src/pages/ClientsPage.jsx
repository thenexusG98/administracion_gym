import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { clientsAPI } from '../api/endpoints';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlinePlus, HiOutlineEye, HiOutlinePencil, HiOutlineTrash } from 'react-icons/hi';

const emptyForm = { firstName: '', lastName: '', email: '', phone: '', phone2: '', address: '', city: '', state: '', zipCode: '', notes: '' };

export default function ClientsPage() {
  const [clients, setClients] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingClient, setEditingClient] = useState(null);
  const [form, setForm] = useState(emptyForm);

  useEffect(() => { loadClients(); }, [page, search]);

  const loadClients = async () => {
    try {
      const { data } = await clientsAPI.getAll({ page, limit: 20, search });
      setClients(data.data);
      setPagination(data.pagination);
    } catch (error) {
      toast.error('Error al cargar clientes');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editingClient) {
        await clientsAPI.update(editingClient.id, form);
        toast.success('Cliente actualizado');
      } else {
        await clientsAPI.create(form);
        toast.success('Cliente creado');
      }
      setModalOpen(false);
      setForm(emptyForm);
      setEditingClient(null);
      loadClients();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al guardar');
    }
  };

  const handleEdit = (client) => {
    setEditingClient(client);
    setForm({
      firstName: client.firstName,
      lastName: client.lastName,
      email: client.email || '',
      phone: client.phone,
      phone2: client.phone2 || '',
      address: client.address || '',
      city: client.city || '',
      state: client.state || '',
      zipCode: client.zipCode || '',
      notes: client.notes || '',
    });
    setModalOpen(true);
  };

  const handleDelete = async (id) => {
    if (!confirm('¿Eliminar este cliente?')) return;
    try {
      await clientsAPI.delete(id);
      toast.success('Cliente eliminado');
      loadClients();
    } catch (error) {
      toast.error('Error al eliminar');
    }
  };

  const columns = [
    {
      key: 'name', label: 'Nombre',
      render: (row) => (
        <Link to={`/clients/${row.id}`} className="font-medium text-vet-600 hover:text-vet-800">
          {row.firstName} {row.lastName}
        </Link>
      ),
    },
    { key: 'phone', label: 'Teléfono' },
    { key: 'email', label: 'Email', render: (row) => row.email || '-' },
    {
      key: 'pets', label: 'Mascotas',
      render: (row) => (
        <span className="badge-blue">{row._count?.pets || row.pets?.length || 0}</span>
      ),
    },
    {
      key: 'actions', label: 'Acciones',
      render: (row) => (
        <div className="flex gap-1">
          <Link to={`/clients/${row.id}`} className="p-1.5 hover:bg-gray-100 rounded-lg">
            <HiOutlineEye className="w-4 h-4 text-gray-500" />
          </Link>
          <button onClick={() => handleEdit(row)} className="p-1.5 hover:bg-gray-100 rounded-lg">
            <HiOutlinePencil className="w-4 h-4 text-blue-500" />
          </button>
          <button onClick={() => handleDelete(row.id)} className="p-1.5 hover:bg-gray-100 rounded-lg">
            <HiOutlineTrash className="w-4 h-4 text-red-500" />
          </button>
        </div>
      ),
    },
  ];

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Clientes</h1>
          <p className="text-gray-500">Gestión de dueños de mascotas</p>
        </div>
      </div>

      <DataTable
        columns={columns}
        data={clients}
        pagination={pagination}
        onPageChange={setPage}
        onSearch={setSearch}
        searchPlaceholder="Buscar por nombre, email o teléfono..."
        actions={
          <button onClick={() => { setEditingClient(null); setForm(emptyForm); setModalOpen(true); }} className="btn-primary flex items-center gap-2">
            <HiOutlinePlus className="w-4 h-4" /> Nuevo Cliente
          </button>
        }
      />

      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editingClient ? 'Editar Cliente' : 'Nuevo Cliente'} size="lg">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nombre *</label>
              <input className="input-field" value={form.firstName} onChange={e => setForm({ ...form, firstName: e.target.value })} required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Apellido *</label>
              <input className="input-field" value={form.lastName} onChange={e => setForm({ ...form, lastName: e.target.value })} required />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Teléfono *</label>
              <input className="input-field" value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Teléfono 2</label>
              <input className="input-field" value={form.phone2} onChange={e => setForm({ ...form, phone2: e.target.value })} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input type="email" className="input-field" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Dirección</label>
            <input className="input-field" value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Ciudad</label>
              <input className="input-field" value={form.city} onChange={e => setForm({ ...form, city: e.target.value })} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Estado</label>
              <input className="input-field" value={form.state} onChange={e => setForm({ ...form, state: e.target.value })} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">C.P.</label>
              <input className="input-field" value={form.zipCode} onChange={e => setForm({ ...form, zipCode: e.target.value })} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Notas internas</label>
            <textarea className="input-field" rows={3} value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })} />
          </div>
          <div className="flex justify-end gap-3 pt-4 border-t">
            <button type="button" onClick={() => setModalOpen(false)} className="btn-secondary">Cancelar</button>
            <button type="submit" className="btn-primary">{editingClient ? 'Actualizar' : 'Crear Cliente'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
