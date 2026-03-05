import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';

/// Caso de uso que manda un correo de verificación de alta de cuenta
class SendEmailVerification {
  // atributos
  final AuthRepository repository;

  // constructor de la clase
  SendEmailVerification({required this.repository});

  // metodo que llama al caso de uso
  Future<Either<Failure, void>> call() {
    return repository.sendEmailVerification();
  }
}
