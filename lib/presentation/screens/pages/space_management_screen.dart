import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/auth_provider.dart';
import 'package:medikeep/presentation/providers/space_provider.dart';
import 'package:medikeep/presentation/utils/ui_traslations.dart';


/// Pantalla para gestionar los miembros y ajustes de un Space.
class SpaceManagementScreen extends ConsumerWidget {
  // atributos
  final String spaceId;

  // constructor
  const SpaceManagementScreen({
    super.key,
    required this.spaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // obtenemos el ID de nuestro propio usuario para saber "quién soy yo"
    final currentUserId = ref.watch(authStateChangesProvider).asData?.value?.id;
    
    // obtenemos el stream de los spaces
    final spacesAsync = ref.watch(spacesStreamProvider);

    return Scaffold(
      // -- APPBAR --
      appBar: AppBar(title: const Text('Gestionar Space')),
      // -- BODY --
      // cuando cargue los spaces
      body: spacesAsync.when(
        // circulo de carga  
        loading: () => const Center(child: CircularProgressIndicator()),
        // mensaje de error
        error: (e, s) => Center(child: Text('Error al cargar el Space: $e')),
        // se obtienen los spaces
        data: (spaces) {
          // buscamos el space actual en la lista de todos nuestros spaces
          final currentSpace = spaces.firstWhere(
            (s) => s.id == spaceId,
            // si no lo encuentra (porque acabamos de salir o borrarlo),
            // creamos uno "falso" para evitar que la app crashee.
            orElse: () => Space(id: '', name: 'Error', members: <UserSpaceProfile>[]),
          );

          // Si el ID está vacío, significa que el space no se encontró (ej: fue borrado)
          if (currentSpace.id.isEmpty) {
            // volvemos a la home si el space ya no existe
            // Usamos 'addPostFrameCallback' para navegar de forma segura
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                 context.go('/home');
              }
            });
            // Mostramos un mensaje de error 
            return const Center(child: Text('Space no encontrado...'));
          }

          // Determinamos nuestro rol en este Space
          final myRole = currentSpace.getMemberRole(currentUserId);
          // Debug
          Console.log(  'Mi rol en el Space "${currentSpace.name}" es: ${myRole?.name}');

          // Convertimos el mapa de miembros en una lista para el ListView
          final membersList = currentSpace.members;

          // -- Lista de miembros --
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Nombre space
              Text(
                currentSpace.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              // Rol que tengo en el space
              Text(
                'Mi Rol: ${myRole?.label ?? 'Desconocido'}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              // Numero de miembros
              Text(
                'Miembros (${membersList.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),

              // --- Lista de Miembros ---
              // Construimos la lista de miembros
              ListView.builder(
                shrinkWrap: true, // Para que funcione dentro de otro ListView
                physics: const NeverScrollableScrollPhysics(),
                itemCount: membersList.length,
                itemBuilder: (context, index) {
                  final memberEntry = membersList[index];

                  // Usamos nuestro widget privado _MemberTile
                  // que busca los datos del usuario
                  return _MemberTile(
                    memberId: memberEntry.id,
                    memberRole: memberEntry.role,
                    currentUserId: currentUserId,
                    myRole: myRole,
                    spaceId: spaceId,
                  );
                },
              ),
              const SizedBox(height: 32),

              // --- Botón de Invitar (Solo para Owners) ---
              if (myRole == UserRole.owner)
                FilledButton.icon(
                  //muestra el dialogo para mostrar un nuevo miembro
                  onPressed: () { _showInviteDialog(context, ref, spaceId);},
                  icon: const Icon(Icons.person_add_alt_1, size: 22),
                  label: const Text(
                    'Invitar Miembro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // --- Botón de Abandonar (Solo si NO soy Owner) ---
              // Esta acción se completará con una cloud function
              // una vez ejecutada el abandono del space, ya que tendrá
              // que actualizar la lista de miembros
              if (myRole != UserRole.owner)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[800],
                    side: BorderSide(color: Colors.orange[700]!, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    // muestra un cua
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: const [
                            Icon(Icons.exit_to_app, color: Colors.orange, size: 26),
                            SizedBox(width: 10),
                            Text('Abandonar Space'),
                          ],
                        ),
                        content: Text(
                          '¿Seguro que quieres salir de "${currentSpace.name}"?\n\n'
                          'Perderás el acceso a todos los medicamentos de este espacio. Tendrán que invitarte de nuevo para volver.',
                          style: const TextStyle(fontSize: 15),
                        ),
                        actionsPadding: const EdgeInsets.only(right: 12, bottom: 12),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange[800],
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Salir del Grupo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                    // si confirma el abandono, llamamos al caso de uso del repositorio
                    // y muestra un mensaje de feedback, regresando al home
                    if (confirmed == true) {
                      ref.read(leaveSpaceUseCaseProvider).call(spaceId).then((_) {
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Has abandonado el espacio')),
                          );
                          context.go('/home');
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.exit_to_app, size: 22),
                  label: const Text(
                    'Abandonar Espacio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

              // --- Botón de Eliminar (Solo si SÍ soy Owner) ---
              if (myRole == UserRole.owner)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    // muestra un dialogo de confirmacion
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text('Eliminar Espace'),
                          ],
                        ),
                        content: const Text(
                          '⚠️ Esta acción es permanente.\n\n'
                          'Se eliminarán todos los datos del Espacio y no podrás recuperarlos.\n\n'
                          '¿Estás seguro de que deseas continuar?',
                          style: TextStyle(fontSize: 15),
                        ),
                        actionsPadding: const EdgeInsets.only(
                          bottom: 12,
                          right: 12,
                        ),
                        actions: [
                          TextButton(
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(fontSize: 16),
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Eliminar definitivamente',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await ref.read(deleteSpaceUseCaseProvider).call(spaceId);
                      if (context.mounted) context.go('/home');
                    }
                  },
                  icon: const Icon(Icons.delete_forever, size: 22),
                  label: const Text(
                    'Eliminar Espacio (Peligro)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Muestra el diálogo para invitar a un nuevo miembro
  void _showInviteDialog(BuildContext context, WidgetRef ref, String spaceId) {
    final emailController = TextEditingController();
    // Valor inicial por defecto para el desplegable de rol
    UserRole selectedRole = UserRole.viewer;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invitar Miembro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // campo: email
              TextField(
                controller: emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email del usuario',
                  hintText: 'ejemplo@correo.com',
                ),
              ),
              const SizedBox(height: 16),
              // Usamos un 'StatefulBuilder' para que el diálogo
              // pueda redibujar solo el desplegable
              // desplegable: rol
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Asignar Rol'),
                    items: const [
                      // No permitimos invitar a un 'owner'
                      DropdownMenuItem(
                        value: UserRole.editor,
                        child: Text('Editor (Editar y ver)'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.viewer,
                        child: Text('Lector (Solo ver)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            // boton y accion cancelar
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            // boton y accion aceptar
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                // Guardamos el context padre (pantalla) antes de abrir el diálogo
                final parentContext = Navigator.of(context).context;

                Navigator.of(context).pop(); // cerramos diálogo

                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Invitando usuario...')),
                );

                // llamamos al caso de uso para invitar al usuario
                final result = await ref.read(inviteMemberUseCaseProvider).call(
                  spaceId: spaceId,
                  userEmail: email,
                  role: selectedRole,
                );

                // usamos el context de la pantalla, no del dialog
                if (!parentContext.mounted) return;

                // mostramos un snackbar con el resultado del caso de uso
                result.fold(
                  // en caso de fallo
                  (failure) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(failure is ValidationFailure
                            ? 'Aviso: ${failure.message}'
                            : 'Error: ${failure.message}'),
                        backgroundColor: failure is ValidationFailure
                            ? Colors.blue
                            : Colors.red,
                      ),
                    );
                  },
                  // en caso de éxito
                  (_) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text('¡Usuario invitado con éxito!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                );
              },
              child: const Text('Invitar'),
            ),

          ],
        );
      },
    );
  }
}

/// Widget privado para la lista de miembros
/// Este es un widget separado que se "enchufa" a su
/// propio provider ('userDetailsProvider') para buscar los datos
/// del usuario (nombre/email) a partir del 'memberId'.
class _MemberTile extends ConsumerWidget {
  final String memberId;
  final UserRole memberRole;
  final String? currentUserId;
  final UserRole? myRole;
  final String spaceId;

  const _MemberTile({
    required this.memberId,
    required this.memberRole,
    required this.currentUserId,
    required this.myRole,
    required this.spaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // nos traemos los datos del usuario mediante el provider pasandole el ID
    final userDetailsAsync = ref.watch(userDetailsProvider(memberId));

    // comprobamos si este 'tile' es el del usuario que está mirando
    final bool isMe = memberId == currentUserId;

    return userDetailsAsync.when(
      // Mientras busca el nombre, mostramos un 'tile' de carga
      loading: () => ListTile(
        leading: const CircleAvatar(child: CircularProgressIndicator()),
        title: const Text('Cargando...'),
        subtitle: Text(memberRole.label),
      ),
      // Si no puede encontrar el usuario (ej: un usuario borrado)
      error: (e, s) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.error)),
        title: const Text('Usuario no encontrado'),
        subtitle: Text('ID: $memberId'),
      ),
      // ¡Éxito! Tenemos los datos del usuario
      data: (user) {
        return ListTile(
          leading: CircleAvatar(
            // Mostramos la foto si existe, si no, las iniciales
            backgroundImage:
                (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                    ? NetworkImage(user.photoUrl!)
                    : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                // Comprobamos si el nombre no es nulo Y no está vacío
                // asi el circulo de avatar es la incial de nombre 
                // o es la incial del email
                ? Text((user.name != null && user.name!.isNotEmpty)
                    ? user.name!.substring(0, 1).toUpperCase()
                    : user.email!.substring(0, 1).toUpperCase())
                : null,
          ),
          title: Text(isMe ? 'Tú' : (user.name ?? 'Sin Nombre')),
          subtitle: Text(memberRole.label), // "owner", "editor", "viewer"
          // Mostramos el botón de "Eliminar" si:
          // Soy 'Owner'
          // Este 'tile' NO soy yo (el usuario que mira, para evitar autoeliminarnos)
          trailing: (myRole == UserRole.owner && !isMe)
              ? IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                    size: 26,
                  ),
                  tooltip: 'Eliminar miembro',
                  // accion si queremos eliminar a un miembro de este espacio
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: const [
                            Icon(Icons.person_remove, color: Colors.red, size: 26),
                            SizedBox(width: 10),
                            Text('Eliminar miembro'),
                          ],
                        ),
                        content: const Text(
                          '¿Seguro que quieres eliminar a este miembro del Espacio?\n'
                          'Podrá volver solo si recibe una nueva invitación.',
                          style: TextStyle(fontSize: 15),
                        ),
                        actionsPadding: const EdgeInsets.only(right: 12, bottom: 12),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                    // si confirma la eliminacion, llamamos al caso de uso del repositorio
                    // y mostramos un mensaje de feedback
                    if (confirmed == true) {
                      await ref.read(removeMemberUseCaseProvider).call(
                        spaceId: spaceId,
                        userIdToRemove: memberId,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Miembro eliminado'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ) : null
        );
      },
    );
  }
}