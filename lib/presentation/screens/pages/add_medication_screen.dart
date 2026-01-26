import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/providers.dart';
import 'package:medikeep/presentation/utils/ui_traslations.dart';

/// Pantalla para añadir un nuevo medicamento al inventario.
/// Esta clase utiliza Riverpod (ConsumerStatefulWidget) para leer y gestionar providers.
class AddMedicationScreen extends ConsumerStatefulWidget {
  // atributos de la pantalla
  final String spaceId; // Space al que pertenecerá
  final Medication medicationTemplate; // Plantilla del medicamento
  final String? preselectedStorageBoxId; // Storagebox seleccionado (opcional)

  // Constructor
  const AddMedicationScreen({
    super.key,
    required this.spaceId,
    required this.medicationTemplate,
    this.preselectedStorageBoxId,
  });

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

/// Estado interno de la pantalla de añadir medicamento
class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {

  // clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para manejar el texto en los campos formulario
  late final TextEditingController _expiryDateController;
  late final TextEditingController _notesController;
  late final TextEditingController _photoUrlController;
  
  // Variables para los campos seleccionables
  MedicationStatus? _selectedStatus;
  String? _selectedStorageBoxId; 

  // inicialización del widget
  @override
  void initState() {
    super.initState();

    // inicializamos los controladores
    _expiryDateController = TextEditingController();
    _notesController = TextEditingController();
    // Si la plantilla ya trae url de la foto se coloca en su campo
    _photoUrlController = TextEditingController(text: widget.medicationTemplate.photoUrl);
    // Si hay un StorageBox preseleccionado, se asigna
    _selectedStorageBoxId = widget.preselectedStorageBoxId;
    // Estado inicial del medicamento
    _selectedStatus = MedicationStatus.unopened; 
  }

  // dispose del widget
  @override
  void dispose() {
    // Liberamos los controladores
    _expiryDateController.dispose();
    _notesController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  // Muestra un datepicker para seleccionar la fecha de caducidad
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      // Seleccionada la fecha, la mostramos en el campo de texto
      setState(() {
        _expiryDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  // Logica a ejecutar cuando pulsamos en "Guardar Medicamento"
  void _onSave() {
    // Validamos el formulario
    if (!_formKey.currentState!.validate()) return;

    // Parseamos los datos del formulario
    final expiryDate = DateTime.parse(_expiryDateController.text);
    final notes = _notesController.text;
    // Obtenemos la URL (si está vacía, guardamos null)
    final photoUrl = _photoUrlController.text.trim();

    // En base a la plantilla de medicamento recibida, creamos
    // una nueva instancia clonando los datos y agregando los nuevos
    final Medication newMedication = widget.medicationTemplate.copyWith(
      expiryDate: expiryDate,
      status: _selectedStatus,
      storageBoxId: _selectedStorageBoxId, 
      notes: notes,
      // Actualizamos la foto con lo que haya en el campo
      photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Llamamos al caso de uso del repositorio del provider
    ref.read(addMedicationUseCaseProvider)
      .call(
        spaceId: widget.spaceId,
        medication: newMedication,
      )
      .then((result) {
        if (context.mounted) {
          result.fold(
            (failure) { // Si hubo error, mostramos un mensaje snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al guardar: ${failure.message}'),
                  backgroundColor: Colors.red));
            },
            (_) { // Si guarda correctamente, mostramos mensaje snacjbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Medicamento añadido con éxito'),
                  backgroundColor: Colors.green),
              );
              context.pop(); // Regresamos atrás
            },
          );
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el flujo de storageboxes del id del space
    final storageBoxesAsync = ref.watch(storageBoxesStreamProvider(widget.spaceId));

    return Scaffold(
      // -- ZONA APPBAR --
      appBar: AppBar(
        title: const Text('Añadir Medicamento')),
      // -- ZONA BOTTOM NAVIGATION BAR --
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56, 
            child: ElevatedButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.save),
              label: const Text(
                'GUARDAR MEDICAMENTO',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      // -- ZONA BODY --
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Sección: datos CIMA ---
              Text(
                'Datos de CIMA',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
              ),
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.medication),
                        title: Text(widget.medicationTemplate.name),
                        subtitle: Text(widget.medicationTemplate.labtitular ?? 'Sin laboratorio'),
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.info_outline),
                        title: Text('CN: ${widget.medicationTemplate.cn ?? 'N/A'}'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Sección :datos dnventario ---
              Text(
                'Datos de Inventario',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // --- Campo: StorageBox ---
              storageBoxesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
                data: (boxes) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedStorageBoxId, 
                    hint: const Text('Seleccionar contenedor...'),
                    decoration: const InputDecoration(
                      labelText: 'Contenedor *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Debes seleccionar un contenedor'
                        : null,
                    items: boxes.map((StorageBox box) {
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
              const SizedBox(height: 16),

              // --- Campo: Fecha ---
              TextFormField(
                controller: _expiryDateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Caducidad *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Campo: Estado ---
              DropdownButtonFormField<MedicationStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Estado *',
                  border: OutlineInputBorder(),
                ),
                items: MedicationStatus.values.map((MedicationStatus status) {
                  return DropdownMenuItem<MedicationStatus>(
                    value: status,
                    child: Row(
                      children: [
                        Icon(status.icon, color: status.color, size: 20),
                        const SizedBox(width: 10),
                        Text(status.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedStatus = value),
              ),
              const SizedBox(height: 16),

              // --- Campo: URL imagen medicamento ---
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

              // --- Campo: Notas ---
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}