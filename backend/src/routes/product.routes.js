import { Router } from 'express';
import { productController } from '../controllers/product.controller.js';
import { authenticate, authorize, ensureClinic } from '../middlewares/auth.js';
import { validateBody } from '../middlewares/validate.js';
import { createProductSchema, updateProductSchema } from '../validators/product.validator.js';
import { activityLogger } from '../middlewares/activityLogger.js';

const router = Router();

router.use(authenticate, ensureClinic);

router.get('/', productController.getAll);
router.get('/low-stock', productController.getLowStock);
router.get('/expiring', productController.getExpiring);
router.get('/:id', productController.getById);
router.post('/', authorize('ADMIN'), validateBody(createProductSchema), activityLogger('CREATE', 'Product'), productController.create);
router.put('/:id', authorize('ADMIN'), validateBody(updateProductSchema), activityLogger('UPDATE', 'Product'), productController.update);
router.delete('/:id', authorize('ADMIN'), activityLogger('DELETE', 'Product'), productController.delete);

export default router;
