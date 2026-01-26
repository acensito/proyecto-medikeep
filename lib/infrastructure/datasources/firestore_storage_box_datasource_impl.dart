import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medikeep/infrastructure/models/models.dart';
import 'storage_box_remote_datasource.dart';

/// Implementación del DataSource de Container con Firestore.
class FirestoreStorageBoxDataSourceImpl implements StorageBoxRemoteDataSource {
  // Instancia de firebase
  final FirebaseFirestore _firestore;

  // Constructor
  FirestoreStorageBoxDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Helper para obtener una referencia a la subcolección /spaces/{spaceId}/storage_boxes
  CollectionReference<Map<String, dynamic>> _getStorageBoxCollection(
      {required String spaceId}) {
    return _firestore.collection('spaces').doc(spaceId).collection('storage_boxes');
  }

  /// Método para obtener un stream actualizado de los storagebox de un space dado por su ID
  /// Devuelve una lista ade StorageBox ordenados por nombre
  /// o devuelve una excepción generica.
  @override
  Stream<List<StorageBoxModel>> getStorageBoxes({required String spaceId}) {
    try {
      // Obtenemos la coleccion pasando el ID del space que nos interesa
      return _getStorageBoxCollection(spaceId: spaceId)
          .orderBy('name') // Ordenamos por nombre
          .snapshots()
          .map((snapshot) {
        return snapshot.docs // Mapeamos los resultados
            .map((doc) => StorageBoxModel.fromFirestore(doc))
            .toList(); // Lo pasamos a lista
      });
    } catch (e) {
      // Lanzamos un error generico
      throw Exception('Error al obtener los containers: ${e.toString()}');
    }
  }

  /// Método para crear un StorageBox. Se le pasa como parametros el ID
  /// del space interesado y el nombre del storagebox a crear
  @override
  Future<void> createStorageBox({
    required String spaceId,
    required String name,
  }) async {
    try {
      // Creamos un modelo temporal (sin ID) para usar su lógica toJsonForCreation
      final tempModel = StorageBoxModel(
        id: '', // El ID real lo asignará Firestore
        name: name,
        // createdAt y updatedAt serán añadidos por el 'toJsonForCreation'
      );
      // Agregamos el storagebox a la coleccion
      await _getStorageBoxCollection(spaceId: spaceId)
          .add(tempModel.toJsonForCreation());
    } catch (e) {
      // Lanzamos un error generico
      throw Exception('Error al crear el container: ${e.toString()}');
    }
  }

  /// Metodo que actualiza un storagebox. Recibe como parametros un ID
  /// de su space correspondiente y un [storageBoxModel] con los datos
  /// de storagebox a actualizar.
  @override
  Future<void> updateStorageBox({
    required String spaceId,
    required StorageBoxModel storageBoxModel,
  }) async {
    try {
      // Usamos el 'toJsonForUpdate' que solo actualiza el nombre y 'updatedAt'
      await _getStorageBoxCollection(spaceId: spaceId)
          .doc(storageBoxModel.id)
          .update(storageBoxModel.toJsonForUpdate());
    } catch (e) {
      // Lanzamos un error generico
      throw Exception('Error al actualizar el container: ${e.toString()}');
    }
  }

  /// Metodo que elimina un StorageBox concreto dado por el ID del space al
  /// que pertenece y el ID de dicho StorageBox a eliminar.
  @override
  Future<void> deleteStorageBox({
    required String spaceId,
    required String storageBoxId,
  }) async {
    try {
      // Esto solo borra el documento 'StorageBox'
      // Las subcolecciones (medications) quedarán huérfanas, por lo que se eliminan
      // mediante una Cloud Function de Firestore
      await _getStorageBoxCollection(spaceId: spaceId).doc(storageBoxId).delete();
    } catch (e) {
      // Lanzamos un error generico
      throw Exception('Error al eliminar el container: ${e.toString()}');
    }
  }
}
