import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/providers.dart';
import 'package:medikeep/presentation/screens/screens.dart';
import 'package:medikeep/presentation/widgets/select_destination_dialog.dart';

// Pantalla de inicio
// Utiliza provider de Riverpod para la gestion de spaces y estado del usuario
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsyncValue = ref.watch(spacesStreamProvider);
    final user = ref.watch(authStateChangesProvider).asData?.value;

    return Scaffold(      
      // --- ZONA APPBAR ---
      appBar: AppBar(
        title: const Text(
          'Mis Espacios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // --- Campo: Buscador
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar en todos los espacios',
            onPressed: () {
              _onGlobalSearchPressed(context, ref);
            },
          ),
          // --- Boton pantalla perfil usuario
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil de usuario',
            onPressed: () => context.push('/profile'),
          )
        ],
      ),
      // --- ZONA BODY ---
      body: spacesAsyncValue.when(
        // carga de espaces, muestra indicador de carga
        loading: () => const Center(child: CircularProgressIndicator()),
        // muestra mensaje de error 
        error: (err, stack) => Center(child: Text('Error: $err')),
        // si hay datos
        data: (spaces) {
          // si no hay datos, muestra el widget de estado vacio
          if (spaces.isEmpty) {
            return _BuildEmptyState(
              userName: user?.name,
              onPressed: () => _showCreateSpaceDialog(context, ref),
            );
          }

          // en caso de existir datos, monta una lista de spacecards
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: spaces.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final space = spaces[index];
              return _SpaceCard(
                space: space,
                onTap: () {
                  // navegamos al dashboard del space
                  context.pushNamed(
                    'space-screen',
                    pathParameters: {'spaceId': space.id},
                  );
                },
              );
            },
          );
        },
      ),
      
      // --- ZONA FAB ---
      // Boton flotante para crear nuevo space.
      // No aparecerá si no hay spaces, quedando el widget de centro de la pantalla
      floatingActionButton: (spacesAsyncValue.asData?.value.isNotEmpty ?? false)
          ? FloatingActionButton.extended(
              key: const Key('start_creating_space_btn'),
              onPressed: () => _showCreateSpaceDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Espacio'),
            )
          : null,
    );
  }
  
  // Metodo para busqueda global
  void _onGlobalSearchPressed(BuildContext context, WidgetRef ref) async {

    // mostramos un cuadro de busqueda de medicamentos usando la clase 
    // MedicationSearchDelegate personalizado. Devolverá un Medication o null
    final Medication? selectedMedication = await showSearch<Medication?>(
      context: context,
      delegate: MedicationSearchDelegate(
        spaceId: null, 
      ),
    );

    // verificamos que el contexto sigue montado (widget activo)
    // y que el usuario haya seleccionado un medicamento
    if (context.mounted && selectedMedication != null) {
      
      // Es local (tiene spaceId)
      if (selectedMedication.spaceId != null) {
        // navegamos al detalle de dicho medicamento directamente
        context.pushNamed(
          'medication-quick-view',
          extra: {
            'medication': selectedMedication,
            'spaceId': selectedMedication.spaceId!,
          },
        );
        return;
      }

      // Es fuente global, procede de API (sin spaceId)
      // mostramos el cuadro de dialogo para que seleccione los
      // destinos de space y storagebox 
      final destination = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => const SelectDestinationDialog(),
      );

      // Si el usuario selecciono destinos validos y el contexto
      // sigue activo
      if (destination != null && context.mounted) {
        // recuperamos spaceId seleccionado
        final spaceId = destination['spaceId']!;
        // recuperamos storageBoxId seleccionado
        final storageBoxId = destination['storageBoxId']!; 

        // navegamos a la pantalla "Añadir medicamento"
        // incluimos los datos necesarios para rellenar 
        // el formulario
        context.pushNamed(
          'add-medication',
          pathParameters: {'spaceId': spaceId},
          extra: {
            'medicationTemplate': selectedMedication,
            'preselectedStorageBoxId': storageBoxId, 
          },
        );
      }
    }
  }

  // Metodo privado que muestra un cuadro de dialogo para poner nombre a un space
  void _showCreateSpaceDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Espacio'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Casa de la Playa',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(createSpaceUseCaseProvider).call(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

/// Widget privado de Tarjeta visual para cada space
/// representa cada espacio que posee el usuario
class _SpaceCard extends StatelessWidget {
  // Objeto dinamico que contiene los datos del space
  final dynamic space;
  // Callback que se ejecuta al tocar la tarjeta
  final VoidCallback onTap;

  // constructor
  const _SpaceCard({required this.space, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work_rounded, color: Colors.blue, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${space.members.length} miembro(s)',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget privado que muestra un mensaje en el centro de la pantalla indicando que no se
/// poseen spaces y sugiera agregar uno con un boton central.
class _BuildEmptyState extends StatelessWidget {
  // Nombre del usuario
  final String? userName;
  // callback con la accion a realizar por el boton (agregar un space)
  final VoidCallback onPressed;
  
  // constructor
  const _BuildEmptyState({this.userName, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.maps_home_work_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          Text(
            '¡Hola, ${userName ?? 'Usuario'}!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Crea tu primer "Espacio" para empezar a organizar tus medicamentos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            key: const Key('start_creating_space_btn'),
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: const Text('Crear mi primer Espacio'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}