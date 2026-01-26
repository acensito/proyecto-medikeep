import 'package:flutter/material.dart';
import 'package:medikeep/domain/entities/medication.dart';
import 'package:medikeep/presentation/utils/helpers.dart';

// Widget que define una tarjeta de medicamentos para el dashboard
// tarjeta de medicamentos que requieren atención 
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onTap;
  final double width;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onTap,
    this.width = 190,
  });

  @override
  Widget build(BuildContext context) {
    // variables
    final colors = Theme.of(context).colorScheme;
    final urgencyColor = getUrgencyColor(medication.expiryDate);
    final daysUntilExpiry = daysUntil(medication.expiryDate);
    
    // texto de alerta para el encabezado
    String urgencyText = _getUrgencyText(daysUntilExpiry);

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: urgencyColor.withValues(alpha: .8), width: 3),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABECERA ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: urgencyColor,
                child: Text(
                  urgencyText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // --- CUERPO ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen (Miniatura)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: (medication.photoUrl != null && medication.photoUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  medication.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => _buildPlaceholder(Colors.grey),
                                ),
                              )
                            : _buildPlaceholder(colors.primary.withValues(alpha: .5)),
                      ),
                      const SizedBox(width: 10),

                      // Nombre y Laboratorio
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              medication.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              medication.labtitular ?? 'CIMA',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- PIE (Fecha) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caduca el:',
                      style: TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    Text(
                      formatDate(medication.expiryDate),
                      style: TextStyle(
                        color: urgencyColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Container(
      color: color.withValues(alpha: .1),
      child: Center(
        child: Icon(Icons.medication, size: 24, color: color),
      ),
    );
  }

  /// Helper para decidir el texto segun situacion de caducidad
  String _getUrgencyText(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) return '❌ CADUCADO';
    if (daysUntilExpiry <= 7) return '‼️ HOY O ESTA SEMANA';
    if (daysUntilExpiry <= 30) return '⚠️ 1 MES';
    if (daysUntilExpiry <= 90) return '⏳ 3 MESES';
    return 'OK';
  }

}