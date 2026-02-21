import { useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../stores/authStore';
import {
  HiOutlineHome, HiOutlineUsers, HiOutlineHeart,
  HiOutlineCalendar, HiOutlineClipboardList, HiOutlineCube,
  HiOutlineShoppingCart, HiOutlineChartBar, HiOutlineCog,
  HiOutlineLogout, HiOutlineMenu, HiOutlineX,
  HiOutlineTruck, HiOutlineArchive, HiOutlineUserGroup
} from 'react-icons/hi';
import toast from 'react-hot-toast';

const navigation = [
  { name: 'Dashboard', href: '/', icon: HiOutlineHome, roles: ['ADMIN', 'VETERINARIO', 'RECEPCION', 'CAJA'] },
  { name: 'Clientes', href: '/clients', icon: HiOutlineUsers, roles: ['ADMIN', 'RECEPCION', 'VETERINARIO'] },
  { name: 'Mascotas', href: '/pets', icon: HiOutlineHeart, roles: ['ADMIN', 'RECEPCION', 'VETERINARIO'] },
  { name: 'Agenda', href: '/appointments', icon: HiOutlineCalendar, roles: ['ADMIN', 'RECEPCION', 'VETERINARIO'] },
  { name: 'Expedientes', href: '/medical-records', icon: HiOutlineClipboardList, roles: ['ADMIN', 'VETERINARIO'] },
  { name: 'Productos', href: '/products', icon: HiOutlineCube, roles: ['ADMIN', 'CAJA'] },
  { name: 'Inventario', href: '/inventory', icon: HiOutlineArchive, roles: ['ADMIN'] },
  { name: 'Proveedores', href: '/suppliers', icon: HiOutlineTruck, roles: ['ADMIN'] },
  { name: 'Punto de Venta', href: '/sales', icon: HiOutlineShoppingCart, roles: ['ADMIN', 'CAJA'] },
  { name: 'Reportes', href: '/reports', icon: HiOutlineChartBar, roles: ['ADMIN'] },
  { name: 'Usuarios', href: '/users', icon: HiOutlineUserGroup, roles: ['ADMIN'] },
];

export default function MainLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  const filteredNav = navigation.filter(item => item.roles.includes(user?.role));

  const handleLogout = () => {
    logout();
    toast.success('Sesión cerrada');
    navigate('/login');
  };

  const linkClasses = ({ isActive }) =>
    `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 ${
      isActive
        ? 'bg-vet-600 text-white shadow-md'
        : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
    }`;

  return (
    <div className="flex h-screen overflow-hidden bg-gray-50">
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-40 bg-black/50 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      {/* Sidebar */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-white border-r border-gray-200 transform transition-transform duration-300 lg:translate-x-0 lg:static lg:z-auto ${
        sidebarOpen ? 'translate-x-0' : '-translate-x-full'
      }`}>
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="flex items-center gap-3 px-6 py-5 border-b border-gray-100">
            <div className="w-10 h-10 bg-vet-600 rounded-xl flex items-center justify-center">
              <span className="text-white text-lg font-bold">🐾</span>
            </div>
            <div>
              <h1 className="text-lg font-bold text-gray-900">VetClinic Pro</h1>
              <p className="text-xs text-gray-500">{user?.clinic?.name}</p>
            </div>
            <button className="ml-auto lg:hidden" onClick={() => setSidebarOpen(false)}>
              <HiOutlineX className="w-5 h-5" />
            </button>
          </div>

          {/* Nav */}
          <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1">
            {filteredNav.map((item) => (
              <NavLink
                key={item.href}
                to={item.href}
                end={item.href === '/'}
                className={linkClasses}
                onClick={() => setSidebarOpen(false)}
              >
                <item.icon className="w-5 h-5 flex-shrink-0" />
                {item.name}
              </NavLink>
            ))}
          </nav>

          {/* User section */}
          <div className="border-t border-gray-100 p-4">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-9 h-9 bg-vet-100 text-vet-700 rounded-full flex items-center justify-center font-semibold text-sm">
                {user?.firstName?.[0]}{user?.lastName?.[0]}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900 truncate">
                  {user?.firstName} {user?.lastName}
                </p>
                <p className="text-xs text-gray-500">{user?.role}</p>
              </div>
            </div>
            <button
              onClick={handleLogout}
              className="flex items-center gap-2 w-full px-3 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
            >
              <HiOutlineLogout className="w-4 h-4" />
              Cerrar sesión
            </button>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top bar */}
        <header className="bg-white border-b border-gray-200 px-4 py-3 lg:px-6">
          <div className="flex items-center justify-between">
            <button className="lg:hidden" onClick={() => setSidebarOpen(true)}>
              <HiOutlineMenu className="w-6 h-6 text-gray-600" />
            </button>
            <div className="flex items-center gap-4 ml-auto">
              <span className="text-sm text-gray-500">
                {new Date().toLocaleDateString('es-MX', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
              </span>
            </div>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
