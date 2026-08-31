import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart'; // Necesario para la captura de pantalla (RenderRepaintBoundary)
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui; // Necesario para convertir el boundary en imagen bytes
import '../widgets/zoom_pan_controls.dart';
import '../widgets/zoomable_simulation_canvas.dart';
import '../widgets/navegacion_simulacion.dart';

/// Simulación de Modos Normales de vibración de una cuerda fija en
/// ambos extremos. El usuario elige la TENSIÓN (T) y la DENSIDAD LINEAL (μ)
/// de la cuerda, junto con su LONGITUD (L); a partir de ahí se calcula
/// la velocidad de propagación v = √(T/μ) y la frecuencia propia de cada
/// modo fₙ = n·f₁ = n·v/(2L). Permite además seleccionar el armónico
/// (n = 1, 2, 3...) y observar la posición de nodos y antinodos.
class ModosNormalesSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;
  // Se llama con los bytes PNG cada vez que el usuario toma una
  // captura, para que el módulo de Cuestionario pueda incluirla en el PDF.
  final void Function(Uint8List bytes)? onCapturar;

  const ModosNormalesSim({super.key, this.onIrATeoria, this.onIrACuestionario, this.onCapturar});

  @override
  State<ModosNormalesSim> createState() => _ModosNormalesSimState();
}

class _ModosNormalesSimState extends State<ModosNormalesSim> {
  double tiempo = 0.0;
  Timer? _timer;
  bool _mostrarControles = true;
  bool _estaCorriendo = true;

  final GlobalKey _globalKeyCaptura = GlobalKey();
  final TransformationController _transformationController = TransformationController();

  // Parámetros del Modo Normal
  int modo = 2; // Número de armónico "n"
  double amplitud = 50.0;
  bool mostrarEnvolvente = true;
  bool mostrarNodos = true;

  // --- Parámetros físicos de la cuerda ---
  double tension = 5.0;        // T, en Newtons (N)
  double densidadLineal = 30.0; // μ, en gramos por metro (g/m)
  double longitudCuerda = 1.5;  // L, en metros (m)

  static const int modoMaximo = 6;

  // --- Cálculos derivados (v, f1, fn) ---
  double get velocidadPropagacion {
    final double muKgPorM = densidadLineal / 1000.0; // g/m -> kg/m
    if (muKgPorM <= 0) return 0;
    return math.sqrt(tension / muKgPorM);
  }

  double get frecuenciaFundamental {
    if (longitudCuerda <= 0) return 0;
    return velocidadPropagacion / (2 * longitudCuerda);
  }

  double get frecuenciaModo => modo * frecuenciaFundamental;

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
      if (bytes != null) widget.onCapturar?.call(bytes);

