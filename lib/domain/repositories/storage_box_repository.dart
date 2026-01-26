import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';

/// Repositorio abstracto que gestiona las operaciones relacionadas con los StorageBox
/// La capa de dominio solo conoce este repositorio, no la implementación
abstract class StorageBoxRepository {
  // Devuelve un Stream con la lista de `StorageBox` de un `Space`
  Stream<Either<Failure, List<StorageBox>>> getStorageBoxes({
    required String spaceId,
  });

  // Crea un nuevo `StorageBox` en un `Space` concreto
  Future<Either<Failure, void>> createStorageBox({
    required String spaceId,
    required String name,
  });

  // Actualiza un `StorageBox` de un `Space` concreto
  Future<Either<Failure, void>> updateStorageBox({
    required String spaceId,
    required StorageBox storageBox,
  });

  // Elimina un `StorageBox` de un `Space` concreto
  Future<Either<Failure, void>> deleteStorageBox({
    required String spaceId,
    required String storageBoxId,
  });
}