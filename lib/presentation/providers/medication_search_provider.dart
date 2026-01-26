import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/providers/providers.dart';

/// Clase que representa los parámetros de una búsqueda: texto y, opcionalmente,
/// un space concreto por una ID de space dada
class SearchQuery extends Equatable {
  // atributos
  final String? spaceId; // Puede ser null para una busqueda global
  final String query; // Texto de busqueda

  // Constructor
  const SearchQuery({this.spaceId, required this.query});

  // Metodo para comparacion entre objetos
  @override
  List<Object?> get props => [spaceId, query];
}

/// Provider que orquesta la busqueda local y en API de medicamentos
/// Usa `family` para aceptar un objeto `SearchQuery` como parámetro
/// Con este provider, obtenemos asi los medicamentos que tenemos ya y los que no
final orchestratedSearchProvider = FutureProvider.autoDispose.family<List<Medication>, SearchQuery>(
  (ref, searchQuery) async {
    // Casos de uso
    final searchLocalUseCase = ref.watch(searchLocalMedicationsUseCaseProvider);
    final searchExternalUseCase = ref.watch(searchExternalMedicationsUseCaseProvider);
    // Se sanea el texto de la búsqueda
    final query = searchQuery.query.trim();
    // Si el texto esta vacio, se devuelve un resultado vacio
    if (query.isEmpty) return [];

    //En caso contrario, montamos una lista para incorporar resultados
    List<Medication> allLocalResults = [];
    // Debug
    Console.log('🔍 Iniciando búsqueda para: "$query" (SpaceId: ${searchQuery.spaceId})');

    // Si se indica que la busqueda es en un space concreto por su ID
    if (searchQuery.spaceId != null) {
      // Se realiza la busqueda de en dicho space concretamente
      final localResult = await searchLocalUseCase.call(
        spaceId: searchQuery.spaceId!,
        query: query,
      );
      // Añadimos los resultados locales
      allLocalResults.addAll(localResult.getOrElse(() => []));
    } else {
      // Iniciamos una búsqueda global
      // Obtenemos los datos del usuario
      final user = ref.watch(authStateChangesProvider).asData?.value;

      // Solo si hay usuario logueado y tiene espacios asociados
      if (user != null && user.spaceIds.isNotEmpty) {
        // Debug
        Console.log('🏠 Buscando en ${user.spaceIds.length} espacios...');

        // Construimos una lista de Futures, uno por cada espacio
        final futures = user.spaceIds.map((spaceId) => 
            searchLocalUseCase.call(spaceId: spaceId, query: query)
        );

        // Esperamos a que terminen todas las búsquedas en paralelo
        final results = await Future.wait(futures);

        // Recorremos cada resultado y acumulamos los medicamentos encontrados
        for (final result in results) {
          result.fold(
            // Mostramos resultados o fallos a modo debug
            (failure) => Console.err('❌ Error en búsqueda local: ${failure.message}'), 
            (meds) {
              Console.log('✅ Encontrados ${meds.length} en un space');
              allLocalResults.addAll(meds);
            },
          );
        }
      }
    }
    // Debug
    Console.log('📦 Total locales encontrados: ${allLocalResults.length}');

    // Búsqueda de los medicamentos en la API externa
    final externalResult = await searchExternalUseCase.call(query: query);
    final externalList = externalResult.getOrElse(() => []);
    
    // Debug
    Console.log('🌐 Total externos encontrados: ${externalList.length}');

    // Fusión final de resultados:
    // - Primero los locales (para priorizar lo que el usuario ya tiene en sus spaces)
    // - Después los externos (posibles nuevos medicamentos a añadir)
    // La UI será la encargada de distinguir visualmente de dónde viene cada uno.
    return [...allLocalResults, ...externalList];
  },
);