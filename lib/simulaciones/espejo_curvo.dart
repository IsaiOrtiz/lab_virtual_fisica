import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/navegacion_simulacion.dart';
import '../widgets/simulation_canvas.dart';

enum TipoEspejo { concavo, convexo }

/// Simulación de espejos curvos (cóncavo/convexo). El usuario elige el
/// tipo de espejo y mueve el objeto, la distancia focal y la altura del
/// objeto; la posición y el tipo de imagen (real o virtual, derecha o
/// invertida, aumentada o reducida) se calculan con la ecuación del
/// espejo y se trazan automáticamente los 3 rayos principales.
///
/// Convención de signos usada (distancia real = positiva):
///  - f > 0 para espejo cóncavo, f < 0 para espejo convexo.
///  - do (distancia del objeto) siempre positiva.
///  - Si di > 0: imagen real (mismo lado que el objeto, frente al espejo).
///  - Si di < 0: imagen virtual (detrás del espejo).
class EspejoCurvoSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;
  final void Function(Uint8List bytes, String nota)? onCapturar;

  const EspejoCurvoSim({super.key, this.onIrATeoria, this.onIrACuestionario, this.onCapturar});

  @override
  State<EspejoCurvoSim> createState() => _EspejoCurvoSimState();
}

class _EspejoCurvoSimState extends State<EspejoCurvoSim> {
  double tiempo = 0.0;
  Timer? _timer;
  bool _mostrarControles = true;
  bool _estaCorriendo = true;

  final GlobalKey _globalKeyCaptura = GlobalKey();

  // Parámetros de la simulación
  TipoEspejo tipoEspejo = TipoEspejo.concavo;
  double distanciaFocal = 6.0;   // |f|, en unidades arbitrarias
  double distanciaObjeto = 15.0; // do, en unidades arbitrarias
  double alturaObjeto = 3.0;     // ho, en unidades arbitrarias
  bool mostrarRayos = true;
  bool mostrarEtiquetas = true;

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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // --- Cálculos derivados (ecuación del espejo) ---
  double get _fSigned => tipoEspejo == TipoEspejo.concavo ? distanciaFocal : -distanciaFocal;

  /// Distancia de la imagen (di). Null si el objeto está exactamente en
  /// el foco (imagen en el infinito).
  double? get _di {
    final double denom = (1 / _fSigned) - (1 / distanciaObjeto);
    if (denom.abs() < 1e-6) return null;
    return 1 / denom;
  }

  double? get _aumento {
    final di = _di;
    if (di == null) return null;
    return -di / distanciaObjeto;
  }

  double? get _alturaImagen {
    final m = _aumento;
    if (m == null) return null;
    return m * alturaObjeto;
  }

  bool get _esReal => (_di ?? -1) > 0;

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
                    'Espejo curvo registrado con éxito.',
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
    final double? di = _di;
    final double? m = _aumento;
    final double? hi = _alturaImagen;

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
                                  "Espejos Curvos",
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Divider(),
                                const SizedBox(height: 6),

