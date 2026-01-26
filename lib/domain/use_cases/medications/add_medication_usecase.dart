import 'package:dartz/dartz.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/medication_repository.dart';
import 'package:medikeep/infrastructure/services/local_notification_service.dart';

/// Caso de uso para añadir un nuevo Medicamento al inventario.
class AddMedication {

  // Repositorio de medicamentos
  final MedicationRepository _repository;
  // Servicio de notificaciones locales
  final LocalNotificationService _notificationService;

  // Constructor
  AddMedication(this._repository, this._notificationService);

  // Llama al caso de uso.
  /// Retorna un Either con un Failure o void si tuvo éxito
  Future<Either<Failure, void>> call({
    required String spaceId,
    required Medication medication,
  }) async {
    // Validaciones de negocio
    // Validación del nombre del medicamento
    if (medication.name.trim().isEmpty) {
      return Left(const ValidationFailure('El medicamento debe tener un nombre.'));
    }
    // Validación del contenedor de almacenamiento
    if (medication.storageBoxId == null || medication.storageBoxId!.isEmpty) {
      return Left(const ValidationFailure('El medicamento debe asignarse a un contenedor.'));
    }
    // Validación de la fecha de caducidad
    if (medication.expiryDate == null) {
      return Left(const ValidationFailure('La fecha de caducidad es obligatoria.'));
    }

    // Llamada al repositorio para guardar el medicamento
    final result = await _repository.addMedication(
      spaceId: spaceId,
      medication: medication,
    );

    // Si falla, devolvemos el error tal cual
    if (result.isLeft()) {
      return result;
    }

    // Si tuvo éxito, programamos la notificación del medicamento
    try {
      await _notificationService.scheduledNotification(
        id: medication.id.hashCode, // ID único para la notificación
        title: 'Medicamento por caducar', // Título de la notificación
        body: 'El medicamento "${medication.name}" caduca el ${medication.expiryDate}.', // Cuerpo de la notificación
        date: medication.expiryDate!, // Fecha de caducidad del medicamento
        advanceTime: const Duration(days: 7), // Notificar 7 días antes
      );
      // Mostrar en consola que la notificación fue programada a efectos de depuración
      Console.log('Notificación programada para el medicamento ${medication.name}');
    } catch (e) {
      // Si falla la notificación, no queremos romper el flujo principal,
      // pero podríamos mostrarlo por consola. El medicamento sí se guardó.
      Console.err('Error al programar notificación: $e');
      return const Left(ValidationFailure('Error al programar la notificación.'));
    }
    // Devolvemos éxito
    return const Right(null);
  }
}
