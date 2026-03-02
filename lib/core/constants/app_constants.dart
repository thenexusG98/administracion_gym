class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Valhalla BJJ';
  static const String appVersion = '1.0.0';

  // Google Sheets
  static const String spreadsheetName = 'Valhalla BJJ - Administración';
  static const List<String> sheetNames = [
    'Alumnos',
    'Pagos',
    'Ingresos',
    'Gastos',
    'Inventario',
    'Ventas',
  ];

  // Planes
  static const String planMensual = 'Mensual';
  static const String planQuincenal = 'Quincenal';
  static const String planClaseSuelta = 'Clase suelta';

  static const List<String> planes = [
    planMensual,
    planQuincenal,
    planClaseSuelta,
  ];

  // Estados de alumno
  static const String estadoActivo = 'Activo';
  static const String estadoVencido = 'Vencido';
  static const String estadoSuspendido = 'Suspendido';

  static const List<String> estadosAlumno = [
    estadoActivo,
    estadoVencido,
    estadoSuspendido,
  ];

  // Categorías de ingreso
  static const List<String> categoriasIngreso = [
    'Mensualidades',
    'Venta de playeras',
    'Venta de rashguards',
    'Venta de Gi',
    'Venta de suplementos',
    'Inscripciones',
    'Otros',
  ];

  // Categorías de gasto
  static const List<String> categoriasGasto = [
    'Renta',
    'Luz',
    'Agua',
    'Limpieza',
    'Mantenimiento',
    'Compra de inventario',
    'Otros',
  ];

  // Productos de inventario
  static const List<String> categoriasProducto = [
    'Playera',
    'Rashguard',
    'Gi (Kimono)',
    'Shorts',
    'Cinturón',
    'Suplemento',
    'Otro',
  ];

  // Tallas
  static const List<String> tallas = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'A0',
    'A1',
    'A2',
    'A3',
    'A4',
    'Única',
  ];

  // Cinturones BJJ
  static const List<String> cinturones = [
    'Blanco',
    'Azul',
    'Púrpura',
    'Café',
    'Negro',
  ];

  // Stock bajo
  static const int stockBajoUmbral = 3;

  // Formato de moneda
  static const String moneda = 'MXN';
  static const String simboloMoneda = '\$';
}
