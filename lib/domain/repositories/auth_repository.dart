import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';

/// Repositorio que define las operaciones de autenticación.
/// La capa de dominio solo conoce este repositorio, no la implementación.
/// Estos son los diferentes casos de uso a los que llama
abstract class AuthRepository {
  // Devuelve un Stream que notifica los cambios en el estado de autenticación.
  // Emite un [AppUser] si el usuario está logueado, o null si no lo está.
  Stream<AppUser?> get authStateChanges;

  // Inicia el flujo de autenticación con Google.
  // Devuelve un [AppUser] si es exitoso, o un [Failure] si falla.
  Future<Either<Failure, AppUser>> signInWithGoogle();

  // Registra un nuevo usuario con email y contraseña.
  Future<Either<Failure, AppUser>> registerWithEmailAndPassword({
    required String email,
    required String password,
  });

  // Inicia sesión con email y contraseña.
  Future<Either<Failure, AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  // Obtiene un usuario por su ID.
  Future<Either<Failure, AppUser>> getUserById(String userId);

  // Cierra la sesión del usuario actual.
  Future<Either<Failure, void>> signOut();

  // Manda email de password reset
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  // Actualiza el password
  Future<Either<Failure, void>> updatePassword(String newPassword);
}