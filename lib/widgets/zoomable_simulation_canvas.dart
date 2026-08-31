import 'package:flutter/material.dart';

/// Pinta ÚNICAMENTE el fondo fijo (color sólido + cuadrícula) de una
/// simulación. Se dibuja siempre al tamaño COMPLETO del área disponible
/// y NUNCA se transforma (no vive dentro del InteractiveViewer), para
/// que el "plano" de la simulación ocupe siempre el mismo espacio en
/// pantalla sin importar el nivel de zoom o el desplazamiento (pan)
/// aplicado al contenido.
class FondoCuadriculaPainter extends CustomPainter {
  final Color colorFondo;
  final Color colorLineas;
  final double pasoMalla;

  const FondoCuadriculaPainter({
    this.colorFondo = const Color(0xFF1A1025),
    this.colorLineas = Colors.white,
    this.pasoMalla = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colorFondo);

    final pinturaMallaFina = Paint()
      ..color = colorLineas.withOpacity(0.02)
      ..strokeWidth = 0.5;
    final pinturaMallaPrincipal = Paint()
      ..color = colorLineas.withOpacity(0.06)
      ..strokeWidth = 1.0;

    for (double y = 0; y <= size.height; y += pasoMalla) {
      final esPrincipal = (y / pasoMalla) % 5 == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina);
    }
    for (double x = 0; x <= size.width; x += pasoMalla) {
      final esPrincipal = (x / pasoMalla) % 5 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina);
    }
  }

  @override
  bool shouldRepaint(covariant FondoCuadriculaPainter oldDelegate) =>
      oldDelegate.colorFondo != colorFondo || oldDelegate.colorLineas != colorLineas;
}

/// Widget reutilizable que corrige el comportamiento del zoom en todas
/// las simulaciones: separa el FONDO (fijo, siempre ocupa el mismo
/// espacio en pantalla) del CONTENIDO (la curva/cuerda/onda), que es lo
/// único que realmente se acerca, aleja o desplaza.
///
/// Antes, el fondo vivía DENTRO del InteractiveViewer junto con el
/// contenido, así que al hacer zoom el "plano" se encogía, se agrandaba
/// o dejaba espacios en blanco alrededor. Ahora el fondo se pinta en una
/// capa aparte que NUNCA se transforma, y el InteractiveViewer solo
/// controla la capa de contenido, recortada (ClipRect) exactamente al
/// tamaño del área visible.
class ZoomableSimulationCanvas extends StatelessWidget {
  final TransformationController controller;
  final CustomPainter contenidoPainter;
  final Color colorFondo;
  final double minScale;
  final double maxScale;
  final EdgeInsets boundaryMargin;
  // Permite reemplazar la cuadrícula genérica por un pintor de fondo a
  // medida (por ejemplo, uno con reglas/escalas en cm o metros). Si se
  // omite, se usa la cuadrícula genérica con [colorFondo].
  final CustomPainter? fondoPainter;

  const ZoomableSimulationCanvas({
    super.key,
    required this.controller,
    required this.contenidoPainter,
    this.colorFondo = const Color(0xFF1A1025),
    this.minScale = 0.5,
    this.maxScale = 6.0,
    this.boundaryMargin = const EdgeInsets.all(600),
    this.fondoPainter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Capa 1 — FONDO FIJO: siempre llena el área disponible, nunca
        // se transforma. El "plano" de la simulación nunca cambia de
        // tamaño ni deja huecos, sin importar el zoom o el pan.
        RepaintBoundary(
          child: CustomPaint(painter: fondoPainter ?? FondoCuadriculaPainter(colorFondo: colorFondo)),
        ),

        // Capa 2 — CONTENIDO: la única capa afectada por el zoom/pan.
        // ClipRect asegura que, aunque el contenido se escale o se
        // desplace, nunca se dibuje fuera del área visible (por encima
        // del fondo fijo).
        ClipRect(
          child: InteractiveViewer(
            transformationController: controller,
            minScale: minScale,
            maxScale: maxScale,
            boundaryMargin: boundaryMargin,
            child: CustomPaint(
              painter: contenidoPainter,
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }
}