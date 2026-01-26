import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/storage_box_repository.dart';
import 'package:medikeep/infrastructure/datasources/storage_box_remote_datasource.dart';
import 'package:medikeep/infrastructure/models/models.dart';


/// Implementación del repositorio de StorageBox
/// Orquesta el DataSource de StorageBox
class StorageBoxRepositoryImpl implements StorageBoxRepository {
  // atributos
  final StorageBoxRemoteDataSource remoteDataSource;

  // Constructor
  StorageBoxRepositoryImpl({
    required this.remoteDataSource,
  });

  // Metodo que devuelve un Stream de storageboxes por un ID
  // de space dado 
  @override
  Stream<Either<Failure, List<StorageBox>>> getStorageBoxes({
    required String spaceId,
  }) {
    try {
      // Llamamos al DataSource para obtener el stream de Modelos
      return remoteDataSource.getStorageBoxes(spaceId: spaceId).map(
        (models) {
          // Transformamos la lista de Modelos a una lista de Entidades
          final entities = models.map((model) => model.toEntity()).toList();
          // Envolvemos el resultado exitoso en un 'Right'
          return Right<Failure, List<StorageBox>>(entities);
        },
      ).handleError((error) {
        // Manejamos cualquier error que ocurra DENTRO del stream
        return Left<Failure, List<StorageBox>>(ServerFailure(error.toString()));
      });
    } catch (e) {
      // Manejamos cualquier error AL INICIAR el stream
      return Stream.value(Left<Failure, List<StorageBox>>(ServerFailure(e.toString())));
    }
  }

  // Metodo que crea un StorageBox
  @override
  Future<Either<Failure, void>> createStorageBox({
    required String spaceId,
    required String name,
  }) async {
    try {
      // Espera a crear el storagebox dado
      await remoteDataSource.createStorageBox(spaceId: spaceId, name: name);
      return const Right(null); // Devolvemos exito
    } catch (e) {
      // Devolvemos un error
      return Left(ServerFailure('No se pudo crear el container: ${e.toString()}'));
    }
  }

  // Metodo que actualiza un storagebox
  @override
  Future<Either<Failure, void>> updateStorageBox({
    required String spaceId,
    required StorageBox storageBox,
  }) async {
    try {
      // Convertimos la Entidad a un Modelo para pode actualizadar
      // Creamos un StorageBoxModel a partir de la Entidad 'storageBox'.
      final storageBoxModel = StorageBoxModel(
        id: storageBox.id,
        name: storageBox.name,
        createdAt: storageBox.createdAt,
        updatedAt: storageBox.updatedAt,
      );
      // Procedemos a actualizar
      await remoteDataSource.updateStorageBox(
        spaceId: spaceId,
        storageBoxModel: storageBoxModel,
      );
      return const Right(null); // Devolvemos exito
    } catch (e) {
      // Devolvemos error
      return Left(ServerFailure('No se pudo actualizar el storageBox: ${e.toString()}'));
    }
  }

  // Metodo que elimina un storagebox
  // Debe complementarse con una Cloud Function para eliminar los medicamentos de 
  // los que depende y no queden huerfanos
  @override
  Future<Either<Failure, void>> deleteStorageBox({
    required String spaceId,
    required String storageBoxId,
  }) async {
    try {
      // Esperamos el borrado del storage_box
      await remoteDataSource.deleteStorageBox(
        spaceId: spaceId,
        storageBoxId: storageBoxId,
      );
      return const Right(null); // Devolvemos exito
    } catch (e) {
      // Devolvemos error
      return Left(ServerFailure('No se pudo eliminar el container: ${e.toString()}'));
    }
  }
}
