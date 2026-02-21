import { useState, useEffect } from 'react';
import { usersAPI } from '../api/endpoints';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlinePlus, HiOutlinePencil, HiOutlineTrash, HiOutlineShieldCheck } from 'react-icons/hi';

const roleLabels = { ADMIN: { label: 'Administrador', css: 'badge-red' }, VETERINARIO: { label: 'Veterinario', css: 'badge-green' }, RECEPCION: { label: 'Recepción', css: 'badge-blue' }, CAJA: { label: 'Cajero', css: 'badge-yellow' } };
const emptyForm = { firstName: '', lastName: '', email: '', phone: '', password: '', role: 'RECEPCION' };

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);

  useEffect(() => { loadUsers(); }, [page, search]);

  const loadUsers = async () => {
    try {
      const { data } = await usersAPI.getAll({ page, limit: 20, search });
      setUsers(data.data || []);
      setPagination(data.pagination);
    } catch {
      toast.error('Error al cargar usuarios');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editing) {
        const payload = { ...form };
        if (!payload.password) delete payload.password;
        await usersAPI.update(editing.id, payload);
        toast.success('Usuario actualizado');
      } else {
        await usersAPI.create(form);
        toast.success('Usuario creado');
      }
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
      loadUsers();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al guardar');
    }
  };

  const handleEdit = (user) => {
    setEditing(user);
    setForm({ firstName: user.firstName, lastName: user.lastName, email: user.email, phone: user.phone || '', password: '', role: user.role });
    setModalOpen(true);
  };

  const handleDelete = async (id) => {
    if (!confirm('¿Eliminar este usuario?')) return;
    try {
      await usersAPI.delete(id);
      toast.success('Usuario eliminado');
      loadUsers();
    } catch {
      toast.error('Error al eliminar');
    }
  };

  const columns = [
    {
      key: 'name', label: 'Nombre',
      render: (row) => (
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-vet-100 flex items-center justify-center font-bold text-vet-700">
            {row.firstName?.[0]}{row.lastName?.[0]}
          </div>
          <div>
            <p className="font-medium text-gray-900">{row.firstName} {row.lastName}</p>
            <p className="text-xs text-gray-500">{row.email}</p>
          </div>
        </div>
      ),
    },
    { key: 'phone', label: 'Teléfono', render: (row) => row.phone || '-' },
    {
      key: 'role', label: 'Rol',
      render: (row) => {
        const cfg = roleLabels[row.role] || { label: row.role, css: 'badge-gray' };
        return <span className={`${cfg.css} flex items-center gap-1 w-fit`}><HiOutlineShieldCheck className="w-3.5 h-3.5" />{cfg.label}</span>;
      },
    },
    {
      key: 'status', label: 'Estado',
      render: (row) => <span className={row.isActive ? 'badge-green' : 'badge-red'}>{row.isActive ? 'Activo' : 'Inactivo'}</span>,
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
        <h1 className="text-2xl font-bold text-gray-900">Usuarios</h1>
        <p className="text-gray-500">Gestión de usuarios y roles del sistema</p>
      </div>

      <DataTable
        columns={columns}
        data={users}
        pagination={pagination}
        onPageChange={setPage}
        onSearch={setSearch}
        searchPlaceholder="Buscar por nombre o email..."
        actions={
          <button onClick={() => { setEditing(null); setForm(emptyForm); setModalOpen(true); }} className="btn-primary flex items-center gap-2">
            <HiOutlinePlus className="w-4 h-4" /> Nuevo Usuario
          </button>
        }
      />

      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Editar Usuario' : 'Nuevo Usuario'} size="md">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Nombre *</label><input className="input-field" value={form.firstName} onChange={e => setForm({ ...form, firstName: e.target.value })} required /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Apellido *</label><input className="input-field" value={form.lastName} onChange={e => setForm({ ...form, lastName: e.target.value })} required /></div>
          </div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Email *</label><input type="email" className="input-field" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} required /></div>
          <div className="grid grid-cols-2 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Teléfono</label><input className="input-field" value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} /></div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Rol *</label>
              <select className="input-field" value={form.role} onChange={e => setForm({ ...form, role: e.target.value })}>
                {Object.entries(roleLabels).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
              </select>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">{editing ? 'Nueva Contraseña (dejar vacío para no cambiar)' : 'Contraseña *'}</label>
            <input type="password" className="input-field" value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} required={!editing} minLength={6} />
          </div>
          <div className="flex justify-end gap-3 pt-4 border-t"><button type="button" onClick={() => setModalOpen(false)} className="btn-secondary">Cancelar</button><button type="submit" className="btn-primary">{editing ? 'Actualizar' : 'Crear Usuario'}</button></div>
        </form>
      </Modal>
    </div>
  );
}
