import 'package:medikeep/infrastructure/models/models.dart';

/// Clase abstracta que define los metodos de acceso por API Externa
abstract class MedicationApiDataSource {
  /// Busca medicamentos por nombre en la API externa.
  /// Devuelve una lista de Modelos solo con datos de CIMA
  Future<List<MedicationModel>> searchByName(String name);

  /// Busca un medicamento por Código Nacional (CN) en la API externa
  Future<MedicationModel?> getByCn(String cn);
}
