import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/storage_box_repository.dart';

/// Caso de uso para actualizar un StorageBox existente.
class UpdateStorageBox {
  // Repositorio de StorageBox
  final StorageBoxRepository repository;

  // Constructor
  UpdateStorageBox(this.repository);

  // Método para ejecutar el caso de uso
  // Según el espacio y la entidad StorageBox a actualizar 
  // Retorna un Either con Failure o void
  Future<Either<Failure, void>> call({
    required String spaceId,
    required StorageBox storageBox,
  }) {
    // Validaciones simples
    // Validamos si esta vacío el nombre
    if (storageBox.name.trim().isEmpty) {
      return Future.value(Left(const ResourceCreationFailure('El nombre del StorageBox no puede estar vacío.')));
    }
    // Llama al repositorio para actualizar el StorageBox
    return repository.updateStorageBox(spaceId: spaceId, storageBox: storageBox);
  }
}