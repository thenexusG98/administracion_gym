import { Router } from 'express';
import { dashboardController } from '../controllers/report.controller.js';
import { authenticate, ensureClinic } from '../middlewares/auth.js';

const router = Router();

router.use(authenticate, ensureClinic);

router.get('/stats', dashboardController.getStats);

export default router;
