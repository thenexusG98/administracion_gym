import api from './axios';

// Auth
export const authAPI = {
  login: (data) => api.post('/auth/login', data),
  logout: () => api.post('/auth/logout'),
  me: () => api.get('/auth/me'),
  register: (data) => api.post('/auth/register', data),
  changePassword: (data) => api.put('/auth/change-password', data),
};

// Dashboard
export const dashboardAPI = {
  getStats: () => api.get('/dashboard/stats'),
};

// Users
export const usersAPI = {
  getAll: (params) => api.get('/users', { params }),
  getById: (id) => api.get(`/users/${id}`),
  update: (id, data) => api.put(`/users/${id}`, data),
  toggleActive: (id) => api.patch(`/users/${id}/toggle-active`),
  getVets: () => api.get('/users/vets'),
};

// Clients
export const clientsAPI = {
  getAll: (params) => api.get('/clients', { params }),
  getById: (id) => api.get(`/clients/${id}`),
  create: (data) => api.post('/clients', data),
  update: (id, data) => api.put(`/clients/${id}`, data),
  delete: (id) => api.delete(`/clients/${id}`),
};

// Pets
export const petsAPI = {
  getAll: (params) => api.get('/pets', { params }),
  getById: (id) => api.get(`/pets/${id}`),
  create: (data) => api.post('/pets', data),
  update: (id, data) => api.put(`/pets/${id}`, data),
  delete: (id) => api.delete(`/pets/${id}`),
  getTimeline: (id) => api.get(`/pets/${id}/timeline`),
};

// Appointments
export const appointmentsAPI = {
  getAll: (params) => api.get('/appointments', { params }),
  getById: (id) => api.get(`/appointments/${id}`),
  create: (data) => api.post('/appointments', data),
  update: (id, data) => api.put(`/appointments/${id}`, data),
  cancel: (id) => api.patch(`/appointments/${id}/cancel`),
  getToday: () => api.get('/appointments/today'),
  getCalendar: (params) => api.get('/appointments/calendar', { params }),
};

// Medical Records
export const medicalRecordsAPI = {
  getAll: (params) => api.get('/medical-records', { params }),
  getById: (id) => api.get(`/medical-records/${id}`),
  create: (data) => api.post('/medical-records', data),
  update: (id, data) => api.put(`/medical-records/${id}`, data),
  getByPet: (petId) => api.get(`/medical-records/pet/${petId}`),
};

// Products
export const productsAPI = {
  getAll: (params) => api.get('/products', { params }),
  getById: (id) => api.get(`/products/${id}`),
  create: (data) => api.post('/products', data),
  update: (id, data) => api.put(`/products/${id}`, data),
  delete: (id) => api.delete(`/products/${id}`),
  getLowStock: () => api.get('/products/low-stock'),
  getExpiring: (days) => api.get('/products/expiring', { params: { days } }),
};

// Inventory
export const inventoryAPI = {
  getMovements: (params) => api.get('/inventory/movements', { params }),
  createMovement: (data) => api.post('/inventory/movements', data),
};

// Sales
export const salesAPI = {
  getAll: (params) => api.get('/sales', { params }),
  getById: (id) => api.get(`/sales/${id}`),
  create: (data) => api.post('/sales', data),
  cancel: (id) => api.patch(`/sales/${id}/cancel`),
  getCashCut: (params) => api.get('/sales/cash-cut', { params }),
};

// Suppliers
export const suppliersAPI = {
  getAll: (params) => api.get('/suppliers', { params }),
  getById: (id) => api.get(`/suppliers/${id}`),
  create: (data) => api.post('/suppliers', data),
  update: (id, data) => api.put(`/suppliers/${id}`, data),
  delete: (id) => api.delete(`/suppliers/${id}`),
};

// Reports
export const reportsAPI = {
  getIncome: (params) => api.get('/reports/income', { params }),
  getTopServices: (params) => api.get('/reports/top-services', { params }),
  getTopProducts: (params) => api.get('/reports/top-products', { params }),
  getPatients: (params) => api.get('/reports/patients', { params }),
};
