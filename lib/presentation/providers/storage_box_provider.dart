import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/storage_box_repository.dart';
import 'package:medikeep/domain/use_cases/usecases.dart';
import 'package:medikeep/infrastructure/datasources/storage_box_remote_datasource.dart';
import 'package:medikeep/infrastructure/datasources/firestore_storage_box_datasource_impl.dart';
import 'package:medikeep/infrastructure/repositories/storage_box_repository_impl.dart';

// --- DATASOURCES ---
/// Provider que expone el DataSource remoto de StorageBoxes
/// (encargado de hablar con la BD remota, por ejemplo Firestore)
final storageBoxRemoteDataSourceProvider = Provider<StorageBoxRemoteDataSource>((ref) {
  return FirestoreStorageBoxDataSourceImpl();
});

// --- REPOSITORIOS ---

/// Repositorio de StorageBoxes, que encapsula la lógica de acceso a datos
/// y delega el trabajo bajo nivel en el DataSource remoto
final storageBoxRepositoryProvider = Provider<StorageBoxRepository>((ref) {
  final remoteDataSource = ref.watch(storageBoxRemoteDataSourceProvider);
  return StorageBoxRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Caso de uso: obtener las StorageBoxes asociadas a un espacio
final getStorageBoxUseCaseProvider = Provider<GetStorageBox>((ref) {
  return GetStorageBox(ref.watch(storageBoxRepositoryProvider));
});

/// Caso de uso: crear un StorageBox
final createStorageBoxUseCaseProvider = Provider<CreateStorageBox>((ref) {
  return CreateStorageBox(ref.watch(storageBoxRepositoryProvider));
});

/// Caso de uso: actualizar un StorageBox
final updateStorageBoxUseCaseProvider = Provider<UpdateStorageBox>((ref) {
  return UpdateStorageBox(ref.watch(storageBoxRepositoryProvider));
});

/// Caso de uso: eliminar un StorageBox (Dependiente de una Cloud Function)
final deleteStorageBoxUseCaseProvider = Provider<DeleteStorageBox>((ref) {
  return DeleteStorageBox(ref.watch(storageBoxRepositoryProvider));
});


// --- PROVIDERS ESPECIALES ---
/// Provider reactivo que expone, en forma de Stream, la lista de StorageBoxes
/// de un Space concreto. La UI puede escucharlo con un 'spaceId' dado
final storageBoxesStreamProvider = StreamProvider.autoDispose.family<List<StorageBox>, String>((ref, spaceId) {
  
  // Obtenemos el caso de uso que devuelve el Stream de StorageBoxes
  final getStorageBoxesUseCase = ref.watch(getStorageBoxUseCaseProvider);
  
  // Llamamos al caso de uso con el spaceId y convertimos el Either en datos o error
  return getStorageBoxesUseCase.call(spaceId: spaceId).map(
    (either) => either.fold(
      (failure) {
        // Debug
        Console.err('Error en storageBoxesStreamProvider: ${failure.message}');
        // Logueamos el fallo y relanzamos para que la UI lo pueda manejar en .when
        throw failure;
      },
      (storageBoxes) => storageBoxes, // Si es exitoso, pasamos la lista de StorageBoxes
    ),
  );
});
