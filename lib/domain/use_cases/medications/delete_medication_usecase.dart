import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/domain/repositories/medication_repository.dart';
import 'package:medikeep/infrastructure/services/local_notification_service.dart';

/// Caso de uso para eliminar un Medicamento y cancelar sus notificaciones.
class DeleteMedication {

  // Repositorio de medicamentos
  final MedicationRepository _repository;
  // Servicio de notificaciones locales
  final LocalNotificationService _notificationService;

  // Constructor
  DeleteMedication(this._repository, this._notificationService);

  // Método para llamar al caso de uso
  // Retorna un Either con un Failure o void si tuvo éxito
  Future<Either<Failure, void>> call({
    required String spaceId,
    required String medicationId,
  }) async {
    // Validaciones de negocio
    // Validación del ID del medicamento
    if (medicationId.trim().isEmpty) {
      return Future.value(Left(const ValidationFailure('El ID del medicamento no es válido.')));
    }

    // Llamada al repositorio para eliminar el medicamento
    // Se le pasa el spaceId y medicationId
    final result = await _repository.deleteMedication(
      spaceId: spaceId, 
      medicationId: medicationId
    );

    // Gestionamos el resultado
    return result.fold(
      // Si recibimos un fallo, lo devolvemos
      (failure) => Left(failure), 
      // Si tuvo éxito, cancelamos la notificación
      (_) async {
        try {
          // Usamos el mismo ID que usamos para crearla, el id.hashCode del medicamento
          await _notificationService.cancelNotification(medicationId.hashCode);
        } catch (e) {
          // Si falla la cancelación, solo lo mostramos en consola, no queremos romper el flujo principal
          Console.err('Error al cancelar notificación: $e');
        }

        // Devolvemos éxito
        return const Right(null);
      },
    );
  }
}