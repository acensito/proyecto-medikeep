import 'package:equatable/equatable.dart';
import 'user_role.dart';
import 'user_space_profile.dart'; 

/// Clase entidad Space
/// Representa un espacio de trabajo o colaboracion
class Space extends Equatable {
  // atributos
  final String id;
  final String name;

  // miembros de este espacio
  final List<UserSpaceProfile> members; 

  // constructor
  const Space({
    required this.id,
    required this.name,
    required this.members,
  });

  /// Obtiene el rol de un miembro dado su ID de usuario.
  UserRole? getMemberRole(String? userId) {
    if (userId == null) return null;

    final profileMatches = members.where((member) => member.id == userId);
    if (profileMatches.isEmpty) return null;

    final profile = profileMatches.first;
    final rawRole = profile.role;

    return rawRole;
  }


  // Lista de propiedades para comparacion con Equatable
  @override
  List<Object?> get props => [id, name, members];

  // Crea una copia de este objeto con los campos actualizados.
  Space copyWith({
    String? id,
    String? name,
    List<UserSpaceProfile>? members,
  }) {
    return Space(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
    );
  }
}