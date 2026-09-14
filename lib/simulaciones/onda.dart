import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui;
import '../widgets/zoom_pan_controls.dart';
import '../widgets/zoomable_simulation_canvas.dart';
import '../widgets/navegacion_simulacion.dart';

class OndaViajeraSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;
  final void Function(Uint8List bytes, String nota)? onCapturar;

  const OndaViajeraSim({super.key, this.onIrATeoria, this.onIrACuestionario, this.onCapturar});

  @override
  State<OndaViajeraSim> createState() => _OndaViajeraSimState();
}

class _OndaViajeraSimState extends State<OndaViajeraSim> {
  double tiempo = 0.0;
  Timer? _timer;
  bool _mostrarControles = true;
  bool _estaCorriendo = true;

  final GlobalKey _globalKeyCaptura = GlobalKey();
  final TransformationController _transformationController = TransformationController();

  double amplitud = 40.0;
  double frecuencia = 1.0;
  double k = 0.03;
  double phi = 0.0;
  bool derecha = true;

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

        final TextEditingController notaController = TextEditingController();

        showDialog(
          context: context,
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
                    'Onda viajera registrada con éxito.',
                    style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notaController,
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
            final ampMaxDinamica = (altoDisponible / 2) - 15;

            if (amplitud > ampMaxDinamica) amplitud = ampMaxDinamica;

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
                                  "Análisis de Onda",
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Divider(),
                                const SizedBox(height: 5),

                                _slider("A", amplitud, 0, ampMaxDinamica, (v) => setState(() => amplitud = v), decimales: 0),
                                _slider("f", frecuencia, 0.1, 3.0, (v) => setState(() => frecuencia = v), decimales: 1, sufijo: " Hz"),
                                _slider("k", k, 0.01, 0.1, (v) => setState(() => k = v), decimales: 3),
                                _slider("φ", phi, 0, 2 * math.pi, (v) => setState(() => phi = v), decimales: 2, sufijo: " rad"),

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

                                const Divider(height: 24),
                                _buildDatoCalculado("Longitud de onda (λ):", "${(2 * math.pi / k).toStringAsFixed(1)} px"),
                                _buildDatoCalculado("Periodo (T):", "${(1 / frecuencia).toStringAsFixed(2)} s"),
                                _buildDatoCalculado("Velocidad de fase (v):", "${((2 * math.pi * frecuencia) / k).toStringAsFixed(1)} px/s"),
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
                        child: Stack(
                          children: [
                            // 1. Capa de fondo fija con cuadrícula blanca centrada y a escala
                            Positioned.fill(
                              child: CustomPaint(
                                painter: FondoCuadriculaPainter(k: k),
                              ),
                            ),
                            // 2. Capa de la onda con zoom y desplazamiento
                            ZoomableSimulationCanvas(
                              controller: _transformationController,
                              colorFondo: Colors.transparent, // Transparente para ver el fondo blanco debajo
                              contenidoPainter: SingleWavePainter(
                                tiempo: tiempo,
                                amplitud: amplitud,
                                frecuencia: frecuencia,
                                k: k,
                                phi: phi,
                                haciaDerecha: derecha,
                              ),
                            ),
                          ],
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
                              heroTag: "btnMenuOnda",
                              backgroundColor: Colors.indigo[900],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _mostrarControles = !_mostrarControles),
                              child: Icon(_mostrarControles ? Icons.fullscreen : Icons.fullscreen_exit),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton.small(
                              heroTag: "btnPausaOnda",
                              backgroundColor: _estaCorriendo ? Colors.amber[700] : Colors.green[700],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _estaCorriendo = !_estaCorriendo),
                              child: Icon(_estaCorriendo ? Icons.pause : Icons.play_arrow),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton.small(
                              heroTag: "btnCapturaOnda",
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
            child: Text(txt, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
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
          Text(valor, style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[700])),
        ],
      ),
    );
  }
}

// Pintor dedicado para la cuadrícula blanca, centrada y escalada de forma proporcional
class FondoCuadriculaPainter extends CustomPainter {
  final double k;

  FondoCuadriculaPainter({required this.k});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fondo completamente blanco
    final fondoPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, fondoPaint);

    final centroX = size.width / 2;
    final centroY = size.height / 2;

    // Escala basada en el número de onda k para que las divisiones coincidan armónicamente
    final double espaciadoGrid = (2 * math.pi / k) / 4; 

    final lineaSecundariaPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.0;

    final lineaPrincipalPaint = Paint()
      ..color = Colors.grey.withOpacity(0.35)
      ..strokeWidth = 1.5;

    // Dibujar líneas verticales centradas
    double x = centroX;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lineaSecundariaPaint);
      x += espaciadoGrid;
    }
    x = centroX - espaciadoGrid;
    while (x > 0) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lineaSecundariaPaint);
      x -= espaciadoGrid;
    }

    // Dibujar líneas horizontales centradas
    double y = centroY;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lineaSecundariaPaint);
      y += espaciadoGrid;
    }
    y = centroY - espaciadoGrid;
    while (y > 0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lineaSecundariaPaint);
      y -= espaciadoGrid;
    }

    // Ejes principales X e Y pasando estrictamente por el centro
    canvas.drawLine(Offset(0, centroY), Offset(size.width, centroY), lineaPrincipalPaint);
    canvas.drawLine(Offset(centroX, 0), Offset(centroX, size.height), lineaPrincipalPaint);
  }

  @override
  bool shouldRepaint(covariant FondoCuadriculaPainter oldDelegate) => oldDelegate.k != k;
}

class SingleWavePainter extends CustomPainter {
  final double tiempo, amplitud, frecuencia, k, phi;
  final bool haciaDerecha;

  SingleWavePainter({
    required this.tiempo,
    required this.amplitud,
    required this.frecuencia,
    required this.k,
    required this.phi,
    required this.haciaDerecha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    final w = 2 * math.pi * frecuencia;

    final path = Path();

    for (double x = 0; x <= size.width; x++) {
      double argumentoTerminoTemporal = haciaDerecha ? (tiempo * w) : -(tiempo * w);
      double y = amplitud * math.sin(k * x - argumentoTerminoTemporal + phi);

      if (x == 0) {
        path.moveTo(x, centroY + y);
      } else {
        path.lineTo(x, centroY + y);
      }
    }

    // Resplandor ajustado para fondo claro (tono verdoso oscuro/azulado con menor opacidad)
    final glowPaint = Paint()
      ..color = const Color(0xFF00796B).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    final wavePaint = Paint()
      ..color = const Color(0xFF00796B) // Teal oscuro para destacar sobre fondo blanco
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(path, wavePaint);

    if (size.width > 0) {
      double argumentoTerminoTemporal = haciaDerecha ? (tiempo * w) : -(tiempo * w);
      double yGuia = amplitud * math.sin(k * (size.width * 0.5) - argumentoTerminoTemporal + phi);
      canvas.drawCircle(
        Offset(size.width * 0.5, centroY + yGuia),
        4.5,
        Paint()..color = Colors.redAccent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SingleWavePainter oldDelegate) => true;
}