import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/core/errors/failure.dart';
import 'package:medikeep/presentation/providers/providers.dart';


/// Pantalla que se muestra si el usuario NO está autenticado.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Estado para indicar si estamos logueando/cargando
  bool _isLoading = false;
  // Estado para determinar si esta en modo registro
  bool _isRegisterMode = false;

  // clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // controladores de los campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();


  // metodo dispose para liberar recursos
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // metodo auxiliar privado para login con email
  void _onEmailAuth() async {
    // colores del tema
    final colors = Theme.of(context).colorScheme;
    // validamos el formulario
    if (!_formKey.currentState!.validate()) return;
    
    // cambiamos el estado a esta logueandose
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ejcuta la accion dependiendo si se esta registrando o logueando
    final result = _isRegisterMode
        ? await ref.read(registerWithEmailProvider).call(email: email, password: password)
        : await ref.read(signInWithEmailProvider).call(email: email, password: password);

    // controlamos el resultado
    if (mounted) {
      result.fold(
        (failure) {
          // si falló, mostramos error y paramos de cargar
          setState(() => _isLoading = false);
          
          // activamos el tema de colores de warning al obtenber fallo
          final isWarning = failure is ValidationFailure;
          
          final backgroundColor = isWarning 
              ? colors.primary // Aviso Color Teal normal
              : colors.error;  // Error Color Rojo error
          
          // muestra mensaje segun el tipo de mensaje
          final message = isWarning 
              ? 'Aviso: ${failure.message}' 
              : 'Error: ${failure.message}';

          // muestra visualmente un snackbar con el resultado
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
            ),
          );
        },
        (user) {
          // si la identificación es correcta
          // se reprograman las notificaciones de los medicamentos para el usuario
          ref.read(rescheduleAllNotificationsUseCaseProvider).call(user);
          // exito: El AuthRepository ya creó el documento de usuario.
          // forzamos una recarga del estado de autenticacion para que router nos redirija solo
          ref.invalidate(authStateChangesProvider);
        },
      );
    }
  }

  /// Lógica para Iniciar Sesión con Google
  void _onGoogleSignIn() async {
    setState(() => _isLoading = true);
    final result = await ref.read(signInWithGoogleProvider).call();

    if (mounted) {
      result.fold(
        (failure) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${failure.message}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        (user) {
          // Reprogramar notificaciones de los medicamentos para el usuario
          // (Lo hacemos sin await para no bloquear la UI, que corra en segundo plano)
          ref.read(rescheduleAllNotificationsUseCaseProvider).call(user);
          // Éxito, forzamos recarga del estado para el Router
          ref.invalidate(authStateChangesProvider);
        },
      );
    }
  }

  // Widget de la pantalla
  @override
  Widget build(BuildContext context) {
    // colores del tema
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // logo de la aplicación
                Icon(Icons.health_and_safety_outlined, 
                  size: 100, 
                  // Uso del color primario del tema
                  color: colors.primary,
                ),
                const SizedBox(height: 24),
                // texto de bienvenida
                Text(
                  'Bienvenido a MediKeep',
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87
                  ),
                ),
                const SizedBox(height: 8),
                // subtexto
                Text(
                  'Gestiona tu botiquín inteligente',
                  style: TextStyle(
                    fontSize: 16, 
                    color: Colors.grey[600]
                  ),
                ),
                const SizedBox(height: 32),

                // --- Campos de email y contraseña ---
                TextFormField(
                  key: const Key('email_login_field'),
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Introduce un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('password_login_field'),
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),

                // --- Link a restauracion de password ---
                if (!_isRegisterMode)
                  Center(
                    child: TextButton(
                      onPressed: () => context.pushNamed('forgot-password'),
                      child: const Text('¿Has olvidado tu contraseña?'),
                    ),
                  ),

                const SizedBox(height: 16),

                // --- Campo de confirmación de email (solo visible en registro) ---
                if (_isRegisterMode)
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: Icon(Icons.lock_open_outlined),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                if (_isRegisterMode) const SizedBox(height: 16),


                // --- Botón de Login/Registro según estado---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onEmailAuth,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isRegisterMode ? 'Registrarse' : 'Iniciar Sesión',
                          ),
                  ),
                ),
                const SizedBox(height: 24),


                // --- Separador o Texto de Alternativa ---
                const Divider(),
                const SizedBox(height: 16),


                // --- Botón de Google ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _onGoogleSignIn,
                    icon: 
                      Image.asset('assets/google_logo.png',
                      height: 24,
                    ),
                    label: const Text(
                      'O iniciar sesión con Google',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Botón de Alternar Modo Registro/Login ---
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            _formKey.currentState?.reset();
                          });
                        },
                  child: Text(
                    _isRegisterMode
                        ? '¿Ya tienes cuenta? ¡Inicia Sesión!'
                        : '¿No tienes cuenta? ¡Regístrate!',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}