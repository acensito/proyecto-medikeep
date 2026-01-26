import 'package:medikeep/infrastructure/models/models.dart';

/// Clase abstracta que establece los metodos de manejo de datos en la 
/// base de datos local Firestore de la subcolección /spaces/{spaceId}/medications.
abstract class MedicationLocalDataSource {
  // Devuelve un Stream con la lista de 'MedicationModels' de un 'Space' específico.
  Stream<List<MedicationModel>> getMedications({required String spaceId});

  // Crea un nuevo 'Medication' en el inventario de un 'Space'.
  Future<void> addMedication({
    required String spaceId,
    required MedicationModel medication,
  });

  // Actualiza un 'Medication' existente en el inventario de un 'Space'
  Future<void> updateMedication({
    required String spaceId,
    required MedicationModel medication,
  });

  // Elimina un 'Medication' del inventario de un 'Space'
  Future<void> deleteMedication({
    required String spaceId,
    required String medicationId,
  });

  // Busca en inventario local por una consulta dada.
  // Utilizado para la busqueda primero en local.
  Future<List<MedicationModel>> searchLocalMedications({
    required String spaceId,
    required String query,
  });
}
