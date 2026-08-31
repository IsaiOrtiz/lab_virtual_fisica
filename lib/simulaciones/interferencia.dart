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

class InterferenciaSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;
  // Se llama con los bytes PNG cada vez que el usuario toma una
  // captura, para que el módulo de Cuestionario pueda incluirla en el PDF.
  final void Function(Uint8List bytes)? onCapturar;

  const InterferenciaSim({super.key, this.onIrATeoria, this.onIrACuestionario, this.onCapturar});

  @override
  State<InterferenciaSim> createState() => _InterferenciaSimState();
}

class _InterferenciaSimState extends State<InterferenciaSim> {
  double tiempo = 0.0;
  Timer? _timer;
  bool _mostrarControles = true; 
  bool _estaCorriendo = true; // Estado de la animación (Pausa/Play)

  // Llave global para capturar la pantalla de la simulación de forma aislada
  final GlobalKey _globalKeyCaptura = GlobalKey();

  // Controlador de transformación para Zoom y Pan (desplazamiento) táctil/con botones
  final TransformationController _transformationController = TransformationController();

  // Parámetros Onda 1 (Azul)
  double amp1 = 30.0;
  double freq1 = 1.0;
  double k1 = 0.03;   
  double phi1 = 0.0; 
  bool vis1 = true;

  // Parámetros Onda 2 (Roja)
  double amp2 = 30.0;
  double freq2 = 1.0;
  double k2 = 0.03;
  double phi2 = 0.0;
  bool vis2 = true;

