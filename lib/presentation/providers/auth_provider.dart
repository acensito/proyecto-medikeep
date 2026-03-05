import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
/////////////////////

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

/// Caso de uso: obtener cambios en el estado de autenticación
/// Este caso observa el stream de autenticación y notifica a la UI cuando
/// un usuario inicia o cierra sesión.
final getAuthStateChangesProvider = Provider<GetAuthStateChanges>((ref) {
  return GetAuthStateChanges(repository: ref.watch(authRepositoryProvider));
});

/// Caso de uso: iniciar sesión con Google
/// Devuelve una instancia encargada de manejar el flujo de autenticación de Google.
final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(repository: ref.watch(authRepositoryProvider));
});

/// Caso de uso: registrarse con correo electronico
final registerWithEmailProvider = Provider<RegisterWithEmail>((ref) {
  return RegisterWithEmail(repository: ref.watch(authRepositoryProvider));
});

/// Caso de uso: iniciar sesión con correo electronico
final signInWithEmailProvider = Provider<SignInWithEmail>((ref) {
  return SignInWithEmail(repository: ref.watch(authRepositoryProvider));
});

  // Caso de uso: cerrar sesión
final signOutProvider = Provider<SignOut>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final notificationService = ref.watch(localNotificationServiceProvider);
  return SignOut(repository, notificationService);
});

/// Caso de uso: obtener información de un usuario por su ID.
final getUserByIdUseCaseProvider = Provider<GetUserById>((ref) {
  return GetUserById(ref.watch(authRepositoryProvider));
});

/// Caso de uso: recuperación de contraseña por email
final sendPasswordResetEmailProvider = Provider((ref) {
  return SendPasswordResetEmail(repository: ref.watch(authRepositoryProvider));
});

/// Caso de uso: actualización de contraseña
final updatePasswordProvider = Provider((ref) {
  return UpdatePassword(repository: ref.watch(authRepositoryProvider));
});

/// Caso de uso: email de verificación de usuario
final sendEmailVerificationUseCaseProvider = Provider<SendEmailVerification>((ref) {
  return SendEmailVerification(repository: ref.watch(authRepositoryProvider));
});

// -- GESTION VERIFICACION USUARIO --

// Provider de estado de la carga de verificación manual
final verificationLoadingProvider = StateProvider<bool>((ref) => false);

// Provider de estado que controla el estado de envio del correo a la UI
final verificationEmailStatusProvider = StateProvider<AsyncValue<void>>((ref){
  return const AsyncValue.data(null);
});

/// Provider de acción para REENVIAR el email de verificación si es necesario
final sendVerificationEmailActionProvider = Provider((ref) {
  return () async {
    ref.read(verificationEmailStatusProvider.notifier).state = const AsyncValue.loading();
    final useCase = ref.read(sendEmailVerificationUseCaseProvider);
    
    // Permite el reenvio manual
    final result = await useCase.call(); // El email obtiene del user actual
    
    result.fold(
      (failure) => ref.read(verificationEmailStatusProvider.notifier).state = 
          AsyncValue.error(failure.message, StackTrace.current),
      (_) => ref.read(verificationEmailStatusProvider.notifier).state = const AsyncValue.data(null),
    );
  };
});

/// Provider reactivo que devuelve el estado de verificación actual
/// Se actualiza cuando el Stream de Auth emite valores
final authVerificationStatusProvider = StateProvider<bool>((ref) {
  final user = ref.watch(authStateChangesProvider).value?.emailVerified;
  return user ?? false;
});

/// Provider de acción para comprobar si el usuario ya pulsó el enlace (Botón "YA HE PULSADO")
final checkEmailVerificationActionProvider = Provider((ref) {
  return () async {
    ref.read(verificationLoadingProvider.notifier).state = true;

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.checkVerificationStatus();

    result.fold(
      (failure) => ref.read(verificationLoadingProvider.notifier).state = false,
      (isVerified) {
        if (isVerified) {
          // Si es verificado, actualizamos el estado local
          ref.read(authVerificationStatusProvider.notifier).state = true;
          // IMPORTANTE: Invalidamos el stream de auth para forzar al Router a revaluar
          ref.invalidate(authStateChangesProvider);
        }
        ref.read(verificationLoadingProvider.notifier).state = false;
      },
    );
  };
});

/// StreamProvider que expone los cambios de autenticacion del usuario actual. Es el motor del Router.
final authStateChangesProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  final getAuthStateChanges = ref.watch(getAuthStateChangesProvider);
  return getAuthStateChanges.call();
});

/// Provider que devuelve los detalles del usuario
final userDetailsProvider = FutureProvider.autoDispose.family<AppUser, String>((ref, userId) async {
  final getUserById = ref.watch(getUserByIdUseCaseProvider);
  final result = await getUserById.call(userId);
  return result.fold((failure) => throw failure, (user) => user);
});