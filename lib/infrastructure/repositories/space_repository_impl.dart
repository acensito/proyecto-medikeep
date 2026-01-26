import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/core/logging/console.dart'; 
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/space_repository.dart';
import 'package:medikeep/infrastructure/datasources/space_remote_datasource.dart';
import 'package:medikeep/infrastructure/datasources/user_remote_datasource.dart';
import 'package:medikeep/infrastructure/models/models.dart'; 

/// Implementacion del repositorio de Space
/// Orquesta con el datasource local con los usuarios 
class SpaceRepositoryImpl implements SpaceRepository {
  // atriibutos
  final SpaceRemoteDataSource spaceDataSource;
  final UserRemoteDataSource userDataSource;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  // Constructor
  SpaceRepositoryImpl({
    required this.spaceDataSource,
    required this.userDataSource,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  // Getter que devuelve el usuario actual
  String? get _currentUserId => _auth.currentUser?.uid;

  // Metodo que pasa a UserSpaceProfile el mapa de miembros de un space.
  // De esta manera "puenteamos", los permisos de usuario para ver nombre y perfil
  // en el detalle de un space.
  Future<List<UserSpaceProfile>> _resolveMemberProfiles(
    Map<String, String> membersMap,
  ) async {
    // Pasamos a lista las key de cada miembro
    final userIds = membersMap.keys.toList();
    // si esta vacio, devolvemos un conjunto vacio
    if (userIds.isEmpty) return [];

    // Retornamos una lista de AppUserModel obteniendo los mismos con los id 
    // de los usuarios
    final List<Future<AppUserModel>> userFetchFutures = userIds.map((uid) {
      return userDataSource.getUserById(uid);
    }).toList();

    // Se espera a que todos los usuarios esten listos
    final List<AppUserModel> userModels = await Future.wait(userFetchFutures);

    // Abrimos una lista de perfiles
    final List<UserSpaceProfile> profiles = [];

    // Procesamos los modelos en perfiles
    for (final userModel in userModels) {
      try {
        // Convierte el modelo a entidad
        final user = userModel.toEntity();
        final roleString = membersMap[user.id] ?? 'viewer';
        final role = UserRole.values.firstWhere(
          (e) => e.name == roleString,
          orElse: () => UserRole.viewer,
        );

        profiles.add(UserSpaceProfile(
          id: user.id,
          name: user.name ?? 'Sin Nombre',
          photoUrl: user.photoUrl,
          role: role,
        ));
      } catch (e) {
        Console.err("Error al convertir perfil de miembro: ${e.toString()}");
      }
    }
    // Devuelve una lista de perfiles
    return profiles;
  }

  // Metodo que obtiene una lista de espacios
  @override
  Stream<Either<Failure, List<Space>>> getSpaces() {
    // obtenemos el ID del usuario actual
    final userId = _currentUserId;
    if (userId == null) { // si no hay usuario
      return Stream.value(Left(const ServerFailure('Usuario no autenticado.')));
    }

    // Obtenemos el stream de SpaceModels desde el DataSource
    final spaceModelStream = spaceDataSource.getSpaces(userId);

    // Definimos el Transformador para convertir Modelos a Entidades con Perfiles Resueltos
    final transformer = StreamTransformer<List<SpaceModel>, Either<Failure, List<Space>>>.fromHandlers(
      // Se lanza cada vez que se lanza un stream de datos
      handleData: (spaceModels, sink) async {
        try {
          // Por cada SpaceModel, resolvemos sus miembros
          final List<Future<Space>> resolvedSpacesFutures = spaceModels.map((model) async {
            // Resolvemos los perfiles (UIDs -> Name/Photo)
            final membersProfiles = await _resolveMemberProfiles(model.members);

            // Construimos la entidad Space con los perfiles completos
            return Space(
              id: model.id,
              name: model.name,
              members: membersProfiles,
            );
          }).toList();

          // Esperamos a que todos los Spaces se resuelvan
          final resolvedSpaces = await Future.wait(resolvedSpacesFutures);
          
          // Emitimos el resultado exitoso
          sink.add(Right(resolvedSpaces));

        } catch (e) {
          // Capturamos errores durante el mapeo (si _resolveMemberProfiles falla)
          sink.add(Left(ServerFailure('Error al procesar datos de Space: ${e.toString()}')));
        }
      },
      handleError: (error, stackTrace, sink) {
        // Manejamos errores de nivel Stream (por ejemplo, un fallo de conexión con Firestore)
        sink.add(Left(ServerFailure('Error de conexión a Space: ${error.toString()}')));
      },
    );

    // Aplicamos el transformador al stream y lo marcamos como broadcast
    return spaceModelStream.transform(transformer).asBroadcastStream();
  }

  // Metodo que crea un space dado una cadena con el nombre a otorgar
  @override
  Future<Either<Failure, void>> createSpace(String name) async {
    try {
      // Usuario actual
      final userId = _currentUserId;
      if (userId == null) { // si no hay usuario
        return Left(const AuthFailure('Usuario no autenticado.'));
      }
      
      // El DataSource se encarga de la lógica atómica (crear Space y actualizar User)
      await spaceDataSource.createSpace(
        userId: userId,
        spaceName: name,
        userName: '', 
      );
      return const Right(null); // Devolvemos exito
    } catch (e) {
      // Devolvemos error
      return Left(ServerFailure(e.toString()));
    }
  }

  // Metodo que actualiza un space dado
  @override
  Future<Either<Failure, void>> updateSpace(Space space) async {
    try {
      // Convertimos la Entidad de dominio a un Modelo de infraestructura
      final spaceModel = SpaceModel.fromEntity(space);
      // Esperamos a actualizar el modelo
      await spaceDataSource.updateSpace(spaceModel);
      return const Right(null); // Devolvemos exito
    } catch (e) {
      // Devolvemos un error
      return Left(ServerFailure(e.toString()));
    }
  }

  // Metodo que elimina un space dado por su ID
  // Este debe complementarse con una Cloud Function para realizar
  // el borrado en cascada y no dejar documentos huerfanos
  @override
  Future<Either<Failure, void>> deleteSpace(String spaceId) async {
    try {
      await spaceDataSource.deleteSpace(spaceId);
      return const Right(null); //Devolvemos exito
    } catch (e) {
      // Devolvemos error
      return Left(ServerFailure(e.toString()));
    }
  }

// Metodo que invita un usuario como miembro de un space
// Por motivos de permisos en base de datos, esto debe hacerse desde una
// Cloud Function
@override
  Future<Either<Failure, void>> inviteMember({
    required String spaceId,
    required String userEmail,
    required UserRole role,
  }) async {
    try {
      
      // Se llama a la Cloud Function HTTPS para ejecutar la invitación atómica
      final callable = _functions.httpsCallable('inviteMemberToSpace');
      
      // Pasamos los datos que la CF necesita
      final result = await callable.call({
        'spaceId': spaceId,
        'invitedEmail': userEmail,
        'role': role.name,
      });

      // La Cloud Function devuelve un mapa con éxito o fallo
      if (result.data['success'] == true) {
        return const Right(null);
      } else {
         // Si llega aquí, significa que la CF devolvió un error de negocio o interno.
         final errorCode = result.data['code'] as String?;
         if (errorCode == 'already-exists') { // Usuario ya es miembro
             return Left(ValidationFailure('Este usuario ya es miembro del Space.'));
         }
         if (errorCode == 'not-found') { // No hay usuario registrado
             return Left(ValidationFailure('No se encontró un usuario registrado con ese email.'));
         }
         if (errorCode == 'permission-denied') { // No tienes permisos para esta accion
             return Left(ServerFailure('Tu rol no te permite invitar.'));
         }
         // Devolvemos cualquier otro error
         return Left(ServerFailure('Error desconocido de la nube: ${result.data['message']}'));
      }
    // En caso de errores de firebase
    } on FirebaseFunctionsException catch (e) {
      // Obtenemos el codigo y generammos el mensaje
      if (e.code == 'already-exists' || e.code == 'not-found') {
            return Left(ValidationFailure(e.message ?? 'Aviso de la nube.'));
      }
      // Devolucion de mensaje de error
      return Left(ServerFailure('Error en la llamada a la nube: ${e.message}'));
    } catch (e) {
      // Devolucion de mensaje de error
      return Left(ServerFailure(e.toString()));
    }
  }

  // Metodo para eliminar un usuario especifico de un space
  @override
  Future<Either<Failure, void>> removeMember({
    required String spaceId,
    required String userIdToRemove,
  }) async {
    try {
      // Lanzamos la peticion
      await spaceDataSource.removeMember(
        spaceId: spaceId,
        userIdToRemove: userIdToRemove,
      );
      return const Right(null); // Devolvemos exito
    } catch (e) {
      // Devolvemos el error
      return Left(ServerFailure(e.toString()));
    }
  }

  // Metodo para abandonar un space
  @override
  Future<Either<Failure, void>> leaveSpace(String spaceId) async {
    try {
      final userId = _currentUserId; // obtenemos usuario actual
      if (userId == null) { // Si el usuario no esta autenticado 
        return Left(const AuthFailure('Usuario no autenticado.'));
      }
      // esperamos a que termine la operacion solicitada
      await spaceDataSource.leaveSpace(spaceId: spaceId, userId: userId);
      return const Right(null); // Devuelve exito
    } catch (e) {
      // Devuelve error
      return Left(ServerFailure(e.toString()));
    }
  }
}
