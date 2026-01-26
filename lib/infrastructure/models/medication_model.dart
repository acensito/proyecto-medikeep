import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:medikeep/domain/entities/entities.dart';

/// Modelo de datos para el Medicamento.
/// Implementación manual
/// Refleja la estructura del documento /space/storagebox/{medicationId}
/// Corresponden con la entidad de dominio
class MedicationModel extends Equatable {
  final String id;
  final String name;
  final String? cn;
  
  final DateTime? expiryDate; 
  final String? status; 
  final String? storageBoxId; 
  final String? spaceId;
  final String? notes; 
  final DateTime? addedAt; 
  final DateTime? updatedAt; 

  final bool? prescriptionNeeded; 
  final bool? affectsDriving; 
  final String? datasheetUrl; 
  final String? prospectusUrl; 
  final String? photoUrl; 
  final String? labtitular; 
  final String? pactivos; 

  const MedicationModel({
    required this.id,
    required this.name,
    this.cn,
    this.expiryDate,
    this.status,
    this.storageBoxId,
    this.spaceId,
    this.notes,
    this.addedAt,
    this.updatedAt,
    this.prescriptionNeeded,
    this.affectsDriving,
    this.datasheetUrl,
    this.prospectusUrl,
    this.photoUrl,
    this.labtitular,
    this.pactivos,
  });

  // --- METODOS DE MAPEO DE DATOS ---