                                Text(
                                  "Tipo de espejo",
                                  style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    ChoiceChip(
                                      label: Text("Cóncavo", style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                                      selected: tipoEspejo == TipoEspejo.concavo,
                                      selectedColor: Colors.indigo[100],
                                      onSelected: (v) { if (v) setState(() => tipoEspejo = TipoEspejo.concavo); },
                                    ),
                                    ChoiceChip(
                                      label: Text("Convexo", style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                                      selected: tipoEspejo == TipoEspejo.convexo,
                                      selectedColor: Colors.indigo[100],
                                      onSelected: (v) { if (v) setState(() => tipoEspejo = TipoEspejo.convexo); },
                                    ),
                                  ],
                                ),

                                const Divider(height: 20),
                                _slider("f", distanciaFocal, 2, 12, (v) => setState(() => distanciaFocal = v), decimales: 1),
                                _slider("dₒ", distanciaObjeto, 1, 30, (v) => setState(() => distanciaObjeto = v), decimales: 1),
                                _slider("hₒ", alturaObjeto, 1, 6, (v) => setState(() => alturaObjeto = v), decimales: 1),

                                const Divider(height: 20),
                                CheckboxListTile(
                                  title: Text("Mostrar rayos principales", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: mostrarRayos,
                                  activeColor: Colors.indigo,
                                  onChanged: (v) => setState(() => mostrarRayos = v!),
                                ),
                                CheckboxListTile(
                                  title: Text("Mostrar F, C y V", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: mostrarEtiquetas,
                                  activeColor: Colors.indigo,
                                  onChanged: (v) => setState(() => mostrarEtiquetas = v!),
                                ),

                                const Divider(height: 24),
                                Text("Ecuación del espejo:  1/dₒ + 1/dᵢ = 1/f", style: GoogleFonts.sourceCodePro(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),
                                _buildDatoCalculado("Distancia focal (f):", "${_fSigned.toStringAsFixed(1)}"),
                                _buildDatoCalculado("Distancia del objeto (dₒ):", distanciaObjeto.toStringAsFixed(1)),
                                _buildDatoCalculado("Distancia de la imagen (dᵢ):", di == null ? "∞ (en el foco)" : di.toStringAsFixed(1)),
                                _buildDatoCalculado("Aumento (m):", m == null ? "—" : m.toStringAsFixed(2)),
                                _buildDatoCalculado("Altura de la imagen (hᵢ):", hi == null ? "—" : hi.toStringAsFixed(1)),
                                const SizedBox(height: 8),
                                if (di != null) ...[
                                  _chipResultado(_esReal ? "REAL" : "VIRTUAL", _esReal ? Colors.green : Colors.orange),
                                  const SizedBox(height: 4),
                                  _chipResultado((hi ?? 0) < 0 ? "INVERTIDA" : "DERECHA", Colors.blueGrey),
                                  const SizedBox(height: 4),
                                  _chipResultado(
                                    m!.abs() > 1.02
                                        ? "AUMENTADA"
                                        : (m.abs() < 0.98 ? "REDUCIDA" : "MISMO TAMAÑO"),
                                    Colors.purple,
                                  ),
                                ] else
                                  Text(
                                    "El objeto está exactamente en el foco: los rayos reflejados salen paralelos y la imagen se forma en el infinito.",
                                    style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                  ),
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
                        child: SimulationCanvas(
                          fondoPainter: FondoCuadriculaPainter(colorFondo: Colors.white, colorLineas: Colors.black),
                          contenidoPainter: EspejoCurvoPainter(
                            tiempo: tiempo,
                            tipoEspejo: tipoEspejo,
                            distanciaFocal: distanciaFocal,
                            distanciaObjeto: distanciaObjeto,
                            alturaObjeto: alturaObjeto,
                            mostrarRayos: mostrarRayos,
                            mostrarEtiquetas: mostrarEtiquetas,
                          ),
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
                              heroTag: "btnMenuEspejo",
                              backgroundColor: Colors.indigo[900],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _mostrarControles = !_mostrarControles),
                              child: Icon(_mostrarControles ? Icons.fullscreen : Icons.fullscreen_exit),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton.small(
                              heroTag: "btnPausaEspejo",
                              backgroundColor: _estaCorriendo ? Colors.amber[700] : Colors.green[700],
                              foregroundColor: Colors.white,
                              onPressed: () => setState(() => _estaCorriendo = !_estaCorriendo),
                              child: Icon(_estaCorriendo ? Icons.pause : Icons.play_arrow),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton.small(
                              heroTag: "btnCapturaEspejo",
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

  Widget _chipResultado(String texto, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: color[800])),
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

class EspejoCurvoPainter extends CustomPainter {
  final double tiempo;
  final TipoEspejo tipoEspejo;
  final double distanciaFocal;
  final double distanciaObjeto;
  final double alturaObjeto;
  final bool mostrarRayos;
  final bool mostrarEtiquetas;

  EspejoCurvoPainter({
    required this.tiempo,
    required this.tipoEspejo,
    required this.distanciaFocal,
    required this.distanciaObjeto,
    required this.alturaObjeto,
    required this.mostrarRayos,
    required this.mostrarEtiquetas,
  });

  static const Color colorEjes = Color(0xFF374151);
  static const Color colorEspejo = Color(0xFF455A64);
  static const Color colorObjeto = Color(0xFF1565C0);
  static const Color colorImagen = Color(0xFFC62828);
  static const Color colorRayo1 = Color(0xFFB45309);
  static const Color colorRayo2 = Color(0xFF2E7D32);
  static const Color colorRayo3 = Color(0xFF6A1B9A);

  double get _fSigned => tipoEspejo == TipoEspejo.concavo ? distanciaFocal : -distanciaFocal;
  double get _centerX => -2 * _fSigned;
  double get _radius => 2 * distanciaFocal;

  @override
  void paint(Canvas canvas, Size size) {
    // Toda la óptica se mantiene dentro del área visible. Los rayos que
    // físicamente continuarían fuera del lienzo se recortan en sus bordes.
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final bool esConcavo = tipoEspejo == TipoEspejo.concavo;
    final double f = _fSigned;
    final double c = _centerX;
    final double r = _radius;

    // Encuadre automático: se calcula a partir del objeto y de los puntos
    // cardinales para que toda la construcción quede centrada sin zoom.
    final double minX = math.min(-distanciaObjeto, math.min(0, c)) - 3;
    final double maxX = math.max(0, math.max(c, -f)) + 3;
    final double apertura = math.min(8.0, r * 0.72);
    final double rangoX = math.max(1, maxX - minX);
    final double rangoY = math.max(14, apertura * 2 + 5);
    final double escala = math.min(
      (size.width - 70) / rangoX,
      (size.height - 105) / rangoY,
    ).clamp(8.0, 24.0).toDouble();
    final double ejeY = size.height * 0.56;
    final double origenX = (size.width - rangoX * escala) / 2 - minX * escala;

    Offset toCanvas(double x, double y) => Offset(
      origenX + x * escala,
      ejeY - y * escala,
    );

    // Eje óptico.
    canvas.drawLine(
      Offset(20, ejeY),
      Offset(size.width - 20, ejeY),
      Paint()..color = colorEjes.withOpacity(0.55)..strokeWidth = 1.2,
    );

    // Espejo esférico real. La curva y los rayos usan exactamente la misma
    // geometría, evitando que los puntos de incidencia queden fuera del espejo.
    final Path espejo = Path();
    const int pasos = 100;
    for (int i = 0; i <= pasos; i++) {
      final double y = -apertura + 2 * apertura * i / pasos;
      final double raiz = math.sqrt(math.max(0, r * r - y * y));
      final double x = esConcavo ? -r + raiz : r - raiz;
      final p = toCanvas(x, y);
      if (i == 0) {
        espejo.moveTo(p.dx, p.dy);
      } else {
        espejo.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      espejo,
      Paint()
        ..color = colorEspejo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Respaldo del espejo para distinguir el lado no reflectante.
    final Paint respaldo = Paint()
      ..color = colorEspejo.withOpacity(0.18)
      ..strokeWidth = 1;
    for (int i = 0; i < pasos; i += 6) {
      final double y = -apertura + 2 * apertura * i / pasos;
      final double raiz = math.sqrt(math.max(0, r * r - y * y));
      final double x = esConcavo ? -r + raiz : r - raiz;
      final p = toCanvas(x, y);
      final double lado = esConcavo ? 8 : -8;
      canvas.drawLine(p, Offset(p.dx + lado, p.dy + 7), respaldo);
    }

    final double foco = -f;
    if (mostrarEtiquetas) {
      _marcaEje(canvas, toCanvas(0, 0), 'V', colorEjes);
      _marcaEje(canvas, toCanvas(foco, 0), 'F', const Color(0xFF00695C));
      _marcaEje(canvas, toCanvas(c, 0), 'C', const Color(0xFFAD4B00));
    }

    // Objeto.
    final Offset puntaObjeto = toCanvas(-distanciaObjeto, alturaObjeto);
    _dibujarFlechaObjeto(
      canvas,
      toCanvas(-distanciaObjeto, 0),
      puntaObjeto,
      colorObjeto,
    );

    final double denom = (1 / f) - (1 / distanciaObjeto);
    double? di;
    double? m;
    double? hi;
    if (denom.abs() > 1e-7) {
      di = 1 / denom;
      m = -di / distanciaObjeto;
      hi = m * alturaObjeto;
    }

    if (mostrarRayos) {
      // Los tres rayos se calculan mediante reflexión vectorial sobre la
      // normal de la esfera. Así funcionan tanto para cóncavos como convexos
      // y para cualquier posición del objeto.
      final List<_RayoPrincipal> rayos = [
        _RayoPrincipal(puntaObjeto, const Offset(1, 0), colorRayo1),
        _RayoPrincipal(puntaObjeto, _normalizar(toCanvas(foco, 0) - puntaObjeto), colorRayo2),
        _RayoPrincipal(puntaObjeto, _normalizar(toCanvas(c, 0) - puntaObjeto), colorRayo3),
      ];

      // Las direcciones de los dos últimos rayos se calculan en coordenadas
      // físicas, no en píxeles.
      rayos[1] = _RayoPrincipal(
        puntaObjeto,
        _normalizar(Offset(foco + distanciaObjeto, -alturaObjeto)),
        colorRayo2,
      );
      rayos[2] = _RayoPrincipal(
        puntaObjeto,
        _normalizar(Offset(c + distanciaObjeto, -alturaObjeto)),
        colorRayo3,
      );

      for (final rayo in rayos) {
        final Offset origenFisico = Offset(-distanciaObjeto, alturaObjeto);
        final Offset hitFisico = _interseccionEsfera(origenFisico, rayo.direccionFisica, Offset(c, 0), r);
        if (hitFisico.dx.isNaN) continue;

        final Offset hit = toCanvas(hitFisico.dx, hitFisico.dy);
        _dibujarSegmento(canvas, puntaObjeto, hit, rayo.color, dashed: false);

        final Offset normal = _normalizar(hitFisico - Offset(c, 0));
        final Offset reflejado = _normalizar(
          rayo.direccionFisica - normal * (2 * _dot(rayo.direccionFisica, normal)),
        );
        final Offset finFisico = hitFisico + reflejado * 50;
        _dibujarSegmento(canvas, hit, toCanvas(finFisico.dx, finFisico.dy), rayo.color, dashed: false);

        // En un convexo la prolongación virtual va detrás del espejo.
        // En un cóncavo solo se dibuja construcción virtual si corresponde.
        final Offset extension = hitFisico - reflejado * 35;
        if (!esConcavo || (di != null && di < 0)) {
          _dibujarSegmento(canvas, hit, toCanvas(extension.dx, extension.dy), rayo.color, dashed: true);
        }
      }
    }

    // Imagen calculada por la ecuación del espejo. Para valores muy grandes
    // (por ejemplo, muy cerca del foco) se coloca en el borde útil del
    // encuadre, pero se conserva el valor físico real en el panel de datos.
    // Así nunca desaparece la imagen de la simulación.
    if (di != null && hi != null) {
      final double maxImagenVisible = math.max(8.0, rangoX * 0.42);
      final double diVisual = di.clamp(-maxImagenVisible, maxImagenVisible).toDouble();
      final double factorAltura = di.abs() > maxImagenVisible
          ? maxImagenVisible / di.abs()
          : 1.0;
      final double hiVisual = hi * factorAltura;
      final Offset baseImagen = toCanvas(-diVisual, 0);
      final Offset puntaImagen = toCanvas(-diVisual, hiVisual);

      // Marca de que la posición está comprimida fuera de escala lineal.
      if (di.abs() > maxImagenVisible) {
        _dibujarSegmento(
          canvas,
          toCanvas(0, 0),
          baseImagen,
          colorImagen,
          dashed: true,
        );
      }

      _dibujarFlechaObjeto(
        canvas,
        baseImagen,
        puntaImagen,
        colorImagen,
        dashed: di < 0,
      );
    }

    // Caso excepcional del espejo cóncavo: objeto exactamente en el foco.
    // La ecuación da dᵢ → ∞, por lo que no existe una imagen finita que pueda
    // dibujarse dentro del lienzo. Se comunica explícitamente al estudiante.
    if (esConcavo && di == null) {
      final rect = Rect.fromLTWH(
        18,
        size.height - 58,
        math.min(size.width - 36, 520),
        40,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = const Color(0xFFFFF3CD),
      );
      final aviso = TextPainter(
        text: TextSpan(
          text: 'Excepción: dₒ = f → los rayos reflejados son paralelos; la imagen se forma en el infinito.',
          style: GoogleFonts.lato(
            fontSize: 10,
            color: const Color(0xFF7A5B00),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: rect.width - 20);
      aviso.paint(canvas, Offset(rect.left + 10, rect.top + 7));
    }

    // Indicador temporal discreto sobre el eje.
    final double recorrido = (tiempo * 18) % math.max(1.0, distanciaObjeto + 30.0);
    final double xFot = -distanciaObjeto + recorrido;
    if (xFot <= 0) {
      canvas.drawCircle(
        toCanvas(xFot, 0).translate(0, -3).clampToSize(size),
        3,
        Paint()..color = const Color(0xFFB7791F).withOpacity(0.55),
      );
    }

    final String titulo = esConcavo ? 'Espejo cóncavo' : 'Espejo convexo';
    final tp = TextPainter(
      text: TextSpan(
        text: titulo,
        style: GoogleFonts.sourceCodePro(
          fontSize: 11,
          color: colorEjes,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, 12));

    canvas.restore();
  }

  Offset _interseccionEsfera(Offset origen, Offset direccion, Offset centro, double radio) {
    final Offset d = _normalizar(direccion);
    final Offset oc = origen - centro;
    final double b = 2 * _dot(oc, d);
    final double cc = _dot(oc, oc) - radio * radio;
    final double disc = b * b - 4 * cc;
    if (disc < 0) return const Offset(double.nan, double.nan);
    final double raiz = math.sqrt(disc);
    final double t1 = (-b - raiz) / 2;
    final double t2 = (-b + raiz) / 2;
    final candidates = [t1, t2].where((t) => t > 1e-4).toList()..sort();
    if (candidates.isEmpty) return const Offset(double.nan, double.nan);
    return origen + d * candidates.first;
  }

  double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  Offset _normalizar(Offset v) {
    final double len = v.distance;
    if (len < 1e-9) return const Offset(1, 0);
    return v / len;
  }

  void _marcaEje(Canvas canvas, Offset punto, String etiqueta, Color color) {
    canvas.drawCircle(punto, 3.2, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(text: etiqueta, style: GoogleFonts.sourceCodePro(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, punto + const Offset(-4, 8));
  }

  void _dibujarFlechaObjeto(Canvas canvas, Offset base, Offset punta, Color color, {bool dashed = false}) {
    final paint = Paint()..color = color..strokeWidth = 2.6..style = PaintingStyle.stroke;
    if (dashed) {
      _dibujarLineaPunteada(canvas, Path()..moveTo(base.dx, base.dy)..lineTo(punta.dx, punta.dy), paint);
    } else {
      canvas.drawLine(base, punta, paint);
    }
    final double angulo = math.atan2(punta.dy - base.dy, punta.dx - base.dx);
    const double tamanoPunta = 9;
    final Path cabeza = Path()
      ..moveTo(punta.dx, punta.dy)
      ..lineTo(punta.dx - tamanoPunta * math.cos(angulo - math.pi / 7), punta.dy - tamanoPunta * math.sin(angulo - math.pi / 7))
      ..lineTo(punta.dx - tamanoPunta * math.cos(angulo + math.pi / 7), punta.dy - tamanoPunta * math.sin(angulo + math.pi / 7))
      ..close();
    canvas.drawPath(cabeza, Paint()..color = color);
  }

  void _dibujarSegmento(Canvas canvas, Offset a, Offset b, Color color, {required bool dashed}) {
    final paint = Paint()..color = color.withOpacity(dashed ? 0.52 : 0.88)..strokeWidth = 1.8;
    if (dashed) {
      _dibujarLineaPunteada(canvas, Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy), paint);
    } else {
      canvas.drawLine(a, b, paint);
    }
  }

  void _dibujarLineaPunteada(Canvas canvas, Path path, Paint paint, {double dashWidth = 5, double gapWidth = 4}) {
    for (final metric in path.computeMetrics()) {
      double d = 0;
      bool dibujar = true;
      while (d < metric.length) {
        final double siguiente = d + (dibujar ? dashWidth : gapWidth);
        if (dibujar) canvas.drawPath(metric.extractPath(d, math.min(siguiente, metric.length)), paint);
        d = siguiente;
        dibujar = !dibujar;
      }
    }
  }

  @override
  bool shouldRepaint(covariant EspejoCurvoPainter oldDelegate) => true;
}

class _RayoPrincipal {
  final Offset origen;
  final Offset direccionFisica;
  final Color color;
  const _RayoPrincipal(this.origen, this.direccionFisica, this.color);
}

extension on Offset {
  Offset clampToSize(Size size) => Offset(
    dx.clamp(0.0, size.width),
    dy.clamp(0.0, size.height),
  );
}
