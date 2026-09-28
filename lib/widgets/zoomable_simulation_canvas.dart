import 'package:flutter/material.dart';

/// Fondo genérico de una simulación.
/// La cuadrícula forma parte del mismo plano que el contenido, por lo que
/// ambos se transforman juntos al hacer zoom o pan.
class FondoCuadriculaPainter extends CustomPainter {
  final Color colorFondo;
  final Color colorLineas;
  final double pasoMalla;

  const FondoCuadriculaPainter({
    this.colorFondo = const Color(0xFF18212B),
    this.colorLineas = const Color(0xFFB8C4CF),
    this.pasoMalla = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colorFondo);

    final pinturaMallaFina = Paint()
      ..color = colorLineas.withOpacity(0.035)
      ..strokeWidth = 0.5;
    final pinturaMallaPrincipal = Paint()
      ..color = colorLineas.withOpacity(0.075)
      ..strokeWidth = 1.0;

    for (double y = 0; y <= size.height; y += pasoMalla) {
      final esPrincipal = (y / pasoMalla).round() % 5 == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina,
      );
    }

    for (double x = 0; x <= size.width; x += pasoMalla) {
      final esPrincipal = (x / pasoMalla).round() % 5 == 0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FondoCuadriculaPainter oldDelegate) =>
      oldDelegate.colorFondo != colorFondo ||
      oldDelegate.colorLineas != colorLineas ||
      oldDelegate.pasoMalla != pasoMalla;
}

/// Lienzo reutilizable de las simulaciones.
///
/// El fondo y el contenido viven dentro del MISMO InteractiveViewer.
/// De esta forma, la cuadrícula, regla, ejes y simulación conservan siempre
/// la misma escala y posición relativa al hacer zoom o desplazamiento.
class ZoomableSimulationCanvas extends StatelessWidget {
  final TransformationController controller;
  final CustomPainter contenidoPainter;
  final Color colorFondo;
  final double minScale;
  final double maxScale;
  final EdgeInsets boundaryMargin;
  final CustomPainter? fondoPainter;

  const ZoomableSimulationCanvas({
    super.key,
    required this.controller,
    required this.contenidoPainter,
    this.colorFondo = const Color(0xFF18212B),
    this.minScale = 0.75,
    this.maxScale = 2.5,
    this.boundaryMargin = const EdgeInsets.all(80),
    this.fondoPainter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        return ClipRect(
          child: InteractiveViewer(
            transformationController: controller,
            minScale: minScale,
            maxScale: maxScale,
            boundaryMargin: boundaryMargin,
            constrained: true,
            panEnabled: true,
            scaleEnabled: true,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo + cuadrícula: ahora recibe exactamente la misma
                  // transformación que la simulación.
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: fondoPainter ??
                          FondoCuadriculaPainter(colorFondo: colorFondo),
                    ),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: contenidoPainter,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
