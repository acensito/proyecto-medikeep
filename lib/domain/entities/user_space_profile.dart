import 'package:equatable/equatable.dart';
import 'package:medikeep/domain/entities/user_role.dart';

/// Entidad que representa el perfil básico de un usuario dentro de un Space.
/// Contiene la información necesaria para mostrar su nombre y avatar en
/// la interfaz de detalles del Space.
class UserSpaceProfile extends Equatable {
  // atributos
  final String id;
  final String name;
  final String? photoUrl;
  final UserRole role; // El rol que tiene en este Space (owner, editor, viewer)

  // constructor
  const UserSpaceProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.role,
  });

  // Lista de propiedades para comparación de objetos.
  @override
  List<Object?> get props => [id, name, photoUrl, role];
}