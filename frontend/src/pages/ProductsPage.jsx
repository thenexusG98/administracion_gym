import { useState, useEffect } from 'react';
import { productsAPI } from '../api/endpoints';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlinePlus, HiOutlinePencil, HiOutlineTrash, HiOutlineExclamation } from 'react-icons/hi';

const emptyForm = { name: '', description: '', barcode: '', category: 'PRODUCTO', price: '', cost: '', stock: '', minStock: '', isService: false, isActive: true };
const categories = ['PRODUCTO', 'MEDICAMENTO', 'ALIMENTO', 'ACCESORIO', 'SERVICIO', 'VACUNA', 'CIRUGÍA', 'LABORATORIO', 'OTRO'];

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [catFilter, setCatFilter] = useState('ALL');

  useEffect(() => { loadProducts(); }, [page, search, catFilter]);

  const loadProducts = async () => {
    try {
      const params = { page, limit: 20, search };
      if (catFilter !== 'ALL') params.category = catFilter;
      const { data } = await productsAPI.getAll(params);
      setProducts(data.data || []);
      setPagination(data.pagination);
    } catch {
      toast.error('Error al cargar productos');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        ...form,
        price: parseFloat(form.price),
        cost: form.cost ? parseFloat(form.cost) : undefined,
        stock: form.isService ? 0 : parseInt(form.stock || '0'),
        minStock: form.isService ? 0 : parseInt(form.minStock || '0'),
      };
      if (editing) {
        await productsAPI.update(editing.id, payload);
        toast.success('Producto actualizado');
      } else {
        await productsAPI.create(payload);
        toast.success('Producto creado');
      }
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
      loadProducts();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al guardar');
    }
  };

  const handleEdit = (product) => {
    setEditing(product);
    setForm({
      name: product.name,
      description: product.description || '',
      barcode: product.barcode || '',
      category: product.category || 'PRODUCTO',
      price: product.price,
      cost: product.cost || '',
      stock: product.stock,
      minStock: product.minStock || '',
      isService: product.isService,
      isActive: product.isActive,
    });
    setModalOpen(true);
  };

  const handleDelete = async (id) => {
    if (!confirm('¿Eliminar este producto?')) return;
    try {
      await productsAPI.delete(id);
      toast.success('Producto eliminado');
      loadProducts();
    } catch {
      toast.error('Error al eliminar');
    }
  };

  const columns = [
    {
      key: 'name', label: 'Producto / Servicio',
      render: (row) => (
        <div>
          <p className="font-medium text-gray-900">{row.name}</p>
          <p className="text-xs text-gray-500">{row.category} {row.barcode ? `• ${row.barcode}` : ''}</p>
        </div>
      ),
    },
    {
      key: 'price', label: 'Precio',
      render: (row) => <span className="font-semibold text-green-700">${parseFloat(row.price).toFixed(2)}</span>,
    },
    {
      key: 'cost', label: 'Costo',
      render: (row) => row.cost ? `$${parseFloat(row.cost).toFixed(2)}` : '-',
    },
    {
      key: 'stock', label: 'Stock',
      render: (row) => {
        if (row.isService) return <span className="badge-blue">Servicio</span>;
        const isLow = row.minStock && row.stock <= row.minStock;
        return (
          <span className={`flex items-center gap-1 ${isLow ? 'text-red-600 font-semibold' : 'text-gray-700'}`}>
            {isLow && <HiOutlineExclamation className="w-4 h-4" />}
            {row.stock} {row.minStock ? `(mín: ${row.minStock})` : ''}
          </span>
        );
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
        <h1 className="text-2xl font-bold text-gray-900">Productos y Servicios</h1>
        <p className="text-gray-500">Catálogo de productos, medicamentos y servicios</p>
      </div>

      {/* Category Filter */}
      <div className="flex gap-2 flex-wrap">
        {['ALL', ...categories].map(c => (
          <button key={c} onClick={() => { setCatFilter(c); setPage(1); }}
            className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${catFilter === c ? 'bg-vet-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
            {c === 'ALL' ? 'Todos' : c.charAt(0) + c.slice(1).toLowerCase()}
          </button>
        ))}
      </div>

      <DataTable
        columns={columns}
        data={products}
        pagination={pagination}
        onPageChange={setPage}
        onSearch={setSearch}
        searchPlaceholder="Buscar por nombre o código..."
        actions={
          <button onClick={() => { setEditing(null); setForm(emptyForm); setModalOpen(true); }} className="btn-primary flex items-center gap-2">
            <HiOutlinePlus className="w-4 h-4" /> Nuevo Producto
          </button>
        }
      />

      {/* Modal */}
      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Editar Producto' : 'Nuevo Producto'} size="lg">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="flex items-center gap-4 mb-2">
            <label className="flex items-center gap-2"><input type="checkbox" checked={form.isService} onChange={e => setForm({ ...form, isService: e.target.checked })} className="rounded border-gray-300 text-vet-600" /><span className="text-sm font-medium text-gray-700">Es un servicio (sin inventario)</span></label>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Nombre *</label><input className="input-field" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Categoría</label><select className="input-field" value={form.category} onChange={e => setForm({ ...form, category: e.target.value })}>{categories.map(c => <option key={c} value={c}>{c.charAt(0) + c.slice(1).toLowerCase()}</option>)}</select></div>
          </div>
          <div><label className="block text-sm font-medium text-gray-700 mb-1">Descripción</label><textarea className="input-field" rows={2} value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} /></div>
          <div className="grid grid-cols-3 gap-4">
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Código / Barcode</label><input className="input-field" value={form.barcode} onChange={e => setForm({ ...form, barcode: e.target.value })} /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Precio venta *</label><input type="number" step="0.01" className="input-field" value={form.price} onChange={e => setForm({ ...form, price: e.target.value })} required /></div>
            <div><label className="block text-sm font-medium text-gray-700 mb-1">Costo</label><input type="number" step="0.01" className="input-field" value={form.cost} onChange={e => setForm({ ...form, cost: e.target.value })} /></div>
          </div>
          {!form.isService && (
            <div className="grid grid-cols-2 gap-4">
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Stock actual</label><input type="number" className="input-field" value={form.stock} onChange={e => setForm({ ...form, stock: e.target.value })} /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Stock mínimo (alerta)</label><input type="number" className="input-field" value={form.minStock} onChange={e => setForm({ ...form, minStock: e.target.value })} /></div>
            </div>
          )}
          <div className="flex items-center gap-2"><input type="checkbox" checked={form.isActive} onChange={e => setForm({ ...form, isActive: e.target.checked })} className="rounded border-gray-300 text-vet-600" /><label className="text-sm text-gray-700">Producto activo</label></div>
          <div className="flex justify-end gap-3 pt-4 border-t">
            <button type="button" onClick={() => setModalOpen(false)} className="btn-secondary">Cancelar</button>
            <button type="submit" className="btn-primary">{editing ? 'Actualizar' : 'Crear'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
