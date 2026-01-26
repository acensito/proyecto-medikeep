import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';

/// Caso de uso para mandar un email de password reset
class SendPasswordResetEmail {
  // atributos (repositorio)
  final AuthRepository repository;

  // constructor
  SendPasswordResetEmail(this.repository);

  // metodo que recibe un email y llama al metodo correspondiente para mandar un email
  // valida previamente que sea un email válido/correcto
  Future<Either<Failure, void>> call(String email) {
    if (email.isEmpty || !email.contains('@')) {
      return Future.value(Left(const ValidationFailure('Por favor, introduce un email válido.')));
    }
    // llamamos al metodo del respositorio
    return repository.sendPasswordResetEmail(email);
  }
}