# ⚔️ Valhalla BJJ - Sistema de Administración

Aplicación móvil completa para la administración personal del gimnasio **Valhalla BJJ**.
Control total financiero y operativo: alumnos, membresías, ingresos, gastos, inventario y reportes automáticos.

## 🛡️ Características

- **📋 Gestión de Alumnos**: Registro completo, membresías, estados (Activo/Vencido/Suspendido), cinturones BJJ, historial de pagos
- **💰 Control de Ingresos**: Categorías (Mensualidades, Ventas, Seminarios, etc.), totales diarios/semanales/mensuales
- **📊 Control de Gastos**: Gastos fijos y recurrentes (Renta, Luz, Agua, etc.), seguimiento mensual
- **🏪 Inventario**: Productos (playeras, gis, rashguards), control de stock, alertas de stock bajo, registro de ventas
- **📈 Dashboard**: Resumen financiero, gráficas (ingresos vs gastos), predicción de fin de mes, alumnos por vencer, top productos
- **☁️ Sincronización**: Backup automático a Google Sheets (incremental + completo)
- **🔒 Seguridad**: PIN de acceso + autenticación biométrica
- **📱 Offline First**: Funciona sin internet, base de datos SQLite local

## 🏗️ Arquitectura

```
lib/
├── core/                      # Capa central
│   ├── constants/             # Constantes de negocio
│   ├── models/                # Modelos de datos (Student, Income, Expense, Product, Sale, Payment)
│   ├── router/                # Navegación con rutas nombradas
│   ├── theme/                 # Tema Valhalla (negro/rojo/dorado)
│   └── utils/                 # Formateadores y extensiones de fecha
├── data/                      # Capa de datos
│   ├── database/              # DatabaseHelper SQLite
│   ├── repositories/          # Repositorios CRUD
│   └── services/              # Google Sheets sync service
├── features/                  # Módulos de la app
│   ├── auth/                  # Autenticación (PIN + biometría)
│   ├── dashboard/             # Panel principal con gráficas
│   ├── expenses/              # Módulo de gastos
│   ├── income/                # Módulo de ingresos
│   ├── inventory/             # Inventario y ventas
│   ├── shell/                 # Navegación principal (BottomNav)
│   └── students/              # Gestión de alumnos
├── providers/                 # Riverpod state management
└── shared/                    # Widgets compartidos
```

## 🛠️ Stack Tecnológico

| Tecnología | Uso |
|---|---|
| **Flutter 3.16+** | Framework UI multiplataforma |
| **Riverpod 2.4** | Gestión de estado reactiva |
| **SQLite (sqflite)** | Base de datos local offline |
| **Google Sheets API** | Sincronización / backup en la nube |
| **fl_chart** | Gráficas del dashboard |
| **Google Fonts (Poppins)** | Tipografía de la app |
| **local_auth** | Autenticación biométrica |
| **flutter_secure_storage** | Almacenamiento seguro del PIN |

## 🚀 Configuración

### Prerrequisitos
- Flutter SDK 3.16+
- Dart SDK 3.2+
- Android Studio / Xcode (para emuladores)

### Instalación

```bash
# Clonar el repositorio
cd administracion_gym

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run
```

### Configurar Google Sheets (Opcional)

1. Crear un proyecto en [Google Cloud Console](https://console.cloud.google.com/)
2. Habilitar la API de Google Sheets
3. Configurar credenciales OAuth 2.0 para Android/iOS
4. Agregar el archivo de configuración a la app
5. La app creará automáticamente el spreadsheet al primer sync

## 📱 Pantallas

| Pantalla | Descripción |
|---|---|
| **Auth Gate** | PIN + biometría para acceso seguro |
| **Dashboard** | Resumen financiero, gráficas, predicciones |
| **Alumnos** | Lista, búsqueda, filtros, detalle con pagos |
| **Ingresos** | Lista con totales, formulario de registro |
| **Gastos** | Lista con categorías, gastos recurrentes |
| **Inventario** | Productos, stock, ventas, alertas |

## 🎨 Tema Valhalla

- **Negro**: `#0A0A0A` - Fondo principal
- **Rojo**: `#C62828` - Accento secundario  
- **Dorado**: `#D4A843` - Accento principal, estilo vikingo
- **Tipografía**: Poppins (Google Fonts)

## 📋 Constantes de Negocio

- **Planes**: Mensual, Quincenal, Clase suelta
- **Cinturones**: Blanco → Marrón → Negro (BJJ)
- **Categorías de ingreso**: Mensualidades, Venta de playeras, Seminarios, Inscripciones, Otros
- **Categorías de gasto**: Renta, Luz, Agua, Internet, Gas, Material, Mantenimiento, Publicidad, Otros
- **Umbral de stock bajo**: 3 unidades

---

**Valhalla BJJ** ⚔️ — _Control total de tu gimnasio_
