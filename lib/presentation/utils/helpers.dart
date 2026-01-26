import 'package:flutter/material.dart';

/// Helper para decidir el color (Rojo < 30 días, Naranja < 90 días)
Color getUrgencyColor(DateTime? expiryDate) {
  if (expiryDate == null) return Colors.grey;

  final daysUntilExpiry = daysUntil(expiryDate);

  if (daysUntilExpiry < 0) return Colors.red[900]!;
  if (daysUntilExpiry < 30) return Colors.red;
  if (daysUntilExpiry < 90) return Colors.orange[800]!;
  return Colors.green;
}

/// Helper para la diferencia de dias a caducar
int daysUntil(DateTime? date) {
  if (date == null) return 99999;
  return date.difference(DateTime.now()).inDays;
}

/// Helper para formatear fecha (DD/MM/AAAA)
String formatDate(DateTime? date) {
  if (date == null) return 'N/A';
  return '${date.day}/${date.month}/${date.year}';
}