import 'auth_remote_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:medikeep/core/errors/failure.dart';

/// Implementación del DataSource de Autenticación con FIREBASE.
/// Proporciona métodos para iniciar sesión, registrarse y cerrar sesión
/// utilizando Firebase Authentication y Google Sign-In.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // Atributos
  // Instancias de FirebaseAuth y GoogleSignIn
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  // Constructor
  AuthRemoteDataSourceImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // --- Métodos de la implementación---
  /// Método para obtener los cambios en el estado de autenticación.
  @override
  Stream<firebase_auth.User?> get authStateChanges {
    // Retornamos el stream de cambios de estado de autenticación
    return _firebaseAuth.authStateChanges();
  }

  /// Método para iniciar sesión con cuenta de Google.
  /// Lanza [ValidationFailure] para errores de validación y
  /// [ServerFailure] para otros errores
  @override
  Future<firebase_auth.User> signInWithGoogle() async {
    try {
      // Iniciamos el flujo de autenticación con Google
      final googleUser = await _googleSignIn.signIn();
      // Si el usuario cancela el inicio de sesión
      if (googleUser == null) {
        throw const ValidationFailure('El usuario canceló el inicio de sesión con Google.');
      }
      // Obtenemos las credenciales de autenticación de Google
      // y las usamos para iniciar sesión en Firebase
      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Iniciamos sesión en Firebase con las credenciales de Google
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      // Si no se obtiene el usuario de Firebase
      if (firebaseUser == null) {
        throw const ServerFailure('No se pudo obtener el usuario de Firebase.');
      }
      // Retornamos el usuario autenticado
      return firebaseUser;
    } catch (e) {
      // Lanzamos la excepción para que el repositorio la capture
      throw ServerFailure('Error en signInWithGoogle: ${e.toString()}');
    }
  }

  /// Método para cerrar sesión.
  /// Lanza [ServerFailure] en caso de error
  @override
  Future<void> signOut() async {
    // Cerramos sesión tanto en Google como en Firebase
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      // Lanzamos la excepción para que el repositorio la capture
      throw ServerFailure('Error al cerrar sesión: ${e.toString()}');
    }
  }

  /// Método para registrar un nuevo usuario con email y contraseña.
  /// Lanza [ValidationFailure] para errores de validación y
  /// [ServerFailure] para otros errores
  @override
  Future<firebase_auth.User> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Creamos un nuevo usuario con email y contraseña
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Obtenemos el usuario creado
      final firebaseUser = userCredential.user;
      // Verificamos y validamos que el usuario no sea nulo
      if (firebaseUser == null) {
        throw const ServerFailure('No se pudo crear el usuario.');
      }
      // Retornamos el usuario creado
      return firebaseUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Manejamos errores específicos de Firebase
      if (e.code == 'weak-password') {
        //Si la contraseña es débil
        throw const ValidationFailure('La contraseña es demasiado débil.');
      } else if (e.code == 'email-already-in-use') {
        //Si el email ya está registrado
        throw const ValidationFailure('Ya existe una cuenta con este email.');
      }
      // Lanzamos otros errores de servidor firebase
      throw ServerFailure('Error de registro: ${e.message}');
    } catch (e) {
      // Lanzamos errores desconocidos
      throw ServerFailure('Error desconocido en registro: ${e.toString()}');
    }
  }

  /// Método para iniciar sesión con email y contraseña.
  /// Lanza [ValidationFailure] para errores de validación y
  /// [ServerFailure] para otros errores
  @override
  Future<firebase_auth.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Iniciamos sesión con email y contraseña
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = userCredential.user;
      // Verificamos que el usuario no sea nulo
      if (firebaseUser == null) {
        throw const ServerFailure('No se pudo iniciar sesión.');
      }
      // Retornamos el usuario autenticado
      return firebaseUser;
      // Manejamos errores específicos de Firebase
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Usuario no encontrado
        throw const ValidationFailure('No existe usuario con ese email.');
      } else if (e.code == 'wrong-password') {
        // Contraseña incorrecta
        throw const ValidationFailure('Contraseña incorrecta.');
      } else if (e.code == 'invalid-credential') {
        // Credenciales inválidas
        throw const ValidationFailure('Email o contraseña incorrectos.');
      }
      // Lanzamos otros errores de servidor firebase
      throw ServerFailure('Error de inicio de sesión: ${e.message}');
    } catch (e) {
      // Lanzamos errores desconocidos
      throw ServerFailure('Error desconocido en login: ${e.toString()}');
    }
  }
  
  /// Método que permite enviar unemail de reset de password al email de la cuenta y poder
  /// iniciar el proceso de cambio de contraseña.
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // mandamos mediante firebase un password de reset del email
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // validaciones en caso de no existir el usuario
      if (e.code == 'user-not-found') {
        throw const ValidationFailure('No hay ningún usuario registrado con ese email.');
      }
      // validaciones en otros casos de error
      throw ServerFailure(e.message ?? 'Error al enviar el email de recuperación.');
    } catch (e) {
      // validaciones si falla el servicio firebase
      throw ServerFailure(e.toString());
    }
  }
  
  /// Método que permite actualizar el password
  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      // comprobamos si es el usuario actual
      final user = _firebaseAuth.currentUser;
      // validamos si no esta autenticado
      if (user == null) throw const ServerFailure('No hay usuario autenticado.');
      // en caso de validar, actualizamos el pass con la nueva contraseña
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // si existen errores, mostramos
      if (e.code == 'requires-recent-login') {
        throw const ValidationFailure('Por seguridad, debes cerrar sesión y volver a entrar para cambiar tu contraseña.');
      }
      // error general de actualizacion de contraseña
      throw ServerFailure(e.message ?? 'Error al actualizar la contraseña.');
    } catch (e) {
      // error si falla el servicio firebase
      throw ServerFailure(e.toString());
    }
  }
}
