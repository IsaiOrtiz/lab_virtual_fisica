import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart'; // Necesario para la captura de pantalla (RenderRepaintBoundary)
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui; // Necesario para convertir el boundary en imagen bytes
import '../widgets/zoom_pan_controls.dart';
import '../widgets/navegacion_simulacion.dart';

class OndasEstacionariasSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;

  const OndasEstacionariasSim({super.key, this.onIrATeoria, this.onIrACuestionario});

  @override
  State<OndasEstacionariasSim> createState() => _OndasEstacionariasSimState();
}

class _OndasEstacionariasSimState extends State<OndasEstacionariasSim> {
  double tiempo = 0.0;
  Timer? _timer;
  bool _mostrarControles = true;
  bool _estaCorriendo = true; // Estado de la animación (Pausa/Play)

  // Llave global para capturar la pantalla de la simulación de forma aislada
  final GlobalKey _globalKeyCaptura = GlobalKey();

  // Controlador de transformación para Zoom y Pan (desplazamiento) táctil/con botones
  final TransformationController _transformationController = TransformationController();

  // Parámetros de la Onda Estacionaria
  double amplitudComponente = 25.0; // Amplitud A de cada onda viajera
  double frecuencia = 1.0;
  double k = 0.03;                   // Número de onda

  bool mostrarComponentes = true;    // Mostrar las dos ondas viajeras base

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

  // Función asíncrona encargada de renderizar y procesar la captura de la simulación
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
                  'Onda estacionaria registrada con éxito.',
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
            // La onda resultante tendrá amplitud máxima de 2 * amplitudComponente
            final ampMaxDinamica = (altoDisponible / 4) - 10;

            if (amplitudComponente > ampMaxDinamica) {
              amplitudComponente = ampMaxDinamica;
            }

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
                                  "Ondas Estacionarias",
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Divider(),
                                const SizedBox(height: 5),

                                _slider("A", amplitudComponente, 5, ampMaxDinamica, (v) => setState(() => amplitudComponente = v), decimales: 0),
                                _slider("f", frecuencia, 0.1, 2.5, (v) => setState(() => frecuencia = v), decimales: 1, sufijo: " Hz"),
                                _slider("k", k, 0.01, 0.08, (v) => setState(() => k = v), decimales: 3),

                                const Divider(height: 20),

                                CheckboxListTile(
                                  title: Text("Mostrar ondas componentes", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: mostrarComponentes,
                                  activeColor: Colors.teal,
                                  onChanged: (v) => setState(() => mostrarComponentes = v!),
                                ),

                                const Divider(height: 20),
                                Text("Propiedades Físicas:", style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),

                                // Datos analíticos clave para el reporte de laboratorio
                                _buildDatoCalculado("Distancia Nodo-Nodo (λ/2):", "${(math.pi / k).toStringAsFixed(1)} px"),
                                _buildDatoCalculado("Amplitud Máxima (2A):", "${(amplitudComponente * 2).toStringAsFixed(0)} px"),
                                _buildDatoCalculado("Nodos visibles aprox:", ((constraints.maxWidth - (_mostrarControles ? 280 : 0)) / (math.pi / k)).toStringAsFixed(1)),
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
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.5,
                          maxScale: 6.0,
                          boundaryMargin: const EdgeInsets.all(600),
                          child: Container(
                            color: const Color(0xFF0F172A), // Azul pizarra oscuro premium
                            child: CustomPaint(
                              painter: StandingWavePainter(
                                tiempo: tiempo,
                                a: amplitudComponente,
                                f: frecuencia,
                                k: k,
                                dibujarComponentes: mostrarComponentes,
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
                              heroTag: "btnMenuEstacionaria",
                              backgroundColor: Colors.indigo[900],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _mostrarControles = !_mostrarControles),
                              child: Icon(_mostrarControles ? Icons.fullscreen : Icons.fullscreen_exit),
                            ),
                            const SizedBox(width: 10),

                            FloatingActionButton.small(
                              heroTag: "btnPausaEstacionaria",
                              backgroundColor: _estaCorriendo ? Colors.amber[700] : Colors.green[700],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _estaCorriendo = !_estaCorriendo),
                              child: Icon(_estaCorriendo ? Icons.pause : Icons.play_arrow),
                            ),
                            const SizedBox(width: 10),

                            FloatingActionButton.small(
                              heroTag: "btnCapturaEstacionaria",
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
            child: Text(txt, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal[700])),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                activeTrackColor: Colors.teal,
                thumbColor: Colors.teal,
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600])),
          Text(valor, style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo[700])),
        ],
      ),
    );
  }
}

