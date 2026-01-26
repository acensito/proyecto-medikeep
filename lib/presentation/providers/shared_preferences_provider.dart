import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Clave para SharedPreferences que indica si el tutorial de bienvenida fue visto.
const String kOnboardingSeenKey = 'hasSeenOnboarding';
/// Provider global que almacena la instancia de SharedPreferences.
///
/// Este provider NO debe usarse directamente sin haber sido inicializado primero.
/// Se inicializa en el archivo `main.dart` usando `overrideWithValue` justo
/// antes de arrancar la aplicación.
///
/// Si intentas leerlo antes de que la app arranque, lanzará un error.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences no ha sido inicializado. Asegúrate de hacer el override en el main.dart.',
  );
});