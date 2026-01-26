import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/medication_repository.dart';

/// Caso de uso para buscar medicamentos SÓLO en el inventario local del usuario.
/// No busca en la API externa.
class SearchLocalMedications {
  // Repositorio de medicamentos
  final MedicationRepository repository;

  // Constructor
  SearchLocalMedications(this.repository);

  // Método para llamar al caso de uso.
  // Retorna un Future de Either con un Failure o la lista de Medicamentos encontrados
  // Se le pasa el spaceId y el query de búsqueda (string con el nombre del medicamento)
  Future<Either<Failure, List<Medication>>> call({
    required String spaceId,
    required String query,
  }) {
    // Validaciones de negocio
    // Si el query está vacío, devolvemos una lista vacía (sin resultados)
    if (query.trim().isEmpty) {
      return Future.value(const Right([]));
    }
    // Llama al método específico del repositorio
    return repository.searchLocalMedications(spaceId: spaceId, query: query);
  }
}