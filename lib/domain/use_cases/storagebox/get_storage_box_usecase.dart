import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/storage_box_repository.dart';

/// Caso de uso para obtener el stream de StorageBoxes de un Space.
class GetStorageBox {
  // Repositorio de StorageBox
  final StorageBoxRepository repository;

  // Constructor
  GetStorageBox(this.repository);

  // Método para ejecutar el caso de uso
  // Retorna un Stream de Either con Failure o lista de StorageBox
  Stream<Either<Failure, List<StorageBox>>> call({required String spaceId}) {
    // Llama al repositorio para obtener los StorageBoxes
    return repository.getStorageBoxes(spaceId: spaceId);
  }
}