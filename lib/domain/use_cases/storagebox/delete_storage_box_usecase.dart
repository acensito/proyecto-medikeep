import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/repositories/storage_box_repository.dart';

/// Caso de uso para eliminar un StorageBox
class DeleteStorageBox {
  // Repositorio de StorageBox
  final StorageBoxRepository repository;
  // Constructor
  DeleteStorageBox(this.repository);

  // Método para ejecutar el caso de uso
  // Según el espacio y el ID del StorageBox a eliminar
  // Retorna un Either con Failure o void
  Future<Either<Failure, void>> call({
    required String spaceId,
    required String storageBoxId,
  }) {
    // Validación simple del ID del StorageBox
    // Asegura que el ID no esté vacío
    if (storageBoxId.trim().isEmpty) {
      return Future.value(Left(const ResourceCreationFailure('El ID del StorageBox no es válido.')));
    }
    // Llama al repositorio para eliminar el StorageBox
    return repository.deleteStorageBox(spaceId: spaceId, storageBoxId: storageBoxId);
  }
}