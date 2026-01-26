import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/space_repository.dart';
import 'package:medikeep/domain/use_cases/usecases.dart';
import 'package:medikeep/infrastructure/datasources/firestore_space_remote_dataosurce_impl.dart';
import 'package:medikeep/infrastructure/datasources/space_remote_datasource.dart';
import 'package:medikeep/infrastructure/repositories/space_repository_impl.dart';
import 'package:medikeep/presentation/providers/auth_provider.dart';

// -- DATASOURCES --
/// Proveedor de dataSource de los spaces
/// Crea una instancia que gestiona las operaciones remotas de los Spaces (Firestore)
final spaceRemoteDataSourceProvider = Provider<SpaceRemoteDataSource>((ref) {
  return FirestoreSpaceDataSourceImpl();
});

// -- REPOSITORIOS --
/// Repositorio de Spaces que orquesta el acceso a datos de espacios y usuarios.
/// Combina el data source de spaces con el de usuarios.
final spaceRepositoryProvider = Provider<SpaceRepository>((ref) {
  final spaceDataSource = ref.watch(spaceRemoteDataSourceProvider);
  final userDataSource = ref.watch(userRemoteDataSourceProvider);
  
  // Creamos el gerente y le pasamos sus especialistas
  return SpaceRepositoryImpl(
    spaceDataSource: spaceDataSource,
    userDataSource: userDataSource,
  );
});

// -- CASOS DE USO --
/// Proveedor de la instancia de Cloud Functions, usada para ciertas operaciones de backend
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

/// Caso de uso: devuelve un stream con todos los Spaces accesibles para el usuario
final getSpacesUseCaseProvider = Provider<GetSpaces>((ref) {
  return GetSpaces(ref.watch(spaceRepositoryProvider));
});

/// Caso de uso: crear un nuevo Space
final createSpaceUseCaseProvider = Provider<CreateSpace>((ref) {
  return CreateSpace(ref.watch(spaceRepositoryProvider));
});

/// Caso de uso: actualizar los datos de un Space existente
final updateSpaceUseCaseProvider = Provider<UpdateSpace>((ref) {
  return UpdateSpace(ref.watch(spaceRepositoryProvider));
});

/// Caso de uso: eliminar un Space (usa Cloud Functions)
final deleteSpaceUseCaseProvider = Provider<DeleteSpace>((ref) {
  return DeleteSpace(ref.watch(spaceRepositoryProvider));
});

/// Caso de uso: invitar a un nuevo miembro a un Space (usa Cloud Functions)
final inviteMemberUseCaseProvider = Provider<InviteMember>((ref) {
  return InviteMember(ref.watch(spaceRepositoryProvider));
});

/// Caso de uso: eliminar a un miembro de un Space (usa Cloud Functions)
final removeMemberUseCaseProvider = Provider<RemoveMember>((ref) {
  return RemoveMember(ref.watch(firebaseFunctionsProvider));
});

/// Caso de uso: el usuario actual abandona un Space (usa Cloud Functions)
final leaveSpaceUseCaseProvider = Provider<LeaveSpace>((ref) {
  return LeaveSpace(ref.watch(firebaseFunctionsProvider));
});

// -- PROVIDERS ESPECIALES --

/// Provider reactivo que expone un Stream con la lista de Spaces
/// La UI puede usarlo para pintar en tiempo real todos los espacios del usuario
final spacesStreamProvider = StreamProvider.autoDispose<List<Space>>((ref) {
  final getSpacesUseCase = ref.watch(getSpacesUseCaseProvider);
  
  // Llama al caso de uso y maneja los dos posibles resultados
  return getSpacesUseCase.call().map(
    (either) => either.fold(
      (failure) {
        // Debug
        Console.err('Error en spacesStreamProvider: ${failure.message}');
        throw failure;
      },
      (spaces) => spaces, // Si es exitoso, pasamos la lista de Spaces
    ),
  );
});


/// Provider parametrizado que devuelve un único Space dado su ID
/// Se mantiene sincronizado porque se alimenta del mismo stream de Spaces.
final currentSpaceProvider = StreamProvider.autoDispose.family<Space, String>((ref, spaceId) {
  // Llama de nuevo al caso de uso para obtener el stream de spaces
  final getSpacesUseCase = ref.watch(getSpacesUseCaseProvider);

  // Mapear el Stream<Either<Failure, List<Space>>> al Space solicitado
  return getSpacesUseCase.call().map(
    (either) => either.fold(
      (failure) { // Si hay fallos
        // Debug
        Console.err('Error en currentSpaceProvider: ${failure.message}');
        // Si hay un error, lo lanzamos para que el .when de la UI lo capture
        throw failure;
      },
      (spaces) => spaces.firstWhere( //Si se recupera space, comprobamos
        (space) => space.id == spaceId,
        orElse: () => throw Exception('Espace no encontrado o permisos perdidos.'),
      ),
    ),
  );
});
