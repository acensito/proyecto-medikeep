import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/repositories/space_repository.dart';

/// Caso de uso para crear un nuevo Space
class CreateSpace {
  // Repositorio de Space
  final SpaceRepository repository;

  // Constructor que recibe el repositorio
  CreateSpace(this.repository);

  // Método que ejecuta el caso de uso
  // Recibe el nombre del Space a crear. Retorna un Either con Failure o void.
  Future<Either<Failure, void>> call(String name) {
    // Validaciones de negocio
    // Validar que el nombre no esté vacío
    if (name.trim().isEmpty) {
      return Future.value(Left(const ResourceCreationFailure('El nombre del Space no puede estar vacío.')));
    }
    // Llamar al repositorio para crear el Space
    return repository.createSpace(name);
  }
}