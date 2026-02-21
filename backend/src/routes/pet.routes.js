import { Router } from 'express';
import { petController } from '../controllers/pet.controller.js';
import { authenticate, authorize, ensureClinic } from '../middlewares/auth.js';
import { validateBody } from '../middlewares/validate.js';
import { createPetSchema, updatePetSchema } from '../validators/pet.validator.js';
import { activityLogger } from '../middlewares/activityLogger.js';

const router = Router();

router.use(authenticate, ensureClinic);

router.get('/', petController.getAll);
router.get('/:id', petController.getById);
router.get('/:id/timeline', petController.getTimeline);
router.post('/', authorize('ADMIN', 'RECEPCION', 'VETERINARIO'), validateBody(createPetSchema), activityLogger('CREATE', 'Pet'), petController.create);
router.put('/:id', authorize('ADMIN', 'RECEPCION', 'VETERINARIO'), validateBody(updatePetSchema), activityLogger('UPDATE', 'Pet'), petController.update);
router.delete('/:id', authorize('ADMIN'), activityLogger('DELETE', 'Pet'), petController.delete);

export default router;
