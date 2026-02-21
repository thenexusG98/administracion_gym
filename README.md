# 🐾 VetClinic Pro - Sistema de Administración Veterinaria

Sistema web completo para la administración de clínicas veterinarias. Multi-tenant (SaaS ready).

## Stack Tecnológico

- **Frontend:** React 18 + Vite + TailwindCSS + Zustand
- **Backend:** Node.js + Express + Prisma ORM
- **Base de datos:** PostgreSQL
- **Autenticación:** JWT + Refresh Tokens + bcrypt
- **Arquitectura:** Clean Architecture (Controllers → Services → Repositories)

## Estructura del Proyecto

```
sistema_vet/
├── backend/                 # API REST (Express + Prisma)
│   ├── prisma/              # Schema y migraciones
│   ├── src/
│   │   ├── config/          # Configuración general
│   │   ├── controllers/     # Controladores HTTP
│   │   ├── middlewares/     # Auth, roles, errores
│   │   ├── repositories/   # Acceso a datos (Prisma)
│   │   ├── routes/          # Definición de rutas
│   │   ├── services/        # Lógica de negocio
│   │   ├── validators/      # Validación con Zod
│   │   ├── utils/           # Helpers
│   │   └── app.js           # Express app
│   └── server.js            # Entry point
├── frontend/                # React + Vite
│   ├── src/
│   │   ├── api/             # Axios config + endpoints
│   │   ├── components/      # Componentes reutilizables
│   │   ├── contexts/        # Context providers
│   │   ├── hooks/           # Custom hooks
│   │   ├── layouts/         # Layouts principales
│   │   ├── pages/           # Páginas/vistas
│   │   ├── stores/          # Zustand stores
│   │   ├── utils/           # Helpers frontend
│   │   └── App.jsx
│   └── index.html
└── docker-compose.yml       # PostgreSQL + pgAdmin
```

## Inicio Rápido

### 1. Levantar PostgreSQL con Docker
```bash
docker-compose up -d
```

### 2. Backend
```bash
cd backend
npm install
cp .env.example .env
npx prisma migrate dev --name init
npx prisma db seed
npm run dev
```

### 3. Frontend
```bash
cd frontend
npm install
npm run dev
```

## Módulos

- ✅ Autenticación (JWT + Refresh Tokens + Roles)
- ✅ Clientes (Dueños de mascotas)
- ✅ Mascotas (Expediente completo)
- ✅ Expediente Clínico
- ✅ Agenda / Citas
- ✅ Inventario
- ✅ Punto de Venta (POS)
- ✅ Reportes
- ✅ Multi-clínica (SaaS ready)
- ✅ Bitácora de actividad

## Roles del Sistema

| Rol | Permisos |
|-----|----------|
| ADMIN | Acceso total, gestión de clínica y usuarios |
| VETERINARIO | Consultas, expedientes, recetas |
| RECEPCION | Citas, clientes, mascotas |
| CAJA | Ventas, cobros, corte de caja |

## API Endpoints

Ver documentación completa en `/api/docs` o en el archivo `backend/API_DOCS.md`

## Variables de Entorno

Ver `backend/.env.example` y `frontend/.env.example`

## Licencia

Proyecto privado - Todos los derechos reservados.
