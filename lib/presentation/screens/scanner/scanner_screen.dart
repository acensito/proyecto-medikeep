import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Pantalla que muestra la cámara para escanear códigos de barras.
/// Devuelve el String del código detectado (o null si se cancela).
class ScannerScreen extends StatefulWidget {
  static const routeName = 'scanner';

  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // controlador para manejar la cámara
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, // Evita leer el mismo codigo varias veces seguidas
    returnImage: false, // no necesitamos la imagen, solo el dato obtenido
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Medicamento'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // si detecta un codigo de barras
                  // cerramos la pantalla y devolvemos el leido
                  final code = barcode.rawValue!;
                  debugPrint('Código escaneado: $code');
                  Navigator.of(context).pop(code);
                  return; // salimos para no devolver muchas veces
                }
              }
            },
          ),
          
          // marco de guia
          Center(
            child: Container(
              width: 300,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          // texto de ayuda
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al código de barras o QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white, 
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}