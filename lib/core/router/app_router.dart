import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/providers.dart';
import 'package:medikeep/presentation/screens/screens.dart';

/// Proveedor del enrutador de la aplicación usando GoRouter
final routerProvider = Provider<GoRouter>((ref) {

  // Notificador para recalcular el enrutado
  final refreshNotifier = _RouterRefreshNotifier();

  // Listerner que reevalua si hay cambios en la autenticación
  ref.listen(authStateChangesProvider, (_,__){
    refreshNotifier.refresh();
  });
  // Listener que reevalua si hay cambios en la verificación
  ref.listen(authVerificationStatusProvider, (_,__){
    refreshNotifier.refresh();
  });

  // Leemos los cambios de la autenticación
  final authState = ref.watch(authStateChangesProvider);

  // Leemos los cambios de la verificación
  final isUserVerified = ref.watch(authVerificationStatusProvider);

  final router = GoRouter(
    // --- RUTA INICIAL ---
    initialLocation: '/home',

    // GoRouter se refrescará cuando reciba notificaciones 
    refreshListenable: refreshNotifier,

    // --- GESTION REDIRECCIONES ---
    redirect: (BuildContext context, GoRouterState state) {
      // Espera si esta cargando los datos
      if (authState.isLoading) return null;
      // Estado de la autenticación del usuario
      final user = authState.asData?.value;
      final bool hasUser = user != null;
      // Estado de la verificación del usuario
      final bool isVerified = (user?.emailVerified ?? false) || isUserVerified;
      // Tiene al menos un espacio asociado
      final bool hasSpaces = user?.spaceIds.isNotEmpty ?? false;
      // Ruta a la que intenta acceder
      final String location = state.matchedLocation;

      // Rutas públicas (sin autenticación)
      const publicRoutes = {'/login', '/forgot-password'};
      const authRoutes = {'/verify-email'};
      const onboardingRoutes = {'/welcome'};

      // Sin sesión, solo rutas públicas, por lo que mandamos a login
      if (!hasUser) return publicRoutes.contains(location) ? null : '/login';
      
      // Con sesión, pero sin verificar, remitimos a la ruta de verify
      if (!isVerified) return authRoutes.contains(location) ? null : '/verify-email';

      // Con sesión verificada pero sin espacios 
      // Remitimos a pantalla onboarding/welcome si no la ha visto por primera vez
      if (!hasSpaces) return onboardingRoutes.contains(location) ? null : '/welcome';

      // Con sesion verificada y espacios, remitimos al home/dashboard
      if (publicRoutes.contains(location) || 
          authRoutes.contains(location) || 
          onboardingRoutes.contains(location)) {
        return '/home';
      }

      // Cualquier otra ruta, no redirigimos (inválidas)
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
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) => const VerificationPendingScreen(),
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

      // Scanner de códigos de barras
      GoRoute(
        path: '/scanner',
        name: 'scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
    ],
  );

  return router;
});

/// Convierte un Stream en un Listenable que GoRouter entiende.
class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}