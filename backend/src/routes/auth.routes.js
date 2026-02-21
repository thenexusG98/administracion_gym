import { Router } from 'express';
import { authController } from '../controllers/auth.controller.js';
import { authenticate, ensureClinic } from '../middlewares/auth.js';
import { validateBody } from '../middlewares/validate.js';
import { loginSchema, registerSchema, refreshTokenSchema } from '../validators/auth.validator.js';

const router = Router();

// Public routes
router.post('/login', validateBody(loginSchema), authController.login);
router.post('/refresh-token', validateBody(refreshTokenSchema), authController.refreshToken);

// Protected routes
router.post('/register', authenticate, ensureClinic, validateBody(registerSchema), authController.register);
router.post('/logout', authenticate, authController.logout);
router.get('/me', authenticate, authController.me);
router.put('/change-password', authenticate, authController.changePassword);

export default router;
