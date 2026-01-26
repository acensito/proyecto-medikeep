import 'package:flutter/material.dart';

/// Clase para gestionar el tema y los colores de la aplicación.
class AppTheme {
  // --- COLORES BASE (Paleta "Farmacia Moderna") ---
  
  // Un verde azulado (Teal) profesional y moderno
  static const Color _primaryColor =Color(0xFF00799D); // Color(0xFF009688); 
  
  // Un tono más oscuro para variantes
  static const Color _primaryVariant = Color(0xFF00796B);

  // Un color secundario para acciones flotantes o destacados (Naranja suave)
  static const Color _secondaryColor = Color(0xFFFF9800);

  // Color de fondo principal
  static const Color _backgroundColor = Color(0xFFF5F7FA); //Color(0xFFEEEEEE);

  // Color blanco puro para tarjetas y superficies
  static const Color _surfaceColor = Colors.white;

  // --- CORRECCIÓN: Hacemos públicos estos colores para evitar advertencias ---
  // Colores de estado (Semáforo) - Ahora sin guion bajo '_'
  static const Color errorColor = Color(0xFFD32F2F); // Rojo
  static const Color warningColor = Color(0xFFFFA000); // Ámbar
  static const Color successColor = Color(0xFF388E3C); // Verde
  // --------------------------------------------------------------------------

  /// Devuelve el [ThemeData] configurado para la aplicación.
  ThemeData getTheme() {
    // Usamos Material 3 y generamos el esquema de colores a partir de nuestra semilla
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      primary: _primaryColor,
      secondary: _secondaryColor,
      error: errorColor, // Actualizado para usar la variable pública
      brightness: Brightness.light, // Tema claro por defecto
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // --- PERSONALIZACIÓN DE COMPONENTES ---

      scaffoldBackgroundColor: _backgroundColor,

      //AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: _primaryColor,
        foregroundColor: _surfaceColor,
        elevation: 0, // Sin sombra (diseño plano)
        scrolledUnderElevation: 2, // Sutil sombra al hacer scroll
      ),

      //Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _surfaceColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Bordes redondeados modernos
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      //Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Más cuadrado que redondo
        ),
      ),

      //Input Decorations (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50, // Fondo muy suave
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      //Card Theme
      cardTheme: CardThemeData(
        color: _surfaceColor,
        surfaceTintColor: _surfaceColor, // Evita el tinte rosa de Material 3
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      //Fuentes principales, colores y estilos por defecto
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: _primaryVariant,
        ),
      ),
    );
  }
}