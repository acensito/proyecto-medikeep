import 'package:dio/dio.dart';
import 'package:medikeep/infrastructure/datasources/medication_api_datasource.dart';
import 'package:medikeep/infrastructure/models/models.dart';

/// Implementación del DataSource que habla con la API de CIMA
class CimaApiDataSourceImpl implements MedicationApiDataSource {
  // URL base de la API CIMA
  static const String _baseUrl = 'https://cima.aemps.es/cima/rest';
  // Instancia de cliente Dio para hacer las peticiones HTTP
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      // Establecemos timeouts para robustez
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  /// Método para buscar medicamentos por nombre.
  /// Recibe un [name] y devuelve una lista de [MedicationModel].
  /// Lanza una excepción si ocurre un error durante la petición.
  @override
  Future<List<MedicationModel>> searchByName(String name) async {
    try {
      // Realizamos la petición GET a la API CIMA por nombre
      final response = await _dio.get(
        '/medicamentos',
        queryParameters: {'nombre': name},
      );
      // Verificamos que la respuesta contiene datos
      if (response.data != null && response.data['resultados'] != null) {
        // Pasamos los resultados como una lista
        final results = response.data['resultados'] as List;
        // Mapeamos los resultados de lista obtenidos de la API al modelo MedicationModel
        return results
            .map(
              (json) =>
                  MedicationModel.fromCimaApi(json as Map<String, dynamic>),
            )
            .toList();
      }
      return []; // No hubo resultados
    } on DioException catch (e) {
      // Manejo de errores específico de Dio
      throw Exception(
        'Error Dio al buscar por nombre en CIMA: ${e.toString()}',
      );
    } catch (e) {
      // Manejo de errores genéricos
      throw Exception('Error inesperado en searchByName: ${e.toString()}');
    }
  }

  /// Método para obtener un medicamento por su código nacional (CN).
  /// Recibe un [cn] y devuelve un [MedicationModel] o null si no se encuentra.
  /// Lanza una excepción si ocurre un error durante la petición.
  @override
  Future<MedicationModel?> getByCn(String cn) async {
    try {
      // Realizamos la petición GET a la API CIMA por codigo nacional
      final response = await _dio.get(
        '/medicamento',
        queryParameters: {'cn': cn},
      );
      // Si la respuesta contiene datos, los convertimos al modelo
      if (response.data != null) {
        // La búsqueda por CN solo devuelve UN SOLO OBJETO
        return MedicationModel.fromCimaApi(
          response.data as Map<String, dynamic>,
        );
      }
      // Si no hay datos, devolvemos null
      return null;
      // Manejo de errores específicos de Dio
    } on DioException catch (e) {
      // La API CIMA devuelve 404 si no encuentra el CN. Dio lo lanza como un error.
      if (e.response?.statusCode == 404) {
        return null;
      }
      // Otros errores de Dio
      throw Exception('Error al buscar por CN en CIMA: ${e.message}');
    } catch (e) {
      // Manejo de errores genéricos
      throw Exception('Error inesperado en getByCn: ${e.toString()}');
    }
  }
}
