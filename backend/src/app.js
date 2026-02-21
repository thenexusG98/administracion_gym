import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import path from 'path';
import { fileURLToPath } from 'url';
import config from './config/index.js';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler.js';

// Routes
import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/user.routes.js';
import clientRoutes from './routes/client.routes.js';
import petRoutes from './routes/pet.routes.js';
import appointmentRoutes from './routes/appointment.routes.js';
import medicalRecordRoutes from './routes/medicalRecord.routes.js';
import productRoutes from './routes/product.routes.js';
import inventoryRoutes from './routes/inventory.routes.js';
import saleRoutes from './routes/sale.routes.js';
import supplierRoutes from './routes/supplier.routes.js';
import reportRoutes from './routes/report.routes.js';
import dashboardRoutes from './routes/dashboard.routes.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Security
app.use(helmet());
app.use(cors({
  origin: config.frontendUrl,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 100,
  message: { error: 'Demasiadas solicitudes, intenta más tarde.' },
});
app.use('/api/', limiter);

// Auth specific rate limit (more strict)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Demasiados intentos de autenticación.' },
});
app.use('/api/auth/login', authLimiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Logging
if (config.nodeEnv === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Static files (uploads)
app.use('/uploads', express.static(path.join(__dirname, '..', config.upload.dir)));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/pets', petRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/medical-records', medicalRecordRoutes);
app.use('/api/products', productRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/sales', saleRoutes);
app.use('/api/suppliers', supplierRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/dashboard', dashboardRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

export default app;
