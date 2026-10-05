import 'package:flutter/material.dart';

/// Lienzo fijo para las simulaciones.
/// No permite zoom ni desplazamiento: el plano físico ocupa siempre todo
/// el espacio disponible y los pintores trabajan sobre el mismo sistema
/// de coordenadas.
class SimulationCanvas extends StatelessWidget {
  final CustomPainter contenidoPainter;
  final Color colorFondo;
  final CustomPainter? fondoPainter;

  const SimulationCanvas({
    super.key,
    required this.contenidoPainter,
    this.colorFondo = const Color(0xFF18212B),
    this.fondoPainter,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colorFondo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: fondoPainter),
          CustomPaint(painter: contenidoPainter),
        ],
      ),
    );
  }
}

/// Cuadrícula de referencia compartida por las simulaciones ópticas.
///
/// La cuadrícula está centrada en el mismo origen visual del lienzo y usa
/// espaciado fijo, por lo que no depende de zoom ni desplazamiento.
class FondoCuadriculaPainter extends CustomPainter {
  final Color colorFondo;
  final Color colorLineas;
  final double separacion;

  const FondoCuadriculaPainter({
    this.colorFondo = Colors.white,
    this.colorLineas = const Color(0xFFD9DEE5),
    this.separacion = 40.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colorFondo,
    );

    final paint = Paint()
      ..color = colorLineas.withOpacity(0.42)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (double x = cx % separacion; x <= size.width; x += separacion) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double x = cx % separacion - separacion; x >= 0; x -= separacion) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = cy % separacion; y <= size.height; y += separacion) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double y = cy % separacion - separacion; y >= 0; y -= separacion) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant FondoCuadriculaPainter oldDelegate) =>
      oldDelegate.colorFondo != colorFondo ||
      oldDelegate.colorLineas != colorLineas ||
      oldDelegate.separacion != separacion;
}
