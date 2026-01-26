
import 'package:medikeep/infrastructure/models/models.dart';

/// Clase abstracta que define los metodos del 
/// Datasource de la subcolección /spaces/{spaceId}/storage_boxes
abstract class StorageBoxRemoteDataSource {
  /// Devuelve un Stream con la lista de `StorageBoxModel` de un `Space` específico.
  Stream<List<StorageBoxModel>> getStorageBoxes({required String spaceId});

  /// Crea un nuevo 'StorageBox' en un `Space` con el [name] proporcionado.
  Future<void> createStorageBox({
    required String spaceId,
    required String name,
  });

  /// Actualiza un 'StorageBox' existente.
  Future<void> updateStorageBox({
    required String spaceId,
    required StorageBoxModel storageBoxModel,
  });

  /// Elimina un 'StorageBox' por su ID.
  Future<void> deleteStorageBox({
    required String spaceId,
    required String storageBoxId,
  });
}
