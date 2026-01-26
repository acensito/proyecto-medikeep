import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';

/// Caso de uso para registrar un nuevo usuario con email y contraseña.
/// Realiza validaciones básicas antes de llamar al repositorio.
class RegisterWithEmail {
  // Repositorio de autenticación.
  final AuthRepository repository;

  // Constructor que recibe el repositorio.
  RegisterWithEmail(this.repository);

  // Método que ejecuta el caso de uso.
  // Retorna un Either con un Failure o un AppUser registrado
  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) {
    // Validaciones básicas de negocio
    // validación si el email esta vacío o no contiene '@'
    if (email.isEmpty || !email.contains('@')) {
      return Future.value(Left(const ValidationFailure('Email no válido.')));
    }
    // validación si la contraseña tiene al menos 6 caracteres
    if (password.length < 6) {
      return Future.value(Left(const ValidationFailure('La contraseña debe tener al menos 6 caracteres.')));
    }

    // Llamada al método del repositorio para registrar el usuario
    return repository.registerWithEmailAndPassword(email: email, password: password);
  }
}