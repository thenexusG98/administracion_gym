import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { salesAPI } from '../api/endpoints';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlinePlus, HiOutlineEye, HiOutlineCash, HiOutlineX } from 'react-icons/hi';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

const statusConfig = { COMPLETED: { label: 'Completada', css: 'badge-green' }, PENDING: { label: 'Pendiente', css: 'badge-yellow' }, CANCELLED: { label: 'Cancelada', css: 'badge-red' } };
const paymentLabels = { CASH: 'Efectivo', CARD: 'Tarjeta', TRANSFER: 'Transferencia', OTHER: 'Otro' };

export default function SalesPage() {
  const [sales, setSales] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [detailModal, setDetailModal] = useState(null);
  const [cashCutModal, setCashCutModal] = useState(false);
  const [cashCut, setCashCut] = useState(null);

  useEffect(() => { loadSales(); }, [page, search]);

  const loadSales = async () => {
    try {
      const { data } = await salesAPI.getAll({ page, limit: 20, search });
      setSales(data.data || []);
      setPagination(data.pagination);
    } catch {
      toast.error('Error al cargar ventas');
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = async (id) => {
    if (!confirm('¿Cancelar esta venta? Se devolverá el stock.')) return;
    try {
      await salesAPI.cancel(id);
      toast.success('Venta cancelada');
      loadSales();
      setDetailModal(null);
    } catch {
      toast.error('Error al cancelar');
    }
  };

  const handleCashCut = async () => {
    try {
      const { data } = await salesAPI.cashCut();
      setCashCut(data.data);
      setCashCutModal(true);
    } catch {
      toast.error('Error al generar corte de caja');
    }
  };

  const columns = [
    {
      key: 'folio', label: 'Folio',
      render: (row) => <span className="font-mono text-sm font-medium">#{row.folio || row.id?.slice(0, 8)}</span>,
    },
    {
      key: 'date', label: 'Fecha',
      render: (row) => format(new Date(row.createdAt), 'd MMM yyyy HH:mm', { locale: es }),
    },
    {
      key: 'client', label: 'Cliente',
      render: (row) => row.client ? (
        <Link to={`/clients/${row.client.id}`} className="text-vet-600 hover:text-vet-800">{row.client.firstName} {row.client.lastName}</Link>
      ) : 'Público General',
    },
    {
      key: 'items', label: 'Artículos',
      render: (row) => <span className="badge-blue">{row.items?.length || row._count?.items || 0}</span>,
    },
    {
      key: 'total', label: 'Total',
      render: (row) => <span className="font-semibold text-green-700">${parseFloat(row.total).toFixed(2)}</span>,
    },
    {
      key: 'payment', label: 'Pago',
      render: (row) => {
        const payment = row.payments?.[0];
        return payment ? paymentLabels[payment.method] || payment.method : '-';
      },
    },
    {
      key: 'status', label: 'Estado',
      render: (row) => {
        const cfg = statusConfig[row.status] || statusConfig.COMPLETED;
        return <span className={cfg.css}>{cfg.label}</span>;
      },
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
          <h1 className="text-2xl font-bold text-gray-900">Ventas</h1>
          <p className="text-gray-500">Historial de ventas y cobros</p>
        </div>
        <div className="flex gap-3">
          <button onClick={handleCashCut} className="btn-secondary flex items-center gap-2"><HiOutlineCash className="w-4 h-4" /> Corte de Caja</button>
          <Link to="/sales/new" className="btn-primary flex items-center gap-2"><HiOutlinePlus className="w-4 h-4" /> Nueva Venta</Link>
        </div>
      </div>

      <DataTable columns={columns} data={sales} pagination={pagination} onPageChange={setPage} onSearch={setSearch} searchPlaceholder="Buscar por folio o cliente..." />

      {/* Detail Modal */}
      <Modal isOpen={!!detailModal} onClose={() => setDetailModal(null)} title={`Venta #${detailModal?.folio || detailModal?.id?.slice(0, 8) || ''}`} size="lg">
        {detailModal && (
          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-4">
              <div><p className="text-sm text-gray-500">Fecha</p><p className="font-medium">{format(new Date(detailModal.createdAt), "d MMM yyyy HH:mm", { locale: es })}</p></div>
              <div><p className="text-sm text-gray-500">Cliente</p><p className="font-medium">{detailModal.client ? `${detailModal.client.firstName} ${detailModal.client.lastName}` : 'Público General'}</p></div>
              <div><p className="text-sm text-gray-500">Estado</p><span className={statusConfig[detailModal.status]?.css}>{statusConfig[detailModal.status]?.label}</span></div>
            </div>

            {/* Items */}
            <div>
              <p className="text-sm font-medium text-gray-700 mb-2">Artículos</p>
              <table className="w-full text-sm">
                <thead><tr className="border-b"><th className="text-left py-2">Producto</th><th className="text-right py-2">Precio</th><th className="text-right py-2">Cant.</th><th className="text-right py-2">Subtotal</th></tr></thead>
                <tbody>
                  {(detailModal.items || []).map((item, i) => (
                    <tr key={i} className="border-b"><td className="py-2">{item.product?.name || item.productName}</td><td className="text-right">${parseFloat(item.unitPrice).toFixed(2)}</td><td className="text-right">{item.quantity}</td><td className="text-right font-medium">${parseFloat(item.subtotal).toFixed(2)}</td></tr>
                  ))}
                </tbody>
                <tfoot>
                  {detailModal.discount > 0 && <tr><td colSpan={3} className="text-right py-2 font-medium">Descuento:</td><td className="text-right text-red-600">-${parseFloat(detailModal.discount).toFixed(2)}</td></tr>}
                  {detailModal.tax > 0 && <tr><td colSpan={3} className="text-right py-2 font-medium">IVA:</td><td className="text-right">${parseFloat(detailModal.tax).toFixed(2)}</td></tr>}
                  <tr><td colSpan={3} className="text-right py-2 font-bold text-lg">Total:</td><td className="text-right font-bold text-lg text-green-700">${parseFloat(detailModal.total).toFixed(2)}</td></tr>
                </tfoot>
              </table>
            </div>

            {/* Payments */}
            {detailModal.payments?.length > 0 && (
              <div>
                <p className="text-sm font-medium text-gray-700 mb-2">Pagos</p>
                {detailModal.payments.map((p, i) => (
                  <div key={i} className="flex justify-between bg-gray-50 p-2 rounded-lg text-sm mb-1">
                    <span>{paymentLabels[p.method]}</span>
                    <span className="font-medium">${parseFloat(p.amount).toFixed(2)}</span>
                  </div>
                ))}
              </div>
            )}

            {detailModal.status !== 'CANCELLED' && (
              <div className="flex justify-end pt-4 border-t">
                <button onClick={() => handleCancel(detailModal.id)} className="btn-danger flex items-center gap-2"><HiOutlineX className="w-4 h-4" /> Cancelar Venta</button>
              </div>
            )}
          </div>
        )}
      </Modal>

      {/* Cash Cut Modal */}
      <Modal isOpen={cashCutModal} onClose={() => setCashCutModal(false)} title="📊 Corte de Caja" size="md">
        {cashCut && (
          <div className="space-y-4">
            <div className="text-center bg-vet-50 rounded-xl p-6">
              <p className="text-sm text-gray-500">Total del día</p>
              <p className="text-4xl font-bold text-vet-700">${parseFloat(cashCut.total || 0).toFixed(2)}</p>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-green-50 rounded-lg p-4 text-center">
                <p className="text-sm text-gray-500">Ventas completadas</p>
                <p className="text-2xl font-bold text-green-700">{cashCut.completedCount || 0}</p>
              </div>
              <div className="bg-red-50 rounded-lg p-4 text-center">
                <p className="text-sm text-gray-500">Ventas canceladas</p>
                <p className="text-2xl font-bold text-red-700">{cashCut.cancelledCount || 0}</p>
              </div>
            </div>
            {cashCut.byMethod && Object.entries(cashCut.byMethod).length > 0 && (
              <div>
                <p className="text-sm font-medium text-gray-700 mb-2">Desglose por método de pago</p>
                {Object.entries(cashCut.byMethod).map(([method, amount]) => (
                  <div key={method} className="flex justify-between p-2 bg-gray-50 rounded-lg mb-1 text-sm">
                    <span>{paymentLabels[method] || method}</span>
                    <span className="font-medium">${parseFloat(amount).toFixed(2)}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
}
