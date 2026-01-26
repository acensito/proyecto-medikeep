import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/providers.dart';
import 'package:medikeep/presentation/utils/ui_traslations.dart';

/// Pantalla para editar un medicamento del inventario
/// Esta clase utiliza Riverpod para leer y gestionar providers
class EditMedicationScreen extends ConsumerStatefulWidget {
  // atributos de la pantalla
  final String spaceId; // space al que pertenece
  final Medication medicationToEdit; // plantilla del medicamento

  // Constructor
  const EditMedicationScreen({
    super.key,
    required this.spaceId,
    required this.medicationToEdit,
  });

  @override
  ConsumerState<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

// Estado interno de la pantalla editar medicamento
class _EditMedicationScreenState extends ConsumerState<EditMedicationScreen> {
  
  // clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // controladores para manejar el texto de los campos del formulario
  late final TextEditingController _nameController;
  late final TextEditingController _cnController;
  late final TextEditingController _expiryDateController;
  late final TextEditingController _notesController;
  late final TextEditingController _labController;
  late final TextEditingController _pActivosController;
  late final TextEditingController _photoUrlController;

  // Variables para los campos seleccionables
  MedicationStatus? _selectedStatus;
  String? _selectedStorageBoxId;

  // inicialización del widget
  @override
  void initState() {
    super.initState();

    // obtenemos la plantilla del medicamento a editar
    final med = widget.medicationToEdit;

    // Pre-rellenamos los datos en el formulario
    _nameController = TextEditingController(text: med.name);
    _cnController = TextEditingController(text: med.cn);
    _expiryDateController = TextEditingController(
      text: med.expiryDate?.toLocal().toString().split(' ')[0] ?? ''
      );
    _notesController = TextEditingController(text: med.notes);
    _labController = TextEditingController(text: med.labtitular);
    _pActivosController = TextEditingController(text: med.pactivos);
    _photoUrlController = TextEditingController(text: med.photoUrl);
    _selectedStatus = med.status;
    _selectedStorageBoxId = med.storageBoxId;
  }

  // dispose del widget
  @override
  void dispose() {
    // liberamos los controladores
    _nameController.dispose();
    _cnController.dispose();
    _expiryDateController.dispose();
    _notesController.dispose();
    _labController.dispose();
    _pActivosController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  // Muestra un datepicker para seleccionar la fecha de caducidad
  Future<void> _selectDate(BuildContext context) async {
    // obtenemos la fecha de hoy como fecha caducidad por defecto
    DateTime initialDate = DateTime.now();
    // si tenemos fecha de caducidad, la parseamos de texto a fecha
    //y la asignamos como fecha de caducidad
    if (_expiryDateController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_expiryDateController.text);
      } catch (_) {}
    }
    // muestra el datepicker en la fecha que esta introducida
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    // seleccionada la fecha, la mostramos en el campo de texto
    if (picked != null) {
      setState(() {
        _expiryDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  // logica a ejecutar cuando pulsamos en "Guardar Medicamento"
  void _onSave() {
    // validamos el formulario
    // campos de texto
    if (!_formKey.currentState!.validate()) return;
    // selector de storagebox
    if (_selectedStorageBoxId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes asignar un contenedor')),
      );
      return;
    }
    // validamos la fecha de caducidad
    final expiryDate = DateTime.parse(_expiryDateController.text);
    // Obtenemos la URL (si está vacía, guardamos null)
    final photoUrl = _photoUrlController.text.trim();

    // En base a la plantilla de medicamento recibida, creamos
    // una nueva instancia clonando los datos y agregando los nuevos
    final Medication updatedMedication = widget.medicationToEdit.copyWith(
      name: _nameController.text,
      cn: _cnController.text,
      expiryDate: expiryDate,
      status: _selectedStatus,
      storageBoxId: _selectedStorageBoxId,
      notes: _notesController.text,
      labtitular: _labController.text,
      pactivos: _pActivosController.text,
      // Actualizamos la foto
      photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
      updatedAt: DateTime.now(),
    );

    // Llamamos al caso de uso del repositorio del provider
    ref.read(updateMedicationUseCaseProvider)
      .call(spaceId: widget.spaceId, medication: updatedMedication)
      .then((result) {
        if (context.mounted) {
          result.fold(
            (failure) { //si hubo error, mostramos mensaje
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al actualizar: ${failure.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            (_) { //si hubo exito, mostramos mensaje 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cambios guardados correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
              context.pop();
            },
          );
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el flujo de storageboxes del id del space
    final storageBoxesAsync = ref.watch(storageBoxesStreamProvider(widget.spaceId));
    final colorTheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo suave
      // --- ZONA APPBAR ---
      appBar: AppBar(
        title: const Text('Editar Medicamento'),
        backgroundColor: colorTheme.primary,
        surfaceTintColor: Colors.white,
      ),
      
      // --- ZONA BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.save_as_outlined),
              label: const Text(
                'GUARDAR CAMBIOS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),

      // --- ZONA BODY --
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // --- Datos producto ---
              Text('Información del Producto', style: textTheme.titleSmall?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 8),              
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Medicamento *',
                          prefixIcon: Icon(Icons.medication_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'El nombre es obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // --- NUEVO CAMPO: URL DE IMAGEN ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _photoUrlController,
                              decoration: const InputDecoration(
                                labelText: 'URL Imagen (Opcional)',
                                hintText: 'https://...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.image_search_outlined),
                              ),
                              // Actualizamos el estado para que la preview intente cargar
                              onChanged: (_) => setState(() {}), 
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Previsualización pequeña
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: (_photoUrlController.text.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _photoUrlController.text,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image, color: Colors.grey);
                                      },
                                    ),
                                  )
                                : const Icon(Icons.image, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cnController,
                              decoration: const InputDecoration(
                                labelText: 'Código Nacional',
                                prefixIcon: Icon(Icons.qr_code),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _labController,
                        decoration: const InputDecoration(
                          labelText: 'Laboratorio',
                          prefixIcon: Icon(Icons.science_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Seccion: Estado del inventario ---
              Text('Estado e Inventario', style: textTheme.titleSmall?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // --- Campo: fecha caducidad
                      TextFormField(
                        controller: _expiryDateController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Caducidad *',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // --- Campo: estado del envase
                      DropdownButtonFormField<MedicationStatus>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Estado del Envase *',
                          border: OutlineInputBorder(),
                        ),
                        items: MedicationStatus.values.map((MedicationStatus status) {
                          // Usamos las extensiones UI para mostrar icono y texto en español
                          return DropdownMenuItem<MedicationStatus>(
                            value: status,
                            child: Row(
                              children: [
                                Icon(status.icon, color: status.color, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  status.label, // ej: "Sin Abrir"
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedStatus = value),
                      ),
                      const SizedBox(height: 16),

                      // --- Campo: Storagebox
                      storageBoxesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) => Text('Error: $e'),
                        data: (boxes) {
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedStorageBoxId,
                            decoration: const InputDecoration(
                              labelText: 'Ubicación / Contenedor *',
                              prefixIcon: Icon(Icons.inbox),
                              border: OutlineInputBorder(),
                            ),
                            items: boxes.map((box) {
                              return DropdownMenuItem<String>(
                                value: box.id,
                                child: Text(box.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStorageBoxId = value;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Seccion: notas ---
              Text('Notas Adicionales', style: textTheme.titleSmall?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 8),
              // --- Campo: notas
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Tomar en ayunas, dosis recomendada...',
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
                maxLines: 3,
              ),
              
              // Espacio final para el botón flotante
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}