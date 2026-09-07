import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fondo FIJO (usado por los módulos de Modos Normales) con cuadrícula y
/// reglas numéricas: eje horizontal en metros (mapeado a la longitud
/// física real y fija del tubo) y eje vertical con una escala de
/// referencia en centímetros. Vive en una capa aparte que nunca se
/// transforma con el zoom/pan (ver ZoomableSimulationCanvas).
class FondoReglaTuboNormal extends CustomPainter {
  final double longitudFisica; // metros
  final Color colorFondo;

  const FondoReglaTuboNormal({
    required this.longitudFisica,
    this.colorFondo = const Color(0xFF1A1025),
  });

  static const double _margen = 36.0;
  static const double _pxPorCm = 50.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colorFondo);

    const double pasoMalla = 10.0;
    final pinturaMallaFina = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 0.5;
    final pinturaMallaPrincipal = Paint()..color = Colors.white.withOpacity(0.07)..strokeWidth = 1.0;

    for (double y = 0; y <= size.height; y += pasoMalla) {
      final esPrincipal = (y / pasoMalla) % 5 == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina);
    }
    for (double x = 0; x <= size.width; x += pasoMalla) {
      final esPrincipal = (x / pasoMalla) % 5 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina);
    }

    // Regla horizontal: divide el largo útil del tubo en 6 tramos
    // iguales y etiqueta cada uno con su posición real en metros.
    final double largoUtil = size.width - 2 * _margen;
    if (largoUtil > 0) {
      const int divisiones = 6;
      for (int i = 0; i <= divisiones; i++) {
        final double x = _margen + (largoUtil * i / divisiones);
        final double metros = longitudFisica * i / divisiones;
        canvas.drawLine(
          Offset(x, size.height - 16),
          Offset(x, size.height - 8),
          Paint()..color = Colors.cyanAccent.withOpacity(0.35)..strokeWidth = 1,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: "${metros.toStringAsFixed(2)} m",
            style: GoogleFonts.sourceCodePro(fontSize: 8, color: Colors.cyanAccent.withOpacity(0.6), fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset((x - tp.width / 2).clamp(0, size.width - tp.width), size.height - 7));
      }
    }

    // Regla vertical: escala de referencia en centímetros (50 px = 1 cm),
    // etiquetada cada 5 bloques de cuadrícula por encima y por debajo del
    // eje central.
    final double centroY = size.height / 2;
    for (double y = centroY; y >= 0; y -= pasoMalla * 5) {
      _etiquetaCm(canvas, size, y, centroY);
    }
    for (double y = centroY; y <= size.height; y += pasoMalla * 5) {
      _etiquetaCm(canvas, size, y, centroY);
    }
  }

  void _etiquetaCm(Canvas canvas, Size size, double y, double centroY) {
    final double deltaY = -(y - centroY);
    final double cm = deltaY / _pxPorCm;
    if (cm.abs() < 0.05) return;
    final tp = TextPainter(
      text: TextSpan(
        text: "${cm.toStringAsFixed(1)} cm",
        style: GoogleFonts.sourceCodePro(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(4, y - 5));
  }

  @override
  bool shouldRepaint(covariant FondoReglaTuboNormal oldDelegate) =>
      oldDelegate.longitudFisica != longitudFisica || oldDelegate.colorFondo != colorFondo;
}