class StandingWavePainter extends CustomPainter {
  final double tiempo, a, f, k;
  final bool dibujarComponentes;

  StandingWavePainter({
    required this.tiempo,
    required this.a,
    required this.f,
    required this.k,
    required this.dibujarComponentes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    final omega = 2 * math.pi * f;

    const double pasoMalla = 10.0;

    final pinturaMallaFina = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;

    final pinturaMallaPrincipal = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 1.0;

    // Cuadrícula de fondo estilo "azul pizarra" + etiquetas de amplitud
    for (double y = 0; y <= size.height; y += pasoMalla) {
      final esPrincipal = (y / pasoMalla) % 5 == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina);

      if (esPrincipal) {
        double deltaY = -(y - centroY);
        if (deltaY.abs() > 0.1) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: "${deltaY.toStringAsFixed(0)} px",
              style: GoogleFonts.sourceCodePro(fontSize: 8, color: Colors.cyanAccent.withOpacity(0.35), fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(8, y - 4));
        }
      }
    }

    for (double x = 0; x <= size.width; x += pasoMalla) {
      final esPrincipal = (x / pasoMalla) % 5 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina);
    }

    // Eje de referencia central
    canvas.drawLine(
      Offset(0, centroY),
      Offset(size.width, centroY),
      Paint()..color = Colors.white.withOpacity(0.18)..strokeWidth = 1.2,
    );

    final pathDerecha = Path();
    final pathIzquierda = Path();
    final pathEstacionaria = Path();

    for (double x = 0; x <= size.width; x++) {
      // Componente viajera hacia la derecha
      double y1 = a * math.sin(k * x - tiempo * omega);
      // Componente viajera hacia la izquierda
      double y2 = a * math.sin(k * x + tiempo * omega);
      // Onda Estacionaria resultante
      double yEstacionaria = y1 + y2;

      if (x == 0) {
        pathDerecha.moveTo(x, centroY + y1);
        pathIzquierda.moveTo(x, centroY + y2);
        pathEstacionaria.moveTo(x, centroY + yEstacionaria);
      } else {
        pathDerecha.lineTo(x, centroY + y1);
        pathIzquierda.lineTo(x, centroY + y2);
        pathEstacionaria.lineTo(x, centroY + yEstacionaria);
      }
    }

    // Dibujar las ondas componentes si el switch está activo (líneas punteadas/delgadas)
    if (dibujarComponentes) {
      canvas.drawPath(
        pathDerecha,
        Paint()..color = Colors.blueAccent.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );
      canvas.drawPath(
        pathIzquierda,
        Paint()..color = Colors.orangeAccent.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );
    }

    // Resplandor sutil detrás de la onda resultante para mejorar la lectura visual
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(pathEstacionaria, glowPaint);

    // Dibujar la Onda Estacionaria Resultante (Línea principal robusta)
    final standingPaint = Paint()
      ..color = const Color(0xFF00E5FF) // Cyan eléctrico hiper-visible
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawPath(pathEstacionaria, standingPaint);

    // Dibujar pequeños marcadores visuales para denotar los Nodos estables en el eje X
    final nodoPaint = Paint()..color = Colors.redAccent.withOpacity(0.55)..style = PaintingStyle.fill;
    final nodoBordePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    double pasoNodo = math.pi / k;
    for (double nx = 0; nx <= size.width; nx += pasoNodo) {
      canvas.drawCircle(Offset(nx, centroY), 4.0, nodoPaint);
      canvas.drawCircle(Offset(nx, centroY), 4.0, nodoBordePaint);
    }
  }

  @override
  bool shouldRepaint(covariant StandingWavePainter oldDelegate) => true;
}
