import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión con correo electrónico y contraseña
class SignInWithEmail {
  // Repositorio de autenticación
  final AuthRepository repository;

  // Constructor
  SignInWithEmail(this.repository);

  // Método para ejecutar el caso de uso
  // Retorna un Either con un Failure o un AppUser autenticado
  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) {
    
    // Validación básica de negocio
    // validación si el email o la contraseña están vacíos 
    if (email.isEmpty || password.isEmpty) {
      return Future.value(Left(const ValidationFailure('Email y contraseña son obligatorios.')));
    }

    // Llamada al método del repositorio para iniciar sesión
    return repository.signInWithEmailAndPassword(email: email, password: password);
  }
}