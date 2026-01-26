import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medication_model.dart';
import 'medication_local_datasource.dart';

/// Implementación del DataSource LOCAL de Medicamentos con FIRESTORE
class FirestoreMedicationLocalDataSourceImpl implements MedicationLocalDataSource {
  // Instancia de Firestore
  final FirebaseFirestore _firestore;

  // Constructor
  FirestoreMedicationLocalDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Helper para obtener una referencia a la subcolección /spaces/{spaceId}/medications
  CollectionReference<Map<String, dynamic>> _getMedicationsCollection({required String spaceId}) {
    // Retornamos la referencia a la colección de medicamentos del espacio dado
    return _firestore.collection('spaces').doc(spaceId).collection('medications');
  }

  /// Método para obtener el stream de medicamentos en tiempo real de un space dado por su id
  /// Devuelve un Stream de lista de [MedicationModel].
  /// Lanza una excepción si ocurre un error.
  /// El stream está ordenado por fecha de caducidad por defecto.
  @override
  Stream<List<MedicationModel>> getMedications({required String spaceId}) {
    try {
      // Obtenemos la colección de medicamentos y escuchamos los cambios en tiempo real
      return _getMedicationsCollection(spaceId: spaceId)
          .orderBy('expiryDate') // Ordenamos por caducidad por defecto
          .snapshots() // Escuchamos los snapshots en tiempo real
          .map((snapshot) { // Mapeamos los documentos a modelos
        return snapshot.docs
            .map((doc) => MedicationModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      // Manejo de errores genéricos
      throw Exception('Error al obtener los medicamentos: ${e.toString()}');
    }
  }

  /// Método para añadir un nuevo medicamento a un space dado por su id
  /// Recibe el [spaceId] y el [medication] a añadir.
  /// Lanza una excepción si ocurre un error.
  @override
  Future<void> addMedication({
    required String spaceId,
    required MedicationModel medication,
  }) async {
    try {
      // Añadimos el medicamento a la colección correspondiente
      // Pasamos el modelo a un mapeado JSON para Firestore
      await _getMedicationsCollection(spaceId: spaceId).add(medication.toJsonForFirestore());
    } catch (e) {
      // Manejo de errores genéricos
      throw Exception('Error al añadir el medicamento: ${e.toString()}');
    }
  }

  /// Método para actualizar un medicamento existente en un space dado por su id
  /// Recibe el [spaceId] y el [medication] a actualizar. 
  /// Lanza una excepción si ocurre un error.
  @override
  Future<void> updateMedication({
    required String spaceId,
    required MedicationModel medication,
  }) async {
    try {
      // Actualizamos el medicamento en la colección correspondiente de un documento específico
      // Pasamos el modelo a un mapeado JSON para Firestore
      await _getMedicationsCollection(spaceId: spaceId).doc(medication.id).update(medication.toJsonForFirestore());
    } catch (e) {
      // Manejo de errores genéricos
      throw Exception('Error al actualizar el medicamento: ${e.toString()}');
    }
  }

  /// Método para eliminar un medicamento existente en un space dado por su id
  /// Recibe el [spaceId] y el [medicationId] a eliminar.
  /// Lanza una excepción si ocurre un error.
  @override
  Future<void> deleteMedication({
    required String spaceId,
    required String medicationId,
  }) async {
    try {
      // Eliminamos el medicamento en la colección correspondiente de un documento específico
      await _getMedicationsCollection(spaceId: spaceId).doc(medicationId).delete();
    } catch (e) {
      // Manejo de errores genéricos
      throw Exception('Error al eliminar el medicamento: ${e.toString()}');
    }
  }

  /// Método para buscar medicamentos almacenados localmente en un space dado por su id
  /// Recibe el [spaceId] y el [query] de búsqueda.
  /// Devuelve una lista de [MedicationModel] que coinciden con la búsqueda.
  /// Lanza una excepción si ocurre un error.
  @override
  Future<List<MedicationModel>> searchLocalMedications({
    required String spaceId,
    required String query,
  }) async {
    try {
      // Normalizamos a minúsculas y quitamos espacios extra
      final normalizedQuery = query.toLowerCase().trim();

      // Obtenemos la colección completa (snapshot de una sola vez)
      // Es rapido para colecciones pequeñas/medianas
      final querySnapshot = await _getMedicationsCollection(spaceId: spaceId).get();

      // Mapeamos los documentos al modelo y en lista
      final allDocs = querySnapshot.docs
          .map((doc) => MedicationModel.fromFirestore(doc))
          .toList();

      // Filtramos los resultados con una consulta local
      final filteredDocs = allDocs.where((med) {
        // Buscamos por nombre (contiene). Pasamos todo a minúsculas
        final nameMatch = med.name.toLowerCase().contains(normalizedQuery);
        // También buscamos por CN si existe, por si el usuario escanea algo que ya tiene
        final cnMatch = med.cn?.contains(normalizedQuery) ?? false;
        // Devolvemos true si hay alguna coincidencia
        return nameMatch || cnMatch;
      }).toList(); // Convertimos el iterable a lista

      // Devolvemos los resultados filtrados
      return filteredDocs;
    } catch (e) {
      // Manejo de errores genéricos
      throw Exception('Error al buscar medicamentos locales: ${e.toString()}');
    }
  }
}