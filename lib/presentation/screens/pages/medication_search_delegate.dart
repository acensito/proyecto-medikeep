import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/medication_search_provider.dart';

/// Clase que establece el delegado para busquedas
class MedicationSearchDelegate extends SearchDelegate<Medication?> {
  // atributos
  final String? spaceId;
  final String _initialQuery; // valor inicial de la búsqueda
  
  // flag que asegura que el auto-rellenado ocurre solo una vez
  bool _isInitialized = false;

  // constructor
  MedicationSearchDelegate({
    this.spaceId,
    String initialQuery = '',
  }) : _initialQuery = initialQuery,
      // si no mostramos consulta previa
      // vemos si tenemos spaceId (busqueda local)
      // o si no tenemos (busqueda en API)
      super(searchFieldLabel: spaceId == null 
            ? 'Buscar en todos mis espacios...' 
            : 'Buscar por Nombre o CN...',
      ); 

  // acciones al construir
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      // si hay texto de búsqueda, ocultamos el icono de la lupa
      // y mostramos uno de limpiar
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  // accion de retorno
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  // accion de mostrar resultados
  @override
  Widget buildResults(BuildContext context) {
    // si está vacío, no buscamos nada
    if (query.trim().isEmpty) return _buildEmptySuggestions();

    return Consumer(
      builder: (context, ref, child) {
        final searchResults = ref.watch(
          orchestratedSearchProvider(SearchQuery(spaceId: spaceId, query: query)),
        );

        return searchResults.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (medications) {
            if (medications.isEmpty) {
              return Center(child: Text('No se encontraron resultados para "$query".'));
            }

            return ListView.builder(
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final med = medications[index];
                final isMine = med.storageBoxId != null; 

                return ListTile(
                  leading: isMine
                      ? const Icon(Icons.inventory, color: Colors.green)
                      : (med.photoUrl != null
                          ? Image.network(med.photoUrl!, width: 40)
                          : const Icon(Icons.cloud_outlined)),
                  title: Text(med.name),
                  subtitle: isMine
                      ? const Text('¡Ya en tu inventario!',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      : Text(med.labtitular ?? 'Catálogo CIMA'),
                  onTap: () {
                    close(context, med);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // widget que muestra los resultados en pantalla
  @override
  Widget buildSuggestions(BuildContext context) {
    // Si tenemos un dato inicial (del escáner) y no hemos inicializado la búsqueda
    if (_initialQuery.isNotEmpty && !_isInitialized) {
      
      // Programamos la actualización para el siguiente frame
      // metodo seguro para evitar congelaciones
      WidgetsBinding.instance.addPostFrameCallback((_) {
        query = _initialQuery; // Escribe el código en la barra
        showResults(context);  // Lanza la vista de resultados automáticamente
      });
      
      _isInitialized = true; // marcamos para no repetir en bucle
      
      // mostramos un spinner mientras hace el cambio rápido
      return const Center(child: CircularProgressIndicator());
    }

    // si tenemos un dato inicial, pero ya hemos inicializado la busqueda
    // mostramos los resultados
    if (query.isNotEmpty) {
      return ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.search, color: Colors.blue),
            title: Text('Buscar "$query"'),
            onTap: () {
              showResults(context);
            },
          ),
        ],
      );
    }

    // si no hay texto de busqueda, se muestra el widget correspondiente
    return _buildEmptySuggestions();
  }

  // widget privado que muestra mensaje en pantalla no hay resultados
  Widget _buildEmptySuggestions() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Busca medicamentos...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}