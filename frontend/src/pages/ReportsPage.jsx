import { useState, useEffect } from 'react';
import { reportsAPI } from '../api/endpoints';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlineDocumentDownload } from 'react-icons/hi';
import { format, subDays, startOfMonth, endOfMonth } from 'date-fns';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line, Legend } from 'recharts';

const COLORS = ['#16a34a', '#2563eb', '#dc2626', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4', '#f97316'];

export default function ReportsPage() {
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState({ start: format(startOfMonth(new Date()), 'yyyy-MM-dd'), end: format(endOfMonth(new Date()), 'yyyy-MM-dd') });
  const [incomeData, setIncomeData] = useState([]);
  const [topServices, setTopServices] = useState([]);
  const [topProducts, setTopProducts] = useState([]);
  const [patientStats, setPatientStats] = useState(null);

  useEffect(() => { loadReports(); }, [dateRange]);

  const loadReports = async () => {
    setLoading(true);
    try {
      const [incomeRes, servicesRes, productsRes, patientsRes] = await Promise.all([
        reportsAPI.income(dateRange).catch(() => ({ data: { data: [] } })),
        reportsAPI.topServices(dateRange).catch(() => ({ data: { data: [] } })),
        reportsAPI.topProducts(dateRange).catch(() => ({ data: { data: [] } })),
        reportsAPI.patients(dateRange).catch(() => ({ data: { data: {} } })),
      ]);
      setIncomeData(incomeRes.data.data || []);
      setTopServices(servicesRes.data.data || []);
      setTopProducts(productsRes.data.data || []);
      setPatientStats(patientsRes.data.data || {});
    } catch {
      toast.error('Error al cargar reportes');
    } finally {
      setLoading(false);
    }
  };

  const quickRanges = [
    { label: 'Hoy', start: format(new Date(), 'yyyy-MM-dd'), end: format(new Date(), 'yyyy-MM-dd') },
    { label: 'Últimos 7 días', start: format(subDays(new Date(), 7), 'yyyy-MM-dd'), end: format(new Date(), 'yyyy-MM-dd') },
    { label: 'Este mes', start: format(startOfMonth(new Date()), 'yyyy-MM-dd'), end: format(endOfMonth(new Date()), 'yyyy-MM-dd') },
    { label: 'Últimos 30 días', start: format(subDays(new Date(), 30), 'yyyy-MM-dd'), end: format(new Date(), 'yyyy-MM-dd') },
  ];

  const totalIncome = incomeData.reduce((sum, d) => sum + (d.total || d.amount || 0), 0);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Reportes</h1>
          <p className="text-gray-500">Análisis de ingresos, servicios y pacientes</p>
        </div>
      </div>

      {/* Date Range */}
      <div className="card">
        <div className="flex flex-wrap items-center gap-4">
          <div className="flex gap-2">
            {quickRanges.map(r => (
              <button key={r.label} onClick={() => setDateRange({ start: r.start, end: r.end })}
                className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${dateRange.start === r.start && dateRange.end === r.end ? 'bg-vet-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
                {r.label}
              </button>
            ))}
          </div>
          <div className="flex items-center gap-2 ml-auto">
            <input type="date" className="input-field text-sm" value={dateRange.start} onChange={e => setDateRange({ ...dateRange, start: e.target.value })} />
            <span className="text-gray-400">a</span>
            <input type="date" className="input-field text-sm" value={dateRange.end} onChange={e => setDateRange({ ...dateRange, end: e.target.value })} />
          </div>
        </div>
      </div>

      {loading ? <LoadingSpinner /> : (
        <>
          {/* Income Summary */}
          <div className="card bg-gradient-to-r from-vet-600 to-vet-700 text-white">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-vet-100">Ingresos del período</p>
                <p className="text-4xl font-bold">${totalIncome.toFixed(2)}</p>
              </div>
              <div className="text-right">
                <p className="text-vet-100">{incomeData.length} registros</p>
              </div>
            </div>
          </div>

          {/* Charts Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Income Chart */}
            <div className="card">
              <h3 className="font-semibold text-gray-900 mb-4">📊 Ingresos por Día</h3>
              {incomeData.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={incomeData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" tick={{ fontSize: 12 }} />
                    <YAxis tick={{ fontSize: 12 }} />
                    <Tooltip formatter={(value) => [`$${parseFloat(value).toFixed(2)}`, 'Ingresos']} />
                    <Bar dataKey="total" fill="#16a34a" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <p className="text-center text-gray-400 py-8">No hay datos para este período</p>
              )}
            </div>

            {/* Top Services */}
            <div className="card">
              <h3 className="font-semibold text-gray-900 mb-4">🏆 Top Servicios</h3>
              {topServices.length > 0 ? (
                <div className="flex items-center gap-6">
                  <ResponsiveContainer width="50%" height={250}>
                    <PieChart>
                      <Pie data={topServices} dataKey="count" nameKey="name" cx="50%" cy="50%" innerRadius={50} outerRadius={90} paddingAngle={3}>
                        {topServices.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                      </Pie>
                      <Tooltip />
                    </PieChart>
                  </ResponsiveContainer>
                  <div className="flex-1 space-y-2">
                    {topServices.slice(0, 6).map((s, i) => (
                      <div key={i} className="flex items-center gap-2 text-sm">
                        <div className="w-3 h-3 rounded-full" style={{ backgroundColor: COLORS[i % COLORS.length] }} />
                        <span className="flex-1 truncate">{s.name}</span>
                        <span className="font-medium">{s.count}</span>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <p className="text-center text-gray-400 py-8">No hay datos</p>
              )}
            </div>

            {/* Top Products */}
            <div className="card">
              <h3 className="font-semibold text-gray-900 mb-4">📦 Productos Más Vendidos</h3>
              {topProducts.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart layout="vertical" data={topProducts.slice(0, 8)}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis type="number" tick={{ fontSize: 12 }} />
                    <YAxis type="category" dataKey="name" width={120} tick={{ fontSize: 11 }} />
                    <Tooltip />
                    <Bar dataKey="quantity" fill="#2563eb" radius={[0, 4, 4, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <p className="text-center text-gray-400 py-8">No hay datos</p>
              )}
            </div>

            {/* Patient Stats */}
            <div className="card">
              <h3 className="font-semibold text-gray-900 mb-4">🐾 Estadísticas de Pacientes</h3>
              {patientStats ? (
                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-blue-50 rounded-xl p-4 text-center">
                    <p className="text-sm text-gray-500">Nuevos pacientes</p>
                    <p className="text-3xl font-bold text-blue-700">{patientStats.newPets || 0}</p>
                  </div>
                  <div className="bg-green-50 rounded-xl p-4 text-center">
                    <p className="text-sm text-gray-500">Consultas realizadas</p>
                    <p className="text-3xl font-bold text-green-700">{patientStats.consultations || 0}</p>
                  </div>
                  <div className="bg-yellow-50 rounded-xl p-4 text-center">
                    <p className="text-sm text-gray-500">Vacunas aplicadas</p>
                    <p className="text-3xl font-bold text-yellow-700">{patientStats.vaccines || 0}</p>
                  </div>
                  <div className="bg-purple-50 rounded-xl p-4 text-center">
                    <p className="text-sm text-gray-500">Cirugías</p>
                    <p className="text-3xl font-bold text-purple-700">{patientStats.surgeries || 0}</p>
                  </div>
                  {patientStats.bySpecies && (
                    <div className="col-span-2">
                      <p className="text-sm text-gray-500 mb-2">Por especie</p>
                      <div className="flex gap-3 flex-wrap">
                        {Object.entries(patientStats.bySpecies).map(([species, count]) => (
                          <span key={species} className="bg-gray-100 px-3 py-1 rounded-full text-sm">{species}: <strong>{count}</strong></span>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              ) : (
                <p className="text-center text-gray-400 py-8">No hay datos</p>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
