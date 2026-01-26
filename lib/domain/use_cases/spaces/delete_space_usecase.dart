import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/repositories/space_repository.dart';

// Caso de uso para eliminar un Space
class DeleteSpace {
  // Repositorio de Space
  final SpaceRepository repository;

  // Constructor
  DeleteSpace(this.repository);

  // Método que ejecuta el caso de uso
  // Recibe el ID del Space a eliminar. Retorna un Either con Failure o void
  Future<Either<Failure, void>> call(String spaceId) {
    // Validaciones de negocio
    // Validar que el ID no esté vacío
    if (spaceId.isEmpty) {
      return Future.value(Left(const ResourceCreationFailure('ID de Space no válido.')));
    }
    // Llamar al metodo del repositorio para eliminar el Space
    return repository.deleteSpace(spaceId);
  }
}