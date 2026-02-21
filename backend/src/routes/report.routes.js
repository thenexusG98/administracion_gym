import { Router } from 'express';
import { reportController } from '../controllers/report.controller.js';
import { authenticate, authorize, ensureClinic } from '../middlewares/auth.js';

const router = Router();

router.use(authenticate, ensureClinic, authorize('ADMIN'));

router.get('/income', reportController.getIncome);
router.get('/top-services', reportController.getTopServices);
router.get('/top-products', reportController.getTopProducts);
router.get('/patients', reportController.getPatients);

export default router;
