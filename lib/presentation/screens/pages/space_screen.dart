import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/providers.dart';
import 'package:medikeep/presentation/screens/pages/medication_search_delegate.dart';
import 'package:medikeep/presentation/widgets/widgets.dart';

/// Pantalla de Space
/// Muestra todos los StorageBox y un pequeño dashboard
class SpaceScreen extends ConsumerWidget {
  // atributos
  final String spaceId;

  // constructor
  const SpaceScreen({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authStateChangesProvider).asData?.value?.id;
    final spaceAsync = ref.watch(currentSpaceProvider(spaceId));
    final storageBoxesAsync = ref.watch(storageBoxesStreamProvider(spaceId));
    final expiringMedsAsync = ref.watch(expiringMedicationsProvider(spaceId));

    return Scaffold(
      // --- APPBAR ---
      appBar: AppBar(
        title: Text(spaceAsync.asData?.value.name ?? 'Cargando...'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Gestionar Miembros',
            onPressed: () {
              context.pushNamed(
                'manage-space',
                pathParameters: {'spaceId': spaceId},
              );
            },
          ),
        ],
      ),

      // --- BODY ---
      body: spaceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (space) {
          final myRole = space.getMemberRole(currentUserId);
          final canEdit = myRole != UserRole.viewer;

          return CustomScrollView(
            slivers: [
              // --- ACCIONES RÁPIDAS ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // accion rapida de buscar medicamento por texto
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.search,
                          label: 'Buscar',
                          color: Colors.blue,
                          onTap: () => _onSearchPressed(context, ref),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // accion rapida de escanear QR/Código de barras
                      if (canEdit)
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.qr_code_scanner,
                            label: 'Escanear',
                            color: Colors.purple,
                            onTap: () => _onScanPressed(context, ref),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // --- ATENCIÓN REQUERIDA ---
              // Sección que muestra los medicamentos vencidos o a punto de vencer
              SliverToBoxAdapter(
                child: expiringMedsAsync.when(
                  data: (meds) {
                    if (meds.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            '⚠️ Atención Requerida',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 190,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: meds.length,
                            itemBuilder: (context, index) {
                              final med = meds[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: MedicationCard(
                                  medication: med,
                                  onTap: () {
                                    context.pushNamed(
                                      'medication-quick-view',
                                      extra: {
                                        'medication': med,
                                        'spaceId': spaceId,
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
              ),

              // --- MIS CONTENEDORES ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📦 Mis Contenedores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (canEdit)
                        TextButton.icon(
                          // acción al dejar pulsado (muestra menu para eliminar o editar)
                          onPressed: () => _showCreateOrUpdateDialog(
                            context,
                            ref,
                            spaceId: spaceId,
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Nuevo'),
                        ),
                    ],
                  ),
                ),
              ),

              storageBoxesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: $e'),
                  ),
                ),
                data: (boxes) {
                  if (boxes.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _BuildEmptyState(
                        canEdit: canEdit,
                        onPressed: () => _showCreateOrUpdateDialog(
                          context,
                          ref,
                          spaceId: spaceId,
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 Columnas
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio:
                                1.1, // Un poco más anchas que altas
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final box = boxes[index];

                        return StorageBoxCard(
                          storageBox: box,
                          onTap: () {
                            context.pushNamed(
                              'storage-screen',
                              pathParameters: {
                                'spaceId': spaceId,
                                'storageBoxId': box.id,
                              },
                              extra: box.name,
                            );
                          },
                          // Mantenemos la opción de editar/borrar con pulsación larga
                          // si tienes el rol minimo de poder editar
                          onLongPress: canEdit
                              ? () {
                                  _showOptionsModal(context, ref, spaceId, box);
                                }
                              : null,
                        );
                      }, childCount: boxes.length),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),

      floatingActionButton:
          ref.watch(currentSpaceProvider(spaceId))
            .asData
            ?.value
            .getMemberRole(currentUserId) != UserRole.viewer &&
            ref.watch(storageBoxesStreamProvider(spaceId))
              .asData
              ?.value
              .isNotEmpty ==
                  true
          ? FloatingActionButton(
              key: const Key('create_storage_box'),
              onPressed: () =>
                  _showCreateOrUpdateDialog(context, ref, spaceId: spaceId),
              tooltip: 'Crear Contenedor',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // --- MÉTODOS AUXILIARES ---

  // Método privado para mostrar el diálogo de editar o añadir un nuevo contenedor
  // Escribes o editas el nombre del contenedor
  void _showCreateOrUpdateDialog(
    BuildContext context,
    WidgetRef ref, {
    required String spaceId,
    StorageBox? storageBoxToEdit,
  }) {
    final bool isEditing = storageBoxToEdit != null;
    final nameController = TextEditingController(
      text: isEditing ? storageBoxToEdit.name : '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Contenedor' : 'Nuevo Contenedor'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Botiquín',
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
                  if (isEditing) {
                    final updatedBox = storageBoxToEdit.copyWith(name: name);
                    ref
                        .read(updateStorageBoxUseCaseProvider)
                        .call(spaceId: spaceId, storageBox: updatedBox);
                  } else {
                    ref
                        .read(createStorageBoxUseCaseProvider)
                        .call(spaceId: spaceId, name: name);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Metodo privado que muestra un pop-up desde la parte inferior 
  // mostrando un menu con los botones de editar o borrar un storagebox
  void _showOptionsModal(
    BuildContext context,
    WidgetRef ref,
    String spaceId,
    StorageBox box,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar nombre'),
              onTap: () {
                Navigator.pop(context);
                _showCreateOrUpdateDialog(
                  context,
                  ref,
                  spaceId: spaceId,
                  storageBoxToEdit: box,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Eliminar contenedor',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context); // Cierra el modal de opciones
                _showDeleteConfirmationDialog(context, ref, spaceId, box);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Metodo que muestra un cuadro dialogo para confirmar el borrado de un storagebox
  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    String spaceId,
    StorageBox box,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Contenedor y Contenido'),
        content: Text(
          '⚠️ Esta acción es permanente. ¿Seguro que quieres eliminar el contenedor "${box.name}"? Se borrarán **TODOS** los medicamentos que contiene.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context, true); // Confirma
              // Ejecutamos la eliminación
              ref
                  .read(deleteStorageBoxUseCaseProvider)
                  .call(spaceId: spaceId, storageBoxId: box.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Contenedor "${box.name}" eliminado.')),
              );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Muestra el diálogo de búsqueda de medicamento por texto en el storagebox
  void _onSearchPressed(BuildContext context, WidgetRef ref) async {
    final Medication? selectedMedication = await showSearch<Medication?>(
      context: context,
      delegate: MedicationSearchDelegate(spaceId: spaceId),
    );
    // si hemos seleccionado un medicamento, lo mostramos
    if (context.mounted && selectedMedication != null) {
      // navegamos al detalle del medicamento
      if (selectedMedication.storageBoxId != null) {
        context.pushNamed(
          'medication-quick-view',
          extra: {'medication': selectedMedication, 'spaceId': spaceId},
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mostrando medicamento del inventario')),
        );
      } else {
        context.pushNamed(
          'add-medication',
          pathParameters: {'spaceId': spaceId},
          extra: {
            'medicationTemplate': selectedMedication,
            'preselectedContainerId': null,
          },
        );
      }
    }
  }

  // extrae del codigo de barras (EAN) el código nacional del medicamento (CN)
  // este codigo es de seis digitos, siendo las seis ultimas empezando desde el
  // penultimo digito del codigo de barras, ya que el ultimo de los digitos es un
  // digito de control
  String _extractCnFromEan(String rawCode) {
    final cleanCode = rawCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCode.length > 7) {
      return cleanCode.substring(cleanCode.length - 7, cleanCode.length - 1);
    }
    return cleanCode;
  }

  // Que hace cuando lanzamos el scanner de codigos de barras
  void _onScanPressed(BuildContext context, WidgetRef ref) async {
    // espera a resultado del scanner 
    final String? scannedCode = await context.push<String>('/scanner');

    // si el codigo es leido del codigo de barras
    if (scannedCode != null && scannedCode.isNotEmpty && context.mounted) {
      // extraemos el codigo nacional del medicamento
      final cn = _extractCnFromEan(scannedCode);

      // mostramos un snackbar mientras buscamos el medicamento
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Buscando código: $cn...')));

      // buscamos el medicamento por su codigo nacional
      final Medication? selectedMedication = await showSearch<Medication?>(
        context: context,
        delegate: MedicationSearchDelegate(spaceId: spaceId, initialQuery: cn),
      );

      // si el medicamento esta en base de datos local (tiene ID),
      // mostramos su detalle
      if (context.mounted && selectedMedication != null) {
        if (selectedMedication.storageBoxId != null) {
          context.pushNamed(
            'medication-quick-view',
            extra: {'medication': selectedMedication, 'spaceId': spaceId},
          );
        // en caso contrario, lo añadimos al inventario
        } else {
          context.pushNamed(
            'add-medication',
            pathParameters: {'spaceId': spaceId},
            extra: {
              'medicationTemplate': selectedMedication,
              'preselectedContainerId': null,
            },
          );
        }
      }
    }
  }
}

// --- WIDGETS AUXILIARES ---

// Widget que define un cuadro/casilla del Grid de 
// storageboxes.
class _QuickActionButton extends StatelessWidget {

  // atributos del widget
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  // constructor
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget que se construye cuando no hay storageboxes en la base de datos
class _BuildEmptyState extends StatelessWidget {
  final VoidCallback onPressed;
  final bool? canEdit;
  const _BuildEmptyState({required this.onPressed, this.canEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay contenedores',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea lugares para guardar tus medicinas (ej: "Baño").',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (canEdit == true)
            ElevatedButton(
              key: const Key('create_storage_box'),
              onPressed: onPressed,
              child: const Text('Crear contenedor'),
            )
          else
            const Text(
              'Solo un "Propietario" o "Editor" puede añadir contenedores.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
