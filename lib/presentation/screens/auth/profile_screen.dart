import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/presentation/providers/providers.dart';

/// Pantalla para mostrar perfil de usuario
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final user = authState.asData!.value;
    final colors = Theme.of(context).colorScheme;

    // Obtenemos el usuario actual de Firebase para ver su provider
    final firebaseUser = FirebaseAuth.instance.currentUser;
    // comprobamos si usa password o usa otro tipo de cuenta
    final isPasswordUser = firebaseUser?.providerData.any(
      (info) => info.providerId == 'password') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // --- AVATAR Y DATOS ---
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      user.name?.substring(0, 1).toUpperCase() ?? user.email?.substring(0, 1).toUpperCase() ?? '?',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colors.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name ?? 'Usuario de MediKeep',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),

                  Chip(
                    label: Text(
                      isPasswordUser ? 'Cuenta de Email' : 'Cuenta de Google',
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: Icon(
                      isPasswordUser ? Icons.email_outlined : Icons.g_mobiledata,
                      size: 18,
                    ),
                    // backgroundColor: colors.surfaceVariant.withOpacity(0.5),
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                  
                  const SizedBox(height: 32),
                  // --- LISTA DE ACCIONES ---
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // solo se mostrara si es usuario con email/password
                        if (isPasswordUser) ...[
                          ListTile(
                            leading: const Icon(Icons.lock_reset_rounded),
                            title: const Text('Cambiar Contraseña'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/change-password'),
                          ),
                          const Divider(height: 1),
                        ],
                        // ListTile(
                        //   leading: const Icon(Icons.notifications_none_rounded),
                        //   title: const Text('Ajustes de Notificaciones'),
                        //   trailing: const Icon(Icons.chevron_right),
                        //   onTap: () {
                        //     //Implementar ajustes de notificaciones
                        //   },
                        // ),
                        // const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.logout_rounded, color: colors.error),
                          title: Text('Cerrar Sesión', style: TextStyle(color: colors.error)),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Cerrar Sesión'),
                                content: const Text('¿Estás seguro de que quieres salir?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir')),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref.read(signOutProvider).call();
                              if (context.mounted) context.go('/login');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    'MediKeep v1.0.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }
}