  bool visSuma = true;

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
      // Buscamos el render object asociado a nuestra llave de simulación
      RenderRepaintBoundary? boundary = _globalKeyCaptura.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Convertimos el vector a formato de imagen de mapa de bits (PNG)
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes != null) widget.onCapturar?.call(bytes);

      if (bytes != null) {
        if (!mounted) return;

        // --- AQUÍ SE COLOCA EL POP-UP PARA VER LA IMAGEN ---
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Vista Previa de la Captura', 
              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Este widget decodifica los bytes y los muestra en la pantalla de PC o Móvil
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
                  'Unidades e interferencia registradas con éxito.', 
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
        // ---------------------------------------------------

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
            final espacioMaxAbsoluto = (altoDisponible / 2) - 20;

            double sumaAmplitudes = amp1 + amp2;
            if (sumaAmplitudes > espacioMaxAbsoluto && sumaAmplitudes > 0) {
              double factorEscala = espacioMaxAbsoluto / sumaAmplitudes;
              amp1 *= factorEscala;
              amp2 *= factorEscala;
            }

            final maxSliderAmplitud = espacioMaxAbsoluto / 2;

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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                Text(
                                  "Parámetros Dinámicos", 
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13)
                                ),
                                const Divider(),
                                _buildWaveControls(
                                  "Onda Azul", Colors.blue[700]!, amp1, freq1, k1, phi1, vis1, maxSliderAmplitud,
                                  (v) => setState(() => amp1 = v), (v) => setState(() => freq1 = v), 
                                  (v) => setState(() => k1 = v), (v) => setState(() => phi1 = v),
                                  (v) => setState(() => vis1 = v!)
                                ),
                                const SizedBox(height: 8),
                                _buildWaveControls(
                                  "Onda Roja", Colors.red[700]!, amp2, freq2, k2, phi2, vis2, maxSliderAmplitud,
                                  (v) => setState(() => amp2 = v), (v) => setState(() => freq2 = v), 
                                  (v) => setState(() => k2 = v), (v) => setState(() => phi2 = v),
                                  (v) => setState(() => vis2 = v!)
                                ),
                                const Divider(),
                                CheckboxListTile(
                                  title: Text("Mostrar Resultante", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold)),
                                  dense: true,
                                  activeColor: Colors.indigo[900],
                                  value: visSuma, 
                                  onChanged: (v) => setState(() => visSuma = v!)
                                ),
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
                          fondoPainter: const _FondoReglaInterferencia(),
                          contenidoPainter: WavePainter(
                            tiempo: tiempo,
                            a1: amp1, f1: freq1, k1: k1, p1: phi1, v1: vis1,
                            a2: amp2, f2: freq2, k2: k2, p2: phi2, v2: vis2,
                            vSuma: visSuma,
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
                            // Botón para colapsar/desplegar el menú lateral
                            FloatingActionButton.small(
                              heroTag: "btnMenu",
                              backgroundColor: Colors.indigo[900],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _mostrarControles = !_mostrarControles),
                              child: Icon(_mostrarControles ? Icons.fullscreen : Icons.fullscreen_exit),
                            ),
                            const SizedBox(width: 10),
                            
                            // NUEVO: Botón de Play / Pausa de simulación
                            FloatingActionButton.small(
                              heroTag: "btnPausa",
                              backgroundColor: _estaCorriendo ? Colors.amber[700] : Colors.green[700],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _estaCorriendo = !_estaCorriendo),
                              child: Icon(_estaCorriendo ? Icons.pause : Icons.play_arrow),
                            ),
                            const SizedBox(width: 10),
                            
                            // NUEVO: Botón de Captura de Pantalla científica
                            FloatingActionButton.small(
                              heroTag: "btnCaptura",
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
          }
        ),
      ),
    );
  }

  Widget _buildWaveControls(
    String label, Color color, double a, double f, double k, double p, bool v, double maxAmp,
    ValueChanged<double> onA, ValueChanged<double> onF, ValueChanged<double> onK, ValueChanged<double> onP, ValueChanged<bool?> onV
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(value: v, onChanged: onV, activeColor: color),
          ),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.lato(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        _slider("A", a, 0, maxAmp, onA, decimales: 0),
        _slider("f", f, 0.1, 3.0, onF, decimales: 1, sufijo: " Hz"),
        _slider("k", k, -0.1, 0.1, onK, decimales: 3),
        _slider("φ", p, 0, 2 * math.pi, onP, decimales: 2, sufijo: " rad"),
      ],
    );
  }

  Widget _slider(String txt, double val, double min, double max, ValueChanged<double> cb, {int decimales = 2, String sufijo = ""}) {
    double valorSeguro = val;
    if (valorSeguro < min) valorSeguro = min;
    if (valorSeguro > max) valorSeguro = max;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(txt, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(value: valorSeguro, min: min, max: max, onChanged: cb),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              "${valorSeguro.toStringAsFixed(decimales)}$sufijo", 
              style: GoogleFonts.sourceCodePro(fontSize: 9, color: Colors.black87),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fondo FIJO con la cuadrícula y las reglas en cm/m. Se pinta en una
/// capa aparte que nunca se transforma con el zoom/pan (ver
/// [ZoomableSimulationCanvas]), así el "plano" de laboratorio siempre
/// ocupa el mismo espacio en pantalla; solo las curvas de onda (dibujadas
/// por [WavePainter]) se acercan o desplazan.
class _FondoReglaInterferencia extends CustomPainter {
  const _FondoReglaInterferencia();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF8FAFC));

    final centroY = size.height / 2;

    // ---- CONSTANTES DE UNIDAD ACADÉMICA ----
    // Vertical: cada bloque principal de 50px equivale a 1.0 Centímetro (cm).
    // Horizontal: cada bloque principal de 50px equivale a 0.5 Metros (m).
    const double pxPorBloque = 50.0;
    const double pasoMalla = 10.0;

    final pinturaMallaFina = Paint()
      ..color = Colors.indigo.withOpacity(0.03)
      ..strokeWidth = 0.5;

    final pinturaMallaPrincipal = Paint()
      ..color = Colors.indigo.withOpacity(0.10)
      ..strokeWidth = 1.0;

    // 1. Líneas horizontales + Unidades en Eje Y (Amplitud en cm)
    for (double y = 0; y <= size.height; y += pasoMalla) {
      final esPrincipal = (y / pasoMalla) % 5 == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina);

      if (esPrincipal) {
        double deltaY = -(y - centroY);
        double valorEnCentimetros = deltaY / pxPorBloque;

        if (valorEnCentimetros.abs() > 0.1) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: "${valorEnCentimetros.toStringAsFixed(1)} cm",
              style: GoogleFonts.sourceCodePro(fontSize: 8, color: Colors.indigo[300], fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(8, y - 4));
        }
      }
    }

    // 2. Líneas verticales + Unidades en Eje X (Distancia en m)
    for (double x = 0; x <= size.width; x += pasoMalla) {
      final esPrincipal = (x / pasoMalla) % 5 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina);

      if (esPrincipal && x > 0 && x < size.width - 60) {
        double valorEnMetros = (x / pxPorBloque) * 0.5;

        final textPainter = TextPainter(
          text: TextSpan(
            text: "${valorEnMetros.toStringAsFixed(2)} m",
            style: GoogleFonts.sourceCodePro(fontSize: 8, color: Colors.indigo[300], fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 2, size.height - 14));
      }
    }

    // Línea de referencia del centro neutro (Y = 0 cm)
    final pinturaEjeCentral = Paint()
      ..color = Colors.indigo.withOpacity(0.35)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, centroY), Offset(size.width, centroY), pinturaEjeCentral);

    final origenPainter = TextPainter(
      text: TextSpan(
        text: "0.0 cm/m",
        style: GoogleFonts.sourceCodePro(fontSize: 8, color: Colors.indigo[400], fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    origenPainter.layout();
    origenPainter.paint(canvas, Offset(8, centroY - 12));
  }

  @override
  bool shouldRepaint(covariant _FondoReglaInterferencia oldDelegate) => false;
}

class WavePainter extends CustomPainter {
  final double tiempo, a1, f1, k1, p1, a2, f2, k2, p2;
  final bool v1, v2, vSuma;

  WavePainter({
    required this.tiempo,
    required this.a1, required this.f1, required this.k1, required this.p1, required this.v1,
    required this.a2, required this.f2, required this.k2, required this.p2, required this.v2,
    required this.vSuma,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    final w1 = 2 * math.pi * f1;
    final w2 = 2 * math.pi * f2;

    // NOTA: la cuadrícula, las reglas en cm/m y el eje central ahora
    // viven en _FondoReglaInterferencia, una capa fija que nunca se
    // transforma con el zoom/pan.

    // ---- GENERACIÓN DE VECTORES DE ONDA ----
    final path1 = Path();
    final path2 = Path();
    final pathSuma = Path();

    for (double x = 0; x <= size.width; x++) {
      double y1 = a1 * math.sin(k1 * x - tiempo * w1 + p1);
      double y2 = a2 * math.sin(k2 * x + tiempo * w2 + p2);
      double yS = y1 + y2;

      if (x == 0) {
        path1.moveTo(x, centroY + y1);
        path2.moveTo(x, centroY + y2);
        pathSuma.moveTo(x, centroY + yS);
      } else {
        path1.lineTo(x, centroY + y1);
        path2.lineTo(x, centroY + y2);
        pathSuma.lineTo(x, centroY + yS);
      }
    }

    // ---- DIBUJAR TRAZOS ----
    if (v1) {
      canvas.drawPath(path1, Paint()..color = Colors.blue[600]!.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0);
    }
    if (v2) {
      canvas.drawPath(path2, Paint()..color = Colors.red[600]!.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0);
    }
    if (vSuma) {
      canvas.drawPath(pathSuma, Paint()..color = Colors.indigo[900]!..style = PaintingStyle.stroke..strokeWidth = 4.0);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}