import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/user_role.dart';
import 'package:medikeep/domain/repositories/space_repository.dart';

/// Caso de uso para invitar a un miembro a un Space
class InviteMember {
  // Repositorio de Space
  final SpaceRepository repository;

  // Constructor
  InviteMember(this.repository);

  // Método que ejecuta el caso de uso
  // Recibe el ID del Space, email del usuario y rol. Retorna un Either con Failure o void
  Future<Either<Failure, void>> call({
    required String spaceId,
    required String userEmail,
    required UserRole role,
  }) {

    // Validaciones
    // Validar que el email no esté vacío y tenga formato válido
    if (userEmail.isEmpty || !userEmail.contains('@')) {
      return Future.value(Left(const ValidationFailure('Email no válido.')));
    }
    // Validar que el rol no sea Owner
    if (role == UserRole.owner) {
      return Future.value(Left(const ValidationFailure('No se puede invitar a un nuevo Owner.')));
    }
    // Llamar al repositorio para invitar al miembro
    return repository.inviteMember(
      spaceId: spaceId,
      userEmail: userEmail,
      role: role,
    );
  }
}