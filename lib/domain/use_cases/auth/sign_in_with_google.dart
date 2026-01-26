import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión con Google Sign-In
class SignInWithGoogle {
  // Repositorio de autenticación
  final AuthRepository repository;

  // Constructor
  SignInWithGoogle(this.repository);

  // Método para ejecutar el caso de uso
  // Retorna un Either con un Failure o un AppUser autenticado
  Future<Either<Failure, AppUser>> call() {
    // Llamada al método del repositorio para iniciar sesión con Google
    return repository.signInWithGoogle();
  }
}