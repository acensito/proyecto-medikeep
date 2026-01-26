import 'package:flutter/material.dart';
import 'package:medikeep/domain/entities/entities.dart';
import 'package:medikeep/presentation/utils/helpers.dart';

/// Widget visual para mostrar un StorageBox (Contenedor) en su Dashboard de Space
class StorageBoxCard extends StatelessWidget {
  final StorageBox storageBox;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const StorageBoxCard({
    super.key,
    required this.storageBox,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // temas de colores
    final colors = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 7,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.primary.withValues(alpha: 1.0),
          width: 3
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Ocupar solo lo necesario
            children: [

              // icono
              Container(
                padding: const EdgeInsets.all(12), 
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.all_inbox_rounded, 
                  size: 28, 
                  color: colors.primary
                ),
              ),
              
              const SizedBox(height: 8), 
              
              // nombre
              Flexible( // Flexible permite que el texto se adapte si falta espacio
                child: Text(
                  storageBox.name,
                  style: const TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // fecha de creacion
              if (storageBox.createdAt != null)
                Text(
                  formatDate(storageBox.createdAt!),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}