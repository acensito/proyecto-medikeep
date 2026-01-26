import 'package:flutter/material.dart';
import 'package:medikeep/domain/entities/medication.dart';
import 'package:medikeep/presentation/utils/helpers.dart';
import 'package:medikeep/presentation/utils/ui_traslations.dart';// Para obtener .label y .color

/// Un widget que reemplaza al ListTile estándar para mostrar un medicamento
/// de forma más informativa y visualmente atractiva.
class MedicationListTile extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onTap;

  const MedicationListTile({
    super.key,
    required this.medication,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Calculamos el color de urgencia para el texto
    final urgencyColor = getUrgencyColor(medication.expiryDate);
    
    // Obtenemos los datos del estado
    final status = medication.status;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Row(
            children: [
              // Indicador de estado
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: status?.color.withValues(alpha: .1) ?? Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(status?.icon ?? Icons.help_outline, color: status?.color ?? Colors.grey),
              ),

              const SizedBox(width: 12),

              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Fecha de Caducidad
                        Icon(Icons.calendar_today, size: 14, color: urgencyColor),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(medication.expiryDate),
                          style: TextStyle(
                            color: urgencyColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        // Separador y Estado
                        const SizedBox(width: 8),
                        Text(
                          '· ${status?.label ?? 'Desconocido'}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // flecha
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}