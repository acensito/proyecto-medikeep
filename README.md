
# 💊 MediKeep - Gestión Inteligente de Medicamentos

MediKeep es una solución multiplataforma diseñada para la gestión doméstica de botiquines. Permite a familias y organizaciones controlar el inventario de medicamentos, monitorizar fechas de caducidad y acceder a información técnica oficial de forma colaborativa y segura.

## Funcionalidades Principales

* *Gestión de Spaces*: Creación de espacios compartidos (Hogar, Oficina) con roles definidos (Propietario, Editor, Lector).
* *Inventario por Contenedores*: Organización lógica por cajas físicas o estancias.
* *Alertas Inteligentes*: Notificaciones locales automáticas antes de la caducidad de cada fármaco.
* *Integración API CIMA*: Consulta en tiempo real de prospectos, fotos y fichas técnicas oficiales.
* *Sincronización Cloud*: Datos en tiempo real y persistencia mediante Firebase.

## Arquitectura utilizada en el proyecto

El proyecto se rige por los principios de Domain Driven Design, Clean Architecture y SOLID, garantizando un código desacoplado y altamente testable que permite un mantenimiento del código a largo plaazo a futuros cambios o mejoras:

* *Domain* (Capa Central): Entidades puras, repositorios y casos de uso de negocio.

* *Infrastructure* (Capa Externa): Implementación de servicios, DataSources (Firestore, API CIMA) y Mappers de modelos.

* *Presentation* (Capa UI): Interfaz Material 3 reactiva gestionada mediante Riverpod.



## 🧪 Estrategia de Pruebas

Se ha implementado una batería de pruebas de dos niveles:

* *Pruebas de Unidad*: Localizadas en /test, validando la lógica de validación de fechas, gestión de roles y casos de uso de medicamentos mediante mocktail.

* Pruebas de Integración (E2E)*: En la carpeta /test_integration, verificando el flujo completo desde el Login hasta la creación de contenedor (StorageBox).

## Instalación para pruebas

- Clonamos el repositorio
```bash
git clone https://github.com/acensito/proyecto-medikeep.git
```

- Añadimos las librerias del proyecto
```bash
flutter pub get
```

- Ejecutamos
```bash
flutter run
```

## Créditos y Tecnologías

*Lenguaje*: Dart

*Framework*: Flutter (Material 3)

*Estado*: Flutter Riverpod

*Backend*: Firebase (Firestore, Auth, Cloud Functions)

*API Externa*: Agencia Española de Medicamentos (CIMA)

### Lista de Tareas Pendientes del Proyecto MediKeep

[x] Implementar Autenticación por Email/Contraseña 

[x] Implementar lógica en AuthRemoteDataSourceImpl.

[x] Crear AuthRepositoryImpl flow.

[x] Crear Casos de Uso Register y SignIn.

[x] Añadir Providers.

[x] UI en LoginScreen.

[x] Implementar Borrado en Cascada (Cloud Functions)

[x] Borrado de Space -> StorageBoxes -> Medications.

[x] Borrado de StorageBox -> Medications.

[x] Confirmación al borrar Medicamento.

[x] Confirmación al borrar Space.

[x] Revisar confirmaciones en StorageBoxScreen y SpaceManagementScreen (algunas ya están, falta revisar leaveSpace).

[x] Añadir Diálogos de Confirmación (UX de Seguridad)

[x] Añadir un AlertDialog de confirmación en SpaceManagementScreen para el botón "Eliminar Miembro" (removeMemberUseCaseProvider).

[x] Añadir un AlertDialog de confirmación en SpaceManagementScreen para el botón "Abandonar Space" (leaveSpaceUseCaseProvider).

[x] Implementar Flujo de Bienvenida con carrusel welcome screen

[x] Lógica redirect en app_router.dart.

[x] Implementar un dashboard

[x] Sección "Caduca pronto" en space screen

[x] Sección "Mis Contenedores" con tarjetas.

[x] Buscar tanto en el dispositivo como en la API y mostrar los resultados

[x] Icono de search en HomeScreen.

[x] Implementar Escáner de Código de Barras de medicamento

[x] Pantalla scanner de codigo de barras

[x] Lógica EAN a CN (codigo nacional).

[x] Mejorar el welcome screen com más explicaciones y advertencia

[x] Solo aparece la welcome screen cuando se da de alta por primera vez

[x] Notificaciones de caducidad

[x] Configurar flutter_local_notifications.

[x] Programar aviso X días antes de expiryDate al crear/editar medicamento.

[x] Cancelar aviso al borrar medicamento.

[x] Definir Tema Global (Theme)

[x] Definir la paleta de colores "farmacia" (verdes, azules, blancos).

[ ] Cambio de colores de tema

[ ] Definir la tipografía (ej: Inter) y aplicarla en main.dart.

[ ] Mejorar textos de la UI

[x] Traducción de Enums (ui_translation.dart).

[ ] Implementar localizacion (i18n)

[ ] Pantalla de ajustes

[ ] Añadir un selector de idioma (Español/Inglés) en una futura pantalla de "Ajustes".

[ ] Separar mas componentes reutilizables

[x] Mejorar lógica de borde/color de caducidad a MedicationCard (rojo/amarillo/verde).

[ ] Mandar un mensaje al usuario que no se ha programado la notificacion por X motivo

[ ] Mejorar la gestión de errores y mostrar mensajes claros al usuario (ej: error de red, error de autenticación).

[x] Verificación de email al registrarse usando email y password.












