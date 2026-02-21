import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from './stores/authStore';
import MainLayout from './layouts/MainLayout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import ClientsPage from './pages/ClientsPage';
import ClientDetailPage from './pages/ClientDetailPage';
import PetsPage from './pages/PetsPage';
import PetDetailPage from './pages/PetDetailPage';
import AppointmentsPage from './pages/AppointmentsPage';
import MedicalRecordsPage from './pages/MedicalRecordsPage';
import ProductsPage from './pages/ProductsPage';
import SalesPage from './pages/SalesPage';
import NewSalePage from './pages/NewSalePage';
import ReportsPage from './pages/ReportsPage';
import UsersPage from './pages/UsersPage';
import SuppliersPage from './pages/SuppliersPage';
import InventoryPage from './pages/InventoryPage';

function ProtectedRoute({ children, roles }) {
  const { user, token } = useAuthStore();
  if (!token || !user) return <Navigate to="/login" replace />;
  if (roles && !roles.includes(user.role)) return <Navigate to="/" replace />;
  return children;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/" element={
        <ProtectedRoute>
          <MainLayout />
        </ProtectedRoute>
      }>
        <Route index element={<DashboardPage />} />
        <Route path="clients" element={<ClientsPage />} />
        <Route path="clients/:id" element={<ClientDetailPage />} />
        <Route path="pets" element={<PetsPage />} />
        <Route path="pets/:id" element={<PetDetailPage />} />
        <Route path="appointments" element={<AppointmentsPage />} />
        <Route path="medical-records" element={<MedicalRecordsPage />} />
        <Route path="products" element={<ProductsPage />} />
        <Route path="inventory" element={<InventoryPage />} />
        <Route path="suppliers" element={<SuppliersPage />} />
        <Route path="sales" element={<SalesPage />} />
        <Route path="sales/new" element={<NewSalePage />} />
        <Route path="reports" element={
          <ProtectedRoute roles={['ADMIN']}>
            <ReportsPage />
          </ProtectedRoute>
        } />
        <Route path="users" element={
          <ProtectedRoute roles={['ADMIN']}>
            <UsersPage />
          </ProtectedRoute>
        } />
      </Route>
    </Routes>
  );
}
