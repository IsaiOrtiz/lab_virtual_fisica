import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/navegacion_simulacion.dart';
import '../widgets/zoom_pan_controls.dart';
import '../widgets/zoomable_simulation_canvas.dart';

/// Los 4 materiales disponibles para combinar en la refracción. El mismo
/// material no puede elegirse en ambos lados de la interfaz.
const List<(String, double)> materialesRefraccion = [
  ('Aire', 1.00),
  ('Agua', 1.33),
  ('Vidrio', 1.52),
  ('Diamante', 2.42),
];

/// Simulación de la Ley de Snell (refracción de la luz): el usuario elige
/// DOS materiales distintos (uno arriba, uno abajo de la interfaz) de un
/// menú de 4 opciones, y un ángulo de incidencia de 0° a 90°. Muestra el
/// rayo refractado, el rayo parcialmente reflejado, y detecta la
/// Reflexión Total Interna (RTI) cuando corresponde.
class RefraccionLuzSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;
  final void Function(Uint8List bytes, String nota)? onCapturar;

  const RefraccionLuzSim({super.key, this.onIrATeoria, this.onIrACuestionario, this.onCapturar});

  @override
  State<RefraccionLuzSim> createState() => _RefraccionLuzSimState();
}

class _RefraccionLuzSimState extends State<RefraccionLuzSim> {
  double tiempo = 0.0;
  Timer? _timer;
  bool _mostrarControles = true;
  bool _estaCorriendo = true;

  final GlobalKey _globalKeyCaptura = GlobalKey();
  final TransformationController _transformationController = TransformationController();

  // Índices dentro de materialesRefraccion. Nunca pueden ser iguales.
  int indiceMedio1 = 0; // Aire, arriba
  int indiceMedio2 = 1; // Agua, abajo

  double anguloIncidencia = 30.0; // grados, medido desde la normal (0-90)
  bool mostrarReflexionParcial = true;
  bool mostrarAngulos = true;

  double get n1 => materialesRefraccion[indiceMedio1].$2;
  double get n2 => materialesRefraccion[indiceMedio2].$2;

  void _elegirMedio1(int indice) {
    if (indice == indiceMedio2) return; // no se permite repetir material
    setState(() => indiceMedio1 = indice);
  }

