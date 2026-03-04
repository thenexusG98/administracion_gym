import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:valhalla_bjj/core/theme/app_theme.dart';
import 'package:valhalla_bjj/core/router/app_router.dart';
import 'package:valhalla_bjj/data/database/database_helper.dart';
import 'package:valhalla_bjj/features/auth/presentation/pages/auth_gate_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar locales para DateFormat en español
  await initializeDateFormatting('es', null);

  // Pre-inicializar la base de datos ANTES de que los providers la necesiten
  debugPrint('🚀 Pre-inicializando base de datos...');
  try {
    await DatabaseHelper().database;
    debugPrint('🚀 ✅ DB pre-inicializada OK');
  } catch (e) {
    debugPrint('🚀 ❌ Error pre-inicializando DB: $e');
  }

  // Capturar errores de Flutter para debug
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('⚠️ FlutterError: ${details.exceptionAsString()}');
  };

  runApp(
    const ProviderScope(
      child: ValhallaApp(),
    ),
  );
}

class ValhallaApp extends StatelessWidget {
  const ValhallaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valhalla BJJ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGatePage(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
