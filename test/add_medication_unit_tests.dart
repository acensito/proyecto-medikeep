import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/domain/use_cases/usecases.dart';
import 'package:mocktail/mocktail.dart';
import 'mock_repository.dart';

void main() {
  // Caso de uso a probar y dependencias mockeadas
  late AddMedication useCase;
  late MockMedicationRepository mockMedicationRepository;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    // Registramos un fallback para Duration, porque Mocktail necesita
    // instancias por defecto para tipos complejos usados como argumentos.
    registerFallbackValue(const Duration(days: 1));
    // Registra los demás fallbacks específicos definidos en tu archivo de mocks.
    registerMockFallbacks();
  });

  setUp(() {
    // Antes de cada test, creamos nuevas instancias de los mocks para asi
    // evitar que puedan "contaminarse" de un test a otro
    mockMedicationRepository = MockMedicationRepository();
    mockNotificationService = MockNotificationService();
    useCase = AddMedication(mockMedicationRepository, mockNotificationService);
  });

  // Definimos un id de space de prueba
  const tSpaceId = 'space_id_1';

  // Objeto base de Medication para tests
  final tMedication = Medication(
    id: 'med_001',
    name: 'Ibuprofeno',
    expiryDate: DateTime.now().add(const Duration(days: 200)),
    status: MedicationStatus.unopened,
    storageBoxId: 'box_a', // Corregido el nombre
    prescriptionNeeded: false,
    affectsDriving: false,
  );

  // --- Test 1: Éxito y Programación ---
  test('Debe devolver Right(null) cuando un medicamento ha sido agregado correctamente', () async {
    // Arrange: creamos mocks locales para aislar aún más este test
    final mockRepo = MockMedicationRepository();
    final mockNotif = MockNotificationService();
    final usecase = AddMedication(mockRepo, mockNotif);

    // Stub: el repositorio responde como exito al guardar
    when(() => mockRepo.addMedication(
          spaceId: any(named: 'spaceId'),
          medication: any(named: 'medication'),
        )).thenAnswer((_) async => const Right(null));

    // Stub: el servicio de notificaciones no lanza errores al programar
    when(() => mockNotif.scheduledNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          date: any(named: 'date'),
          advanceTime: any(named: 'advanceTime'),
        )).thenAnswer((_) async => Future.value());

    // Act: ejecutamos el caso de uso
    final result = await usecase(
      spaceId: 's1',
      medication: tMedication,
    );

    // Verificamos si el resultado es exitoso
    expect(result, const Right(null));
  });


  // --- Test 2: Fallo de Validación (Contenedor Nulo) ---
  test('Debe dar error si el storageBoxId es nulo',() async {
      // Clonamos un medicamento con un storageBoxId inválido
      final invalidMed = tMedication.copyWith(storageBoxId: '');

      // Act: ejecutamos el caso de uso con datos invalidos
      final result = await useCase.call(
        spaceId: tSpaceId,
        medication: invalidMed,
      );

      // Assert:
      // El resultado debe ser un Left (un Failure de validación)
      // No debe llamar al repositorio ni al servicio de notificaciones
      expect(result, isA<Left>()); // Esperamos un Left (error)
      verifyZeroInteractions(
        mockMedicationRepository,
      ); // Aseguramos que no se llamó al repositorio
      verifyZeroInteractions(
        mockNotificationService,
      ); // Aseguramos que no se tocó el servicio de notificaciones
    },
  );

  // --- Test 3: Fallo de Repositorio (Aseguramos que no se programa) ---
  test('Debe devolver Left si el repositorio falla al guardar',() async {
      // Arrange: Simular que el repositorio (servidor) falla
      when(
        () => mockMedicationRepository.addMedication(
          spaceId: any(named: 'spaceId'),
          medication: any(named: 'medication'),
        ),
      ).thenAnswer((_) async => Left(ServerFailure('Error')));

      // Act
      final result = await useCase.call(
        spaceId: tSpaceId,
        medication: tMedication,
      );

      // Assert:
      // El resultado debe ser un Left (un ServerFailure)
      // El repositorio se llama
      // No se programa ninguna notificación
      expect(result, isA<Left>());
      // Verificamos que se llamó al repositorio
      verify(
        () => mockMedicationRepository.addMedication(
          spaceId: tSpaceId,
          medication: tMedication,
        ),
      ).called(1);
      // Verificamos que NO se tocó el servicio de notificaciones
      verifyZeroInteractions(mockNotificationService);
    },
  );

  // --- Test 4: Validacion de nombre vacío
  test('Debe fallar si el nombre está vacío y no debe llamar a repo ni notificaciones', () async {
    // Arrange: generamos un medicamento con nombre incorrecto (solo espacios)
    final invalidMed = tMedication.copyWith(name: '  ');

    // Act
    final result = await useCase.call(
      spaceId: tSpaceId,
      medication: invalidMed,
    );

    // Assert: la validación debe cortar antes de llamada a los repositorios
    expect(result, isA<Left>());
    verifyZeroInteractions(mockMedicationRepository);
    verifyZeroInteractions(mockNotificationService);
  });

  // --- Test 5: una fecha de caducidad pasada no debe crear notificación
  test('No programa notificación si expiryDate es anterior a hoy', () async {
    // Arrange: creamos un medicamento con la fecha caducada
    final expired = DateTime.now().subtract(const Duration(days: 1));
    final med = tMedication.copyWith(expiryDate: expired);

    // Stub: el repositorio devuelve error de validación
    when(() => mockMedicationRepository.addMedication(
          spaceId: any(named: 'spaceId'),
          medication: any(named: 'medication'),
        )).thenAnswer((_) async => const Left(ValidationFailure('Error al programar la notificación.')));

    // Act
    final result = await useCase(spaceId: tSpaceId, medication: med);

    // Assert:
    // Ser propaga el ValidationFailure.
    // No se intenta programar la notificación para medicacion ya caducada
    expect(result, const Left(ValidationFailure('Error al programar la notificación.')));
    verifyZeroInteractions(mockNotificationService);
  });

  // --- Test 6: fecha caducidad hoy, no se programa notificación
  test('No programa notificación si expiryDate es igual a hoy', () async {
    // Arrange: creamos un medicamento con la fecha de hoy
    final today = DateTime.now();
    final med = tMedication.copyWith(expiryDate: today);

    // Stub: el repositorio devuelve error de validacion
    when(() => mockMedicationRepository.addMedication(
          spaceId: any(named: 'spaceId'),
          medication: any(named: 'medication'),
        )).thenAnswer((_) async => const Left(ValidationFailure('Error al programar la notificación.')));

    // Act
    final result = await useCase(spaceId: tSpaceId, medication: med);

    // Assert:
    // Se propaga el ValidationFailure
    // No se intenta programar la notificacion para medicacion ya caducada
    expect(result, const Left(ValidationFailure('Error al programar la notificación.')));
    verifyZeroInteractions(mockNotificationService);
  });

  // --- Test 7: comprobar que crea notificación con una fecha válida
  test('Programa la notificacion de un medicamento si la fecha es futura.', () async {
    // Arrange: creamos un medicamento con la fecha de caducidad futura
    final future = DateTime.now().add(const Duration(days: 3));
    final med = tMedication.copyWith(expiryDate: future);

    // Stub: el repositorio guarda correctamente
    when(() => mockMedicationRepository.addMedication(
          spaceId: any(named: 'spaceId'),
          medication: any(named: 'medication'),
        )).thenAnswer((_) async => const Right(null));

    // Stub la notificación se programa sin errores
    when(() => mockNotificationService.scheduledNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          date: any(named: 'date'),
          advanceTime: any(named: 'advanceTime'),
        )).thenAnswer((_) async => Future.value());

    // Act
    final result = await useCase(spaceId: tSpaceId, medication: med);

    // Assert:
    // El caso de uso devuelve exito
    // Se ha llamado al metodo con los resultados esperados
    expect(result, const Right(null));

    verify(() => mockNotificationService.scheduledNotification(
          id: med.id.hashCode,
          title: any(named: 'title'),
          body: any(named: 'body'),
          date: med.expiryDate!,
          advanceTime: const Duration(days: 7),
        )).called(1);
  });

  // --- Test 8:
  test('Debe devolver Left si scheduledNotification lanza excepción, pero el repo sí se llamó', () async {
    // Arrange
    // El repositorio guarda bien
    when(() => mockMedicationRepository.addMedication(
          spaceId: any(named: 'spaceId'),
          medication: any(named: 'medication'),
        )).thenAnswer((_) async => const Right(null));

    // Pero el servicio de notificaciones lanza una excepción
    when(() => mockNotificationService.scheduledNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          date: any(named: 'date'),
          advanceTime: any(named: 'advanceTime'),
        )).thenThrow(Exception('Error al programar'));

    // Act
    final result = await useCase.call(
      spaceId: tSpaceId,
      medication: tMedication,
    );

    // Assert: 
    // El caso de uso devuelve Left con la excepcion
    // El repositorio se llama correctamente
    // Se intentó programar la notificación
    expect(result, isA<Left>());

    // Se llamó al repo
    verify(() => mockMedicationRepository.addMedication(
          spaceId: tSpaceId,
          medication: tMedication,
        )).called(1);

    // También se intentó notificar
    verify(() => mockNotificationService.scheduledNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          date: any(named: 'date'),
          advanceTime: any(named: 'advanceTime'),
        )).called(1);
  });

  // Test 9: argumentos exactos en la notificación
  test('scheduledNotification debe ser llamado con los argumentos correctos', () async {
    // Arrange
    when(() => mockMedicationRepository.addMedication(
          spaceId: any(named: 'spaceId'),
          medication: any(named: 'medication'),
        )).thenAnswer((_) async => const Right(null));

    when(() => mockNotificationService.scheduledNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          date: any(named: 'date'),
          advanceTime: any(named: 'advanceTime'),
        )).thenAnswer((_) async => Future.value());

    // Act
    await useCase.call(
      spaceId: tSpaceId,
      medication: tMedication,
    );

    // Assert:
    // Comprobamos que los argumentos sean exactamente los esperados
    // protege asi el sistema de notificaciones
    verify(() => mockNotificationService.scheduledNotification(
          id: tMedication.id.hashCode,
          title: 'Medicamento por caducar',
          body: 'El medicamento "${tMedication.name}" caduca el ${tMedication.expiryDate}.',
          date: tMedication.expiryDate!,
          advanceTime: const Duration(days: 7),
        )).called(1);
  });

  // Test 10: formato del body de la notificación
  test('El body de la notificación debe formarse correctamente', () async {
    // Arrange
    when(() => mockMedicationRepository.addMedication(
          spaceId: any(named: 'spaceId'),
          medication: any(named: 'medication'),
        )).thenAnswer((_) async => const Right(null));

    when(() => mockNotificationService.scheduledNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          date: any(named: 'date'),
          advanceTime: any(named: 'advanceTime'),
        )).thenAnswer((_) async => Future.value());

    // Act
    await useCase.call(
      spaceId: tSpaceId,
      medication: tMedication,
    );

    // Assert:
    // Se construye el body de notificacion esperado y que se envia al servicio
    final expectedBody =
        'El medicamento "${tMedication.name}" caduca el ${tMedication.expiryDate}.';

    verify(() => mockNotificationService.scheduledNotification(
          body: expectedBody,
          id: any(named: 'id'),
          title: any(named: 'title'),
          date: any(named: 'date'),
          advanceTime: any(named: 'advanceTime'),
        )).called(1);
  });

}
