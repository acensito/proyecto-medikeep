import 'package:flutter/material.dart';
import 'package:medikeep/domain/entities/medication_status.dart';
import 'package:medikeep/domain/entities/user_role.dart';

/// Extension de la clase MedicationStatus
/// con los getter para obtener los nombres traducidos
extension MedicationStatusX on MedicationStatus {
  
  /// Texto legible en español
  String get label {
    switch (this) {
      case MedicationStatus.unopened:
        return 'Sin Abrir';
      case MedicationStatus.opened:
        return 'Abierto';
      case MedicationStatus.lowstock:
        return 'A Reponer';
    }
  }

  /// Color asociado al estado
  Color get color {
    switch (this) {
      case MedicationStatus.unopened:
        return Colors.green;
      case MedicationStatus.opened:
        return Colors.blue;
      case MedicationStatus.lowstock:
        return Colors.orange;
    }
  }

  /// Icono asociado al estado
  IconData get icon {
    switch (this) {
      case MedicationStatus.unopened:
        return Icons.inventory_2_outlined;
      case MedicationStatus.opened:
        return Icons.medication_liquid_outlined;
      case MedicationStatus.lowstock:
        return Icons.warning_amber_rounded;
    }
  }
}

/// Extensiones (getters) para traducir UserRole
extension UserRoleX on UserRole {
  
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Propietario';
      case UserRole.editor:
        return 'Editor';
      case UserRole.viewer:
        return 'Lector';
    }
  }

  String get description {
    switch (this) {
      case UserRole.owner:
        return 'Control total del espacio';
      case UserRole.editor:
        return 'Puede añadir, editar y borrar';
      case UserRole.viewer:
        return 'Solo puede ver el inventario';
    }
  }
}