import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';
import 'package:medikeep/infrastructure/datasources/auth_remote_datasource.dart';
import 'package:medikeep/infrastructure/datasources/user_remote_datasource.dart';
import 'package:medikeep/infrastructure/models/models.dart';

/// Implementación del repositorio de Auth
/// Orquesta los DataSources de Auth y de User.
class AuthRepositoryImpl implements AuthRepository {
  // Atributos con las fuentes de datos
  final AuthRemoteDataSource authDataSource;
  final UserRemoteDataSource userDataSource;

  // Constructor
  AuthRepositoryImpl({
    required this.authDataSource,
    required this.userDataSource,
  });

  /// Metodo Helper privado _handleAuthFlow.
  /// 1. Autentica con Firebase Auth (Google, Email, etc.).
  /// 2. Una vez autenticado, comprueba si el usuario existe en nuestra BD /users.
  /// 3. Si no existe (primer login), lo crea.
  /// 4. Devuelve la entidad AppUser completa.
  Future<Either<Failure, AppUser>> _handleAuthFlow(
    Future<firebase_auth.User> authFuture,
  ) async {
    try {
      // 1. Esperamos a que el DataSource de Auth complete la autenticación
      final firebaseUser = await authFuture;

      // 2. Comprobamos si el usuario ya existe en nuestra colección /users
      try {
        final appUserModel = await userDataSource.getUserById(firebaseUser.uid);
        // 3. SI EXISTE: Es un login normal. Devolvemos el usuario.
        return Right(appUserModel.toEntity());
      } catch (e) {
        // 4. NO EXISTE: Es el primer login (registro).
        // Creamos un nuevo AppUserModel a partir de los datos de Firebase Auth.
        final newUserModel = AppUserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email,
          name: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          spaceIds: [], // Lista vacía ya que no tiene spaces creados
        );

        // 5. Guardamos este nuevo usuario en la colección /users
        await userDataSource.createUser(newUserModel);

        // 6. Devolvemos el nuevo usuario con resultado satisfactorio
        return Right(newUserModel.toEntity());
      }
    }on Failure catch (e) {
      // Si existe
      return Left(e);
    } catch (e) {
      // Si falla la autenticación (usuario cierra el popup, email/pass incorrecto)
      return Left(ServerFailure('Error de autenticación: ${e.toString()}'));
    }
  }

  // Devuelve un Stream de datos con los cambios de estado de autenticación
  @override
  Stream<AppUser?> get authStateChanges {
    // Escuchamos al DataSource de Auth
    return authDataSource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null; // Usuario cerró sesión
      }
      // Si está autenticado, buscamos su perfil en nuestra BD /users
      try {
        final appUserModel = await userDataSource.getUserById(firebaseUser.uid);
        // Devolvemos el usuario como objeto entidad
        return appUserModel.toEntity();
      } catch (e) {
        // Autenticado pero sin perfil en la BD (ej: registro incompleto, error)
        // Devolvemos null para que la app lo trate como "no logueado".
        return null;
      }
    });
  }

  // Metodo para login con cuenta Google
  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() {
    // Usamos nuestro flujo helper para manejar la lógica
    return _handleAuthFlow(authDataSource.signInWithGoogle());
  }

  // Metodo para hacer SignOut
  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      // Le decimos al DataSource que cierre sesión
      await authDataSource.signOut();
      // Si todo va bien, devolvemos 'Right(null)' (éxito)
      return const Right(null);
    } on Failure catch (e) {
      // Si el DataSource devolvió un Failure, lo propagamos como Left
      return Left(e);
    } catch (e) {
      // Si algo falla, devolvemos 'Left' (fallo)
      return Left(ServerFailure('Error al cerrar sesión: ${e.toString()}'));
    }
  }

  // Metodo que registra un usuario con email y password
  @override
  Future<Either<Failure, AppUser>> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    // Retornamos usando nuestro flujo helper
    return _handleAuthFlow(
      authDataSource.registerWithEmailAndPassword(email: email, password: password),
    );
  }

  // Metodo para identificarse con Email y Password
  @override
  Future<Either<Failure, AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    // Retornamos usando nuestro flujo helper
    return _handleAuthFlow(
      authDataSource.signInWithEmailAndPassword(email: email, password: password),
    );
  }
  
  // Metodo que obtiene un usuario por su ID dado como parametro
  @override
  Future<Either<Failure, AppUser>> getUserById(String userId) async {
    try {
      // Le pedimos el modelo al especialista
      final appUserModel = await userDataSource.getUserById(userId);
      // Lo traducimos a entidad y lo devolvemos como éxito
      return Right(appUserModel.toEntity());
    } on Failure catch (e) {
      // En caso de error devolvemos un fallo Left
      return Left(e);
    } catch (e) {
      // En caso de error, devolvemos un fallo Left
      return Left(ServerFailure('No se pudo encontrar al usuario: ${e.toString()}'));
    }
  }

  // Método que manda un email para recuperar la password
  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      // Hacemos la llamada al datasource
      await authDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on Failure catch (e) {
      // Capturamos fallos como 'user-not-found' o 'invalid-email'
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Error al enviar el email de recuperación: ${e.toString()}'));
    }
  }
  
  // Método que resetea la password
  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    try {
      // Delegamos la llamada al especialista (DataSource)
      await authDataSource.updatePassword(newPassword);
      return const Right(null);
    } on Failure catch (e) {
      // Capturamos fallos como 'requires-recent-login' o 'weak-password'
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar la contraseña: ${e.toString()}'));
    }
  }
  
}

