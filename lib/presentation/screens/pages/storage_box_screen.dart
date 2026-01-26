import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/auth_provider.dart';
import 'package:medikeep/presentation/providers/medication_provider.dart';
import 'package:medikeep/presentation/providers/space_provider.dart';
import 'package:medikeep/presentation/screens/pages/medication_search_delegate.dart';
import 'package:medikeep/presentation/widgets/widgets.dart';


/// Pantalla para mostrar y gestionar los medicamentos
/// que pertenecen a un StorageBox
class StorageBoxScreen extends ConsumerWidget {
  // atributos
  final String spaceId;
  final String storageBoxId;
  final String storageBoxName;

  // constructor
  const StorageBoxScreen({
    super.key,
    required this.spaceId,
    required this.storageBoxId,
    required this.storageBoxName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // obtenemos datos de los repositorios
    final currentUserId = ref.watch(authStateChangesProvider).asData?.value?.id; 
    final spaceAsync = ref.watch(currentSpaceProvider(spaceId));
    final myRole = spaceAsync.asData?.value.getMemberRole(currentUserId);
    final medicationsAsyncValue = ref.watch(medicationsStreamProvider(spaceId));

    return Scaffold(
      // -- APPBAR --
      appBar: AppBar(
        // Titulo de la pantalla
        title: Text(storageBoxName),
        actions: [
          // Si no soy 'Viewer', muestro el botón de búsqueda
          if (myRole != UserRole.viewer)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar/Añadir Medicamento',
              onPressed: () { _onSearchPressed(context, ref);},
            ),
        ],
      ),
      // -- BODY --
      body: Center(
        child: medicationsAsyncValue.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Error al cargar los medicamentos: $err'),
          data: (allMedications) {
            // muestra los medicamentos que coincidan con este storagebox
            final filteredMedications = allMedications
                .where((med) => med.storageBoxId == storageBoxId)
                .toList();

            if (filteredMedications.isEmpty) {
              // Si la lista de medicamentos esta vacia, mostramos el
              // widget privado para el estado vacío, pasando el rol
              // para asi mostrar o no el boton de añadir 
              return _BuildEmptyState(
                myRole: myRole, // <-- ¡Le pasamos el rango!
                onPressed: () {
                  _onSearchPressed(context, ref);
                },
              );
            }

            // Si hay datos, mostramos la lista de Medicamentos
            return ListView.builder(
              itemCount: filteredMedications.length,
              itemBuilder: (context, index) {
                final medication = filteredMedications[index];
                
                return MedicationListTile(
                  medication: medication,
                  onTap: () {
                    // Navegamos al detalle del medicamento
                    context.pushNamed(
                      'medication-details',
                      pathParameters: {
                        'spaceId': spaceId,
                        'storageBoxId': storageBoxId,
                        'medicationId': medication.id,
                      },
                      extra: {
                        'medication': medication,
                        'storageBoxName': storageBoxName,
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),

      // -- FAB --
      // comprueba si tiene permisos y no esta vacía la lista, se muestra
      floatingActionButton: (myRole != UserRole.viewer && (medicationsAsyncValue.asData?.value.isNotEmpty ?? false))
          ? FloatingActionButton(
              onPressed: () {
                // El FAB también llama a la búsqueda
                _onSearchPressed(context, ref);
              },
              tooltip: 'Añadir Medicamento',
              child: const Icon(Icons.add),
            )
          : null, // Si soy 'Viewer', no hay botón flotante
    );
  }

  /// metodo de búsqueda
  void _onSearchPressed(BuildContext context, WidgetRef ref) async {
    // abrimos la pantalla de buscqueda y espera los resultados.
    // le adjuntamos a la busqueda el spaceId del medicamento
    final Medication? selectedMedication = await showSearch<Medication?>(
      context: context,
      delegate: MedicationSearchDelegate(
        spaceId: spaceId,
      ),
    );

    // si el usuario seleccionó un medicamento...
    if (context.mounted && selectedMedication != null) {
      // navegamos a la pantalla añadir/editar
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

/// Widget privado para mostrar un estado vacio
class _BuildEmptyState extends StatelessWidget {
  final VoidCallback onPressed;
  final UserRole? myRole;

  const _BuildEmptyState({required this.onPressed, required this.myRole});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.medication_liquid_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Este contenedor está vacío',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Añade tu primer medicamento escaneando el código de barras o buscándolo en la base de datos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // comprobamos los roles
          if (myRole != UserRole.viewer)
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: const Text('Añadir medicamento'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            )
          // Si soy viewer, solo muestro un texto
          else
            const Text(
              'Solo un "Propietario" o "Editor" puede añadir medicamentos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}