import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/presentation/providers/auth_provider.dart';

// Pantalla para pedir un correo de cambio de password
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

// control del estado
class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // metodo que controla la solicitud
  void _onReset() async {
    //validamos si el campo de email se encuentra vacio
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    // inciamos el estado de solicitud a "cargando"
    setState(() => _isLoading = true);
    // llamamos al metodo del provider
    final result = await ref.read(sendPasswordResetEmailProvider).call(email);
    // volvemos a cambiar el estado de solicitud a normal
    setState(() => _isLoading = false);

    // mostramos un resultado
    if (mounted) {
      result.fold(
        // si falla
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        ),
        // si todo va correcto
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email enviado. Revisa tu bandeja de entrada.'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // volvemos a la pantalla anterior (login)
        },
      );
    }
  }

  // Widget de la pantalla
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Acceso')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Introduce tu email y te enviaremos las instrucciones para crear una nueva contraseña.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onReset,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('ENVIAR EMAIL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}