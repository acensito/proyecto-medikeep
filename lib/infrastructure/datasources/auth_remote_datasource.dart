import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Interfaz del DataSource de Autenticación Remota.
abstract class AuthRemoteDataSource {
  /// Método para obtener los cambios en el estado de autenticación.
  Stream<firebase_auth.User?> get authStateChanges;
  /// Método para iniciar sesión con cuenta de Google.
  Future<firebase_auth.User> signInWithGoogle();
  /// Método para registrarse con email y contraseña.
  Future<firebase_auth.User> registerWithEmailAndPassword({
    required String email,
    required String password,
  });
  /// Método para iniciar sesión con email y contraseña.
  Future<firebase_auth.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  /// Método para cerrar sesión.
  Future<void> signOut();

  /// Método que envia un Email para restablecer la contraseña
  Future<void> sendPasswordResetEmail(String email);

  /// Método que actualiza la contraseña de usuario actual (requiere un login reciente)
  Future<void> updatePassword(String newPassword);
}
