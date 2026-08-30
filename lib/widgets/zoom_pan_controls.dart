import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Panel flotante reutilizable que permite hacer ZOOM (acercar/alejar)
/// y desplazarse (PAN) en los 4 ejes (arriba, abajo, izquierda, derecha)
/// dentro del área de una simulación.
///
/// Se usa junto a un [TransformationController] que también debe estar
/// conectado a un [InteractiveViewer] envolviendo el `CustomPaint` de la
/// simulación. De esta forma:
///   - El usuario puede pellizcar (pinch) y arrastrar con el dedo
///     directamente sobre el lienzo (gestos táctiles nativos de
///     [InteractiveViewer]).
///   - Además puede usar estos botones para controles más precisos,
///     útil también en computadoras sin pantalla táctil.
class ZoomPanControls extends StatelessWidget {
  final TransformationController controller;
  final Size viewportSize;
  final double pasoZoom;
  final double pasoPan;

  const ZoomPanControls({
    super.key,
    required this.controller,
    required this.viewportSize,
    this.pasoZoom = 1.2,
    this.pasoPan = 40,
  });

  void _zoomPor(double factor) {
    final Matrix4 m = controller.value.clone();
    final double cx = viewportSize.width / 2;
    final double cy = viewportSize.height / 2;
    // Hacemos zoom centrado en el medio del área visible, no en la
    // esquina (0,0), para que el acercamiento se sienta natural.
    m.translate(cx, cy);
    m.scale(factor);
    m.translate(-cx, -cy);
    controller.value = m;
  }

  void _panPor(double dx, double dy) {
    final Matrix4 m = controller.value.clone();
    m.translate(dx, dy);
    controller.value = m;
  }

  void _resetear() {
    controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Controles de Zoom ---
        _PanelFlotante(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _botonMini(Icons.add, () => _zoomPor(pasoZoom), tooltip: "Acercar"),
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final double escala = controller.value.getMaxScaleOnAxis();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      "${(escala * 100).toStringAsFixed(0)}%",
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              _botonMini(Icons.remove, () => _zoomPor(1 / pasoZoom), tooltip: "Alejar"),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Divider(height: 1, color: Colors.white24),
              ),
              _botonMini(Icons.center_focus_strong, _resetear, tooltip: "Restablecer vista"),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // --- Cruceta de desplazamiento (Pan) en los 4 ejes ---
        _PanelFlotante(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _botonMini(Icons.keyboard_arrow_up, () => _panPor(0, pasoPan), tooltip: "Desplazar arriba"),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _botonMini(Icons.keyboard_arrow_left, () => _panPor(pasoPan, 0), tooltip: "Desplazar izquierda"),
                  const SizedBox(width: 30),
                  _botonMini(Icons.keyboard_arrow_right, () => _panPor(-pasoPan, 0), tooltip: "Desplazar derecha"),
                ],
              ),
              _botonMini(Icons.keyboard_arrow_down, () => _panPor(0, -pasoPan), tooltip: "Desplazar abajo"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _botonMini(IconData icon, VoidCallback onTap, {String? tooltip}) {
    final boton = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: boton) : boton;
  }
}

class _PanelFlotante extends StatelessWidget {
  final Widget child;
  const _PanelFlotante({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: child,
    );
  }
}
