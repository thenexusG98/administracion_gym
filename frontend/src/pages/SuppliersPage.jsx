import { useState, useEffect } from 'react';
import { suppliersAPI } from '../api/endpoints';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlinePlus, HiOutlinePencil, HiOutlineTrash, HiOutlinePhone, HiOutlineMail } from 'react-icons/hi';

const emptyForm = { name: '', contactName: '', email: '', phone: '', address: '', notes: '' };

export default function SuppliersPage() {
  const [suppliers, setSuppliers] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);

  useEffect(() => { loadSuppliers(); }, [page, search]);

  const loadSuppliers = async () => {
    try {
      const { data } = await suppliersAPI.getAll({ page, limit: 20, search });
      setSuppliers(data.data || []);
      setPagination(data.pagination);
    } catch {
      toast.error('Error al cargar proveedores');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editing) {
        await suppliersAPI.update(editing.id, form);
        toast.success('Proveedor actualizado');
      } else {
        await suppliersAPI.create(form);
        toast.success('Proveedor creado');
      }
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
      loadSuppliers();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al guardar');
    }
  };

  const handleEdit = (s) => {
    setEditing(s);
    setForm({ name: s.name, contactName: s.contactName || '', email: s.email || '', phone: s.phone || '', address: s.address || '', notes: s.notes || '' });
    setModalOpen(true);
  };

  const handleDelete = async (id) => {
    if (!confirm('¿Eliminar este proveedor?')) return;
    try {
      await suppliersAPI.delete(id);
      toast.success('Proveedor eliminado');
      loadSuppliers();
    } catch {
      toast.error('Error al eliminar');
    }
  };

  const columns = [
    {
      key: 'name', label: 'Empresa',
      render: (row) => (
        <div>
          <p className="font-medium text-gray-900">{row.name}</p>
          {row.contactName && <p className="text-xs text-gray-500">Contacto: {row.contactName}</p>}
        </div>
      ),
    },
    {
      key: 'phone', label: 'Teléfono',
      render: (row) => row.phone ? <span className="flex items-center gap-1"><HiOutlinePhone className="w-3.5 h-3.5 text-gray-400" />{row.phone}</span> : '-',
    },
    {
      key: 'email', label: 'Email',
      render: (row) => row.email ? <span className="flex items-center gap-1"><HiOutlineMail className="w-3.5 h-3.5 text-gray-400" />{row.email}</span> : '-',
    },
    { key: 'address', label: 'Dirección', render: (row) => row.address || '-' },
    {
      key: 'products', label: 'Productos',
      render: (row) => <span className="badge-blue">{row._count?.products || 0}</span>,
    },
    {
      key: 'actions', label: 'Acciones',
      render: (row) => (
        <div className="flex gap-1">
          <button onClick={() => handleEdit(row)} className="p-1.5 hover:bg-gray-100 rounded-lg"><HiOutlinePencil className="w-4 h-4 text-blue-500" /></button>
          <button onClick={() => handleDelete(row.id)} className="p-1.5 hover:bg-gray-100 rounded-lg"><HiOutlineTrash className="w-4 h-4 text-red-500" /></button>
        </div>
      ),
    },
  ];

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Proveedores</h1>
        <p className="text-gray-500">Gestión de proveedores de productos</p>
      </div>

      <DataTable
        columns={columns}
        data={suppliers}
        pagination={pagination}
        onPageChange={setPage}
        onSearch={setSearch}
        searchPlaceholder="Buscar por nombre, contacto..."
        actions={
          <button onClick={() => { setEditing(null); setForm(emptyForm); setModalOpen(true); }} className="btn-primary flex items-center gap-2">
            <HiOutlinePlus className="w-4 h-4" /> Nuevo Proveedor
          </button>
        }
      />

      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Editar Proveedor' : 'Nuevo Proveedor'} size="md">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Nombre de Empresa *</label><input className="input-field" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required /></div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Nombre de Contacto</label><input className="input-field" value={form.contactName} onChange={e => setForm({ ...form, contactName: e.target.value })} /></div>
          <div className="grid grid-cols-2 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Teléfono</label><input className="input-field" value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Email</label><input type="email" className="input-field" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} /></div>
          </div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Dirección</label><input className="input-field" value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} /></div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Notas</label><textarea className="input-field" rows={2} value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })} /></div>
          <div className="flex justify-end gap-3 pt-4 border-t"><button type="button" onClick={() => setModalOpen(false)} className="btn-secondary">Cancelar</button><button type="submit" className="btn-primary">{editing ? 'Actualizar' : 'Crear'}</button></div>
        </form>
      </Modal>
    </div>
  );
}
