import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/app_user.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';

/// Caso de uso para obtener un usuario por su ID
/// Retorna un Either con Failure o AppUser
class GetUserById {
  // Repositorio de autenticación
  final AuthRepository repository;
  // Constructor
  GetUserById(this.repository);

  // Método que ejecuta el caso de uso
  // Recibe el ID del usuario. Retorna un Either con Failure o AppUser
  Future<Either<Failure, AppUser>> call(String userId) {
    // Llamar al repositorio para obtener el usuario por ID
    return repository.getUserById(userId); 
  }
}