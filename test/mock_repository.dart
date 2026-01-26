import 'package:mocktail/mocktail.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/repositories/medication_repository.dart';
import 'package:medikeep/domain/repositories/space_repository.dart';
import 'package:medikeep/infrastructure/services/local_notification_service.dart';

// Mocks para la capa de Dominio
class MockMedicationRepository extends Mock implements MedicationRepository {}
class MockSpaceRepository extends Mock implements SpaceRepository {}

// Mock para Servicios (Infrastructure)
class MockNotificationService extends Mock implements LocalNotificationService {}

// Registro de valores de fallback (necesario para mocktail con tipos complejos)
void registerMockFallbacks() {
  registerFallbackValue(const Medication(
    id: 'test_id',
    name: 'Test Medication',
    expiryDate: null,
    status: MedicationStatus.unopened,
    prescriptionNeeded: false,
    affectsDriving: false,
    storageBoxId: 'test_box',
  ));
  registerFallbackValue(const Space(id: 'test_id', name: 'Test Space', members: []));
}