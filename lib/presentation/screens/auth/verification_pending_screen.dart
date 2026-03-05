
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikeep/presentation/providers/providers.dart';

/// Pantalla que bloquea al usuario hasta que verifique su email.
class VerificationPendingScreen extends ConsumerWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(verificationLoadingProvider);
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 100, color: Colors.teal),
              const SizedBox(height: 32),
              Text(
                '¡Confirma tu correo!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Hemos enviado un enlace a: ${user?.email ?? "tu correo"}. Si no llega, revisa la carpeta de Spam.\nPulsa el enlace del correo para activar tu cuenta.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              
              if (isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton.icon(
                  // llama al provider para comprobar si ha cambiado la verificación
                  onPressed: () => ref.read(checkEmailVerificationActionProvider)(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('YA HE PULSADO EL ENLACE'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // llama al provider para mandar un nuevo email
                    ref.read(sendVerificationEmailActionProvider);
                  },
                  child: const Text('Reenviar enlace de confirmación'),
                ),
              ],
              
              const Spacer(),
              
              // Botón para salir si el usuario se equivocó de correo
              TextButton.icon(
                onPressed: () => ref.read(signOutProvider).call(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Usar otra cuenta'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}