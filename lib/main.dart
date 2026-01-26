import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/core/router/app_router.dart';
import 'package:medikeep/core/theme/app_theme.dart';
import 'package:medikeep/firebase_options.dart';
import 'package:medikeep/infrastructure/services/local_notification_service.dart';
import 'package:medikeep/presentation/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Punto de entrada de la aplicación
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final init = await initApp();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(init)],
      child: const MyApp(),
    ),
  );
}

/// Inicialización de Firebase, notificaciones y preferencias
/// devuelve una instancia de SharedPreferences
/// para ser usada en el Provider
/// 
/// @return SharedPreferences
Future<SharedPreferences> initApp() async {
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar notificaciones locales
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  // Solicitar permisos para notificaciones (opcional)
  await notificationService.requestPermissions();

  // Retorna una instancia de SharedPreferences
  return await SharedPreferences.getInstance();
}

/// Widget principal de la aplicación
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);

    // Construir la aplicación con MaterialApp.router
    // para usar GoRouter
    // y aplicar el tema personalizado
    return MaterialApp.router(
      title: 'MediKeep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
      routerConfig: router,
    );
  }
}
