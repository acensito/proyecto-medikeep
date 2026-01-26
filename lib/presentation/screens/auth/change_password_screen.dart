import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/presentation/providers/auth_provider.dart';

/// Pantalla para cambiar el password
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false; // estado si esta cargando el cambio de contraseña

  // metodo privado para cambiar la contraseña
  void _onChange() async {
    //obtenemos la contraseña y validamos
    final pass = _passController.text;
    if (pass != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden.')));
      return;
    }
    // si son iguales marcamos el estado como "cargando"
    setState(() => _isLoading = true);
    // llamamos al caso de uso del provider para cambiar la pass
    final result = await ref.read(updatePasswordProvider).call(pass);
    // cambiamos de nuevo el estado a normal
    setState(() => _isLoading = false);

    // mostramos un resultado
    if (mounted) {
      result.fold(
        // si ha fallado el cambio, mostramos el error
        (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
        // en caso contrario, mostramos mensaje de feedback con el resultado
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada.')));
          context.pop();
        },
      );
    }
  }

  // Widget de la pantalla
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva Contraseña'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar Contraseña'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _onChange,
              child: const Text('ACTUALIZAR'),
            )
          ],
        ),
      ),
    );
  }
}