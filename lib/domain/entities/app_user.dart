import 'package:equatable/equatable.dart';

/// Clase entidad AppUser
/// Representa un usuario de la aplicacion
class AppUser extends Equatable {
  // atributos
  final String id;             // uid
  final String? email;         // email
  final String? name;          // nombre
  final String? photoUrl;      // url de foto perfil
  final bool? emailVerified;   // verificacion del email
  final List<String> spaceIds; // lista de ids de espacios

  // constructor
  const AppUser({
    required this.id,
    this.email,
    this.name, 
    this.photoUrl,
    this.emailVerified = false, //valor por defecto: no verificado
    this.spaceIds = const [], // valor por defecto: lista vacia
  });

  // Comparacion de valores entre objetos con Equatable
  @override
  List<Object?> get props => [id, email, name, photoUrl, spaceIds, emailVerified];

  /// Crea una copia de este objeto con los campos actualizados.
  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    bool? emailVerified,
    List<String>? spaceIds,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      spaceIds: spaceIds ?? this.spaceIds,
    );
  }
}