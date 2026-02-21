import { Router } from 'express';
import { supplierController } from '../controllers/supplier.controller.js';
import { authenticate, authorize, ensureClinic } from '../middlewares/auth.js';

const router = Router();

router.use(authenticate, ensureClinic);

router.get('/', supplierController.getAll);
router.get('/:id', supplierController.getById);
router.post('/', authorize('ADMIN'), supplierController.create);
router.put('/:id', authorize('ADMIN'), supplierController.update);
router.delete('/:id', authorize('ADMIN'), supplierController.delete);

export default router;
