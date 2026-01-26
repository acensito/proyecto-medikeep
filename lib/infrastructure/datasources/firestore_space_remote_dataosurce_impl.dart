import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medikeep/infrastructure/datasources/space_remote_datasource.dart';
import 'package:medikeep/infrastructure/models/models.dart';


/// Implementación del DataSource de Space con Firestore.
class FirestoreSpaceDataSourceImpl implements SpaceRemoteDataSource {
  // Instancia de Firestore
  final FirebaseFirestore _firestore;

  // Constructor que permite inyectar una instancia de Firestore
  FirestoreSpaceDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Referencia a la colección /spaces
  CollectionReference<Map<String, dynamic>> get _spacesCollection {
    return _firestore.collection('spaces');
  }

  // Referencia a la colección /users
  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  /// Obtiene un Stream de listas de SpaceModel para un usuario dado por su ID.
  /// Filtra y devuelve una Lista de modelos Spaces donde el usuario es miembro.
  @override
  Stream<List<SpaceModel>> getSpaces(String userId) {
    // Buscamos en la colección 'spaces' donde el mapa 'members'
    // contenga una clave con el ID del usuario.
    return _spacesCollection
        .where('members.$userId', isNull: false)
        .snapshots()
        .map((snapshot) {
      // Convertimos cada documento Firestore a nuestro modelo SpaceModel
      return snapshot.docs
          .map((doc) => SpaceModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Metodo para obtener un Space por su ID.
  /// Devuelve el SpaceModel correspondiente.
  /// Lanza una excepción si no se encuentra.
  @override
  Future<SpaceModel> getSpaceById(String spaceId) async {
    try {
      // Obtenemos el documento por su ID
      final doc = await _spacesCollection.doc(spaceId).get();
      // Verificamos si el documento existe
      if (!doc.exists) {
        throw Exception('Space no encontrado');
      }
      // Usamos mapeamoso para convertir el documento a SpaceModel
      return SpaceModel.fromFirestore(doc);
    } catch (e) {
      // Lanzamos una excepción en caso de error
      throw Exception('Error al obtener Space por ID: ${e.toString()}');
    }
  }

  /// Crea un nuevo Space y actualiza el documento del usuario
  /// para incluir el ID del nuevo Space.
  /// Utiliza un WriteBatch para asegurar la atomicidad.
  /// Lanza una excepción en caso de error.
  @override
  Future<void> createSpace({
    required String userId,
    required String userName,
    required String spaceName,
  }) async {
    try {
      // Gerenamos un nuevo documento en la colección 'spaces'
      final newSpaceDoc = _spacesCollection.doc();
      
      // Creamos el nuevo SpaceModel con el usuario actual como 'owner'
      final newSpaceModel = SpaceModel(
        id: newSpaceDoc.id,
        name: spaceName,
        members: {userId: 'owner'}, // El rol se guarda como string
      );
      final batch = _firestore.batch();
      // Generamos una operación de escritura para crear el nuevo Space
      batch.set(newSpaceDoc, newSpaceModel.toJson());
      // Generamos una operación de escritura para actualizar el usuario
      final userDoc = _usersCollection.doc(userId);
      // Añadimos el ID del nuevo Space al array 'spaceIds' del usuario
      batch.update(userDoc, {'spaceIds': FieldValue.arrayUnion([newSpaceDoc.id])});

      // Ejecutamos el batch
      await batch.commit();
    } catch (e) {
      // Lanzamos una excepción en caso de error
      throw Exception('Error al crear el Space: ${e.toString()}');
    }
  }

  /// Actualiza un Space existente en Firestore
  /// Lanza una excepción en caso de error.
  @override
  Future<void> updateSpace(SpaceModel space) async {
    try {
      // Se actualiza un space existente
      await _spacesCollection.doc(space.id).update(space.toJson());
    } catch (e) {
      // Lanza una excepción
      throw Exception('Error al actualizar el Space: ${e.toString()}');
    }
  }

  /// Elimina un space dado por su ID.
  /// Esto solo borra el documento space. Las subcolecciones para evitar que
  /// queden huerfanas, se eliminarán con una cloud function.
  @override
  Future<void> deleteSpace(String spaceId) async {
    try {
      //Se elimina un space concreto por su ID
      await _spacesCollection.doc(spaceId).delete();
    } catch (e) {
      // Lanaza una excepción
      throw Exception('Error al eliminar el Space: ${e.toString()}');
    }
  }

  /// Invita un miembro a participar en un space dado por su ID.
  /// Se aporta el [AppUserModel] a invitar y su [role] en el space.
  /// Se complementa con la correspondiente Cloud Function para poder
  /// otorgar permisos y poder ver los datos de los invitados.
  /// Lanza una excepcion en caso de error.
  @override
  Future<void> inviteMember({
    required String spaceId,
    required AppUserModel invitedUser,
    required String role,
  }) async {
    try {
      //  Se abre un batch
      final batch = _firestore.batch();

      // Obtemos el documento del espacio concreto por su ID.
      final spaceDoc = _spacesCollection.doc(spaceId);
      // Actualizamos el documento de espacio en la seccion miembros con 
      // el usuario a invitar y su rol
      batch.update(spaceDoc, {'members.${invitedUser.id}': role});

      // Actualizamos el documento de usuario con los spaceIDs que posee
      final userDoc = _usersCollection.doc(invitedUser.id);
      batch.update(userDoc, {
        'spaceIds': FieldValue.arrayUnion([spaceId])
      });
      // Ejecutamos los cambios
      await batch.commit();
    } catch (e) {
      // Lanzamos error
      throw Exception('Error al invitar miembro: ${e.toString()}');
    }
  }
  /// Elimina un miembro de un space.
  /// Se complementa con la Cloud Function correspondiente para
  /// obtener los permisos firestore correspondientes
  @override
  Future<void> removeMember({
    required String spaceId,
    required String userIdToRemove,
  }) async {
    try {
      //Se abre una ejecucion por lotes
      final batch = _firestore.batch();

      // Eliminamos del mapa members del space dado el ID dado
      final spaceDoc = _spacesCollection.doc(spaceId);
      batch.update(spaceDoc, {'members.$userIdToRemove': FieldValue.delete()});

      // Eliminamos el spaceId de la lista del usuario invitado
      final userDoc = _usersCollection.doc(userIdToRemove);
      batch.update(userDoc, {
        'spaceIds': FieldValue.arrayRemove([spaceId])
      });
      // Efectuamos los cambios
      await batch.commit();
    } catch (e) {
      // Lanzamos mensaje de error
      throw Exception('Error al eliminar miembro: ${e.toString()}');
    }
  }

  /// Método que hace abandonar un usuario un space
  @override
  Future<void> leaveSpace({
    required String spaceId,
    required String userId,
  }) async {
    // La lógica es la misma que removeMember, pero le pasamos como parametro
    // el mismo id del usuario que abandona.
    await removeMember(spaceId: spaceId, userIdToRemove: userId);
  }
}
