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

class OndaViajeraSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;
  // Se llama con los bytes PNG cada vez que el usuario toma una
  // captura, para que el módulo de Cuestionario pueda incluirla en el PDF.
  final void Function(Uint8List bytes)? onCapturar;

  const OndaViajeraSim({super.key, this.onIrATeoria, this.onIrACuestionario, this.onCapturar});

  @override
  State<OndaViajeraSim> createState() => _OndaViajeraSimState();
}

class _OndaViajeraSimState extends State<OndaViajeraSim> {
  double tiempo = 0.0;
  Timer? _timer;
  bool _mostrarControles = true;
  bool _estaCorriendo = true; // Estado de la animación (Pausa/Play)

  // Llave global para capturar la pantalla de la simulación de forma aislada
  final GlobalKey _globalKeyCaptura = GlobalKey();

  // Controlador de transformación para Zoom y Pan (desplazamiento) táctil/con botones
  final TransformationController _transformationController = TransformationController();

  // Parámetros de la Onda Única
  double amplitud = 40.0;
  double frecuencia = 1.0;
  double k = 0.03;      // Número de onda
  double phi = 0.0;     // Fase inicial
  bool derecha = true;  // Dirección de movimiento (+x o -x)

  @override
  void initState() {
    super.initState();
    // Forzar modo horizontal al entrar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Timer para la animación continua (aprox 60 FPS)
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

  // Función asíncrona encargada de renderizar y procesar la captura de la simulación
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
                  'Onda viajera registrada con éxito.',
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
            final ampMaxDinamica = (altoDisponible / 2) - 15;

            // Corrección de rango dinámico preventivo
            if (amplitud > ampMaxDinamica) amplitud = ampMaxDinamica;

            // Tamaño real del área de dibujo (sin contar el panel lateral),
            // usado para centrar el zoom con los botones.
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

                                // Selector de dirección estilizado
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
                                // Datos calculados en tiempo real (Útil para el laboratorio)
                                _buildDatoCalculado("Longitud de onda (λ):", "${(2 * math.pi / k).toStringAsFixed(1)} px"),
                                _buildDatoCalculado("Periodo (T):", "${(1 / frecuencia).toStringAsFixed(2)} s"),
                                _buildDatoCalculado("Velocidad de fase (v):", "${((2 * math.pi * frecuencia) / k).toStringAsFixed(1)} px/s"),
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
                      // RepaintBoundary encapsula el área de dibujo para congelar sus pixeles en la captura
                      RepaintBoundary(
                        key: _globalKeyCaptura,
                        child: ZoomableSimulationCanvas(
                          controller: _transformationController,
                          colorFondo: const Color(0xFF0D1117), // Fondo oscuro estilo osciloscopio
                          contenidoPainter: SingleWavePainter(
                            tiempo: tiempo,
                            amplitud: amplitud,
                            frecuencia: frecuencia,
                            k: k,
                            phi: phi,
                            haciaDerecha: derecha,
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
    final w = 2 * math.pi * frecuencia; // Frecuencia angular (omega)

    // NOTA: la cuadrícula de fondo (y sus etiquetas de amplitud) ahora
    // vive en una capa fija aparte (FondoCuadriculaPainter) que nunca se
    // transforma, así el "plano" siempre ocupa el mismo espacio en
    // pantalla y solo la onda hace zoom/pan.

    // Línea de referencia central (Eje X)
    final ejePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, centroY), Offset(size.width, centroY), ejePaint);

    final path = Path();

    for (double x = 0; x <= size.width; x++) {
      // Física del cambio de dirección:
      // Hacia la derecha (+x): kx - wt
      // Hacia la izquierda (-x): kx + wt
      double argumentoTerminoTemporal = haciaDerecha ? (tiempo * w) : -(tiempo * w);
      double y = amplitud * math.sin(k * x - argumentoTerminoTemporal + phi);

      if (x == 0) {
        path.moveTo(x, centroY + y);
      } else {
        path.lineTo(x, centroY + y);
      }
    }

    // Resplandor sutil detrás de la onda para mejorar la lectura visual
    final glowPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glowPaint);

    final wavePaint = Paint()
      ..color = const Color(0xFF00E676) // Verde brillante tipo fósforo de osciloscopio
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(path, wavePaint);

    // Punto guía sobre la onda en el centro para reforzar el sentido de movimiento
    if (size.width > 0) {
      double argumentoTerminoTemporal = haciaDerecha ? (tiempo * w) : -(tiempo * w);
      double yGuia = amplitud * math.sin(k * (size.width * 0.5) - argumentoTerminoTemporal + phi);
      canvas.drawCircle(
        Offset(size.width * 0.5, centroY + yGuia),
        4.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SingleWavePainter oldDelegate) => true;
}