  // Crea un MedicationModel con datos recibidos de un documento
  // de Firestore.
  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {

    // Obtenemos los datos del documento
    final data = doc.data() as Map<String, dynamic>? ?? {};
    // Obtenemos el spaceID desde la ruta del documento
    final extractedSpaceId = doc.reference.parent.parent?.id;

    // Mapeamos los datos obtenidos a un objeto MedicationModel
    return MedicationModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Nombre Desconocido',
      cn: data['cn'] as String?,
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      status: data['status'] as String?,
      storageBoxId: data['storageBoxId'] as String?,
      spaceId: extractedSpaceId, // Asignamos el ID extraído
      notes: data['notes'] as String?,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      prescriptionNeeded: data['prescriptionNeeded'] as bool?,
      affectsDriving: data['affectsDriving'] as bool?,
      datasheetUrl: data['datasheetUrl'] as String?,
      prospectusUrl: data['prospectusUrl'] as String?,
      photoUrl: data['photoUrl'] as String?,
      labtitular: data['labtitular'] as String?,
      pactivos: data['pactivos'] as String?,
    );
  }

  // Factory que  mapea los datos de la API CIMA
  factory MedicationModel.fromCimaApi(Map<String, dynamic> json) {
    // Busca la url de un documento según su tipo.
    // Este metodo interno sirve para recuperar la url del prospecto
    // o del folleto de caracteristicas dependiendo del valor entero de
    // posicion que se reciba.
    String? findDocUrl(int tipo) {
      // Si el campo 'docs' no existe, devuelve null
      if (json['docs'] == null) return null;
      try {
        // Convierte el json en una lista y busca la primera coincidencia
        // que coincida con el parametro tipo
        // (1) Caracteristicas
        // (2) Prospecto
        final doc = (json['docs'] as List).firstWhere((d) => d['tipo'] == tipo);
        // Devuelve la url, que puede ser null
        return doc['urlHtml'] as String?;
        // En caso de errores, se devuelve null
      } catch (e) { return null; }
    }
    // Este metodo interno obtiene la primera fotografía de un medicamento
    // recibe por parametro un string que identifica la fotografía a obtener de los
    // datos recibidos por CIMA
    String? findPhotoUrl(String tipo) {
      // Si se recibe null, se devuelve null
      if (json['fotos'] == null) return null;
      try {
        // Se convierte el json en lista y se busca la primera coincidencia con el
        // parametro string 'tipo'
        final photo = (json['fotos'] as List).firstWhere((f) => f['tipo'] == tipo);
        // Devuelve una url de imagen, que puede ser null
        return photo['url'] as String?;
        // En caso de error devolvemos null
      } catch (e) { return null; }
    }

    // Devolvemos el MedicationModel con los campos mapeados
    return MedicationModel(
      id: json['nregistro'] as String? ?? '',
      name: json['nombre'] as String? ?? 'Nombre Desconocido',
      cn: json['nregistro'] as String?,
      prescriptionNeeded: json['receta'] as bool?,
      affectsDriving: json['conduc'] as bool?,
      datasheetUrl: findDocUrl(1),
      prospectusUrl: findDocUrl(2),
      photoUrl: findPhotoUrl('materialas'),
      labtitular: json['labtitular'] as String?,
      pactivos: json['pactivos'] as String?,
      expiryDate: null,
      status: null,
      storageBoxId: null,
      spaceId: null, // No tiene Space porque es de la API
      notes: null,
      addedAt: null,
      updatedAt: null,
    );
  }

  // Factory que mapea una entidad Medication a un MedicationModel
  factory MedicationModel.fromEntity(Medication entity) {
    return MedicationModel(
      id: entity.id,
      name: entity.name,
      cn: entity.cn,
      expiryDate: entity.expiryDate,
      status: entity.status?.name,
      storageBoxId: entity.storageBoxId,
      spaceId: entity.spaceId, // Mapper
      notes: entity.notes,
      addedAt: entity.addedAt,
      updatedAt: entity.updatedAt,
      prescriptionNeeded: entity.prescriptionNeeded,
      affectsDriving: entity.affectsDriving,
      datasheetUrl: entity.datasheetUrl,
      prospectusUrl: entity.prospectusUrl,
      photoUrl: entity.photoUrl,
      labtitular: entity.labtitular,
      pactivos: entity.pactivos,
    );
  }

  // Convierte el objeto en un mapa para JSON para uso en Firestore
  Map<String, dynamic> toJsonForFirestore() {
    return {
      'name': name,
      'cn': cn,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'status': status,
      'storageBoxId': storageBoxId,
      'notes': notes,
      'addedAt': addedAt != null ? Timestamp.fromDate(addedAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'prescriptionNeeded': prescriptionNeeded,
      'affectsDriving': affectsDriving,
      'datasheetUrl': datasheetUrl,
      'prospectusUrl': prospectusUrl,
      'photoUrl': photoUrl,
      'labtitular': labtitular,
      'pactivos': pactivos,
    };
  }
  
  // Convierte el objeto a una entidad Medication
  Medication toEntity() {
    return Medication(
      id: id,
      name: name,
      cn: cn,
      expiryDate: expiryDate,
      status: _statusFromString(status),
      storageBoxId: storageBoxId,
      spaceId: spaceId,
      notes: notes,
      addedAt: addedAt,
      updatedAt: updatedAt,
      prescriptionNeeded: prescriptionNeeded ?? false,
      affectsDriving: affectsDriving ?? false,
      datasheetUrl: datasheetUrl,
      prospectusUrl: prospectusUrl,
      photoUrl: photoUrl,
      labtitular: labtitular,
      pactivos: pactivos,
    );
  }

  // Lista de campos para comparar entre objetos si son iguales
  @override
  List<Object?> get props => [
        id, name, cn, expiryDate, status, storageBoxId, spaceId, notes,
        addedAt, updatedAt, prescriptionNeeded, affectsDriving,
        datasheetUrl, prospectusUrl, photoUrl, labtitular, pactivos
      ];

  // Metodo que devuelve un MedicationStatus o null segun el string del status
  // que recibe.
  MedicationStatus? _statusFromString(String? statusString) {
    // Si el status es null, devuelve null
    if (statusString == null) return null;
    // Busca en el ENUM de MedicationStatus y devuelve la primera coincidencia
    return MedicationStatus.values.firstWhere(
      (e) => e.name == statusString,
      // Si no la halla, devuelve medicamento cerrado (unopened)
      orElse: () => MedicationStatus.unopened,
    );
  }
}