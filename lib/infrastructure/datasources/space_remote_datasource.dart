import 'package:medikeep/infrastructure/models/models.dart';

/// Clase abstracta que define un datasource de Space.
abstract class SpaceRemoteDataSource {
  /// Devuelve un Stream con la lista de `SpaceModels` a los que
  /// pertenece el usuario actual (basado en [userId]).
  Stream<List<SpaceModel>> getSpaces(String userId);

  // Devuelve un 'Space' dado por su ID
  Future<SpaceModel> getSpaceById(String spaceId);

  /// Crea un nuevo 'Space' en Firestore y actualiza el documento del usuario.
  Future<void> createSpace({
    required String userId,
    required String userName,
    required String spaceName,
  });

  // Actualiza un 'Space' existente.
  Future<void> updateSpace(SpaceModel space);

  /// Elimina un 'Space'.
  /// NOTA: La lógica de borrado en cascada (StorageBoxes, Medications)
  /// se gestionará con una Cloud Function.
  Future<void> deleteSpace(String spaceId);

  /// Añade un [invitedUser] a un [spaceId] con un [role] (string).
  /// Esta operación es compleja y requiere actualizar tanto el Space como el User.
  Future<void> inviteMember({
    required String spaceId,
    required AppUserModel invitedUser, // Modelo del usuario a invitar
    required String role, // Rol como string (editor, viewer)
  });

  /// Elimina un miembro de un Space.
  Future<void> removeMember({
    required String spaceId,
    required String userIdToRemove,
  });

  /// Permite a un usuario abandonar un Space.
  Future<void> leaveSpace({
    required String spaceId,
    required String userId,
  });
}
