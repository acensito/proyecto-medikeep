import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:medikeep/domain/entities/entities.dart';

/// Modelo de datos para 'Space' que sabe cómo comunicarse con Firestore.
/// Esta es una implementacióon manual
/// Refleja la estructura del documento en la colección /spaces/{spaceId}
class SpaceModel extends Equatable {
  // atributos
  final String id;
  final String name;
  // En el modelo, guardamos los roles como strings,
  // tal como irán en Firestore (ej: "owner", "editor").
  final Map<String, String> members; // memberID, role

  // constructor
  const SpaceModel({
    required this.id,
    required this.name,
    required this.members,
  });

  // -- METODOS DE MAPEOS DE DATOS --
  // Crea un SpaceModel a partir de un documento de Firestore.
  factory SpaceModel.fromFirestore(DocumentSnapshot doc) {

    // Obtenemos los datos y los pasamos a un Mapa
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Convertimos el mapa de 'members' de Firestore
    // (que es Map<String, dynamic>) a Map<String, String>
    final membersData = data['members'] as Map<String, dynamic>? ?? {};
    final membersMap = membersData.map(
      (key, value) => MapEntry(key, value as String),
    );
    // Mapeamos los datos a un StringModel, que se retorna
    return SpaceModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Nombre no encontrado',
      members: membersMap,
    );
  }

  /// Convierte este objeto Modelo a un Map que Firestore puede entender.
  Map<String, dynamic> toJson() {
    // No incluimos el 'id', ya que es el nombre del documento
    return {
      'name': name,
      'members': members, // El mapa de strings ya es compatible con JSON
    };
  }

  /// Crea un SpaceModel a partir de una Entidad Space que recibe por parametro
  /// Este se usa para escribir en la BD
  factory SpaceModel.fromEntity(Space space) {
    // Obtenemos una lista de perfiles de usuarios del space
    final List<UserSpaceProfile> resolvedMembers = space.members; 

    // Convertimos la lista de perfiles de vuelta al formato simple de Firestore (Map<String, String>)
    final Map<String, String> modelMembers = {};
    for (final profile in resolvedMembers) {
      // Usamos el ID como clave y el string de rol como valor
      modelMembers[profile.id] = profile.role.name; 
    }
    // Devolvemos el SpaceModel
    return SpaceModel(
      id: space.id,
      name: space.name,
      members: modelMembers,
    );
  }

  // Metodo para comparar campos entre objetos
  @override
  List<Object?> get props => [id, name, members];

  // Crea una copia de este objeto con los campos actualizados.
  SpaceModel copyWith({
    String? id,
    String? name,
    Map<String, String>? members,
  }) {
    return SpaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
    );
  }
}

