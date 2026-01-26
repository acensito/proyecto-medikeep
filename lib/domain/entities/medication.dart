import 'medication_status.dart'; 
import 'package:equatable/equatable.dart';

// Representa un medicamento con sus propiedades
class Medication extends Equatable {
  //atributos principales
  final String id;  //identificador unico
  final String name; //nombre del medicamento
  final String? cn; //codigo nacional, opcional

  final DateTime? expiryDate;     //fecha de caducidad, opcional
  final MedicationStatus? status; //estado del medicamento, opcional
  final String? storageBoxId;     //id de la caja de almacenamiento, opcional
  final String? spaceId;          //id del espacio de almacenamiento, opcional
  final String? notes;            //notas adicionales, opcional
  final DateTime? addedAt;        //fecha de adicion, opcional  
  final DateTime? updatedAt;      //fecha de actualizacion, opcional 

  final bool prescriptionNeeded;  //indica si se necesita receta
  final bool affectsDriving;      //indica si afecta a la conduccion
  final String? datasheetUrl;     //url de la ficha tecnica, opcional
  final String? prospectusUrl;    //url del prospecto, opcional
  final String? photoUrl;         //url de la foto del medicamento, opcional 
  final String? labtitular;       //nombre del laboratorio titular, opcional
  final String? pactivos;         //principios activos, opcional


  //constructor
  const Medication({
    required this.id,
    required this.name,
    this.cn,
    this.expiryDate,
    this.status,
    this.storageBoxId,
    this.spaceId, // Constructor
    this.notes,
    this.addedAt,
    this.updatedAt,
    required this.prescriptionNeeded,
    required this.affectsDriving,
    this.datasheetUrl,
    this.prospectusUrl,
    this.photoUrl,
    this.labtitular,
    this.pactivos,
  });

  //props para comparar objetos de tipo Medication
  @override
  List<Object?> get props => [
        id, name, cn, expiryDate, status, storageBoxId, spaceId, notes, // Props
        addedAt, updatedAt, prescriptionNeeded, affectsDriving,
        datasheetUrl, prospectusUrl, photoUrl, labtitular, pactivos,
      ];

  //metodo copyWith para crear una copia modificada del medicamento
  Medication copyWith({
    String? id,
    String? name,
    String? cn,
    DateTime? expiryDate,
    MedicationStatus? status,
    String? storageBoxId,
    String? spaceId, // CopyWith
    String? notes,
    DateTime? addedAt,
    DateTime? updatedAt,
    bool? prescriptionNeeded,
    bool? affectsDriving,
    String? datasheetUrl,
    String? prospectusUrl,
    String? photoUrl,
    String? labtitular,
    String? pactivos,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      cn: cn ?? this.cn,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      storageBoxId: storageBoxId ?? this.storageBoxId,
      spaceId: spaceId ?? this.spaceId, // CopyWith
      notes: notes ?? this.notes,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      prescriptionNeeded: prescriptionNeeded ?? this.prescriptionNeeded,
      affectsDriving: affectsDriving ?? this.affectsDriving,
      datasheetUrl: datasheetUrl ?? this.datasheetUrl,
      prospectusUrl: prospectusUrl ?? this.prospectusUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      labtitular: labtitular ?? this.labtitular,
      pactivos: pactivos ?? this.pactivos,
    );
  }
}