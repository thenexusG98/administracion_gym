import { useState, useEffect } from 'react';
import { inventoryAPI, productsAPI } from '../api/endpoints';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlinePlus, HiOutlineArrowUp, HiOutlineArrowDown } from 'react-icons/hi';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

const movementTypes = { IN: { label: 'Entrada', icon: HiOutlineArrowUp, color: 'text-green-600' }, OUT: { label: 'Salida', icon: HiOutlineArrowDown, color: 'text-red-600' }, ADJUSTMENT: { label: 'Ajuste', icon: HiOutlineArrowUp, color: 'text-yellow-600' }, RETURN: { label: 'Devolución', icon: HiOutlineArrowUp, color: 'text-blue-600' } };
const emptyForm = { productId: '', type: 'IN', quantity: '', reason: '', notes: '' };

export default function InventoryPage() {
  const [movements, setMovements] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState(emptyForm);
  const [products, setProducts] = useState([]);
  const [typeFilter, setTypeFilter] = useState('ALL');

  useEffect(() => { loadMovements(); }, [page, search, typeFilter]);
  useEffect(() => { loadProducts(); }, []);

  const loadMovements = async () => {
    try {
      const params = { page, limit: 20, search };
      if (typeFilter !== 'ALL') params.type = typeFilter;
      const { data } = await inventoryAPI.getMovements(params);
      setMovements(data.data || []);
      setPagination(data.pagination);
    } catch {
      toast.error('Error al cargar movimientos');
    } finally {
      setLoading(false);
    }
  };

  const loadProducts = async () => {
    try {
      const { data } = await productsAPI.getAll({ limit: 500 });
      setProducts((data.data || []).filter(p => !p.isService));
    } catch { /* ignore */ }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await inventoryAPI.createMovement({ ...form, quantity: parseInt(form.quantity) });
      toast.success('Movimiento registrado');
      setModalOpen(false);
      setForm(emptyForm);
      loadMovements();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al registrar');
    }
  };

  const columns = [
    {
      key: 'date', label: 'Fecha',
      render: (row) => format(new Date(row.createdAt), 'd MMM yyyy HH:mm', { locale: es }),
    },
    {
      key: 'type', label: 'Tipo',
      render: (row) => {
        const cfg = movementTypes[row.type] || movementTypes.IN;
        const Icon = cfg.icon;
        return <span className={`flex items-center gap-1 font-medium ${cfg.color}`}><Icon className="w-4 h-4" />{cfg.label}</span>;
      },
    },
    { key: 'product', label: 'Producto', render: (row) => row.product?.name || '-' },
    {
      key: 'quantity', label: 'Cantidad',
      render: (row) => (
        <span className={`font-semibold ${row.type === 'OUT' ? 'text-red-600' : 'text-green-600'}`}>
          {row.type === 'OUT' ? '-' : '+'}{row.quantity}
        </span>
      ),
    },
    { key: 'reason', label: 'Motivo', render: (row) => row.reason || '-' },
    { key: 'user', label: 'Usuario', render: (row) => row.user ? `${row.user.firstName}` : '-' },
  ];

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Inventario</h1>
        <p className="text-gray-500">Movimientos de entrada y salida de productos</p>
      </div>

      {/* Low Stock Alert */}
      {products.filter(p => p.minStock && p.stock <= p.minStock).length > 0 && (
        <div className="bg-red-50 border border-red-200 rounded-xl p-4">
          <h3 className="font-semibold text-red-800 mb-2">⚠️ Productos con stock bajo</h3>
          <div className="flex gap-3 flex-wrap">
            {products.filter(p => p.minStock && p.stock <= p.minStock).map(p => (
              <span key={p.id} className="bg-red-100 text-red-700 px-3 py-1 rounded-full text-sm">{p.name}: <strong>{p.stock}</strong> (mín: {p.minStock})</span>
            ))}
          </div>
        </div>
      )}

      {/* Type Filter */}
      <div className="flex gap-2 flex-wrap">
        {['ALL', ...Object.keys(movementTypes)].map(t => (
          <button key={t} onClick={() => { setTypeFilter(t); setPage(1); }}
            className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${typeFilter === t ? 'bg-vet-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
            {t === 'ALL' ? 'Todos' : movementTypes[t].label}
          </button>
        ))}
      </div>

      <DataTable
        columns={columns}
        data={movements}
        pagination={pagination}
        onPageChange={setPage}
        onSearch={setSearch}
        searchPlaceholder="Buscar por producto..."
        actions={
          <button onClick={() => { setForm(emptyForm); setModalOpen(true); }} className="btn-primary flex items-center gap-2">
            <HiOutlinePlus className="w-4 h-4" /> Nuevo Movimiento
          </button>
        }
      />

      {/* Modal */}
      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Nuevo Movimiento de Inventario" size="md">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Producto *</label>
            <select className="input-field" value={form.productId} onChange={e => setForm({ ...form, productId: e.target.value })} required>
              <option value="">Seleccionar producto</option>
              {products.map(p => <option key={p.id} value={p.id}>{p.name} (Stock: {p.stock})</option>)}
            </select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tipo *</label>
              <select className="input-field" value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>
                {Object.entries(movementTypes).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Cantidad *</label>
              <input type="number" min="1" className="input-field" value={form.quantity} onChange={e => setForm({ ...form, quantity: e.target.value })} required />
            </div>
          </div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Motivo</label><input className="input-field" value={form.reason} onChange={e => setForm({ ...form, reason: e.target.value })} placeholder="Ej: Compra a proveedor, ajuste..." /></div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Notas</label><textarea className="input-field" rows={2} value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })} /></div>
          <div className="flex justify-end gap-3 pt-4 border-t"><button type="button" onClick={() => setModalOpen(false)} className="btn-secondary">Cancelar</button><button type="submit" className="btn-primary">Registrar</button></div>
        </form>
      </Modal>
    </div>
  );
}
