import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_theme.dart';
import 'package:valhalla_bjj/core/router/app_router.dart';
import 'package:valhalla_bjj/features/auth/presentation/pages/auth_gate_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
