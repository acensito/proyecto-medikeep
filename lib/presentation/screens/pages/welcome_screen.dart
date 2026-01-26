import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medikeep/presentation/providers/providers.dart';

// Pantalla de bienvenida con "minitutorial"
class WelcomeScreen extends ConsumerStatefulWidget {

  static const String routeName = 'welcome';
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();

}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  // controladores de pantallas
  final PageController _pageController = PageController();
  // contador de numero de pantalla
  int _currentPage = 0;

  // controladores para el formulario final
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // metodo para crear el primer space
  void _createFirstSpace() async {
    if (!_formKey.currentState!.validate()) return;
    // marcamos el flag a true como que esta cargando
    setState(() => _isLoading = true);

    // limpiamos el nombre del texto y llamamos al caso de uso
    final name = _nameController.text.trim();
    final result = await ref.read(createSpaceUseCaseProvider).call(name);

    // mostramos resultados
    if (context.mounted) {
      // en caso de fallo
      result.fold(
        (failure) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) async {
          // guardamos en shared preferences que hemos hecho el welcome
          final prefs = ref.read(sharedPreferencesProvider);
          await prefs.setBool(kOnboardingSeenKey, true);

          // refrescamos el auth, y navegamos al home
          ref.invalidate(authStateChangesProvider);
          setState(() => _isLoading = false);
          if (mounted) {
            context.goNamed('home-screen');
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- BOTÓN SALTAR ---
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _currentPage < 5
                    ? TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            6, // Ir a la última página
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('SALTAR'),
                      )
                    : const SizedBox(height: 48),
              ),
            ),

            // --- CARRUSEL DE PÁGINAS ---
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // PÁGINA 1: Introducción
                  _buildTutorialPage(
                    icon: Icons.medication_liquid_outlined,
                    title: 'Tu Botiquín, Bajo Control',
                    description:
                        'Gestiona tus medicamentos, controla las fechas de caducidad y evita compras innecesarias.',
                    color: Colors.blue,
                  ),

                  // PÁGINA 2: Explicación de Spaces
                  _buildTutorialPage(
                    icon: Icons.people_outline,
                    title: 'Comparte tu Espacio',
                    description:
                        'Crea un "Espacio" para tu casa o trabajo. Invita a tu familia o compañeros y gestionad el inventario juntos.',
                    color: Colors.green,
                  ),
                  // PÁGINA 3: Explicación de Compartimentos
                  _buildTutorialPage(
                    icon: Icons.inventory_2_outlined,
                    title: 'Gestiona tus compartimentos',
                    description:
                        'Puedes crear compartimentos para organizar tus medicamentos en los diferentes espacios.',
                    color: Colors.orange,
                  ),
                  // PÁGINA 4: Explicación de Búsqueda
                  _buildTutorialPage(
                    icon: Icons.search_outlined,
                    title: 'Busca y encuentra fácilmente',
                    description:
                        'Localiza con el buscador tus medicamentos o agregalos con facilidad.',
                    color: Colors.deepPurple,
                  ),
                  // PÁGINA 5: Recordatorio advertencia
                  _buildInfoPage(),
                  // PÁGINA 6: Acción (Formulario)
                  _buildCreationPage(),
                ],
              ),
            ),

            // --- INDICADOR DE PÁGINAS (PUNTITOS) ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: Página de Tutorial (Texto e Icono) ---
  Widget _buildTutorialPage({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: color),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPage() {

    const Color customBlue = Color(0xFF0055A4);

    return Container(
      padding: const EdgeInsets.all(24.0),
      color: customBlue,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Se ajusta al contenido
          children: [
            // primera fila: advertencia
            _buildInfoRow(
              icon: Icons.warning_amber_rounded,
              text: 'Y recuerde:'
            ),
            const SizedBox(height: 30),
            // segunda fila
            _buildInfoRow(
              icon: Icons.assignment_outlined,
              text: 'Lea las instrucciones',
            ),
            const SizedBox(height: 30),
            // tercera fila
            _buildInfoRow(
              icon: Icons.science_outlined,
              text: 'de sus medicamentos, y en caso de duda,',
            ),
            const SizedBox(height: 30),
        
            // cuarta fila
            _buildInfoRow(
              icon: Icons.contact_support_outlined,
              text: 'consulte al Farmacéutico o a su Médico',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 60, // Tamaño grande para que destaque como en la imagen
        ),
        const SizedBox(width: 20), // Espacio entre icono y texto
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w400,
              fontFamily: 'Roboto', // Fuente estándar de Flutter
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET: Página Final (Formulario) ---
  Widget _buildCreationPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.home_work_outlined,
                size: 100,
                color: Colors.orange,
              ),
              const SizedBox(height: 32),
              const Text(
                '¡Empecemos!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ponle nombre a tu primer espacio (ej: "Casa").',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del espacio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre no puede estar vacío';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('start_creating_space_btn'),
                  onPressed: _isLoading ? null : _createFirstSpace,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Crear y Entrar',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
              // Añadimos un pequeño espacio extra para que el botón no toque el fondo
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
