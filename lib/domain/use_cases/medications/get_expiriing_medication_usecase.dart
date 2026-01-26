import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/medication_repository.dart';

/// Caso de uso para obtener los medicamentos que están próximos a caducar.
/// Filtra la lista completa y devuelve solo los urgentes.
class GetExpiringMedications {
  // Repositorio de medicamentos
  final MedicationRepository repository;

  // Constructor
  GetExpiringMedications(this.repository);

  // Método para llamar al caso de uso.
  // Retorna un Stream de Either con un Failure o la lista de Medicamentos próximos a caducar
  // dentro de los próximos 3 meses. Necesita el spaceId para filtrar.
  Stream<Either<Failure, List<Medication>>> call({required String spaceId}) {
    // Obtenemos el stream de TODOS los medicamentos
    return repository.getMedications(spaceId: spaceId).map((result) {
      return result.map((medications) {
        // Filtramos y Ordenamos
        final now = DateTime.now(); // Obtenemos la fecha actual
        final threeMonthsFromNow = now.add(const Duration(days: 90)); // Fecha dentro de 3 meses

        // Filtramos: Solo los que caducan antes de 3 meses (o ya han caducado)
        final expiring = medications.where((med) { //Filstrado como consulta
          if (med.expiryDate == null) return false; // Si no tiene fecha de caducidad, lo ignoramos
          return med.expiryDate!.isBefore(threeMonthsFromNow); // Caduca antes de 3 meses
        }).toList(); // Convertimos a lista

        // Ordenamos: Los que caducan antes van primero
        expiring.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

        // Devolvemos la lista filtrada y ordenada
        return expiring;
      });
    });
  }
}