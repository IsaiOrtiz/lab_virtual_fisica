import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart'; // Necesario para la captura de pantalla (RenderRepaintBoundary)
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui; // Necesario para convertir el boundary en imagen bytes
import '../widgets/zoom_pan_controls.dart';
import '../widgets/navegacion_simulacion.dart';

/// Condición de frontera de la cuerda/columna vibrante.
///
/// - [fijoAbierto]: un extremo fijo (nodo obligado) y un extremo libre
///   (antinodo obligado). Solo existen armónicos IMPARES: k = 1, 3, 5...
///   f_k = k·v/(4L)
/// - [abiertoAbierto]: ambos extremos libres (antinodo en ambos). Existen
///   TODOS los armónicos: k = 1, 2, 3...
///   f_k = k·v/(2L)  (misma fórmula que fijo-fijo, pero con antinodos en
///   los extremos en lugar de nodos)
enum CondicionFrontera { fijoAbierto, abiertoAbierto }

/// Simulación de Modos Normales con fronteras MIXTAS (fijo-abierto) o
/// LIBRES (abierto-abierto). Complementa al módulo de "Modos Normales"
/// (fijo-fijo): aquí el usuario elige primero el tipo de frontera y
/// luego el armónico k disponible para esa frontera. La frecuencia
/// también se calcula a partir de la TENSIÓN (T) y la DENSIDAD LINEAL (μ)
/// de la cuerda: v = √(T/μ), y fₖ depende de la frontera elegida.
class ModosNormalesFronteraSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;

  const ModosNormalesFronteraSim({super.key, this.onIrATeoria, this.onIrACuestionario});

  @override
  State<ModosNormalesFronteraSim> createState() => _ModosNormalesFronteraSimState();
}

class _ModosNormalesFronteraSimState extends State<ModosNormalesFronteraSim> {
  double tiempo = 0.0;
  Timer? _timer;
  bool _mostrarControles = true;
  bool _estaCorriendo = true;

  final GlobalKey _globalKeyCaptura = GlobalKey();
  final TransformationController _transformationController = TransformationController();

  // Condición de frontera y armónico (k) actualmente seleccionado.
  CondicionFrontera condicion = CondicionFrontera.fijoAbierto;
  int armonicoK = 1;

  double amplitud = 50.0;
  bool mostrarEnvolvente = true;
  bool mostrarNodos = true;

  // --- Parámetros físicos de la cuerda ---
  double tension = 5.0;         // T, en Newtons (N)
  double densidadLineal = 30.0; // μ, en gramos por metro (g/m)
  double longitudCuerda = 1.5;  // L, en metros (m)

  /// Lista de armónicos válidos según la frontera elegida.
  List<int> get armonicosDisponibles {
    if (condicion == CondicionFrontera.fijoAbierto) {
      return const [1, 3, 5, 7, 9, 11]; // Solo impares
    }
    return const [1, 2, 3, 4, 5, 6]; // Todos
  }

  // --- Cálculos derivados (v, f1, fk) ---
  double get velocidadPropagacion {
    final double muKgPorM = densidadLineal / 1000.0; // g/m -> kg/m
    if (muKgPorM <= 0) return 0;
    return math.sqrt(tension / muKgPorM);
  }

  /// Frecuencia fundamental propia de la frontera elegida.
  /// Fijo-Abierto:  f1 = v / (4L)
  /// Abierto-Abierto: f1 = v / (2L)
  double get frecuenciaFundamental {
    if (longitudCuerda <= 0) return 0;
    final double divisor = condicion == CondicionFrontera.fijoAbierto ? 4 : 2;
    return velocidadPropagacion / (divisor * longitudCuerda);
  }

  double get frecuenciaModo => armonicoK * frecuenciaFundamental;

  /// Número de nodos y antinodos internos (sin contar los extremos),
  /// útil para mostrar en el panel de datos.
  int get nodosInternos {
    if (condicion == CondicionFrontera.fijoAbierto) {
      return (armonicoK - 1) ~/ 2;
    }
    return armonicoK; // abierto-abierto: k nodos internos
  }

  int get antinodosTotales {
    if (condicion == CondicionFrontera.fijoAbierto) {
      return (armonicoK + 1) ~/ 2; // incluye el extremo abierto
    }
    return armonicoK + 1; // incluye ambos extremos
  }

