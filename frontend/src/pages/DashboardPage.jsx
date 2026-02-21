import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { dashboardAPI } from '../api/endpoints';
import StatsCard from '../components/StatsCard';
import LoadingSpinner from '../components/LoadingSpinner';
import {
  HiOutlineUsers, HiOutlineHeart, HiOutlineCalendar,
  HiOutlineCurrencyDollar, HiOutlineClock, HiOutlineExclamation,
  HiOutlineOfficeBuilding
} from 'react-icons/hi';

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const { data } = await dashboardAPI.getStats();
      setStats(data.data);
    } catch (error) {
      console.error('Error loading stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-500">Resumen general de tu clínica</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard title="Clientes" value={stats?.totalClients || 0} icon={HiOutlineUsers} color="blue" />
        <StatsCard title="Mascotas" value={stats?.totalPets || 0} icon={HiOutlineHeart} color="green" />
        <StatsCard title="Citas Hoy" value={stats?.todayAppointments || 0} icon={HiOutlineCalendar} color="purple" />
        <StatsCard
          title="Ingresos del Mes"
          value={`$${(stats?.monthRevenue || 0).toLocaleString('es-MX')}`}
          icon={HiOutlineCurrencyDollar}
          color="green"
          subtitle={`${stats?.monthSalesCount || 0} ventas`}
        />
      </div>

      {/* Second row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatsCard title="Citas Pendientes" value={stats?.pendingAppointments || 0} icon={HiOutlineClock} color="yellow" />
        <StatsCard title="Stock Bajo" value={stats?.lowStockProducts || 0} icon={HiOutlineExclamation} color="red" />
        <StatsCard title="Hospitalizados" value={stats?.activeHospitalizations || 0} icon={HiOutlineOfficeBuilding} color="indigo" />
      </div>

      {/* Quick actions & Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Quick actions */}
        <div className="card">
          <h3 className="text-lg font-semibold mb-4">Acciones Rápidas</h3>
          <div className="grid grid-cols-2 gap-3">
            <Link to="/appointments" className="p-4 bg-vet-50 rounded-xl hover:bg-vet-100 transition-colors text-center">
              <HiOutlineCalendar className="w-8 h-8 text-vet-600 mx-auto mb-2" />
              <p className="text-sm font-medium text-vet-800">Nueva Cita</p>
            </Link>
            <Link to="/clients" className="p-4 bg-blue-50 rounded-xl hover:bg-blue-100 transition-colors text-center">
              <HiOutlineUsers className="w-8 h-8 text-blue-600 mx-auto mb-2" />
              <p className="text-sm font-medium text-blue-800">Nuevo Cliente</p>
            </Link>
            <Link to="/sales/new" className="p-4 bg-purple-50 rounded-xl hover:bg-purple-100 transition-colors text-center">
              <HiOutlineCurrencyDollar className="w-8 h-8 text-purple-600 mx-auto mb-2" />
              <p className="text-sm font-medium text-purple-800">Nueva Venta</p>
            </Link>
            <Link to="/pets" className="p-4 bg-yellow-50 rounded-xl hover:bg-yellow-100 transition-colors text-center">
              <HiOutlineHeart className="w-8 h-8 text-yellow-600 mx-auto mb-2" />
              <p className="text-sm font-medium text-yellow-800">Registrar Mascota</p>
            </Link>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="card">
          <h3 className="text-lg font-semibold mb-4">Actividad Reciente</h3>
          <div className="space-y-3 max-h-64 overflow-y-auto">
            {stats?.recentActivity?.map((log) => (
              <div key={log.id} className="flex items-center gap-3 text-sm">
                <div className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center text-xs font-medium">
                  {log.user?.firstName?.[0]}{log.user?.lastName?.[0]}
                </div>
                <div className="flex-1">
                  <p className="text-gray-700">
                    <span className="font-medium">{log.user?.firstName}</span>{' '}
                    <span className="text-gray-400">{log.action}</span>{' '}
                    <span className="text-gray-600">{log.entity}</span>
                  </p>
                  <p className="text-xs text-gray-400">
                    {new Date(log.createdAt).toLocaleString('es-MX')}
                  </p>
                </div>
              </div>
            ))}
            {(!stats?.recentActivity || stats.recentActivity.length === 0) && (
              <p className="text-gray-400 text-center py-4">Sin actividad reciente</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
