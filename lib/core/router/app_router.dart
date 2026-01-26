import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/providers.dart';
import 'package:medikeep/presentation/screens/screens.dart';

/// Proveedor del enrutador de la aplicación usando GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  /// Obtenemos el estado de autenticación del usuario
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    // --- RUTA INICIAL ---
    initialLocation: '/home',

    // --- GESTION REDIRECCIONES ---
    redirect: (BuildContext context, GoRouterState state) {
      final user = authState.asData?.value; // Usuario actual
      final bool isLoading = authState.isLoading; // Estado de carga
      final bool hasUser = user != null; // Si hay usuario autenticado

      final bool isGoingToLogin =
          state.matchedLocation == '/login'; // Si va a Login
      final bool isGoingToWelcome =
          state.matchedLocation == '/welcome'; // Si va a Welcome
      final bool isForgotPass = state.matchedLocation == '/forgot-password';

      if (isLoading) return null; // Si está cargando, no redirigimos

      // Rutas publicas: si no tiene ususario, no se esta registrando
      // o no esta recuperando la contraseña, se redirige al login
      if (!hasUser && !isGoingToLogin && !isForgotPass) return '/login';

      // Ruta privada: Si tiene usuario y va al login -> redirigimos a Home
      if (hasUser && isGoingToLogin) return '/home';

      // Ruta privada: Si TIENE usuario pero NO tiene Spaces -> Pantalla Bienvenida Welcome
      if (hasUser && user.spaceIds.isEmpty && !isGoingToWelcome) return '/welcome';

      // Ruta privada: Si TIENE usuario y TIENE Spaces e intenta ir a Welcome -> Home
      if (hasUser && user.spaceIds.isNotEmpty && isGoingToWelcome) return '/home';

      return null;
    },

    // --- RUTAS DE LA APP ---
    routes: [
      // Rutas Base
      GoRoute(
        path: '/login',
        name: 'login-screen',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home-screen',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome-screen',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // --- RUTA SPACE (ANIDADA) ---
      // Dentro de un space específico
      GoRoute(
        path: '/space/:spaceId',
        name: 'space-screen',
        builder: (context, state) {
          final spaceId = state.pathParameters['spaceId']!;
          return SpaceScreen(spaceId: spaceId);
        },

        // Rutas Hijas
        routes: [
          // Dentro de un storage box específico
          // Recibe en el path el ID del StorageBox y como extra
          // los medicamentos que lo componen.
          GoRoute(
            path: 'storagebox/:storageBoxId',
            name: 'storage-screen',
            builder: (context, state) {
              final spaceId = state.pathParameters['spaceId']!;
              final storageBoxId = state.pathParameters['storageBoxId']!;
              final storageBoxName = state.extra as String? ?? 'Medicamentos';
              return StorageBoxScreen(
                spaceId: spaceId,
                storageBoxId: storageBoxId,
                storageBoxName: storageBoxName,
              );
            },
            // Dentro de un medicamento específico
            // Recibe en el path el id de un space y como extra
            // el medicamento a mostrar.
            routes: [
              GoRoute(
                path: 'medication/:medicationId',
                name: 'medication-details',
                builder: (context, state) {
                  final spaceId = state.pathParameters['spaceId']!;
                  final extraData = state.extra as Map<String, dynamic>?;
                  final medication = extraData?['medication'] as Medication?;

                  if (medication == null) {
                    return const Scaffold(
                      body: Center(
                        child: Text('Error: Medicamento no encontrado.'),
                      ),
                    );
                  }
                  return MedicationDetailScreen(
                    spaceId: spaceId,
                    medication: medication,
                  );
                },
              ),
            ],
          ),
          // Añadir Medicamento
          // Recibe como extra un Map con:
          // - medicationTemplate: Medication (datos del medicamento a añadir)
          // - preselectedStorageBoxId: String? (ID del StorageBox preseleccionado, opcional)
          // - pathParameter: spaceId: String (ID del Space actual)
          GoRoute(
            path: 'add-medication',
            name: 'add-medication',
            builder: (context, state) {
              final spaceId = state.pathParameters['spaceId']!;
              final extraData = state.extra as Map<String, dynamic>;
              final medicationTemplate =
                  extraData['medicationTemplate'] as Medication;
              final preselectedStorageBoxId =
                  extraData['preselectedStorageBoxId'] as String?;

              return AddMedicationScreen(
                spaceId: spaceId,
                medicationTemplate: medicationTemplate,
                preselectedStorageBoxId: preselectedStorageBoxId,
              );
            },
          ),

          // Editar Medicamento
          // Recibe como extra el Medication a editar
          // y como pathParameter el spaceId actual
          GoRoute(
            path: 'edit-medication',
            name: 'edit-medication',
            builder: (context, state) {
              final spaceId = state.pathParameters['spaceId']!;
              final medicationToEdit = state.extra as Medication;
              return EditMedicationScreen(
                spaceId: spaceId,
                medicationToEdit: medicationToEdit,
              );
            },
          ),

          // Gestión del Space
          // Recibe como pathParameter el spaceId actual
          GoRoute(
            path: 'manage-space',
            name: 'manage-space',
            builder: (context, state) {
              final spaceId = state.pathParameters['spaceId']!;
              return SpaceManagementScreen(spaceId: spaceId);
            },
          ),
        ],
      ),

      // --- RUTAS ADICIONALES ---
      // Vista WebView
      GoRoute(
        path: '/webview',
        name: 'webview',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          final title = params['title'] ?? 'MediKeep';
          final url = params['url'] ?? '';
          if (url.isEmpty) return const Scaffold(body: Center(child: Text('Error URL')));
          return WebViewScreen(title: title, url: url);
        },
      ),

      // Atajo Detalle medicamento (Quick View)
      GoRoute(
        path: '/medication-quick-view',
        name: 'medication-quick-view',
        builder: (context, state) {
          final extraMap = state.extra as Map<String, dynamic>?;
          if (extraMap == null) {
            return const Scaffold(
              body: Center(child: Text('Error: Datos no pasados')),
            );
          }
          final medication = extraMap['medication'] as Medication;
          final spaceId = extraMap['spaceId'] as String;

          return MedicationDetailScreen(
            spaceId: spaceId,
            medication: medication,
          );
        },
      ),

      // Escáner
      GoRoute(
        path: '/scanner',
        name: 'scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
    ],
  );
});
