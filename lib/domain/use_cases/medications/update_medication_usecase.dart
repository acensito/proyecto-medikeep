import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/medication_repository.dart';
import 'package:medikeep/infrastructure/services/local_notification_service.dart';


/// Caso de uso para actualizar un Medicamento existente y reprogramar sus notificaciones
class UpdateMedication {
  // Repositorio de medicamentos
  final MedicationRepository _repository;
  // Servicio de notificaciones locales
  final LocalNotificationService _notificationService;

  // Constructor
  UpdateMedication(this._repository, this._notificationService);

  // Método para llamar al caso de uso.
  // Retorna un Either con un Failure o void si tuvo éxito
  // Se le pasa el spaceId y el medicamento a actualizar
  Future<Either<Failure, void>> call({
    required String spaceId,
    required Medication medication,
  }) async {
    // Validaciones de negocio
    // Validación del nombre del medicamento
    if (medication.name.trim().isEmpty) {
      return Future.value(Left(const ValidationFailure('El medicamento debe tener un nombre.')));
    }
    // Validación del contenedor de almacenamiento
    if (medication.storageBoxId == null || medication.storageBoxId!.isEmpty) {
      return Future.value(Left(const ValidationFailure('El medicamento debe tener un contenedor.')));
    }
    // Validación de la fecha de caducidad
    if (medication.expiryDate == null) {
      return Future.value(Left(const ValidationFailure('La fecha de caducidad es obligatoria.')));
    }
    
    // Intentamos guardar la actualización en la BD
    final result = await _repository.updateMedication(spaceId: spaceId, medication: medication);

    // Gestionamos las notificaciones
    return result.fold(
      // Si recibimos un fallo, lo devolvemos
      (failure) => Left(failure),
      // Si tuvo éxito, reprogramamos la notificación del medicamento
      (_) async {
        try {
          // Cancelamos la notificación antigua (por si acaso ha cambiado la fecha)
          // Usamos el mismo ID (medication.id)
          await _notificationService.cancelNotification(medication.id.hashCode);

          // Programamos la nueva notificación con los datos actualizados
          await _notificationService.scheduledNotification(
            id: medication.id.hashCode, // ID único para la notificación
            title: 'Medicamento por caducar', // Título de la notificación
            body: 'El medicamento "${medication.name}" caduca el ${medication.expiryDate}.', // Cuerpo de la notificación
            date: medication.expiryDate!, // Fecha de caducidad del medicamento
            advanceTime: const Duration(days: 7),  // Notificar 7 días antes
          );
        } catch (e) {
          // Si falla la reprogramación, solo lo mostramos en consola, no queremos romper el flujo principal
          Console.err('Error al reprogramar notificación: $e');
        }
        // Devolvemos éxito
        return const Right(null);
      },
    );
  }
}