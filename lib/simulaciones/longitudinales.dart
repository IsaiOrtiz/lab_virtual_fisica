import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart'; // Necesario para la captura de pantalla (RenderRepaintBoundary)
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui; // Necesario para convertir el boundary en imagen bytes
import '../widgets/zoom_pan_controls.dart';
import '../widgets/navegacion_simulacion.dart';

/// Simulación de Ondas Longitudinales (p.ej. ondas de sonido).
/// A diferencia de una onda transversal, aquí cada partícula oscila
/// EN LA MISMA dirección de propagación, generando zonas visibles de
/// compresión (partículas muy juntas) y rarefacción (partículas muy
/// separadas), tal como ocurre con el sonido en el aire.
class OndasLongitudinalesSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;

  const OndasLongitudinalesSim({super.key, this.onIrATeoria, this.onIrACuestionario});

  @override
  State<OndasLongitudinalesSim> createState() => _OndasLongitudinalesSimState();
}

class _OndasLongitudinalesSimState extends State<OndasLongitudinalesSim> {
  double tiempo = 0.0;
  Timer? _timer;
  bool _mostrarControles = true;
  bool _estaCorriendo = true;

  final GlobalKey _globalKeyCaptura = GlobalKey();
  final TransformationController _transformationController = TransformationController();

  // Parámetros de la Onda Longitudinal
  double amplitud = 8.0;
  double frecuencia = 1.0;
  double k = 0.03;
  bool derecha = true;
  double numParticulasD = 50; // se maneja como double para reutilizar _slider
  bool mostrarGrafica = true;

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
                  'Onda longitudinal registrada con éxito.',
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

            // Tamaño real del área de dibujo (sin contar el panel lateral)
            final double anchoCanvas = constraints.maxWidth - (_mostrarControles ? 280 : 0);
            final Size tamanoCanvas = Size(anchoCanvas, altoDisponible);

            final int numParticulas = numParticulasD.round();
            // Evitamos que la amplitud provoque que las partículas se
            // entrecrucen de forma caótica: la limitamos según el espacio
            // libre entre partículas en reposo.
            final double espacioReposo = anchoCanvas / numParticulas;
            final double ampMaxDinamica = (espacioReposo * 0.9).clamp(2.0, 60.0);
            if (amplitud > ampMaxDinamica) amplitud = ampMaxDinamica;

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
                                  "Onda Longitudinal (Sonido)",
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Divider(),
                                const SizedBox(height: 5),

                                _slider("A", amplitud, 0, ampMaxDinamica, (v) => setState(() => amplitud = v), decimales: 0),
                                _slider("f", frecuencia, 0.1, 3.0, (v) => setState(() => frecuencia = v), decimales: 1, sufijo: " Hz"),
                                _slider("k", k, 0.01, 0.1, (v) => setState(() => k = v), decimales: 3),
                                _slider("N", numParticulasD, 20, 80, (v) => setState(() => numParticulasD = v), decimales: 0),

                                const Divider(height: 24),
                                Text(
                                  "Dirección de Propagación",
                                  style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ChoiceChip(
                                        label: Center(child: Text('Hacia la Derecha (+x)', style: GoogleFonts.lato(fontSize: 10))),
                                        selected: derecha,
                                        onSelected: (val) { if (val) setState(() => derecha = true); },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ChoiceChip(
                                        label: Center(child: Text('Hacia la Izquierda (-x)', style: GoogleFonts.lato(fontSize: 10))),
                                        selected: !derecha,
                                        onSelected: (val) { if (val) setState(() => derecha = false); },
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(height: 20),
                                CheckboxListTile(
                                  title: Text("Mostrar gráfica de desplazamiento", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: mostrarGrafica,
                                  activeColor: Colors.deepOrange,
                                  onChanged: (v) => setState(() => mostrarGrafica = v!),
                                ),

                                const Divider(height: 24),
                                _buildDatoCalculado("Longitud de onda (λ):", "${(2 * math.pi / k).toStringAsFixed(1)} px"),
                                _buildDatoCalculado("Periodo (T):", "${(1 / frecuencia).toStringAsFixed(2)} s"),
                                _buildDatoCalculado("Velocidad de fase (v):", "${((2 * math.pi * frecuencia) / k).toStringAsFixed(1)} px/s"),
                                _buildDatoCalculado("Partículas simuladas:", "$numParticulas"),
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
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.5,
                          maxScale: 6.0,
                          boundaryMargin: const EdgeInsets.all(600),
                          child: Container(
                            color: const Color(0xFF111827), // Gris pizarra muy oscuro
                            child: CustomPaint(
                              painter: LongitudinalWavePainter(
                                tiempo: tiempo,
                                amplitud: amplitud,
                                frecuencia: frecuencia,
                                k: k,
                                haciaDerecha: derecha,
                                numParticulas: numParticulas,
                                mostrarGrafica: mostrarGrafica,
                              ),
                              child: Container(),
                            ),
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
                              heroTag: "btnMenuLongitudinal",
                              backgroundColor: Colors.indigo[900],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _mostrarControles = !_mostrarControles),
                              child: Icon(_mostrarControles ? Icons.fullscreen : Icons.fullscreen_exit),
                            ),
                            const SizedBox(width: 10),

                            FloatingActionButton.small(
                              heroTag: "btnPausaLongitudinal",
                              backgroundColor: _estaCorriendo ? Colors.amber[700] : Colors.green[700],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _estaCorriendo = !_estaCorriendo),
                              child: Icon(_estaCorriendo ? Icons.pause : Icons.play_arrow),
                            ),
                            const SizedBox(width: 10),

                            FloatingActionButton.small(
                              heroTag: "btnCapturaLongitudinal",
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
            width: 14,
            child: Text(txt, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                activeTrackColor: Colors.deepOrange,
                thumbColor: Colors.deepOrange,
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
          Text(etiqueta, style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600])),
          Text(valor, style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange[700])),
        ],
      ),
    );
  }
}

