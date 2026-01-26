import 'package:medikeep/infrastructure/models/models.dart';
/// Clase abstracta que define los metodos de negocio del
/// Datasource de la coleccion /users
abstract class UserRemoteDataSource {
  // Busca un usuario en la colección /users por su [email].
  // Esencial para la funcionalidad de "Invitar Miembro".
  Future<AppUserModel?> getUserByEmail(String email);

  // Obtiene un documento de usuario por su [ID].
  Future<AppUserModel> getUserById(String id);

  // Crea un nuevo documento de usuario en /users/{userId}
  // Se llama después de un registro exitoso.
  Future<void> createUser(AppUserModel user);

  /// Actualiza el documento de un usuario (ej: al unirse a un Space).
  Future<void> updateUser(AppUserModel user);
}