  void _elegirMedio2(int indice) {
    if (indice == indiceMedio1) return; // no se permite repetir material
    setState(() => indiceMedio2 = indice);
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_estaCorriendo) {
        setState(() {
          tiempo += 0.05;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _transformationController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // --- Cálculos derivados (Ley de Snell) ---
  double get _theta1Rad => anguloIncidencia * math.pi / 180.0;

  double get _sinTheta2 => (n1 / n2) * math.sin(_theta1Rad);

  bool get _hayReflexionTotalInterna => _sinTheta2.abs() > 1.0;

  double? get _theta2Grados {
    if (_hayReflexionTotalInterna) return null;
    return math.asin(_sinTheta2) * 180.0 / math.pi;
  }

  double? get _anguloCriticoGrados {
    if (n1 <= n2) return null; // solo existe ángulo crítico si n1 > n2
    return math.asin(n2 / n1) * 180.0 / math.pi;
  }

  Future<void> _capturarSimulacion() async {
    try {
      RenderRepaintBoundary? boundary = _globalKeyCaptura.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (bytes != null) {
        if (!mounted) return;

        // Pausamos la simulación mientras se revisa la captura: si sigue
        // corriendo y redibujando en segundo plano, el diálogo se siente
        // como si "pasara muy rápido" y no da tiempo de escribir la nota.
        final bool estabaCorriendoAntesDeCapturar = _estaCorriendo;
        if (_estaCorriendo) {
          setState(() => _estaCorriendo = false);
        }

        final TextEditingController notaController = TextEditingController();

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFFF5F6FA),
            title: Text(
              'Vista Previa de la Captura',
              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Image.memory(bytes),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Refracción de la luz registrada con éxito.',
                    style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notaController,
                    autofocus: true,
                    maxLines: 3,
                    style: GoogleFonts.lato(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Tu interpretación (opcional)',
                      labelStyle: GoogleFonts.lato(fontSize: 11),
                      hintText: 'Escribe qué observas en esta captura...',
                      hintStyle: GoogleFonts.lato(fontSize: 11, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                child: const Text('Descartar'),
              ),
              FilledButton.icon(
                onPressed: () {
                  widget.onCapturar?.call(bytes, notaController.text.trim());
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text('Guardar'),
              ),
            ],
          ),
        );

        if (mounted && estabaCorriendoAntesDeCapturar) {
          setState(() => _estaCorriendo = true);
        }
      }
    } catch (e) {
      debugPrint("Error al exportar captura: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final altoDisponible = constraints.maxHeight;
            final double anchoCanvas = constraints.maxWidth - (_mostrarControles ? 280 : 0);
            final Size tamanoCanvas = Size(anchoCanvas, altoDisponible);

            return Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _mostrarControles ? 280 : 0,
                  child: _mostrarControles
                      ? Container(
                          color: Colors.grey[100],
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Refracción de la Luz",
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Divider(),
                                const SizedBox(height: 6),

                                _slider("θ₁", anguloIncidencia, 0, 90, (v) => setState(() => anguloIncidencia = v), decimales: 0, sufijo: "°"),

                                const Divider(height: 20),
                                Text(
                                  "Medio 1 (arriba)",
                                  style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                _selectorMaterial(indiceMedio1, indiceMedio2, _elegirMedio1),

                                const SizedBox(height: 12),
                                Text(
                                  "Medio 2 (abajo)",
                                  style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                _selectorMaterial(indiceMedio2, indiceMedio1, _elegirMedio2),
                                const SizedBox(height: 4),
                                Text(
                                  "No puedes repetir el mismo material en ambos lados.",
                                  style: GoogleFonts.lato(fontSize: 9, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                ),

                                const Divider(height: 20),
                                CheckboxListTile(
                                  title: Text("Mostrar reflexión parcial", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: mostrarReflexionParcial,
                                  activeColor: Colors.indigo,
                                  onChanged: (v) => setState(() => mostrarReflexionParcial = v!),
                                ),
                                CheckboxListTile(
                                  title: Text("Mostrar ángulos y ejes", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: mostrarAngulos,
                                  activeColor: Colors.indigo,
                                  onChanged: (v) => setState(() => mostrarAngulos = v!),
                                ),

                                const Divider(height: 24),
                                Text("Ley de Snell:  n₁·sen(θ₁) = n₂·sen(θ₂)", style: GoogleFonts.sourceCodePro(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),
                                _buildDatoCalculado("n₁ (${materialesRefraccion[indiceMedio1].$1}):", n1.toStringAsFixed(2)),
                                _buildDatoCalculado("n₂ (${materialesRefraccion[indiceMedio2].$1}):", n2.toStringAsFixed(2)),
                                _buildDatoCalculado("Ángulo de incidencia (θ₁):", "${anguloIncidencia.toStringAsFixed(0)}°"),
                                _buildDatoCalculado(
                                  "Ángulo de refracción (θ₂):",
                                  _hayReflexionTotalInterna ? "No existe (RTI)" : "${_theta2Grados!.toStringAsFixed(1)}°",
                                ),
                                _buildDatoCalculado(
                                  "Ángulo crítico:",
                                  _anguloCriticoGrados == null ? "No aplica (n₁ ≤ n₂)" : "${_anguloCriticoGrados!.toStringAsFixed(1)}°",
                                ),
                                if (_hayReflexionTotalInterna) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      "¡Reflexión Total Interna! Toda la luz se refleja, ninguna se refracta.",
                                      style: GoogleFonts.lato(fontSize: 10, color: Colors.red[800], fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        key: _globalKeyCaptura,
                        child: ZoomableSimulationCanvas(
                          controller: _transformationController,
                          fondoPainter: const FondoCuadriculaPainter(colorFondo: Colors.white, colorLineas: Colors.black),
                          contenidoPainter: RefraccionPainter(
                            tiempo: tiempo,
                            nombreMedio1: materialesRefraccion[indiceMedio1].$1,
                            nombreMedio2: materialesRefraccion[indiceMedio2].$1,
                            n1: n1,
                            n2: n2,
                            anguloIncidenciaGrados: anguloIncidencia,
                            theta2Grados: _theta2Grados,
                            anguloCriticoGrados: _anguloCriticoGrados,
                            hayReflexionTotalInterna: _hayReflexionTotalInterna,
                            mostrarReflexionParcial: mostrarReflexionParcial,
                            mostrarAngulos: mostrarAngulos,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: ZoomPanControls(
                          controller: _transformationController,
                          viewportSize: tamanoCanvas,
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: BotonesNavegacionTabs(
                          onIrATeoria: widget.onIrATeoria,
                          onIrACuestionario: widget.onIrACuestionario,
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Row(
                          children: [
                            FloatingActionButton.small(
                              heroTag: "btnMenuRefraccion",
                              backgroundColor: Colors.indigo[900],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _mostrarControles = !_mostrarControles),
                              child: Icon(_mostrarControles ? Icons.fullscreen : Icons.fullscreen_exit),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton.small(
                              heroTag: "btnPausaRefraccion",
                              backgroundColor: _estaCorriendo ? Colors.amber[700] : Colors.green[700],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _estaCorriendo = !_estaCorriendo),
                              child: Icon(_estaCorriendo ? Icons.pause : Icons.play_arrow),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton.small(
                              heroTag: "btnCapturaRefraccion",
                              backgroundColor: Colors.teal[700],
                              foregroundColor: Colors.white,
                              onPressed: _capturarSimulacion,
                              child: const Icon(Icons.camera_alt),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Fila de chips para elegir un material. [indiceActual] es el que ya
  /// está elegido para ESTE lado; [indiceProhibido] es el elegido en el
  /// OTRO lado (se deshabilita para no poder repetirlo).
  Widget _selectorMaterial(int indiceActual, int indiceProhibido, void Function(int) onElegir) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(materialesRefraccion.length, (i) {
        final (nombre, n) = materialesRefraccion[i];
        final bool prohibido = i == indiceProhibido;
        return ChoiceChip(
          label: Text(
            "$nombre ($n)",
            style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: prohibido ? Colors.grey[400] : null),
          ),
          selected: i == indiceActual,
          selectedColor: Colors.indigo[100],
          onSelected: prohibido ? null : (v) { if (v) onElegir(i); },
        );
      }),
    );
  }

  Widget _slider(String txt, double val, double min, double max, ValueChanged<double> cb, {int decimales = 0, String sufijo = ""}) {
    double valorSeguro = val.clamp(min, max);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(txt, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                activeTrackColor: Colors.indigo,
                thumbColor: Colors.indigo,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(value: valorSeguro, min: min, max: max, onChanged: cb),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              "${valorSeguro.toStringAsFixed(decimales)}$sufijo",
              style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.black87),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatoCalculado(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(etiqueta, style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600]))),
          Text(valor, style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo[700])),
        ],
      ),
    );
  }
}

class RefraccionPainter extends CustomPainter {
  final double tiempo;
  final String nombreMedio1, nombreMedio2;
  final double n1, n2;
  final double anguloIncidenciaGrados;
  final double? theta2Grados;
  final double? anguloCriticoGrados;
  final bool hayReflexionTotalInterna;
  final bool mostrarReflexionParcial;
  final bool mostrarAngulos;

  RefraccionPainter({
    required this.tiempo,
    required this.nombreMedio1,
    required this.nombreMedio2,
    required this.n1,
    required this.n2,
    required this.anguloIncidenciaGrados,
    required this.theta2Grados,
    required this.anguloCriticoGrados,
    required this.hayReflexionTotalInterna,
    required this.mostrarReflexionParcial,
    required this.mostrarAngulos,
  });

  static const Color colorIncidente = Color(0xFFD32F2F); // rojo
  static const Color colorReflejado = Color(0xFFF57C00); // naranja
  static const Color colorRefractado = Color(0xFF2E7D32); // verde
  static const Color colorEjes = Color(0xFF212121);

  @override
  void paint(Canvas canvas, Size size) {
    final double interfazY = size.height / 2;
    final Offset p = Offset(size.width / 2, interfazY);
    final double theta1 = anguloIncidenciaGrados * math.pi / 180.0;
    final double radio = math.min(size.width, size.height) * 0.42;

    // ---- Medios (arriba = medio 1, abajo = medio 2) ----
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, interfazY), Paint()..color = const Color(0xFF90CAF9).withOpacity(0.25));
    canvas.drawRect(Rect.fromLTWH(0, interfazY, size.width, size.height - interfazY), Paint()..color = const Color(0xFF80CBC4).withOpacity(0.30));

    // ---- Eje horizontal (interfaz entre medios) ----
    canvas.drawLine(Offset(0, interfazY), Offset(size.width, interfazY), Paint()..color = colorEjes..strokeWidth = 2.0);

    // ---- Eje vertical (normal), a todo lo alto del canvas ----
    canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), Paint()..color = colorEjes..strokeWidth = 1.4);

    final tpN1 = TextPainter(
      text: TextSpan(text: "$nombreMedio1  (n₁ = ${n1.toStringAsFixed(2)})", style: GoogleFonts.sourceCodePro(fontSize: 11, color: const Color(0xFF1565C0), fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tpN1.paint(canvas, const Offset(12, 10));

    final tpN2 = TextPainter(
      text: TextSpan(text: "$nombreMedio2  (n₂ = ${n2.toStringAsFixed(2)})", style: GoogleFonts.sourceCodePro(fontSize: 11, color: const Color(0xFF00695C), fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tpN2.paint(canvas, Offset(12, size.height - tpN2.height - 10));

    // ---- Rayo incidente (siempre existe, en el medio 1) ----
    final Offset origenIncidente = Offset(p.dx - radio * math.sin(theta1), interfazY - radio * math.cos(theta1));
    _dibujarFlecha(canvas, origenIncidente, p, colorIncidente, grosor: 2.6);

    // ---- Rayo parcialmente reflejado (vuelve al medio 1) ----
    if (mostrarReflexionParcial) {
      final Offset finReflejado = Offset(p.dx + radio * math.sin(theta1), interfazY - radio * math.cos(theta1));
      final double opacidadReflejo = hayReflexionTotalInterna ? 1.0 : 0.4;
      _dibujarFlecha(canvas, p, finReflejado, colorReflejado.withOpacity(opacidadReflejo), grosor: hayReflexionTotalInterna ? 2.8 : 1.6);
    }

    // ---- Rayo refractado (entra al medio 2), si no hay RTI ----
    double? xFinRefractado, yFinRefractado;
    if (!hayReflexionTotalInterna && theta2Grados != null) {
      final double theta2 = theta2Grados! * math.pi / 180.0;
      xFinRefractado = p.dx + radio * math.sin(theta2);
      yFinRefractado = interfazY + radio * math.cos(theta2);
      _dibujarFlecha(canvas, p, Offset(xFinRefractado, yFinRefractado), colorRefractado, grosor: 2.6);
    }

    // ---- Arcos y etiquetas de ángulo ----
    if (mostrarAngulos) {
      _dibujarArcoAngulo(canvas, p, -math.pi / 2 - theta1, theta1, colorIncidente, "θ₁ = ${anguloIncidenciaGrados.toStringAsFixed(0)}°");
      if (!hayReflexionTotalInterna && theta2Grados != null) {
        final double theta2 = theta2Grados! * math.pi / 180.0;
        _dibujarArcoAngulo(canvas, p, math.pi / 2, theta2, colorRefractado, "θ₂ = ${theta2Grados!.toStringAsFixed(1)}°");
      }
    }

    // ---- Fotón animado ----
    final double largoTotal = radio * 2;
    final double avance = (tiempo * 90) % largoTotal;
    Offset posicion;
    if (avance < radio) {
      posicion = Offset.lerp(origenIncidente, p, avance / radio)!;
    } else {
      final double f = (avance - radio) / radio;
      if (!hayReflexionTotalInterna && xFinRefractado != null && yFinRefractado != null) {
        posicion = Offset.lerp(p, Offset(xFinRefractado, yFinRefractado), f)!;
      } else {
        final Offset finReflejado = Offset(p.dx + radio * math.sin(theta1), interfazY - radio * math.cos(theta1));
        posicion = Offset.lerp(p, finReflejado, f)!;
      }
    }
    canvas.drawCircle(posicion, 6, Paint()..color = Colors.black.withOpacity(0.15));
    canvas.drawCircle(posicion, 3.5, Paint()..color = const Color(0xFFFFA000));

    // ---- Mensaje de Reflexión Total Interna ----
    if (hayReflexionTotalInterna) {
      final String sufijo = anguloCriticoGrados != null ? "  (θc = ${anguloCriticoGrados!.toStringAsFixed(1)}°)" : "";
      final tpRti = TextPainter(
        text: TextSpan(
          text: "¡REFLEXIÓN TOTAL INTERNA!$sufijo",
          style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.red[700], fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpRti.paint(canvas, Offset((size.width - tpRti.width) / 2, size.height - tpRti.height - 10));
    }
  }

  void _dibujarFlecha(Canvas canvas, Offset origen, Offset destino, Color color, {double grosor = 2}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = grosor
      ..style = PaintingStyle.stroke;
    canvas.drawLine(origen, destino, paint);

    final double angulo = math.atan2(destino.dy - origen.dy, destino.dx - origen.dx);
    const double tamanoPunta = 9;
    final Path punta = Path()
      ..moveTo(destino.dx, destino.dy)
      ..lineTo(destino.dx - tamanoPunta * math.cos(angulo - math.pi / 7), destino.dy - tamanoPunta * math.sin(angulo - math.pi / 7))
      ..lineTo(destino.dx - tamanoPunta * math.cos(angulo + math.pi / 7), destino.dy - tamanoPunta * math.sin(angulo + math.pi / 7))
      ..close();
    canvas.drawPath(punta, Paint()..color = color);
  }

  void _dibujarArcoAngulo(Canvas canvas, Offset centro, double anguloInicio, double barrido, Color color, String etiqueta) {
    const double radioArco = 34;
    final rect = Rect.fromCircle(center: centro, radius: radioArco);
    canvas.drawArc(rect, anguloInicio, barrido, false, Paint()..color = color.withOpacity(0.85)..style = PaintingStyle.stroke..strokeWidth = 1.8);

    final double anguloMedio = anguloInicio + barrido / 2;
    final Offset posEtiqueta = Offset(centro.dx + (radioArco + 18) * math.cos(anguloMedio), centro.dy + (radioArco + 18) * math.sin(anguloMedio));
    final tp = TextPainter(
      text: TextSpan(text: etiqueta, style: GoogleFonts.sourceCodePro(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, posEtiqueta - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant RefraccionPainter oldDelegate) => true;
}