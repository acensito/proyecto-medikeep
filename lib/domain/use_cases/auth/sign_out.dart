import 'package:dartz/dartz.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/repositories/auth_repository.dart';
import 'package:medikeep/infrastructure/services/local_notification_service.dart';

/// Caso de uso para cerrar sesión del usuario
/// Primero limpia las notificaciones locales y luego cierra sesión en Firebase
class SignOut {
  // Repositorio de autenticación
  final AuthRepository _repository;
  // Servicio de notificaciones locales
  final LocalNotificationService _notificationService;

  // Constructor
  SignOut(this._repository, this._notificationService);

  // Método para ejecutar el caso de uso
  // Retorna un Either con un Failure o void si es exitoso
  Future<Either<Failure, void>> call() async{
    // Limpiamos todas las notificaciones locales del usuario actual
    // que tenía programadas
    try {
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      // Si falla, seguimos con el logout
      // pero registramos el error por consola/terminal
      Console.err('Error al limpiar notificaciones: $e');
    }

    // Cerramos sesión en Firebase Auth
    return _repository.signOut();
  }
}