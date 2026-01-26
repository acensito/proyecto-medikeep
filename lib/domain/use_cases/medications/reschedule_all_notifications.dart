import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/medication_repository.dart';
import 'package:medikeep/infrastructure/services/local_notification_service.dart';

/// Caso de uso para reprogramar TODAS las notificaciones de un usuario
/// Se debe llamar tras el Login para restaurar las alarmas en un dispositivo nuevo
class RescheduleAllNotifications {
  // Repositorio de medicamentos
  final MedicationRepository _repository;
  // Servicio de notificaciones locales
  final LocalNotificationService _notificationService;

  // Constructor
  RescheduleAllNotifications(this._repository, this._notificationService);

  // Método para llamar al caso de uso
  // Retorna void
  Future<void> call(AppUser user) async {
    // Log de inicio por terminal/consola
    Console.log('🔄 Iniciando resincronización de notificaciones para: ${user.name}');
    // Contador de notificaciones reprogramadas
    int count = 0;

    // Recorremos todos los Spaces del usuario
    for (final spaceId in user.spaceIds) {
      
      // Obtenemos los medicamentos de ese Space
      // (Usamos .first para obtener el valor actual del Stream como si fuera un Future)
      final result = await _repository.getMedications(spaceId: spaceId).first;

      // Si hay datos,los procesamos
      result.fold(
        // Si hay un fallo, lo logueamos en terminal
        (failure) => Console.err('Error al leer medicamentos de $spaceId: ${failure.message}'),
        // Si tenemos la lista de medicamentos, los procesamos
        (medications) async {
          // Recorremos todos los medicamentos
          for (final med in medications) {
            // Solo reprogramamos si tiene fecha y es futura (no esta caducado)
            if (med.expiryDate != null && med.expiryDate!.isAfter(DateTime.now())) {
              await _notificationService.scheduledNotification(
                id: med.id.hashCode,
                title: med.name,
                date: med.expiryDate!,
              );
              count++;
            }
          }
        },
      );
    }
    
    // Log indicando que hemos finalizado y cuántas alarmas se han programado
    Console.log('✅ Resincronización completada. $count alarmas programadas.');
  }
}