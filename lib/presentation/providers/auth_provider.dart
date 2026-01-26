import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikeep/domain/entities/app_user.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';
import 'package:medikeep/domain/use_cases/usecases.dart';
import 'package:medikeep/infrastructure/datasources/auth_remote_datasource_impl.dart';
import 'package:medikeep/infrastructure/datasources/auth_remote_datasource.dart';
import 'package:medikeep/infrastructure/datasources/user_remote_datasource_impl.dart';
import 'package:medikeep/infrastructure/datasources/user_remote_datasource.dart';
import 'package:medikeep/infrastructure/repositories/auth_repository_impl.dart';
import 'package:medikeep/presentation/providers/medication_provider.dart';

// -- DATASOURCES --

/// Proveedor del datasource de autenticacion
/// Crea una instancia encargada de comunicarse con autenticacion remota (Firebase)
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

/// Proveedor del datasource de usuarios remotos
/// Crea una instancia encargada de comunicarse con la coleccion de usuarios
/// en la base de datos
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl();
});

// -- REPOSITORIOS --

/// Proveedor del repositorio de autenticación.
/// Combina los datasources de autenticación y usuarios en un repositorio que
/// centraliza la lógica de negocio relacionada con el acceso y gestión de cuentas.
final authRepositoryProvider = Provider<AuthRepository>((ref) {

  final authDataSource = ref.watch(authRemoteDataSourceProvider);
  final userDataSource = ref.watch(userRemoteDataSourceProvider);
  
  return AuthRepositoryImpl(
    authDataSource: authDataSource,
    userDataSource: userDataSource,
  );
});

// -- CASOS DE USO REPOSITORIO AUTH --

/// Caso de uso: obtener cambios en el estado de autenticación.
/// Este caso observa el stream de autenticación y notifica a la UI cuando
/// un usuario inicia o cierra sesión.
final getAuthStateChangesProvider = Provider<GetAuthStateChanges>((ref) {
  // Pide el repositorio que necesita
  final repository = ref.watch(authRepositoryProvider);

  return GetAuthStateChanges(repository);
});

/// Caso de uso: iniciar sesión con Google.
/// Devuelve una instancia encargada de manejar el flujo de autenticación de Google.
final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return SignInWithGoogle(repository);
});

/// Caso de uso: registrarse con correo electronico
final registerWithEmailProvider = Provider<RegisterWithEmail>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return RegisterWithEmail(repository);
});

/// Caso de uso: iniciar sesión con correo electronico
final signInWithEmailProvider = Provider<SignInWithEmail>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithEmail(repository);
});

  // Caso de uso: cerrar sesión
final signOutProvider = Provider<SignOut>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final notificationService = ref.watch(localNotificationServiceProvider);

  return SignOut(repository, notificationService);
});

/// Caso de uso: obtener información de un usuario por su ID.
final getUserByIdUseCaseProvider = Provider<GetUserById>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return GetUserById(repository);
});

/// Caso de uso: recuperación de contraseña por email
final sendPasswordResetEmailProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendPasswordResetEmail(repository);
});

/// Caso de uso: actualización de contraseña
final updatePasswordProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdatePassword(repository);
});

/// Provider reactivo que expone el estado de autenticación en tiempo real.
/// La UI puede escucharlo con `ref.watch(authStateChangesProvider)` y responder
/// automáticamente a los cambios de sesión.
/// Útil para saber el estado de sesión y hacer redirecciones
final authStateChangesProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  // Obtiene el Caso de Uso
  final getAuthStateChanges = ref.watch(getAuthStateChangesProvider);
  // Llama al Caso de Uso y devuelve el stream para que la UI lo escuche
  return getAuthStateChanges.call();
});

/// Provider parametrizado (family) que obtiene los detalles de un usuario.
/// Se puede usar en la UI pasando un ID concreto: `ref.watch(userDetailsProvider(userId))`.
final userDetailsProvider = FutureProvider.autoDispose.family<AppUser, String>((ref, userId) async {
  
  final getUserById = ref.watch(getUserByIdUseCaseProvider);
  final result = await getUserById.call(userId);

  // Abrimos la "caja" (Either)
  return result.fold(
    (failure) => throw failure, // Si falló, lanzamos un error
    (user) => user, // Si tuvo éxito, devolvemos el AppUser
  );
});