      if (bytes != null) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Vista Previa de la Captura',
              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            content: Column(
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
                  'Modo normal registrado con éxito.',
                  style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                ),
              ),
            ],
          ),
        );
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
            final ampMaxDinamica = (altoDisponible / 2) - 30;
            if (amplitud > ampMaxDinamica) amplitud = ampMaxDinamica;

            // Tamaño real del área de dibujo (sin contar el panel lateral)
            final double anchoCanvas = constraints.maxWidth - (_mostrarControles ? 280 : 0);
            final Size tamanoCanvas = Size(anchoCanvas, altoDisponible);

            return Row(
              children: [
                // PANEL DE CONTROLES COLAPSABLE CON ANIMACIÓN
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
                                  "Modos Normales (cuerda fija-fija)",
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Divider(),
                                const SizedBox(height: 6),

                                Text(
                                  "Armónico (n)",
                                  style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: List.generate(modoMaximo, (i) {
                                    final int n = i + 1;
                                    return ChoiceChip(
                                      label: Text("n=$n", style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                                      selected: modo == n,
                                      selectedColor: Colors.purple[100],
                                      onSelected: (val) { if (val) setState(() => modo = n); },
                                    );
                                  }),
                                ),

                                const Divider(height: 24),
                                Text(
                                  "Propiedades físicas de la cuerda",
                                  style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                _slider("A", amplitud, 5, ampMaxDinamica, (v) => setState(() => amplitud = v), decimales: 0),
                                _slider("T", tension, 0.5, 20.0, (v) => setState(() => tension = v), decimales: 1, sufijo: " N"),
                                _slider("μ", densidadLineal, 5.0, 100.0, (v) => setState(() => densidadLineal = v), decimales: 1, sufijo: " g/m"),
                                _slider("L", longitudCuerda, 0.5, 3.0, (v) => setState(() => longitudCuerda = v), decimales: 2, sufijo: " m"),

                                const Divider(height: 20),
                                CheckboxListTile(
                                  title: Text("Mostrar envolvente", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: mostrarEnvolvente,
                                  activeColor: Colors.purple,
                                  onChanged: (v) => setState(() => mostrarEnvolvente = v!),
                                ),
                                CheckboxListTile(
                                  title: Text("Mostrar nodos y antinodos", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: mostrarNodos,
                                  activeColor: Colors.purple,
                                  onChanged: (v) => setState(() => mostrarNodos = v!),
                                ),

                                const Divider(height: 24),
                                Text("Propiedades del modo n=$modo:", style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),
                                _buildDatoCalculado("Velocidad (v = √(T/μ)):", "${velocidadPropagacion.toStringAsFixed(2)} m/s"),
                                _buildDatoCalculado("Frec. fundamental (f₁ = v/2L):", "${frecuenciaFundamental.toStringAsFixed(2)} Hz"),
                                _buildDatoCalculado("Frecuencia (fₙ = n·f₁):", "${frecuenciaModo.toStringAsFixed(2)} Hz"),
                                _buildDatoCalculado("Longitud de onda (λₙ = 2L/n):", "${(2 * longitudCuerda / modo).toStringAsFixed(2)} m"),
                                _buildDatoCalculado("Nodos internos:", "${modo - 1}"),
                                _buildDatoCalculado("Antinodos:", "$modo"),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // ÁREA DE SIMULACIÓN + CONTROLES MULTIMEDIA FLOTANTES
                Expanded(
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        key: _globalKeyCaptura,
                        child: ZoomableSimulationCanvas(
                          controller: _transformationController,
                          colorFondo: const Color(0xFF1A1025), // Morado oscuro premium
                          contenidoPainter: NormalModePainter(
                            tiempo: tiempo,
                            amplitud: amplitud,
                            modo: modo,
                            frecuenciaModo: frecuenciaModo,
                            mostrarEnvolvente: mostrarEnvolvente,
                            mostrarNodos: mostrarNodos,
                          ),
                        ),
                      ),

                      // PANEL DE ZOOM Y DESPLAZAMIENTO (arriba a la derecha)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: ZoomPanControls(
                          controller: _transformationController,
                          viewportSize: tamanoCanvas,
                        ),
                      ),

                      // ACCESO RÁPIDO A TEORÍA / CUESTIONARIO (arriba a la izquierda)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: BotonesNavegacionTabs(
                          onIrATeoria: widget.onIrATeoria,
                          onIrACuestionario: widget.onIrACuestionario,
                        ),
                      ),

                      // BOTONERA DE CONTROL FLOTANTE (Abajo a la izquierda)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Row(
                          children: [
                            FloatingActionButton.small(
                              heroTag: "btnMenuModoNormal",
                              backgroundColor: Colors.indigo[900],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _mostrarControles = !_mostrarControles),
                              child: Icon(_mostrarControles ? Icons.fullscreen : Icons.fullscreen_exit),
                            ),
                            const SizedBox(width: 10),

                            FloatingActionButton.small(
                              heroTag: "btnPausaModoNormal",
                              backgroundColor: _estaCorriendo ? Colors.amber[700] : Colors.green[700],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _estaCorriendo = !_estaCorriendo),
                              child: Icon(_estaCorriendo ? Icons.pause : Icons.play_arrow),
                            ),
                            const SizedBox(width: 10),

                            FloatingActionButton.small(
                              heroTag: "btnCapturaModoNormal",
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

  Widget _slider(String txt, double val, double min, double max, ValueChanged<double> cb, {int decimales = 2, String sufijo = ""}) {
    double valorSeguro = val;
    if (valorSeguro < min) valorSeguro = min;
    if (valorSeguro > max) valorSeguro = max;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(txt, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                activeTrackColor: Colors.purple,
                thumbColor: Colors.purple,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(value: valorSeguro, min: min, max: max, onChanged: cb),
            ),
          ),
          SizedBox(
            width: 55,
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
          Text(valor, style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple[700])),
        ],
      ),
    );
  }
}

class NormalModePainter extends CustomPainter {
  final double tiempo, amplitud;
  final double frecuenciaModo; // fₙ ya calculada (n · v / 2L), en Hz
  final int modo;
  final bool mostrarEnvolvente, mostrarNodos;

