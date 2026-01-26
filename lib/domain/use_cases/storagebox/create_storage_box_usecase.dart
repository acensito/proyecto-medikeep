import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/repositories/storage_box_repository.dart';

/// Caso de uso para crear un nuevo StorageBox
class CreateStorageBox {
  // Repositorio de StorageBox
  final StorageBoxRepository repository;

  // Constructor
  CreateStorageBox(this.repository);

  // Método para ejecutar el caso de uso
  // Retorna un Either con Failure o void
  Future<Either<Failure, void>> call({
    required String spaceId,
    required String name,
  }) {
    // Validación simple del nombre
    // Asegura que el nombre no esté vacío
    if (name.trim().isEmpty) {
      return Future.value(Left(const ResourceCreationFailure('El nombre del StorageBox no puede estar vacío.')));
    }
    
    // Llama al repositorio para crear el StorageBox
    return repository.createStorageBox(spaceId: spaceId, name: name);
  }
}