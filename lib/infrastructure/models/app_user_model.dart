import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:medikeep/domain/entities/entities.dart';

/// Modelo de datos para el Usuario que sabe cómo comunicarse con Firestore.
/// Esta es una implementación manual.
/// Refleja la estructura del documento en la colección /users/{userId}
class AppUserModel extends Equatable {
  // atributos
  final String id;
  final String? email;
  final String? name;
  final String? photoUrl;
  final List<String>
  spaceIds; // Listas de IDs de espacios a los que pertenece el usuario

  // constructor
  const AppUserModel({
    required this.id,
    this.email,
    this.name,
    this.photoUrl,
    required this.spaceIds,
  });

  /// -- METODOS DE MAPEO DE DATOS --
  /// Crea un AppUserModel a partir de un documento de Firestore
  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    // Obtenemos los datos, asegurándonos de que no sean nulos
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Firestore devuelve las listas como List<dynamic>
    // por lo que se convierte a List<String>
    final spaceIdsList =
        (data['spaceIds'] as List<dynamic>?)
            ?.map((id) => id as String) // Convertimos cada elemento a String
            .toList() ??
        []; // Si el campo no existe o es nulo, damos una lista vacía

    // Retornamos una instancia del modelo con los datos mapeados
    return AppUserModel(
      id: doc.id, // El ID viene del propio documento, no de los datos internos
      email: data['email'] as String?,
      name: data['name'] as String?,
      photoUrl: data['photoUrl'] as String?,
      spaceIds: spaceIdsList,
    );
  }

  /// -- MAPPER INVERSO DEL MODELO A FIRESTORE JSON --
  /// Convierte este objeto Modelo a un Map que Firestore puede entender.
  /// No incluimos el 'id', ya que es el nombre del documento.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'spaceIds': spaceIds,
    };
  }

  /// -- MAPPER DEL MODELO A LA ENTIDAD --
  /// Mapea este modelo a una entidad domimio [AppUser]
  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      name: name,
      photoUrl: photoUrl,
      spaceIds: spaceIds,
    );
  }

  /// Para la igualdad de valor con Equatable
  @override
  List<Object?> get props => [id, email, name, photoUrl, spaceIds];

  /// Crea una copia de este objeto con los campos actualizados.
  AppUserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    List<String>? spaceIds,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      spaceIds: spaceIds ?? this.spaceIds,
    );
  }
}
