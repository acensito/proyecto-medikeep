import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/space_repository.dart';

/// Caso de uso para actualizar un Space existente
class UpdateSpace {
  // Repositorio de Space
  final SpaceRepository repository;

  // Constructor que recibe el repositorio
  UpdateSpace(this.repository);

  // Método que ejecuta el caso de uso
  // Recibe el Space a actualizar. Retorna un Either con Failure o void.
  Future<Either<Failure, void>> call(Space space) {
    // Validaciones de negocio
    // Validar que el nombre no esté vacío
    if (space.name.trim().isEmpty) {
      return Future.value(Left(const ResourceCreationFailure('El nombre del Space no puede estar vacío.')));
    }
    return repository.updateSpace(space);
  }
}