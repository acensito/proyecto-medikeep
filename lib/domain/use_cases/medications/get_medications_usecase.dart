import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/medication_repository.dart';

class GetMedications {
  /// Repositorio de medicamentos
  final MedicationRepository repository;

  // Constructor
  GetMedications(this.repository);

  // Método para llamar al caso de uso.
  // Retorna un Stream de Either con un Failure o la lista de Medicamentos
  Stream<Either<Failure, List<Medication>>> call({required String spaceId}) {
    // Llamada al repositorio para obtener el stream de TODOS los medicamentos
    return repository.getMedications(spaceId: spaceId);
  }
}