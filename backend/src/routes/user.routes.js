import { Router } from 'express';
import { userController } from '../controllers/user.controller.js';
import { authenticate, authorize, ensureClinic } from '../middlewares/auth.js';

const router = Router();

router.use(authenticate, ensureClinic);

router.get('/', authorize('ADMIN'), userController.getAll);
router.get('/vets', userController.getVets);
router.get('/:id', authorize('ADMIN'), userController.getById);
router.put('/:id', authorize('ADMIN'), userController.update);
router.patch('/:id/toggle-active', authorize('ADMIN'), userController.toggleActive);

export default router;
