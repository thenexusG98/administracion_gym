import { useState, useEffect, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { productsAPI, clientsAPI, salesAPI } from '../api/endpoints';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlineSearch, HiOutlinePlus, HiOutlineMinus, HiOutlineTrash, HiOutlineArrowLeft, HiOutlineShoppingCart } from 'react-icons/hi';

const paymentMethods = [
  { id: 'CASH', label: '💵 Efectivo' },
  { id: 'CARD', label: '💳 Tarjeta' },
  { id: 'TRANSFER', label: '🏦 Transferencia' },
];

export default function NewSalePage() {
  const navigate = useNavigate();
  const [products, setProducts] = useState([]);
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchProduct, setSearchProduct] = useState('');
  const [searchClient, setSearchClient] = useState('');
  const [cart, setCart] = useState([]);
  const [selectedClient, setSelectedClient] = useState(null);
  const [paymentMethod, setPaymentMethod] = useState('CASH');
  const [discount, setDiscount] = useState(0);
  const [amountPaid, setAmountPaid] = useState('');
  const [notes, setNotes] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    Promise.all([
      productsAPI.getAll({ limit: 500 }),
      clientsAPI.getAll({ limit: 500 }),
    ]).then(([prodRes, clientRes]) => {
      setProducts((prodRes.data.data || []).filter(p => p.isActive));
      setClients(clientRes.data.data || []);
    }).catch(() => toast.error('Error al cargar datos')).finally(() => setLoading(false));
  }, []);

  const filteredProducts = useMemo(() => {
    if (!searchProduct) return products.slice(0, 20);
    const q = searchProduct.toLowerCase();
    return products.filter(p => p.name.toLowerCase().includes(q) || p.barcode?.toLowerCase().includes(q) || p.category?.toLowerCase().includes(q));
  }, [products, searchProduct]);

  const filteredClients = useMemo(() => {
    if (!searchClient) return [];
    const q = searchClient.toLowerCase();
    return clients.filter(c => `${c.firstName} ${c.lastName}`.toLowerCase().includes(q) || c.phone?.includes(q));
  }, [clients, searchClient]);

  const addToCart = (product) => {
    const existing = cart.find(c => c.productId === product.id);
    if (existing) {
      if (!product.isService && existing.quantity >= product.stock) return toast.error('Stock insuficiente');
      setCart(cart.map(c => c.productId === product.id ? { ...c, quantity: c.quantity + 1 } : c));
    } else {
      if (!product.isService && product.stock <= 0) return toast.error('Sin stock disponible');
      setCart([...cart, { productId: product.id, name: product.name, unitPrice: parseFloat(product.price), quantity: 1, maxStock: product.isService ? 999 : product.stock, isService: product.isService }]);
    }
  };

  const updateQuantity = (productId, delta) => {
    setCart(cart.map(c => {
      if (c.productId !== productId) return c;
      const newQty = c.quantity + delta;
      if (newQty <= 0) return c;
      if (!c.isService && newQty > c.maxStock) { toast.error('Stock insuficiente'); return c; }
      return { ...c, quantity: newQty };
    }));
  };

  const removeFromCart = (productId) => setCart(cart.filter(c => c.productId !== productId));

  const subtotal = useMemo(() => cart.reduce((sum, c) => sum + c.unitPrice * c.quantity, 0), [cart]);
  const tax = useMemo(() => subtotal * 0.16, [subtotal]);
  const total = useMemo(() => subtotal + tax - discount, [subtotal, tax, discount]);
  const change = useMemo(() => {
    const paid = parseFloat(amountPaid) || 0;
    return paid - total;
  }, [amountPaid, total]);

  const handleSubmit = async () => {
    if (cart.length === 0) return toast.error('Agrega productos al carrito');
    setSubmitting(true);
    try {
      const payload = {
        clientId: selectedClient?.id || undefined,
        items: cart.map(c => ({ productId: c.productId, quantity: c.quantity, unitPrice: c.unitPrice })),
        discount: discount,
        tax: tax,
        payments: [{ method: paymentMethod, amount: total }],
        notes: notes,
      };
      await salesAPI.create(payload);
      toast.success('✅ Venta registrada correctamente');
      navigate('/sales');
    } catch (error) {
      toast.error(error.response?.data?.message || 'Error al registrar venta');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="h-[calc(100vh-6rem)] flex gap-6">
      {/* Left: Products */}
      <div className="flex-1 flex flex-col">
        <div className="flex items-center gap-4 mb-4">
          <button onClick={() => navigate('/sales')} className="p-2 hover:bg-gray-100 rounded-lg"><HiOutlineArrowLeft className="w-5 h-5" /></button>
          <h1 className="text-xl font-bold text-gray-900">Punto de Venta</h1>
        </div>

        {/* Product Search */}
        <div className="relative mb-4">
          <HiOutlineSearch className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input className="input-field pl-10" value={searchProduct} onChange={e => setSearchProduct(e.target.value)} placeholder="Buscar producto por nombre o código..." autoFocus />
        </div>

        {/* Product Grid */}
        <div className="flex-1 overflow-y-auto grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3 content-start">
          {filteredProducts.map(p => (
            <button key={p.id} onClick={() => addToCart(p)}
              className="bg-white rounded-xl border p-3 text-left hover:shadow-md hover:border-vet-300 transition-all group">
              <div className="flex justify-between items-start mb-2">
                <span className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">{p.category}</span>
                {!p.isService && <span className={`text-xs font-medium ${p.stock <= (p.minStock || 0) ? 'text-red-500' : 'text-gray-400'}`}>{p.stock} uds</span>}
                {p.isService && <span className="text-xs text-blue-500">Servicio</span>}
              </div>
              <p className="font-medium text-gray-900 truncate group-hover:text-vet-700">{p.name}</p>
              <p className="text-lg font-bold text-vet-600 mt-1">${parseFloat(p.price).toFixed(2)}</p>
            </button>
          ))}
          {filteredProducts.length === 0 && <p className="col-span-full text-center text-gray-400 py-8">No se encontraron productos</p>}
        </div>
      </div>

      {/* Right: Cart */}
      <div className="w-[400px] bg-white rounded-xl border shadow-sm flex flex-col">
        {/* Client */}
        <div className="p-4 border-b">
          <label className="text-sm font-medium text-gray-700 mb-1 block">Cliente (opcional)</label>
          {selectedClient ? (
            <div className="flex items-center justify-between bg-vet-50 p-2 rounded-lg">
              <span className="text-sm font-medium">{selectedClient.firstName} {selectedClient.lastName}</span>
              <button onClick={() => setSelectedClient(null)} className="text-red-500 text-xs">✕</button>
            </div>
          ) : (
            <div className="relative">
              <input className="input-field text-sm" value={searchClient} onChange={e => setSearchClient(e.target.value)} placeholder="Buscar cliente..." />
              {filteredClients.length > 0 && (
                <div className="absolute z-10 top-full left-0 right-0 bg-white border rounded-lg shadow-lg max-h-40 overflow-y-auto">
                  {filteredClients.slice(0, 8).map(c => (
                    <button key={c.id} onClick={() => { setSelectedClient(c); setSearchClient(''); }}
                      className="w-full text-left px-3 py-2 hover:bg-gray-50 text-sm">{c.firstName} {c.lastName} — {c.phone}</button>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Cart Items */}
        <div className="flex-1 overflow-y-auto p-4">
          {cart.length === 0 ? (
            <div className="text-center text-gray-400 py-8">
              <HiOutlineShoppingCart className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>Carrito vacío</p>
              <p className="text-sm">Selecciona productos para agregar</p>
            </div>
          ) : (
            <div className="space-y-3">
              {cart.map(item => (
                <div key={item.productId} className="flex items-center gap-3 bg-gray-50 rounded-lg p-2">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{item.name}</p>
                    <p className="text-xs text-gray-500">${item.unitPrice.toFixed(2)} c/u</p>
                  </div>
                  <div className="flex items-center gap-1">
                    <button onClick={() => updateQuantity(item.productId, -1)} className="w-7 h-7 flex items-center justify-center rounded-full bg-gray-200 hover:bg-gray-300"><HiOutlineMinus className="w-3 h-3" /></button>
                    <span className="w-8 text-center font-semibold text-sm">{item.quantity}</span>
                    <button onClick={() => updateQuantity(item.productId, 1)} className="w-7 h-7 flex items-center justify-center rounded-full bg-gray-200 hover:bg-gray-300"><HiOutlinePlus className="w-3 h-3" /></button>
                  </div>
                  <p className="text-sm font-semibold w-20 text-right">${(item.unitPrice * item.quantity).toFixed(2)}</p>
                  <button onClick={() => removeFromCart(item.productId)} className="text-red-400 hover:text-red-600"><HiOutlineTrash className="w-4 h-4" /></button>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Totals & Payment */}
        <div className="border-t p-4 space-y-3">
          <div className="space-y-1 text-sm">
            <div className="flex justify-between"><span className="text-gray-500">Subtotal</span><span>${subtotal.toFixed(2)}</span></div>
            <div className="flex justify-between"><span className="text-gray-500">IVA (16%)</span><span>${tax.toFixed(2)}</span></div>
            <div className="flex justify-between items-center">
              <span className="text-gray-500">Descuento</span>
              <input type="number" min="0" step="0.01" className="w-24 text-right input-field text-sm py-1" value={discount} onChange={e => setDiscount(parseFloat(e.target.value) || 0)} />
            </div>
            <div className="flex justify-between text-lg font-bold border-t pt-2"><span>Total</span><span className="text-vet-700">${total.toFixed(2)}</span></div>
          </div>

          {/* Payment Method */}
          <div className="flex gap-2">
            {paymentMethods.map(m => (
              <button key={m.id} onClick={() => setPaymentMethod(m.id)}
                className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium border transition-colors ${paymentMethod === m.id ? 'bg-vet-600 text-white border-vet-600' : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'}`}>
                {m.label}
              </button>
            ))}
          </div>

          {/* Amount Paid (for cash) */}
          {paymentMethod === 'CASH' && (
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs text-gray-500">Monto recibido</label>
                <input type="number" step="0.01" className="input-field" value={amountPaid} onChange={e => setAmountPaid(e.target.value)} placeholder="0.00" />
              </div>
              <div>
                <label className="text-xs text-gray-500">Cambio</label>
                <p className={`input-field bg-gray-50 ${change >= 0 ? 'text-green-700' : 'text-red-600'} font-bold`}>${change >= 0 ? change.toFixed(2) : '0.00'}</p>
              </div>
            </div>
          )}

          <button onClick={handleSubmit} disabled={submitting || cart.length === 0}
            className="w-full btn-primary py-3 text-lg font-bold disabled:opacity-50 disabled:cursor-not-allowed">
            {submitting ? 'Procesando...' : `💰 Cobrar $${total.toFixed(2)}`}
          </button>
        </div>
      </div>
    </div>
  );
}
