import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/space_provider.dart';
import 'package:medikeep/presentation/providers/storage_box_provider.dart'; // Para Space y StorageBox

/// Un diálogo "paso a paso" para seleccionar un Space y luego un StorageBox.
/// Devuelve un mapa con {'spaceId': String, 'storageBoxId': String} o null.
/// necesario cuando añades un medicamento desde la busqueda directa
class SelectDestinationDialog extends ConsumerStatefulWidget {
  const SelectDestinationDialog({super.key});

  @override
  ConsumerState<SelectDestinationDialog> createState() => _SelectDestinationDialogState();
}

class _SelectDestinationDialogState extends ConsumerState<SelectDestinationDialog> {
  Space? _selectedSpace;
  StorageBox? _selectedStorageBox;

  @override
  Widget build(BuildContext context) {
    // Cargamos la lista de Spaces
    final spacesAsync = ref.watch(spacesStreamProvider);

    return AlertDialog(
      title: const Text('Guardar en...'),
      content: SizedBox(
        width: double.maxFinite, // Para que el diálogo no sea muy estrecho
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- PASO 1: SELECCIONAR SPACE ---
            spacesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('Error cargando espacios: $e'),
              data: (spaces) {
                if (spaces.isEmpty) return const Text('No tienes espacios creados.');
                
                return DropdownButtonFormField<Space>(
                  initialValue: _selectedSpace,
                  hint: const Text('Elige un espacio (Casa/Oficina)'),
                  isExpanded: true,
                  items: spaces.map((space) {
                    return DropdownMenuItem(
                      value: space,
                      child: Text(space.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSpace = value;
                      // Al cambiar de Space, reseteamos el StorageBox seleccionado
                      _selectedStorageBox = null;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // seleccionamos StorageBox
            if (_selectedSpace != null) ...[
              Consumer(
                builder: (context, ref, child) {
                  // cargamos los storagebox del space seleccionado
                  final boxesAsync = ref.watch(storageBoxesStreamProvider(_selectedSpace!.id));

                  return boxesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => const Text('Error cargando contenedores'),
                    data: (boxes) {
                      if (boxes.isEmpty) return const Text('Este espacio no tiene contenedores, crea uno primero');

                      return DropdownButtonFormField<StorageBox>(
                        initialValue: _selectedStorageBox,
                        hint: const Text('Elige un contenedor (Ej: Botiquín)'),
                        isExpanded: true,
                        items: boxes.map((box) {
                          return DropdownMenuItem(
                            value: box,
                            child: Text(box.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStorageBox = value;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          // Solo habilitado si hemos seleccionado AMBOS
          onPressed: (_selectedSpace != null && _selectedStorageBox != null)
              ? () {
                  // Devolvemos la selección
                  Navigator.pop(context, {
                    'spaceId': _selectedSpace!.id,
                    'storageBoxId': _selectedStorageBox!.id,
                  });
                }
              : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}