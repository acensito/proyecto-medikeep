import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';

/// Repositorio abstracto para la gestión de medicamentos.
abstract class MedicationRepository {

  // Obtiene un stream de la lista de medicamentos de un Space
  Stream<Either<Failure, List<Medication>>> getMedications({
    required String spaceId,
  });
  // Agrega un nuevo medicamento al inventario de un Space
  Future<Either<Failure, void>> addMedication({
    required String spaceId,
    required Medication medication,
  });
  // Actualiza un medicamento existente en el inventario de un Space
  Future<Either<Failure, void>> updateMedication({
    required String spaceId,
    required Medication medication,
  });
  // Elimina un medicamento del inventario de un Space
  Future<Either<Failure, void>> deleteMedication({
    required String spaceId,
    required String medicationId,
  });

  // --- MÉTODOS DE BÚSQUEDA ---

  /// Busca medicamentos SÓLO en el inventario local de un Space
  /// se, le pasa el spaceId para buscar en ese inventario específico
  Future<Either<Failure, List<Medication>>> searchLocalMedications({
    required String spaceId,
    required String query,
  });

  /// Busca medicamentos SÓLO en la fuente externa (API CIMA),
  /// NO en el inventario local
  Future<Either<Failure, List<Medication>>> searchExternalMedications({
    required String query,
  });
}

