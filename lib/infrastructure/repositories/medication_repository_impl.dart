import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/medication.dart';
import 'package:medikeep/domain/repositories/medication_repository.dart';
import 'package:medikeep/infrastructure/datasources/medication_api_datasource.dart';
import 'package:medikeep/infrastructure/datasources/medication_local_datasource.dart';
import 'package:medikeep/infrastructure/models/models.dart';

/// Implementación del Repositorio Medication
/// Orquesta el DataSource local (Firestore) y el externo (API CIMA).
class MedicationRepositoryImpl implements MedicationRepository {
  // atributos con los datasource
  final MedicationLocalDataSource localDataSource;
  final MedicationApiDataSource apiDataSource;

  // Constructor
  MedicationRepositoryImpl({
    required this.localDataSource,
    required this.apiDataSource,
  });


  // Metodo que devuelve un stream con los medicamentos de un space
  // dado por un ID concreto.
  @override
  Stream<Either<Failure, List<Medication>>> getMedications({
    required String spaceId,
  }) {
    try {
      //Llamamos al DataSource para obtener el stream de Modelos
      return localDataSource.getMedications(spaceId: spaceId).map(
        (models) {
          // Transformamos la lista de Modelos a una lista de Entidades
          final entities = models.map((model) => model.toEntity()).toList();
          // Envolvemos el resultado exitoso en un 'Right'
          return Right<Failure, List<Medication>>(entities);
        },
      ).handleError((error) {
        // Manejamos cualquier error que ocurra DENTRO del stream
        Left<Failure, List<Medication>>(ServerFailure(error.toString()));
      });
    } catch (e) {
      // Manejamos cualquier error AL INICIAR el stream
      return Stream<Either<Failure, List<Medication>>>.value(Left(ServerFailure(e.toString())));
    }
  }

  // Metodo que añade un medicamento en firestore
  @override
  Future<Either<Failure, void>> addMedication({
    required String spaceId,
    required Medication medication,
  }) async {
    try {
      // Convertimos la Entidad a un Modelo para guardarla
      final medicationModel = MedicationModel.fromEntity(medication);
      // Añadimos el medicamento
      await localDataSource.addMedication(
        spaceId: spaceId,
        medication: medicationModel,
      );
      return const Right(null); // Devolvemos exito
    } catch (e) {
      // Lanzamos un error si no ha sido posible
      return Left(ServerFailure('No se pudo añadir el medicamento: ${e.toString()}'));
    }
  }

  // Metodo que actualiza un medicamento dado el ID de un space
  @override
  Future<Either<Failure, void>> updateMedication({
    required String spaceId,
    required Medication medication,
  }) async {
    try {
      // Transformamos la entidad a un modelo de datos
      final medicationModel = MedicationModel.fromEntity(medication);
      // Llamamos al metodo del datasource para actualizar
      await localDataSource.updateMedication(
        spaceId: spaceId,
        medication: medicationModel,
      );
      return const Right(null); // Devolvemos exito
    } catch (e) {
      // Lanzamos un error si no ha sido poisble
      return Left(ServerFailure('No se pudo actualizar el medicamento: ${e.toString()}'));
    }
  }

  // Metodo que elimina un medicamento dado su ID y el spaceID
  @override
  Future<Either<Failure, void>> deleteMedication({
    required String spaceId,
    required String medicationId,
  }) async {
    try {
      // Eliminamos el medicamento del datasource
      await localDataSource.deleteMedication(
        spaceId: spaceId,
        medicationId: medicationId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('No se pudo eliminar el medicamento: ${e.toString()}'));
    }
  }

  // Metodo que busca un medicamento de forma local (en base de datos)
  // Se recibe un ID del space en el que buscar, se pasa un string de busqueda
  // Devuelve un fallo o una Lista de entidades Medication como resultados
  @override
  Future<Either<Failure, List<Medication>>> searchLocalMedications({
    required String spaceId,
    required String query,
  }) async {
    try {
      // Recortamos los espacios vacios
      final cleanQuery = query.trim();
      if (cleanQuery.isEmpty) { // Si no hay cadena de busqueda
        return const Right([]); // Devolvemos vacío si no hay búsqueda
      }
      
      // Buscamos solo en el datasource local en el ID especificado con la 
      // cadena especificada
      final localResults = await localDataSource.searchLocalMedications(
        spaceId: spaceId,
        query: cleanQuery,
      );

      // Devuelve los resultados locales
      // mapeamos los resultados y los pasamos a lista de entidades Medication
      final entities = localResults.map((model) => model.toEntity()).toList();
      return Right(entities); //Devolvemos el resultado
    } catch (e) {
      // Devolvemos error
      return Left(ServerFailure('Error en la búsqueda local: ${e.toString()}'));
    }
  }

  // Metodo que busca un medicamento en API Externa dado una cadena de busqueda
  @override
  Future<Either<Failure, List<Medication>>> searchExternalMedications({
    required String query,
  }) async {
    try {
      // Limpiamos la cadena de busqueda
      final cleanQuery = query.trim();
      if (cleanQuery.isEmpty) {
        return const Right([]); // Devolvemos vacío si no hay búsqueda
      }

      // Montamos una expresion regular para filtrar si es CN o por nombre
      final isLikelyCn = RegExp(r'^[0-9.]+$').hasMatch(cleanQuery);
      // Montamos una lista de resultados
      List<MedicationModel> apiResults = [];
      // Si la busqueda es un codigo nacional (CN)
      if (isLikelyCn) {
        // Realizamos la busqueda usando el metodo por CN
        final result = await apiDataSource.getByCn(cleanQuery);
        if (result != null) {
          apiResults.add(result);
        }
      } else {
        // En el caso contrario, buscamos por nombre
        apiResults = await apiDataSource.searchByName(cleanQuery);
      }

      // Devuelve los resultados de la API
      // Mapeamos como una lista de entidades Medication los resultados
      final entities = apiResults.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      // Devolvemos error
      return Left(ApiFailure('Error en la búsqueda externa: ${e.toString()}'));
    }
  }
}

