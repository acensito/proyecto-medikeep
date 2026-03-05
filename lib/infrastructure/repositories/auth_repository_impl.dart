import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';
import 'package:medikeep/infrastructure/datasources/auth_remote_datasource.dart';
import 'package:medikeep/infrastructure/datasources/user_remote_datasource.dart';
import 'package:medikeep/infrastructure/models/models.dart';

/// Repositorio de autenticación
class AuthRepositoryImpl implements AuthRepository {
  // datasources
  final AuthRemoteDataSource authDataSource;
  final UserRemoteDataSource userDataSource;

  AuthRepositoryImpl({
    required this.authDataSource,
    required this.userDataSource,
  });

  /// Método privado que lleva el flujo de autenticación
  /// Resuelve la identidad y sincroniza el perfil.
  Future<Either<Failure, AppUser>> _handleAuthFlow(
    Future<firebase_auth.User> authFuture,
  ) async {
    try {
      // Obtenemos el usuario de firestore que se identifica
      final firebaseUser = await authFuture;

      // Obtiene o crea el perfil en Firestore
      final userModel = await _getOrCreateUserProfile(firebaseUser);

      // Dispara la verificación de email si es necesario
      _triggerEmailVerificationIfNeeded(firebaseUser);

      // Devolvemos el modelo como entidad de usuario
      return Right(userModel.toEntity());

    } on Failure catch (e) {
      return Left(ServerFailure('Error inesperado en la autenticación: ${e.toString()}'));
    } catch (e) {
      return Left(ServerFailure('Error inesperado en la autenticación: ${e.toString()}'));
    }
  }

  /// Gestiona la obtención del usuario o su creación si es la primera vez.
  Future<AppUserModel> _getOrCreateUserProfile(firebase_auth.User firebaseUser) async {
    try {
      // Intentamos obtener el usuario
      return await userDataSource.getUserById(firebaseUser.uid);
    } catch (_) {
      // Usamos el email como nombre si no tiene uno asignado
      final String? nameFallback = (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty)
          ? firebaseUser.displayName
          : firebaseUser.email;  

      // Si falla la obtención, asumimos que es un nuevo registro
      final newUser = AppUserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        name: nameFallback,
        photoUrl: firebaseUser.photoURL,
        emailVerified: firebaseUser.emailVerified,
        spaceIds: const [],
      );
      // Creamos el usuario y lo devolvemos
      await userDataSource.createUser(newUser);
      return newUser;
    }
  }

  /// Verifica si el proveedor es Password y envía el correo si no está verificado.
  void _triggerEmailVerificationIfNeeded(firebase_auth.User firebaseUser) {
    // comprobamos el tipo de proveedor
    final isPasswordProvider = firebaseUser.providerData.any(
      (info) => info.providerId == 'password',
    );
    // si es via email/pass y no ha verificado el correo, se lo enviamos
    if (isPasswordProvider && !firebaseUser.emailVerified) {
      // Lo ejecutamos "fire and forget" o con un try-catch silencioso
      // para no bloquear el login si falla el servicio de correo
      authDataSource.sendEmailVerification().catchError((e) {
        Console.print('Error no crítico enviando email: $e');
      });
    }
  }

  /// Obtiene un stream con los cambios de la autenticación
  @override
  Stream<AppUser?> get authStateChanges {
    return authDataSource.authStateChanges.asyncMap((firebaseUser) async {
      // devuelve si no hay usuario autenticado
      if (firebaseUser == null) return null;

      try {
        // en caso de haber usuario autenticado, lo obtenemos
        final appUserModel = await userDataSource.getUserById(firebaseUser.uid);
        // devolvemos el usuario con copia del estado de verificacion
        return appUserModel.toEntity().copyWith(
          emailVerified: firebaseUser.emailVerified,
        );
      } catch (_) {
        return null;
      }
    });
  }

  // Método que se registra/autentica con Google-Sign In
  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() {
    return _handleAuthFlow(authDataSource.signInWithGoogle());
  }

  // Método de registro por email y password
  @override
  Future<Either<Failure, AppUser>> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _handleAuthFlow(
      authDataSource.registerWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  // Método de autenticación con email y password
  @override
  Future<Either<Failure, AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _handleAuthFlow(
      authDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  // Cierre de sesión
  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await authDataSource.signOut();
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Error al cerrar sesión: ${e.toString()}'));
    }
  }

  // Método que devuelve el usuario por su id
  @override
  Future<Either<Failure, AppUser>> getUserById(String userId) async {
    try {
      final appUserModel = await userDataSource.getUserById(userId);
      return Right(appUserModel.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure('No se pudo encontrar al usuario: ${e.toString()}'),
      );
    }
  }

  // Método que envia email de reseteo de password
  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await authDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure('Error al enviar el email de recuperación: ${e.toString()}'),
      );
    }
  }

  // Método que actualiza el password
  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    try {
      await authDataSource.updatePassword(newPassword);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure('Error al actualizar la contraseña: ${e.toString()}'),
      );
    }
  }

  // Método que envia un email de verificación
  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await authDataSource.sendEmailVerification();
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure('Error al enviar el email de verificación: ${e.toString()}'),
      );
    }
  }

  // Método que comprueba el estado de verificación
  @override
  Future<Either<Failure, bool>> checkVerificationStatus() async {
    try {
      // consultamos el estado real de la verificación
      final isVerified = await authDataSource.checkVerificationStatus();
      // si finalmente ha verificado, actualizamos la situación del usuario
      if (isVerified) {
        final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final model = await userDataSource.getUserById(currentUser.uid);
          
          // solo actualizamos Firestore si todavía figura como false
          if (model.emailVerified == false) {
            await userDataSource.updateUser(
              model.copyWith(emailVerified: true),
            );
            Console.print('Base de datos actualizada: Usuario verificado.');
          }
        }
      }
      return Right(isVerified);
    } catch (e) {
      return Left(
        ServerFailure(
          'Error al comprobar el estado de verificación: ${e.toString()}',
        ),
      );
    }
  }
}
