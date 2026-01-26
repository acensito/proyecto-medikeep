import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/providers.dart';
import 'package:medikeep/presentation/utils/ui_traslations.dart';


/// Pantalla para mostrar los detalles completos de un solo medicamento.
/// Utiliza un SliverAppBar para una UI atractiva con la imagen.
class MedicationDetailScreen extends ConsumerStatefulWidget {
  final String spaceId;
  final Medication medication;

  const MedicationDetailScreen({
    super.key,
    required this.spaceId,
    required this.medication,
  });

  @override
  ConsumerState<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends ConsumerState<MedicationDetailScreen> {
  // Controlador para detectar el scroll y mostrar/ocultar el título en la AppBar
  late ScrollController _scrollController;
  // flag de control para mostrar u ocultar el titulo de la AppBar
  bool _showAppBarTitle = false;

  // inicialización
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  // dispose para liberalización de recursos
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Metodo privado que controla si hemos hecho scroll más 
  // allá de los 180px (casi colapsado), para poder mostrar el titulo título
  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 180 && !_showAppBarTitle) {
        setState(() => _showAppBarTitle = true);
      } else if (_scrollController.offset <= 180 && _showAppBarTitle) {
        setState(() => _showAppBarTitle = false);
      }
    }
  }

  // Widget de la pantalla
  @override
  Widget build(BuildContext context) {
    // datos a utilizar
    final colors = Theme.of(context).colorScheme; //colores del tema
    final textStyles = Theme.of(context).textTheme; //estilos del tema
    final medication = widget.medication; 
    final spaceId = widget.spaceId;

    // obtenemos nuestro userId
    final currentUserId = ref.watch(authStateChangesProvider).asData?.value?.id;
    // obtenemos los datos de nuestro space
    final spaceAsync = ref.watch(currentSpaceProvider(spaceId));
    // obtenemos nuestro rol de usuario
    final myRole = spaceAsync.asData?.value.getMemberRole(currentUserId);
    // Obtenemos nuestros StorageBoxes para el nombre de la ubicación
    final storageBoxesAsync = ref.watch(storageBoxesStreamProvider(spaceId));

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController, // Conectamos el controlador
        slivers: [
          // -- Cabecera SliverAppbar --
          SliverAppBar(
            expandedHeight: 250.0, // Altura de la imagen cuando está expandida
            floating: false,
            pinned: true, // La barra se queda "pegada" arriba al colapsar
            stretch: true,
            // Cambiamos el color de los iconos a blanco para que destaquen sobre el degradado
            iconTheme: const IconThemeData(color: Colors.white), 
            backgroundColor: colors.primary, // color al colapsar
            
            // Titulo dinamico
            // Solo se muestra si hemos hecho scroll
            title: _showAppBarTitle 
                ? Text(
                    medication.name,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, 
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1, 
                  )
                : null,
            // espacio flexible
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  (medication.photoUrl != null &&
                          medication.photoUrl!.isNotEmpty)
                      ? Image.network(
                          medication.photoUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(context),
                        )
                      : _buildPlaceholderImage(context),
                  
                  // Degradados en esquinas para mejor visualización de botones
                  // Esquina Superior Izquierda (zona botón Atrás)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.0,
                          colors: [
                            colors.primary.withValues(alpha: 0.6),
                            colors.primary.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                  ),
                  // Esquina Superior Derecha (zona botones de acción)
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topRight,
                          radius: 1.0,
                          colors: [
                            colors.primary.withValues(alpha: 0.6),
                            colors.primary.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                  ),
                  
                  // Degradado Inferior (para separar visualmente)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              stretchModes: const [StretchMode.zoomBackground],
            ),

            // --- Botones de acción ---
            // Si tiene rol viewer, no verá estos botones
            actions: (myRole == UserRole.viewer)
                ? null 
                : [
                    IconButton(
                      icon: const Icon(Icons.edit_note),
                      tooltip: 'Editar',
                      onPressed: () {
                        context.pushNamed(
                          'edit-medication',
                          pathParameters: {'spaceId': spaceId},
                          extra: medication,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Eliminar',
                      onPressed: () {
                        _showDeleteConfirmation(context, ref, spaceId);
                      },
                    ),
                  ],
          ),

          // --- Cuerpo del sliverlist (datos) ---
          SliverList(
            delegate: SliverChildListDelegate(
              [
                // nombre del medicamento
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    medication.name,
                    style: textStyles.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                      height: 1.2,
                    ),
                  ),
                ),

                // tarjeta con ruta ubicacion del medicamento
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    elevation: 0,
                    color: colors.primaryContainer.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.primary.withValues(alpha: 0.2))),
                    child: ListTile(
                      leading: Icon(Icons.location_on, color: colors.primary),
                      title: const Text('Ubicación', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: storageBoxesAsync.when(
                        loading: () => const Text('Cargando...'),
                        error: (_, __) => const Text('Desconocida'),
                        data: (boxes) {
                          final box = boxes.firstWhere(
                            (b) => b.id == medication.storageBoxId,
                            orElse: () => const StorageBox(id: '', name: 'No asignado'),
                          );
                          final spaceName = spaceAsync.asData?.value.name ?? 'Espace';
                          
                          return Text(
                            '$spaceName - ${box.name}', 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: colors.onSurface
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // tarjeta de estado y caducidad
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoColumn(
                            icon: Icons.calendar_today_outlined,
                            title: 'Caducidad',
                            value: medication.expiryDate
                                    ?.toLocal()
                                    .toString()
                                    .split(' ')[0] ??
                                'N/A',
                          ),
                          _InfoColumn(
                            icon: medication.status?.icon ?? Icons.help_outline,
                            iconColor: medication.status?.color,
                            title: 'Estado',
                            value: medication.status?.label ?? 'Desconocido',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // tarjeta de información general
                _RenderInfoCard(
                  context: context,
                  title: 'Información General',
                  icon: Icons.info_outline,
                  children: [
                    _InfoRow(
                        title: 'Principio Activo',
                        value: medication.pactivos ?? 'No disponible'),
                    _InfoRow(
                        title: 'Laboratorio',
                        value: medication.labtitular ?? 'No disponible'),
                    _InfoRow(
                        title: 'Código Nacional (CN)',
                        value: medication.cn ?? 'N/A'),
                  ],
                ),

                // tarjeta de advertencias
                _RenderInfoCard(
                  context: context,
                  title: 'Advertencias',
                  icon: Icons.warning_amber_outlined,
                  children: [
                    _InfoRow(
                      title: 'Necesita Receta',
                      value:
                          medication.prescriptionNeeded ? 'Sí' : 'No',
                      valueColor: medication.prescriptionNeeded
                          ? colors.error
                          : colors.primary,
                    ),
                    _InfoRow(
                      title: 'Afecta Conducción',
                      value: medication.affectsDriving ? 'Sí' : 'No',
                      valueColor: medication.affectsDriving
                          ? colors.error
                          : colors.primary,
                    ),
                  ],
                ),

                // tarjeta de notas
                if (medication.notes != null && medication.notes!.isNotEmpty)
                  _RenderInfoCard(
                    context: context,
                    title: 'Mis Notas',
                    icon: Icons.note_alt_outlined,
                    children: [
                      Text(medication.notes!,
                          style: textStyles.bodyLarge
                              ?.copyWith(height: 1.5)),
                    ],
                  ),
                
                // -- Sección de enlaces --
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // boton prospecto
                      // se muestra solo si posee 
                      if (medication.prospectusUrl != null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Ver Prospecto'),
                          onPressed: () {
                            context.push(
                              Uri(
                                path: '/webview',
                                queryParameters: {
                                  'title': 'Prospecto',
                                  'url': medication.prospectusUrl!,
                                },
                              ).toString(),
                            );
                          },
                        ),
                      const SizedBox(height: 12),

                      // boton ficha tecnica
                      // se muestra solo si posee
                      if (medication.datasheetUrl != null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.article_outlined),
                          label: const Text('Ver Ficha Técnica'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.secondaryContainer,
                            foregroundColor: colors.onSecondaryContainer,
                          ),
                          onPressed: () {
                            context.push(
                              Uri(
                                path: '/webview',
                                queryParameters: {
                                  'title': 'Ficha Técnica',
                                  'url': medication.datasheetUrl!,
                                },
                              ).toString(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                
                // Espacio al final
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Metodo privado para mostrar el cuadro de dialogo de confirmacion de eliminación de un 
  /// medicamento.
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String spaceId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar "${widget.medication.name}" de tu inventario?'),
          actions: [
            TextButton(
              //en caso de cancelar, cerramos el cuadro dialogo
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              // en caso de afirmar, continuamos con la eliminacion
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                // llamamos al caso de uso del provider
                ref.read(deleteMedicationUseCaseProvider).call(
                      spaceId: spaceId, //id del space
                      medicationId: widget.medication.id, // id del medicamento
                    );
                
                // cerramos el dialogo y el contexto (la pantalla, ya que lo hemos eliminado)
                Navigator.of(context).pop(); 
                context.pop(); 
                
                // mostramos un mensaje de feedback con cun snackbar.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.medication.name} eliminado'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // -- Metodos privados de la clase --

  // Método privado que establece una imagen placeholder en caso de no existir imagen
  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(
        Icons.medication,
        size: 180,
        color: Colors.grey.shade500,
      ),
    );
  }
}

// -- Widgets privados de la clase --

// Widget privado para crear una tarjeta de información del medicamento
class _RenderInfoCard extends StatelessWidget {
  final BuildContext context; // contexto en el que trabaja
  final String title; // titulo
  final IconData icon; // icono
  final List<Widget> children; // lista de widgets

  const _RenderInfoCard({
    required this.context,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: textStyles.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget privado que genera una fila de datos
/// Recibe un [title], un [value] y un [valueColor]
class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: textStyles.bodyMedium?.copyWith(color: Colors.grey.shade600)),
          // Para evitar un overflow (salirse de pantalla), si el valor recibido es largo
          Flexible( 
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textStyles.bodyLarge?.copyWith(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget privado auxiliar que genera una columna. Recibe como parametros
/// un [icon], un color con [iconColor] de manera opcional, un titulo [title]
/// y un valor de texto [value]
class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final Color? iconColor; 
  final String title;
  final String value;

  const _InfoColumn({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: iconColor ?? colors.primary, size: 28),
        const SizedBox(height: 8),
        Text(title, style: textStyles.labelLarge),
        const SizedBox(height: 4),
        Text(value, style: textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}