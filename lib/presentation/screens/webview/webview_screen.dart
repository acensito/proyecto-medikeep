import 'package:flutter/material.dart';
import 'package:medikeep/core/logging/console.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Pantalla genérica que muestra contenido web usando un WebView.
/// Recibe un [title] para la AppBar y la [url] a cargar.
class WebViewScreen extends StatefulWidget {
  static const String routeName = 'webview';
  final String title;
  final String url;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  // controlador para el mininavegador
  late final WebViewController _controller;
  // variable para saber si la pagina esta cargando
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // configuramos el controlador
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // permitimos el uso de js
      ..setNavigationDelegate(
        NavigationDelegate(
          // activado al cargar
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true; // mostramos el spinner de carga
            });
          },
          // activado al finalizar
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false; // ocultamos el spinner
            });
          },
          // activado si hay error
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false; // ocultamos el spinner
            });
            // Debug
            Console.err('Error al cargar la página: ${error.description}');
          },
        ),
      )
      // indicamos cargar la url pasada
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // -- APPBAR --
      appBar: AppBar(
        title: Text(widget.title), // titulo pasado por parametro
      ),
      // usamos un 'Stack' para poner el spinner de carga sobre el navegador
      body: Stack(
        children: [
          // mininavegador
          WebViewWidget(controller: _controller),

          // spinner
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}