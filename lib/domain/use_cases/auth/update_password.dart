import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';

/// Caso de uso para actualizar la contraseña
class UpdatePassword {
  //atributos (repositorio)
  final AuthRepository repository;

  //constructor
  UpdatePassword(this.repository);

  // metodo que recibe un texto con el nuevo password y llama al metodo del repositorio correspondiente
  // valida previamente que el password cumpla las condiciones marcadas
  Future<Either<Failure, void>> call(String newPassword) {
    if (newPassword.length < 6) {
      return Future.value(Left(const ValidationFailure('La nueva contraseña debe tener al menos 6 caracteres.')));
    }
    // llamamos al metodo del repositorio
    return repository.updatePassword(newPassword);
  }
}