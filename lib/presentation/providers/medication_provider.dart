import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/medication_repository.dart';
import 'package:medikeep/domain/use_cases/usecases.dart';
import 'package:medikeep/infrastructure/datasources/cima_api_datasource_impl.dart';
import 'package:medikeep/infrastructure/datasources/firestore_medication_local_datasource.dart';
import 'package:medikeep/infrastructure/datasources/medication_api_datasource.dart';
import 'package:medikeep/infrastructure/datasources/medication_local_datasource.dart';
import 'package:medikeep/infrastructure/repositories/medication_repository_impl.dart';
import 'package:medikeep/infrastructure/services/local_notification_service.dart';

// --- SERVICIO DE NOTIFICACIONES LOCALES ---
/// Servicio centralizado para manejar notificaciones locales
final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

// -- DATASOURCES --
/// DataSource que gestiona el inventario de medicamentos en almacenamiento local (por ejemplo, Firestore)
final medicationLocalDataSourceProvider = Provider<MedicationLocalDataSource>((ref) {
  // Inyectamos el datasource de firestore, aqui se cambiaria otro datasource
  return FirestoreMedicationLocalDataSourceImpl();
});

/// DataSource que habla con la API externa (CIMA) para buscar/consultar medicamentos remotos
final medicationApiDataSourceProvider = Provider<MedicationApiDataSource>((ref) {
  // Inyectamos el datasource de consultas CIMA
  return CimaApiDataSourceImpl();
});

// -- REPOSITORIO --
/// Repositorio que combina el origen local y el externo.
/// Decide de dónde leer y dónde escribir (local, API, ambos, etc.)
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {

  final localDataSource = ref.watch(medicationLocalDataSourceProvider);
  final apiDataSource = ref.watch(medicationApiDataSourceProvider);
  
  return MedicationRepositoryImpl(
    localDataSource: localDataSource,
    apiDataSource: apiDataSource,
  );
});

// --- CASOS DE USO --
/// Caso de uso: obtener la lista de medicamentos de un espacio
final getMedicationsUseCaseProvider = Provider<GetMedications>((ref) {
  return GetMedications(ref.watch(medicationRepositoryProvider));
});

/// Caso de uso: añadir un medicamento
final addMedicationUseCaseProvider = Provider<AddMedication>((ref) {
  return AddMedication(
    ref.watch(medicationRepositoryProvider),
    ref.watch(localNotificationServiceProvider),
    );
});

/// Caso de uso: actualizar un medicamento y actualizar su notificacion
final updateMedicationUseCaseProvider = Provider<UpdateMedication>((ref) {
  return UpdateMedication(
    ref.watch(medicationRepositoryProvider),
    ref.watch(localNotificationServiceProvider),
    );
});

/// Caso de uso: eliminar un medicamento y su notificacion
final deleteMedicationUseCaseProvider = Provider<DeleteMedication>((ref) {
  return DeleteMedication(
    ref.watch(medicationRepositoryProvider),
    ref.watch(localNotificationServiceProvider),
    );
});

/// Caso de uso: buscar localmente medicamentos
final searchLocalMedicationsUseCaseProvider = Provider<SearchLocalMedications>((ref) {
  return SearchLocalMedications(ref.watch(medicationRepositoryProvider));
});

/// Caso de uso: busca medicamento en una base datos externa (API)
final searchExternalMedicationsUseCaseProvider = Provider<SearchExternalMedications>((ref) {
  return SearchExternalMedications(ref.watch(medicationRepositoryProvider));
});

/// Caso de uso: obtener medicamentos que van a caducar
final getExpiringMedicationsUseCaseProvider = Provider<GetExpiringMedications>((ref) {
  return GetExpiringMedications(ref.watch(medicationRepositoryProvider));
});

/// Caso de uso: reprogramar todas las notificaciones
final rescheduleAllNotificationsUseCaseProvider = Provider<RescheduleAllNotifications>((ref) {
  return RescheduleAllNotifications(
    ref.watch(medicationRepositoryProvider),
    ref.watch(localNotificationServiceProvider),
  );
});

// -- PROVIDERS ESPECIALES --

/// Provider reactivo (por espacio) que expone un Stream con la lista de medicamentos de un espacio dado su ID
/// La UI puede escuchar este stream para mostrar el inventario en tiempo real.
final medicationsStreamProvider = StreamProvider.autoDispose.family<List<Medication>, String>((ref, spaceId) {
  
  final getMedicationsUseCase = ref.watch(getMedicationsUseCaseProvider);
  
  // Llama al caso de uso pasándole el 'spaceId'
  return getMedicationsUseCase.call(spaceId: spaceId).map(
    (either) => either.fold(
      (failure) {
        throw failure;
      },
      (medications) => medications, // Devuelve la lista de medicamentos
    ),
  );
});

/// Provider que expone un Stream con los medicamentos a punto de caducar de un espacio dado por su ID,
/// pensado para la vista dashboard resumen
final expiringMedicationsProvider = StreamProvider.autoDispose.family<List<Medication>, String>((ref, spaceId) {
  final getExpiringUseCase = ref.watch(getExpiringMedicationsUseCaseProvider);
  
  return getExpiringUseCase.call(spaceId: spaceId).map(
    (either) => either.fold(
      (failure) => [], // Si falla, devolvemos lista vacía para no romper el dashboard
      (medications) => medications,
    ),
  );
});

