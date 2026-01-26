import 'package:equatable/equatable.dart';

/// Clase entidad Container
/// Representa una caja de almacenamiento con atributos como id, nombre,
class StorageBox extends Equatable {
  // atributos
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // constructor
  const StorageBox({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  /// Lista de propiedades para comparación de objetos.
  @override
  List<Object?> get props => [id, name, createdAt, updatedAt];

  // Crea una copia de este objeto con los campos actualizados.
  StorageBox copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StorageBox(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
