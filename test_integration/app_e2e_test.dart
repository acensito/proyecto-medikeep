import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/main.dart' as app;

// --- CREDENCIALES FIJAS PARA TEST ---
// Nota: ESTE USUARIO DEBE EXISTIR EN EL PROYECTO REAL DE FIREBASE AUTH.
const String testEmail = 'autouser@medikeep.com';
const String testPassword = 'autouser123';
// ------------------------------------

/// Test de integración que se identifica como usuario en la aplicación,
/// Pasa a la pantalla de spaces
/// Crea un space y verifica su creación
/// Pasa a la pantalla de dicho space concreto
/// Crea un storage_box y verifica su creación
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo Completo de Creación de Inventario', () {
    // Inicialización de la aplicación y Firebase.
    setUpAll(() async {
      // Llamar a main() inicia la aplicación (conecta al proyecto LIVE de Firebase)
      app.main(); 
    });

    testWidgets('Login con credenciales, Creación de Space y Creación de Contenedor',
        (tester) async {
      
      // Esperamos a que la aplicación termine de cargar el primer widget
      await tester.pumpAndSettle(const Duration(seconds: 1)); 

      // --- PASO 0: LIMPIEZA DE AUTH (Conexión al Firebase Real) ---
      
      // Aseguramos que no haya sesión activa para probar el Login
      await FirebaseAuth.instance.signOut();
      await tester.pumpAndSettle(const Duration(seconds: 1)); 

      // --- PASO 1: REALIZAR LOGIN ---
      Console.log('PASO 1: Ejecutando Login con credenciales...');
      
      // Buscamos los elementos de la pantalla de Login
      final emailField = find.byKey(const Key('email_login_field'));
      final passwordField = find.byKey(const Key('password_login_field'));
      final signInButton = find.text('Iniciar Sesión'); 

      // Verificamos la existencia de la pantalla de Login
      expect(signInButton, findsOneWidget, reason: 'No se encontró el botón de Iniciar Sesión. La app no navegó a /login.');
      
      // Interacción, rellenamos el formulario, pulsamos en el boton de acceso con cuenta Google
      await tester.enterText(emailField, testEmail);
      await tester.enterText(passwordField, testPassword);
      await tester.tap(signInButton);
      
      // Esperamos el flujo de Auth
      await tester.pumpAndSettle(const Duration(seconds: 3)); 
      
      // --- PASO 2: VERIFICAR LA PANTALLA DE BIENVENIDA ---
      Console.log('PASO 2: Verificando pantalla de bienvenida...');
      // buscamos el boron de crear
      final createSpaceButton = find.byKey(const Key('start_creating_space_btn'));
      // en caos de encontrar error por no encontrarlo
      expect(createSpaceButton, findsOneWidget, reason: 'El botón de inicio de creación (Key: start_creating_space_btn) no fue encontrado.'); 
      
      await tester.tap(createSpaceButton);
      await tester.pumpAndSettle(); 
      
      // Verificar que se abre el diálogo de creación
      final createSpaceTitle = find.text('Crear Nuevo Espacio'); 
      expect(createSpaceTitle, findsOneWidget);

      // --- PASO 3: CREAR EL SPACE ---
      Console.log('PASO 3: Creando el Espacio de prueba...');
      const spaceName = 'Space Automatizado Test';
      
      final nameField = find.byType(TextField).first; 
      await tester.enterText(nameField, spaceName);
      
      final saveButton = find.text('Crear'); 
      await tester.tap(saveButton);
      await tester.pumpAndSettle(const Duration(seconds: 2)); 

      // --- PASO 4: VERIFICAR EL DASHBOARD (Home Screen) ---
      Console.log('PASO 4: Verificando que el nuevo Espacio existe en la Home...');
      
      final newSpaceTile = find.text(spaceName);
      expect(newSpaceTile, findsOneWidget);
      
      await tester.tap(newSpaceTile);
      await tester.pumpAndSettle(); 

      // --- PASO 5: CREAR EL PRIMER CONTENEDOR (Empty State) ---
      Console.log('PASO 5: Creando el primer StorageBox desde Empty State...');
      
      final storageBoxName = 'Caja de Baño Test';
      final storageBoxEmptyBtn = find.byKey(const Key('create_storage_box'));
      expect(storageBoxEmptyBtn, findsOneWidget);
      
      await tester.tap(storageBoxEmptyBtn);
      await tester.pumpAndSettle();

      // Verificar que el diálogo está visible
      final newContainerTitle = find.text('Nuevo Contenedor');
      expect(newContainerTitle, findsOneWidget);
      
      final containerNameField = find.byType(TextField).first;
      await tester.enterText(containerNameField, storageBoxName);
      
      final saveContainerBtn = find.text('Guardar');
      await tester.tap(saveContainerBtn);
      await tester.pumpAndSettle(const Duration(seconds: 1)); 

      // --- PASO 6: VERIFICAR EL RESULTADO FINAL ---
      Console.log('PASO 6: Verificando que el Contenedor aparece en el dashboard...');
      
      final boxCard = find.text(storageBoxName);
      expect(boxCard, findsOneWidget);

      Console.log('FINALIZADO TEST DE INTEGRACION CON ÉXITO!');
    });
  });
}