  NormalModePainter({
    required this.tiempo,
    required this.amplitud,
    required this.modo,
    required this.frecuenciaModo,
    required this.mostrarEnvolvente,
    required this.mostrarNodos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    const double margen = 36.0;
    final double largoCuerda = size.width - 2 * margen;
    if (largoCuerda <= 0) return;

    final double wn = 2 * math.pi * frecuenciaModo;

    // NOTA: la cuadrícula de fondo ya no se dibuja aquí — vive en una
    // capa fija aparte (FondoCuadriculaPainter) que nunca se transforma,
    // así el "plano" de la simulación siempre ocupa el mismo espacio en
    // pantalla y solo la cuerda hace zoom/pan.

    // Eje central de referencia
    canvas.drawLine(
      Offset(margen, centroY),
      Offset(size.width - margen, centroY),
      Paint()..color = Colors.white.withOpacity(0.15)..strokeWidth = 1,
    );

    // ---- Envolvente (curvas guía ± amplitud·sin) ----
    if (mostrarEnvolvente) {
      final pathSup = Path();
      final pathInf = Path();
      for (double xi = 0; xi <= largoCuerda; xi += 2) {
        final double env = amplitud * math.sin(modo * math.pi * xi / largoCuerda).abs();
        final double x = margen + xi;
        if (xi == 0) {
          pathSup.moveTo(x, centroY - env);
          pathInf.moveTo(x, centroY + env);
        } else {
          pathSup.lineTo(x, centroY - env);
          pathInf.lineTo(x, centroY + env);
        }
      }
      final paintEnvolvente = Paint()
        ..color = Colors.purpleAccent.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      _dibujarLineaPunteada(canvas, pathSup, paintEnvolvente);
      _dibujarLineaPunteada(canvas, pathInf, paintEnvolvente);
    }

    // ---- Forma instantánea de la cuerda ----
    final pathCuerda = Path();
    for (double xi = 0; xi <= largoCuerda; xi += 1) {
      final double x = margen + xi;
      final double y = amplitud * math.sin(modo * math.pi * xi / largoCuerda) * math.cos(wn * tiempo);
      if (xi == 0) {
        pathCuerda.moveTo(x, centroY - y);
      } else {
        pathCuerda.lineTo(x, centroY - y);
      }
    }

    final glowPaint = Paint()
      ..color = const Color(0xFFE040FB).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(pathCuerda, glowPaint);

    canvas.drawPath(
      pathCuerda,
      Paint()
        ..color = const Color(0xFFE040FB) // Magenta vibrante
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // ---- Soportes fijos en los extremos ----
    _dibujarSoporteFijo(canvas, Offset(margen, centroY));
    _dibujarSoporteFijo(canvas, Offset(size.width - margen, centroY));

    // ---- Nodos y antinodos ----
    if (mostrarNodos) {
      // Nodos: xi = m * L/n, m = 0..n (incluye extremos, ya marcados como soportes)
      for (int m = 1; m < modo; m++) {
        final double xi = m * largoCuerda / modo;
        final double x = margen + xi;
        canvas.drawCircle(Offset(x, centroY), 5.0, Paint()..color = Colors.redAccent.withOpacity(0.85));
        canvas.drawCircle(Offset(x, centroY), 5.0, Paint()..color = Colors.white.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }
      // Antinodos: guía vertical punteada en xi = (m+0.5) * L/n
      for (int m = 0; m < modo; m++) {
        final double xi = (m + 0.5) * largoCuerda / modo;
        final double x = margen + xi;
        final pathGuia = Path()
          ..moveTo(x, 12)
          ..lineTo(x, size.height - 12);
        _dibujarLineaPunteada(
          canvas,
          pathGuia,
          Paint()
            ..color = Colors.cyanAccent.withOpacity(0.25)
            ..strokeWidth = 1.0,
          dashWidth: 4,
          gapWidth: 5,
        );
      }
    }

    // ---- Etiqueta informativa ----
    final etiqueta = TextPainter(
      text: TextSpan(
        text: "Modo n=$modo  ·  fₙ=${frecuenciaModo.toStringAsFixed(2)} Hz",
        style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    etiqueta.layout();
    etiqueta.paint(canvas, Offset(margen, 10));
  }

  void _dibujarSoporteFijo(Canvas canvas, Offset punto) {
    final Path triangulo = Path()
      ..moveTo(punto.dx, punto.dy)
      ..lineTo(punto.dx - 8, punto.dy + 14)
      ..lineTo(punto.dx + 8, punto.dy + 14)
      ..close();
    canvas.drawPath(triangulo, Paint()..color = Colors.white70);
    canvas.drawLine(
      Offset(punto.dx - 12, punto.dy + 14),
      Offset(punto.dx + 12, punto.dy + 14),
      Paint()..color = Colors.white70..strokeWidth = 2,
    );
  }

  void _dibujarLineaPunteada(Canvas canvas, Path path, Paint paint, {double dashWidth = 5, double gapWidth = 4}) {
    for (final metric in path.computeMetrics()) {
      double distancia = 0;
      bool dibujar = true;
      while (distancia < metric.length) {
        final double siguiente = distancia + (dibujar ? dashWidth : gapWidth);
        if (dibujar) {
          final double fin = math.min(siguiente, metric.length);
          final extracto = metric.extractPath(distancia, fin);
          canvas.drawPath(extracto, paint);
        }
        distancia = siguiente;
        dibujar = !dibujar;
      }
    }
  }

  @override
  bool shouldRepaint(covariant NormalModePainter oldDelegate) => true;
}