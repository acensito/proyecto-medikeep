import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';

/// Repositorio que define las operaciones relacionadas con los Spaces
/// La capa de dominio solo conoce este repositorio, no la implementación
abstract class SpaceRepository {
  // Devuelve un Stream con la lista de Spaces a los que
  // pertenece el usuario actual
  Stream<Either<Failure, List<Space>>> getSpaces();

  // Crea un nuevo Space con el [name] proporcionado
  // El usuario actual se añadirá automáticamente con el rol'owner' (propietario) 
  // de dicho Space
  Future<Either<Failure, void>> createSpace(String name);

  // Actualiza un Space existente (cambiar el nombre).
  Future<Either<Failure, void>> updateSpace(Space space);

  // Elimina un Space completo.
  // Solo un 'owner' puede realizar esta acción.
  Future<Either<Failure, void>> deleteSpace(String spaceId);

  // invita/Añade un nuevo usuario por su [userEmail] a un [spaceId]
  // con un [role] específico
  Future<Either<Failure, void>> inviteMember({
    required String spaceId,
    required String userEmail,
    required UserRole role,
  });

  // Elimina un [userIdToRemove] de un [spaceId].
  // Solo un 'owner' puede realizar esta acción.
  Future<Either<Failure, void>> removeMember({
    required String spaceId,
    required String userIdToRemove,
  });

  // Permite al usuario actual abandonar un [spaceId].
  // No se puede abandonar si es el último 'owner'.
  Future<Either<Failure, void>> leaveSpace(String spaceId);
}