  void _cambiarCondicion(CondicionFrontera nueva) {
    setState(() {
      condicion = nueva;
      // Si el armónico actual ya no es válido para la nueva frontera,
      // se reinicia al primero disponible (fundamental).
      final disponibles = condicion == CondicionFrontera.fijoAbierto
          ? const [1, 3, 5, 7, 9, 11]
          : const [1, 2, 3, 4, 5, 6];
      if (!disponibles.contains(armonicoK)) {
        armonicoK = 1;
      }
    });
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
                                  "Modos Normales (fronteras mixtas/libres)",
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Divider(),
                                const SizedBox(height: 6),

                                Text(
                                  "Condición de frontera",
                                  style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                SegmentedButton<CondicionFrontera>(
                                  segments: const [
                                    ButtonSegment(
                                      value: CondicionFrontera.fijoAbierto,
                                      label: Text("Fijo-Abierto", style: TextStyle(fontSize: 10)),
                                    ),
                                    ButtonSegment(
                                      value: CondicionFrontera.abiertoAbierto,
                                      label: Text("Abierto-Abierto", style: TextStyle(fontSize: 10)),
                                    ),
                                  ],
                                  selected: {condicion},
                                  onSelectionChanged: (nuevo) => _cambiarCondicion(nuevo.first),
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),

                                const Divider(height: 24),
                                Text(
                                  "Armónico (k)",
                                  style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: armonicosDisponibles.map((k) {
                                    return ChoiceChip(
                                      label: Text("k=$k", style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                                      selected: armonicoK == k,
                                      selectedColor: Colors.purple[100],
                                      onSelected: (val) { if (val) setState(() => armonicoK = k); },
                                    );
                                  }).toList(),
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
                                Text("Propiedades del modo k=$armonicoK:", style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),
                                _buildDatoCalculado("Velocidad (v = √(T/μ)):", "${velocidadPropagacion.toStringAsFixed(2)} m/s"),
                                _buildDatoCalculado(
                                  condicion == CondicionFrontera.fijoAbierto
                                      ? "Frec. fundamental (f₁ = v/4L):"
                                      : "Frec. fundamental (f₁ = v/2L):",
                                  "${frecuenciaFundamental.toStringAsFixed(2)} Hz",
                                ),
                                _buildDatoCalculado("Frecuencia (fₖ = k·f₁):", "${frecuenciaModo.toStringAsFixed(2)} Hz"),
                                _buildDatoCalculado(
                                  "Longitud de onda:",
                                  condicion == CondicionFrontera.fijoAbierto
                                      ? "${(4 * longitudCuerda / armonicoK).toStringAsFixed(2)} m"
                                      : "${(2 * longitudCuerda / armonicoK).toStringAsFixed(2)} m",
                                ),
                                _buildDatoCalculado("Nodos internos:", "$nodosInternos"),
                                _buildDatoCalculado("Antinodos totales:", "$antinodosTotales"),
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
                            color: const Color(0xFF1A1025), // Morado oscuro premium
                            child: CustomPaint(
                              painter: NormalModeFronteraPainter(
                                tiempo: tiempo,
                                amplitud: amplitud,
                                armonicoK: armonicoK,
                                frecuenciaModo: frecuenciaModo,
                                condicion: condicion,
                                mostrarEnvolvente: mostrarEnvolvente,
                                mostrarNodos: mostrarNodos,
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
                              heroTag: "btnMenuModoFrontera",
                              backgroundColor: Colors.indigo[900],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _mostrarControles = !_mostrarControles),
                              child: Icon(_mostrarControles ? Icons.fullscreen : Icons.fullscreen_exit),
                            ),
                            const SizedBox(width: 10),

                            FloatingActionButton.small(
                              heroTag: "btnPausaModoFrontera",
                              backgroundColor: _estaCorriendo ? Colors.amber[700] : Colors.green[700],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _estaCorriendo = !_estaCorriendo),
                              child: Icon(_estaCorriendo ? Icons.pause : Icons.play_arrow),
                            ),
                            const SizedBox(width: 10),

                            FloatingActionButton.small(
                              heroTag: "btnCapturaModoFrontera",
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

class NormalModeFronteraPainter extends CustomPainter {
  final double tiempo, amplitud;
  final double frecuenciaModo; // fₖ ya calculada, en Hz
  final int armonicoK;
  final CondicionFrontera condicion;
  final bool mostrarEnvolvente, mostrarNodos;

  NormalModeFronteraPainter({
    required this.tiempo,
    required this.amplitud,
    required this.armonicoK,
    required this.frecuenciaModo,
    required this.condicion,
    required this.mostrarEnvolvente,
    required this.mostrarNodos,
  });

  /// Factor espacial (sin dimensiones, entre -1 y 1) de la forma del
  /// modo normal en la posición xi (0 <= xi <= largoCuerda), según la
  /// condición de frontera:
  ///  - Fijo-Abierto: sin(kπx / 2L)   -> nodo en x=0, antinodo en x=L
  ///  - Abierto-Abierto: cos(kπx / L) -> antinodo en x=0 y en x=L
  double _formaEspacial(double xi, double largoCuerda) {
    if (condicion == CondicionFrontera.fijoAbierto) {
      return math.sin(armonicoK * math.pi * xi / (2 * largoCuerda));
    }
    return math.cos(armonicoK * math.pi * xi / largoCuerda);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    const double margen = 36.0;
    final double largoCuerda = size.width - 2 * margen;
    if (largoCuerda <= 0) return;

    final double wn = 2 * math.pi * frecuenciaModo;
    final double cosT = math.cos(wn * tiempo);

    // ---- Cuadrícula de fondo ----
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

    // Eje central de referencia
    canvas.drawLine(
      Offset(margen, centroY),
      Offset(size.width - margen, centroY),
      Paint()..color = Colors.white.withOpacity(0.15)..strokeWidth = 1,
    );

    // ---- Envolvente (curvas guía ± amplitud·forma) ----
    if (mostrarEnvolvente) {
      final pathSup = Path();
      final pathInf = Path();
      for (double xi = 0; xi <= largoCuerda; xi += 2) {
        final double env = amplitud * _formaEspacial(xi, largoCuerda).abs();
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
    double yIni = 0, yFin = 0;
    for (double xi = 0; xi <= largoCuerda; xi += 1) {
      final double x = margen + xi;
      final double y = amplitud * _formaEspacial(xi, largoCuerda) * cosT;
      if (xi == 0) {
        yIni = y;
        pathCuerda.moveTo(x, centroY - y);
      } else {
        pathCuerda.lineTo(x, centroY - y);
      }
    }
    yFin = amplitud * _formaEspacial(largoCuerda, largoCuerda) * cosT;

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

    // ---- Extremos: fijo (soporte triangular) o libre (riel deslizante) ----
    if (condicion == CondicionFrontera.fijoAbierto) {
      _dibujarSoporteFijo(canvas, Offset(margen, centroY));
      _dibujarExtremoLibre(canvas, Offset(size.width - margen, centroY), centroY - yFin);
    } else {
      _dibujarExtremoLibre(canvas, Offset(margen, centroY), centroY - yIni);
      _dibujarExtremoLibre(canvas, Offset(size.width - margen, centroY), centroY - yFin);
    }

    // ---- Nodos y antinodos ----
    if (mostrarNodos) {
      const double paso = 1.0;
      double anterior = _formaEspacial(0, largoCuerda);
      for (double xi = paso; xi <= largoCuerda; xi += paso) {
        final double actual = _formaEspacial(xi, largoCuerda);
        // Detecta cambios de signo (cruce por cero) como NODOS internos.
        if (anterior != 0 && actual != 0 && (anterior > 0) != (actual > 0)) {
          final double x = margen + xi;
          canvas.drawCircle(Offset(x, centroY), 5.0, Paint()..color = Colors.redAccent.withOpacity(0.85));
          canvas.drawCircle(Offset(x, centroY), 5.0, Paint()..color = Colors.white.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.0);
        }
        anterior = actual;
      }
      // Antinodos: guías verticales punteadas donde |forma| alcanza máximo local (~1).
      const double pasoFino = 1.0;
      double prevAbs = _formaEspacial(0, largoCuerda).abs();
      double prevPrevAbs = prevAbs;
      for (double xi = pasoFino; xi <= largoCuerda; xi += pasoFino) {
        final double actualAbs = _formaEspacial(xi, largoCuerda).abs();
        if (prevAbs > prevPrevAbs && prevAbs >= actualAbs && prevAbs > 0.9) {
          final double x = margen + (xi - pasoFino);
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
        prevPrevAbs = prevAbs;
        prevAbs = actualAbs;
      }
    }

    // ---- Etiqueta informativa ----
    final String nombreFrontera = condicion == CondicionFrontera.fijoAbierto ? "Fijo-Abierto" : "Abierto-Abierto";
    final etiqueta = TextPainter(
      text: TextSpan(
        text: "$nombreFrontera  ·  k=$armonicoK  ·  fₖ=${frecuenciaModo.toStringAsFixed(2)} Hz",
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

  /// Dibuja un extremo LIBRE: un pequeño riel vertical (dos líneas
  /// paralelas) por el que se desliza un anillo situado en la posición
  /// vertical instantánea del extremo de la cuerda (yActual), indicando
  /// que ese punto puede moverse libremente (antinodo obligado).
  void _dibujarExtremoLibre(Canvas canvas, Offset punto, double yActual) {
    final paintRiel = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2;
    canvas.drawLine(Offset(punto.dx - 6, punto.dy - 34), Offset(punto.dx - 6, punto.dy + 34), paintRiel);
    canvas.drawLine(Offset(punto.dx + 6, punto.dy - 34), Offset(punto.dx + 6, punto.dy + 34), paintRiel);

    canvas.drawCircle(Offset(punto.dx, yActual), 6.0, Paint()..color = const Color(0xFF4FC3F7));
    canvas.drawCircle(
      Offset(punto.dx, yActual),
      6.0,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
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
  bool shouldRepaint(covariant NormalModeFronteraPainter oldDelegate) => true;
}