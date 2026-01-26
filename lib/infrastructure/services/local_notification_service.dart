import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Clase que maneja las notificaciones locales de los medicamentos.
/// Permite programar notificaciones locales para advertir de la
/// fecha de caducidad de un medicamento con antelacion suficiente
class LocalNotificationService {
  // Instanciamos el plugin de notificaciones locales
  final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Lanzamos un flag de control si esta inicializado
  bool _isInitialized = false;

  // INICIALIZACION 

  Future<void> initialize() async {
    // Comprueba si ya esta inicializado, asi evitamos reinicializaciones
    if (_isInitialized) return; 

    // Inicializamos la zona horaria
    tz.initializeTimeZones();

    // Obtenemos la zona horaria y el id de zona horaria
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    String timeZoneID = timezoneInfo.toString();
    // Mostramos mensaje en consola a modo debug
    Console.log("Local timezone: $timeZoneID");

    // Obtenemos el ID del timezone
    if (timeZoneID.startsWith('TimezoneInfo')) {
       final parts = timeZoneID.split(',');
       if (parts.isNotEmpty) {
         timeZoneID = parts[0].replaceAll('TimezoneInfo(', '').trim();
       }
    }
    
    try {
      // Establecemos el timezone local
      tz.setLocalLocation(tz.getLocation(timeZoneID));
      Console.log('🌍 Zona horaria configurada: $timeZoneID');
    } catch (e) {
      // Devolvemos error y dejamos hora en formato UTC
      Console.err('Error zona horaria: $e. Usando UTC.');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Configuración para Android
    const initAndroidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuracion de inicialización
    const initSettings = InitializationSettings(android: initAndroidSettings);

    // Inicialización del plugin
    await _notificationsPlugin.initialize(initSettings);

    // Cambiamos el estado del flag como inicializado
    _isInitialized = true;
  }

  // Metodo para solicitar permisos
  Future<void> requestPermissions() async {
    // Comprobamos si esta inicializado, en caso contrario procedemos
    if (!_isInitialized) {
      await initialize();
    }

    // Solicitamos permisos para Android (necesario en Android 13+)
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation
            <AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }


  // Mostrar notificacion
  // Configuración del canal de notificaciones
  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'notification_channel_id',
      'notification_channel',
      channelDescription: 'Canal de notificaciones para la app',
      importance: Importance.max,
      priority: Priority.high,
    );
    // devolvemos un canal de notificaciones
    return const NotificationDetails(android: androidDetails);
  }

  /// Mostrar una notificación
  /// Parametros minimos un [title], un [body]
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    // Comprobamos previamente si esta inicializado 
    // el sistema de notificaciones
    if (!_isInitialized) {
      await initialize();
    }
    // Muestra la notificacion
    await _notificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetails()
    );
  }

  // Mostrar notificación programada
  // Se le pasa como el anterior los parametros. En este caso le debemos pasar
  // obligatoriamente un date con la fecha de caducidad. Se puede cambiar el tiempo
  // de adelanto de notificacion
  Future<void> scheduledNotification({
    int id = 0,
    String? title,
    String? body,
    required DateTime date,
    Duration advanceTime = const Duration(days: 7) // Tiempo de adelanto (por defecto 1 semana)
  }) async {
    // Comprobamos si esta inicializado
    if (!_isInitialized) {
      await initialize();
    }

    // Obtener la hora actual en la zona horaria local
    final now = tz.TZDateTime.now(tz.local);
    Console.log('Fecha actual: $now');

    // Calcular la fecha de la notificación (fecha caducidad menos el tiempo de adelanto)
    final notificationDate = tz.TZDateTime(
      tz.local, 
      date.year, 
      date.month, 
      date.day, 
      10,  // Siempre a las 10:00 AM
      0
    ).subtract(advanceTime);

    // Verificar que la fecha de notificación no sea en el pasado, es decir, que la 
    // fecha de notificacion sea menor a hoy.
    // En este caso no se realiza alarma
    if (notificationDate.isBefore(now)) {
      // Se muestra unicamente mensaje por consola a modo debug
      Console.warn('No se establece alarma. La fecha de notificación está en el pasado: $notificationDate');
      return;
    }
    // Se programa la notificacion
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      notificationDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      //matchDateTimeComponents: DateTimeComponents.time //activandolo haría que se repita diariamente
    );
    // Mostamos mensaje de exito a nivel debug unicamente
    Console.log('Notificación programada para: $notificationDate');
  }

  // Metodo que cancela una notificacion dada por su id (id del medicamento en BD)
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    Console.log('🗑️ Notificación cancelada con ID: $id');
  }

  // Metodo que cancela todas las notificaciones programadas en el sistema
  Future<void> cancelAllNotifications() async {
    // Se comprueba si se encuentra inicializado
    if (!_isInitialized) {
      await initialize();
    }
    // Cancelamos todas las notificaciones
    await _notificationsPlugin.cancelAll();
    // Mostramos mensaje por consola unicamente a modo debug
    Console.log('🧹 Todas las notificaciones han sido canceladas.');
  }
}