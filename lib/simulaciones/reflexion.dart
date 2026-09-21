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

/// Simulación de la Ley de la Reflexión (reflexión ESPECULAR, superficie
/// lisa): un rayo incidente llega a un espejo plano y se refleja de modo
/// que el ángulo de incidencia (θᵢ, medido desde la normal) es siempre
/// igual al ángulo de reflexión (θᵣ). Incluye un eje horizontal (el
/// espejo) y un eje vertical (la normal) como referencia geométrica.
class ReflexionLuzSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;
  final void Function(Uint8List bytes, String nota)? onCapturar;

  const ReflexionLuzSim({super.key, this.onIrATeoria, this.onIrACuestionario, this.onCapturar});

  @override
  State<ReflexionLuzSim> createState() => _ReflexionLuzSimState();
}

class _ReflexionLuzSimState extends State<ReflexionLuzSim> {
  double tiempo = 0.0;
  Timer? _timer;
  bool _mostrarControles = true;
  bool _estaCorriendo = true;

  final GlobalKey _globalKeyCaptura = GlobalKey();
  final TransformationController _transformationController = TransformationController();

  // Parámetros de la simulación
  double anguloIncidencia = 35.0; // grados, medido desde la normal (0-90)
  bool mostrarAngulos = true;

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
                    'Reflexión de la luz registrada con éxito.',
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
                                  "Reflexión de la Luz (superficie lisa)",
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Divider(),
                                const SizedBox(height: 6),

                                _slider("θᵢ", anguloIncidencia, 0, 90, (v) => setState(() => anguloIncidencia = v), decimales: 0, sufijo: "°"),

                                const Divider(height: 20),
                                CheckboxListTile(
                                  title: Text("Mostrar ángulos y ejes", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: mostrarAngulos,
                                  activeColor: Colors.indigo,
                                  onChanged: (v) => setState(() => mostrarAngulos = v!),
                                ),

                                const Divider(height: 24),
                                Text("Ley de la reflexión:", style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),
                                _buildDatoCalculado("Ángulo de incidencia (θᵢ):", "${anguloIncidencia.toStringAsFixed(0)}°"),
                                _buildDatoCalculado("Ángulo de reflexión (θᵣ):", "${anguloIncidencia.toStringAsFixed(0)}°"),
                                const SizedBox(height: 4),
                                Text("θᵢ = θᵣ  (medidos desde la normal)", style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo[700])),
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
                          contenidoPainter: ReflexionPainter(
                            tiempo: tiempo,
                            anguloIncidenciaGrados: anguloIncidencia,
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
                              heroTag: "btnMenuReflexion",
                              backgroundColor: Colors.indigo[900],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _mostrarControles = !_mostrarControles),
                              child: Icon(_mostrarControles ? Icons.fullscreen : Icons.fullscreen_exit),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton.small(
                              heroTag: "btnPausaReflexion",
                              backgroundColor: _estaCorriendo ? Colors.amber[700] : Colors.green[700],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _estaCorriendo = !_estaCorriendo),
                              child: Icon(_estaCorriendo ? Icons.pause : Icons.play_arrow),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton.small(
                              heroTag: "btnCapturaReflexion",
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

class ReflexionPainter extends CustomPainter {
  final double tiempo;
  final double anguloIncidenciaGrados;
  final bool mostrarAngulos;

  ReflexionPainter({
    required this.tiempo,
    required this.anguloIncidenciaGrados,
    required this.mostrarAngulos,
  });

  static const Color colorIncidente = Color(0xFFD32F2F); // rojo
  static const Color colorReflejado = Color(0xFF1565C0); // azul
  static const Color colorEjes = Color(0xFF212121); // gris oscuro / negro

  @override
  void paint(Canvas canvas, Size size) {
    final double espejoY = size.height * 0.6;
    final Offset p = Offset(size.width / 2, espejoY);
    final double theta = anguloIncidenciaGrados * math.pi / 180.0;
    final double radio = math.min(size.width, size.height) * 0.42;

    // ---- Eje horizontal (superficie del espejo) ----
    final paintEje = Paint()
      ..color = colorEjes
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(0, espejoY), Offset(size.width, espejoY), paintEje);

    // Sombreado detrás del espejo (indica el respaldo sólido)
    final paintSombreado = Paint()
      ..color = colorEjes.withOpacity(0.35)
      ..strokeWidth = 1.2;
    for (double x = 0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, espejoY + 4), Offset(x - 10, espejoY + 16), paintSombreado);
    }

    // ---- Eje vertical (normal), a todo lo alto del canvas ----
    canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), Paint()..color = colorEjes..strokeWidth = 1.4);

    // Marcas de grados sobre el eje vertical, como referencia
    if (mostrarAngulos) {
      for (int g = 0; g <= 90; g += 30) {
        if (g == 0) continue;
        final double rad = g * math.pi / 180.0;
        final Offset marca = Offset(p.dx - radio * math.sin(rad), espejoY - radio * math.cos(rad));
        canvas.drawCircle(marca, 1.6, Paint()..color = colorEjes.withOpacity(0.3));
      }
    }

    // ---- Rayo incidente ----
    final Offset origenIncidente = Offset(p.dx - radio * math.sin(theta), espejoY - radio * math.cos(theta));
    _dibujarFlecha(canvas, origenIncidente, p, colorIncidente, grosor: 2.6);

    // ---- Rayo reflejado ----
    final Offset finReflejado = Offset(p.dx + radio * math.sin(theta), espejoY - radio * math.cos(theta));
    _dibujarFlecha(canvas, p, finReflejado, colorReflejado, grosor: 2.6);

    // ---- Arcos y etiquetas de ángulo ----
    if (mostrarAngulos) {
      _dibujarArcoAngulo(canvas, p, -math.pi / 2 - theta, theta, colorIncidente, "θᵢ = ${anguloIncidenciaGrados.toStringAsFixed(0)}°");
      _dibujarArcoAngulo(canvas, p, -math.pi / 2, theta, colorReflejado, "θᵣ = ${anguloIncidenciaGrados.toStringAsFixed(0)}°");
    }

    // ---- Fotón animado viajando por el camino incidente + reflejado ----
    final double largoTotal = radio * 2;
    final double avance = (tiempo * 90) % largoTotal;
    Offset posicion;
    if (avance < radio) {
      posicion = Offset.lerp(origenIncidente, p, avance / radio)!;
    } else {
      posicion = Offset.lerp(p, finReflejado, (avance - radio) / radio)!;
    }
    canvas.drawCircle(posicion, 6, Paint()..color = Colors.black.withOpacity(0.15));
    canvas.drawCircle(posicion, 3.5, Paint()..color = const Color(0xFFFFA000));

    // ---- Etiqueta informativa ----
    final etiqueta = TextPainter(
      text: TextSpan(
        text: "Reflexión especular  ·  θᵢ = θᵣ",
        style: GoogleFonts.sourceCodePro(fontSize: 10, color: colorEjes.withOpacity(0.7), fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    etiqueta.layout();
    etiqueta.paint(canvas, const Offset(12, 10));
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
    final Offset posEtiqueta = Offset(centro.dx + (radioArco + 16) * math.cos(anguloMedio), centro.dy + (radioArco + 16) * math.sin(anguloMedio));
    final tp = TextPainter(
      text: TextSpan(text: etiqueta, style: GoogleFonts.sourceCodePro(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, posEtiqueta - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant ReflexionPainter oldDelegate) => true;
}