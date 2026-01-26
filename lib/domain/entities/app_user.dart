import 'package:equatable/equatable.dart';

/// Clase entidad AppUser
/// Representa un usuario de la aplicacion
class AppUser extends Equatable {
  // atributos
  final String id;
  final String? email;
  final String? name; 
  final String? photoUrl;
  // lista de id de los espacios a los que pertenece el usuario
  final List<String> spaceIds;

  // constructor
  const AppUser({
    required this.id,
    this.email,
    this.name, 
    this.photoUrl,
    this.spaceIds = const [], // valor por defecto: lista vacia
  });

  // Comparacion de valores entre objetos con Equatable
  @override
  List<Object?> get props => [id, email, name, photoUrl, spaceIds];

  /// Crea una copia de este objeto con los campos actualizados.
  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    List<String>? spaceIds,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      spaceIds: spaceIds ?? this.spaceIds,
    );
  }
}

