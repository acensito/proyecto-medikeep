import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:medikeep/domain/entities/entities.dart';

/// Modelo de datos para el `StorageBox` que sabe cómo comunicarse con Firestore.
/// Refleja la estructura del documento en la subcolección /spaces/{spaceId}/storage_boxes/{storageBoxId}
class StorageBoxModel extends Equatable {
  // atributos
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // constructor
  const StorageBoxModel({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  /// -- METODOS DE MAPEOS DE DATOS --
  /// Crea un StorageBoxModel a partir de un documento de Firestore.
  factory StorageBoxModel.fromFirestore(DocumentSnapshot doc) {
    // Obtiene los datos como un Mapa String, dynamic
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Devolvemos el Modelo con los datos mapeados
    return StorageBoxModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Nombre no encontrado',
      // Convertimos de forma segura los Timestamps de Firestore a DateTime de Dart
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Devuelve el Map para crear un nuevo documento en Firestore.
  Map<String, dynamic> toJsonForCreation() {
    return {
      'name': name,
      // Usamos ServerTimestamp para que Firestore ponga la fecha en el servidor
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Devuelve el Map para actualizar un documento existente en Firestore.
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Mapea este modelo a la entidad de dominio StorageBox
  StorageBox toEntity() {
    return StorageBox(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Para la igualdad de valor con Equatable
  @override
  List<Object?> get props => [id, name, createdAt, updatedAt];

  /// Crea una copia de este objeto con los campos actualizados.
  StorageBoxModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StorageBoxModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
