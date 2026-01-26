import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Clase Console para logging en consola con colores y niveles
/// Utiliza dart:developer para mejor integración
/// Reemplaza print en desarrollo y añade niveles en producción,
/// lo que facilita la depuración, el monitoreo y el analisis, evitando
/// mensajes de warning innecesarios en producción.
/// 
/// Niveles: debug, info, warning, error
class Console {
  
  // Colores ANSI para terminal (funciona en VS Code, Android Studio, terminal)
  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _white = '\x1B[37m';
  
  /// Niveles de log
  static const Level debug = Level('DEBUG', _blue, 0);
  static const Level info = Level('INFO', _green, 1);
  static const Level warning = Level('WARNING', _yellow, 2);
  static const Level error = Level('ERROR', _red, 3);
  
  /// Configuración
  static Level minLevel = kDebugMode ? debug : warning;
  
  /// Método principal de logging
  static void _log(Level level, dynamic message, {dynamic error, StackTrace? stackTrace}) {
    if (level.priority < minLevel.priority) return;
    
    final time = DateTime.now().toIso8601String().substring(11, 23);
    final coloredLevel = '${level.color}[${level.name}]$_reset';
    
    // Mensaje principal
    developer.log(
      '$coloredLevel $_white$time$_reset $message',
      name: 'APP',
      level: level.priority,
      error: error,
      stackTrace: stackTrace,
    );
    
    // Stack trace para errores
    if (error != null && stackTrace != null && level == error) {
      developer.log('$coloredLevel StackTrace: $stackTrace', name: 'APP');
    }
  }
  
  /// Métodos de conveniencia
  
  /// Para depuración (reemplaza print)
  static void log(dynamic message) => _log(debug, message);
  
  /// Información
  static void inf(dynamic message) => _log(info, message);
  
  /// Advertencias
  static void warn(dynamic message, {dynamic error}) => 
      _log(warning, message, error: error);
  
  /// Errores
  static void err(dynamic message, {dynamic error, StackTrace? stackTrace}) => 
      _log(Console.error, message, error: error, stackTrace: stackTrace);
  
  /// Método que funciona exactamente como print pero con color
  static void print(dynamic message) => _log(debug, message);
}

/// Clase auxiliar para niveles
class Level {
  final String name;
  final String color;
  final int priority;
  
  const Level(this.name, this.color, this.priority);
}