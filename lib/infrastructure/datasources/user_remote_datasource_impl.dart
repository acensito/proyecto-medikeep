import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medikeep/infrastructure/models/models.dart';
import 'user_remote_datasource.dart';


/// Implementacion del DATASOURCE de usuario con FIRESTORE
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  // Intancia de firebase
  final FirebaseFirestore _firestore;

  // Constructor
  UserRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Helper de referencia a la colección /users
  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  /// Metodo que devuelve un usuario dado su email
  @override
  Future<AppUserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      // Devuelve null si no se encuentran resultados
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      // Devuelve un [AppUserModel] si se encuentra resultado
      return AppUserModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      // Lanzamos error generico
      throw Exception('Error al buscar usuario por email: ${e.toString()}');
    }
  }

  /// Metodo que obtiene un usuario dado su ID
  /// Devuelve un [AppUserModel] en caso positivo o un [Exception] en
  /// caso de error.
  @override
  Future<AppUserModel> getUserById(String id) async {
    try {
      // Obtenemos el documento
      final docSnapshot = await _usersCollection.doc(id).get();
      // Si no existe, devolvemos error
      if (!docSnapshot.exists) {
        throw Exception('Usuario no encontrado en la base de datos.');
      }
      // Devolvemos un AppUser en caso positivo
      return AppUserModel.fromFirestore(docSnapshot);
    } catch (e) {
      // Lanzamos un error generico 
      throw Exception('Error al obtener usuario por ID: ${e.toString()}');
    }
  }

  /// Metodo para crear un usuario. Recibe como parametro un [AppUserModel].
  /// lanza un [Exception] en caso de error
  @override
  Future<void> createUser(AppUserModel user) async {
    try {
      // Usamos 'set' con el ID del usuario de Auth como nombre del documento
      await _usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      // Lanzamos un error generico
      throw Exception('Error al crear el usuario en la base de datos: ${e.toString()}');
    }
  }
  /// Método que actualiza un usuario. Recibe como parametro un [AppUserModel]
  /// con los datos actualizados.
  /// Lanza un [Exception] en caso de error.
  @override
  Future<void> updateUser(AppUserModel user) async {
    try {
      // Actualizamos el documento con el ID del usuario y los datos en JSON
      await _usersCollection.doc(user.id).update(user.toJson());
    } catch (e) {
      // Lanzamos un error generico
      throw Exception('Error al actualizar el usuario: ${e.toString()}');
    }
  }
}