class LongitudinalWavePainter extends CustomPainter {
  final double tiempo, amplitud, frecuencia, k;
  final bool haciaDerecha;
  final int numParticulas;
  final bool mostrarGrafica;

  LongitudinalWavePainter({
    required this.tiempo,
    required this.amplitud,
    required this.frecuencia,
    required this.k,
    required this.haciaDerecha,
    required this.numParticulas,
    required this.mostrarGrafica,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    final w = 2 * math.pi * frecuencia;
    final double argumentoTiempo = haciaDerecha ? (tiempo * w) : -(tiempo * w);

    // ---- Cuadrícula de fondo (estilo consistente con las demás simulaciones) ----
    const double pasoMalla = 10.0;
    final pinturaMallaFina = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 0.5;
    final pinturaMallaPrincipal = Paint()..color = Colors.white.withOpacity(0.06)..strokeWidth = 1.0;
    for (double y = 0; y <= size.height; y += pasoMalla) {
      final esPrincipal = (y / pasoMalla) % 5 == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina);
    }
    for (double x = 0; x <= size.width; x += pasoMalla) {
      final esPrincipal = (x / pasoMalla) % 5 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina);
    }

    // ---- Gráfica auxiliar de desplazamiento (opcional, parte superior) ----
    final double yGrafica = size.height * 0.22;
    if (mostrarGrafica) {
      final pathGrafica = Path();
      for (double x = 0; x <= size.width; x += 2) {
        double y = amplitud * 2.5 * math.sin(k * x - argumentoTiempo);
        if (x == 0) {
          pathGrafica.moveTo(x, yGrafica + y);
        } else {
          pathGrafica.lineTo(x, yGrafica + y);
        }
      }
      canvas.drawLine(
        Offset(0, yGrafica),
        Offset(size.width, yGrafica),
        Paint()..color = Colors.white.withOpacity(0.15)..strokeWidth = 1,
      );
      canvas.drawPath(
        pathGrafica,
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      final etiqueta = TextPainter(
        text: TextSpan(
          text: "u(x) — desplazamiento horizontal (graficado en vertical)",
          style: GoogleFonts.sourceCodePro(fontSize: 9, color: Colors.cyanAccent.withOpacity(0.6), fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      etiqueta.layout();
      etiqueta.paint(canvas, Offset(8, yGrafica - 26));
    }

    // ---- Fila de partículas (cadena tipo "resorte"/slinky) ----
    final double restSpacing = size.width / numParticulas;
    final double maxDeriv = amplitud * k;

    const Color colorRarefaccion = Color(0xFF42A5F5); // azul: partículas separadas
    const Color colorCompresion = Color(0xFFFF7043); // naranja: partículas comprimidas

    final List<Offset> posiciones = [];
    final List<Color> colores = [];
    final List<double> compresiones = []; // factor 0 (rarefacción) .. 1 (compresión), por partícula

    for (int i = 0; i < numParticulas; i++) {
      final double x0 = i * restSpacing + restSpacing / 2;
      final double desplazamiento = amplitud * math.sin(k * x0 - argumentoTiempo);
      final double x = x0 + desplazamiento;

      // Deformación local du/dx: negativa => compresión, positiva => rarefacción
      final double derivada = amplitud * k * math.cos(k * x0 - argumentoTiempo);
      double t = maxDeriv > 0 ? ((-derivada) + maxDeriv) / (2 * maxDeriv) : 0.5;
      t = t.clamp(0.0, 1.0);

      final Color color = Color.lerp(colorRarefaccion, colorCompresion, t)!;
      posiciones.add(Offset(x, centroY));
      colores.add(color);
      compresiones.add(t);
    }

    // Línea "resorte" conectando partículas consecutivas
    for (int i = 0; i < posiciones.length - 1; i++) {
      canvas.drawLine(
        posiciones[i],
        posiciones[i + 1],
        Paint()
          ..color = Color.lerp(colores[i], colores[i + 1], 0.5)!.withOpacity(0.45)
          ..strokeWidth = 1.5,
      );
    }

    // Partículas (círculos), con resplandor sutil en las más comprimidas
    for (int i = 0; i < posiciones.length; i++) {
      final double t = compresiones[i];
      final double radio = 3.0 + 2.5 * t;

      if (t > 0.55) {
        canvas.drawCircle(
          posiciones[i],
          radio + 4,
          Paint()
            ..color = colores[i].withOpacity(0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawCircle(posiciones[i], radio, Paint()..color = colores[i]);
    }

    // Línea de referencia central (posición de reposo)
    canvas.drawLine(
      Offset(0, centroY + 22),
      Offset(size.width, centroY + 22),
      Paint()..color = Colors.white.withOpacity(0.08)..strokeWidth = 1,
    );
    final etiquetaEje = TextPainter(
      text: TextSpan(
        text: "Compresión (naranja)  ·  Rarefacción (azul)",
        style: GoogleFonts.sourceCodePro(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    etiquetaEje.layout();
    etiquetaEje.paint(canvas, Offset(8, centroY + 26));
  }

  @override
  bool shouldRepaint(covariant LongitudinalWavePainter oldDelegate) => true;
}
