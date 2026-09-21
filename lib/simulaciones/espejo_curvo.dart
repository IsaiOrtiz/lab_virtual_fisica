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
  final TransformationController _transformationController = TransformationController();

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
    _transformationController.dispose();
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
                        child: ZoomableSimulationCanvas(
                          controller: _transformationController,
                          fondoPainter: const FondoCuadriculaPainter(colorFondo: Colors.white, colorLineas: Colors.black),
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

  static const double escala = 16.0; // px por unidad física
  static const Color colorEjes = Color(0xFF212121);
  static const Color colorObjeto = Color(0xFF1565C0); // azul
  static const Color colorImagen = Color(0xFFD32F2F); // rojo
  static const Color colorRayo1 = Color(0xFFF57C00); // naranja
  static const Color colorRayo2 = Color(0xFF2E7D32); // verde
  static const Color colorRayo3 = Color(0xFF6A1B9A); // morado

  @override
  void paint(Canvas canvas, Size size) {
    final double fSigned = tipoEspejo == TipoEspejo.concavo ? distanciaFocal : -distanciaFocal;
    final double vertexX = size.width * 0.58;
    final double axisY = size.height / 2;
    final bool esConcavo = tipoEspejo == TipoEspejo.concavo;

    Offset toCanvas(double xFisico, double yFisico) => Offset(vertexX + xFisico * escala, axisY - yFisico * escala);

    // ---- Eje óptico (horizontal) ----
    canvas.drawLine(Offset(0, axisY), Offset(size.width, axisY), Paint()..color = colorEjes..strokeWidth = 1.4);

    // ---- Espejo curvo ----
    final double R = 2 * distanciaFocal;
    final double centerXFisico = -2 * fSigned; // posición física de C
    final double focoXFisico = -fSigned; // posición física de F
    final double alturaMirror = math.min(9.0, R * 0.85);

    final Path pathEspejo = Path();
    const int pasos = 60;
    for (int i = 0; i <= pasos; i++) {
      final double y = -alturaMirror + (2 * alturaMirror) * i / pasos;
      final double raiz = math.sqrt(math.max(0, R * R - y * y));
      final double x = esConcavo ? (-R + raiz) : (R - raiz);
      final Offset punto = toCanvas(x, y);
      if (i == 0) {
        pathEspejo.moveTo(punto.dx, punto.dy);
      } else {
        pathEspejo.lineTo(punto.dx, punto.dy);
      }
    }
    canvas.drawPath(pathEspejo, Paint()..color = Colors.cyan[800]!..style = PaintingStyle.stroke..strokeWidth = 3.0);

    // Sombreado (respaldo sólido) detrás del espejo
    final Paint paintSombreado = Paint()..color = colorEjes.withOpacity(0.3)..strokeWidth = 1.0;
    for (int i = 0; i <= pasos; i += 3) {
      final double y = -alturaMirror + (2 * alturaMirror) * i / pasos;
      final double raiz = math.sqrt(math.max(0, R * R - y * y));
      final double x = esConcavo ? (-R + raiz) : (R - raiz);
      final double dxSombra = 10;
      final Offset p1 = toCanvas(x, y);
      canvas.drawLine(p1, Offset(p1.dx + dxSombra, p1.dy + 8), paintSombreado);
    }

    // ---- Marcas de V, F y C ----
    if (mostrarEtiquetas) {
      _marcaEje(canvas, toCanvas(0, 0), "V", colorEjes);
      _marcaEje(canvas, toCanvas(focoXFisico, 0), "F", Colors.teal[800]!);
      _marcaEje(canvas, toCanvas(centerXFisico, 0), "C", Colors.deepOrange[800]!);
    }

    // ---- Objeto (flecha azul, siempre real) ----
    final Offset baseObjeto = toCanvas(-distanciaObjeto, 0);
    final Offset puntaObjeto = toCanvas(-distanciaObjeto, alturaObjeto);
    _dibujarFlechaObjeto(canvas, baseObjeto, puntaObjeto, colorObjeto);

    // ---- Cálculo de imagen ----
    final double denom = (1 / fSigned) - (1 / distanciaObjeto);
    double? di, m, hi;
    if (denom.abs() >= 1e-6) {
      di = 1 / denom;
      m = -di / distanciaObjeto;
      hi = m * alturaObjeto;
    }

    // ---- Rayos principales ----
    if (mostrarRayos) {
      final Offset tipFisico = Offset(-distanciaObjeto, alturaObjeto);

      // Rayo 1: paralelo -> pasa por F
      final Offset hit1Fisico = Offset(0, alturaObjeto);
      _dibujarSegmento(canvas, toCanvas(tipFisico.dx, tipFisico.dy), toCanvas(hit1Fisico.dx, hit1Fisico.dy), colorRayo1, dashed: false);
      final Offset fFisico = Offset(focoXFisico, 0);
      final Offset dir1 = esConcavo ? (fFisico - hit1Fisico) : (hit1Fisico - fFisico);
      final Offset dir1Norm = _normalizar(dir1);
      final Offset finReal1 = hit1Fisico + dir1Norm * 40;
      _dibujarSegmento(canvas, toCanvas(hit1Fisico.dx, hit1Fisico.dy), toCanvas(finReal1.dx, finReal1.dy), colorRayo1, dashed: false);
      if (!esConcavo) {
        _dibujarSegmento(canvas, toCanvas(hit1Fisico.dx, hit1Fisico.dy), toCanvas(fFisico.dx, fFisico.dy), colorRayo1, dashed: true);
      }

      // Rayo 2: pasa por F -> sale paralelo
      if ((distanciaObjeto - fSigned).abs() > 1e-3) {
        final double y2 = -fSigned * alturaObjeto / (distanciaObjeto - fSigned);
        final Offset hit2Fisico = Offset(0, y2);
        _dibujarSegmento(canvas, toCanvas(tipFisico.dx, tipFisico.dy), toCanvas(hit2Fisico.dx, hit2Fisico.dy), colorRayo2, dashed: false);
        final Offset finReal2 = Offset(-40, y2);
        _dibujarSegmento(canvas, toCanvas(hit2Fisico.dx, hit2Fisico.dy), toCanvas(finReal2.dx, finReal2.dy), colorRayo2, dashed: false);
      }

      // Rayo 3: pasa por C -> incide perpendicular al espejo y se
      // refleja sobre la MISMA línea (ida y vuelta se sobreponen). La
      // parte real (sólida) es la que queda frente al espejo (x <= 0);
      // si C está detrás del espejo (convexo), la parte de x=0 hasta C
      // es una construcción virtual (punteada).
      final Offset cFisico = Offset(centerXFisico, 0);
      final Offset dirTipC = cFisico - tipFisico;
      if (dirTipC.dx.abs() > 1e-3) {
        final Offset dirTipCNorm = _normalizar(dirTipC);
        final double tCorte = (0 - tipFisico.dx) / dirTipCNorm.dx;
        final Offset hit3 = tipFisico + dirTipCNorm * tCorte;
        // Dirección que apunta hacia x negativa (frente al espejo), sin
        // importar hacia dónde apuntaba originalmente dirTipCNorm.
        final Offset dirHaciaFrente = dirTipCNorm.dx > 0 ? -dirTipCNorm : dirTipCNorm;
        final Offset finSolido = hit3 + dirHaciaFrente * 45;
        _dibujarSegmento(canvas, toCanvas(hit3.dx, hit3.dy), toCanvas(finSolido.dx, finSolido.dy), colorRayo3, dashed: false);
        if (centerXFisico > 0) {
          // Espejo convexo: C está detrás del espejo (construcción virtual).
          _dibujarSegmento(canvas, toCanvas(hit3.dx, hit3.dy), toCanvas(cFisico.dx, cFisico.dy), colorRayo3, dashed: true);
        }
      }
    }

    // ---- Imagen (flecha roja, sólida si real, punteada si virtual) ----
    if (di != null && hi != null) {
      final Offset baseImagen = toCanvas(-di, 0);
      final Offset puntaImagen = toCanvas(-di, hi);
      final bool esReal = di > 0;
      _dibujarFlechaObjeto(canvas, baseImagen, puntaImagen, colorImagen, dashed: !esReal);
    }

    // ---- Fotón animado sobre el eje óptico (decorativo) ----
    final double t = (tiempo * 60) % (distanciaObjeto + 40);
    final Offset posFoton = toCanvas(-distanciaObjeto + t, 0.3 * alturaObjeto * math.sin(tiempo * 3));
    canvas.drawCircle(posFoton, 3, Paint()..color = Colors.amber.withOpacity(0.6));

    // ---- Etiqueta informativa ----
    final etiqueta = TextPainter(
      text: TextSpan(
        text: esConcavo ? "Espejo cóncavo" : "Espejo convexo",
        style: GoogleFonts.sourceCodePro(fontSize: 11, color: colorEjes.withOpacity(0.7), fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    etiqueta.layout();
    etiqueta.paint(canvas, const Offset(12, 10));
  }

  Offset _normalizar(Offset v) {
    final double len = v.distance;
    if (len < 1e-9) return const Offset(1, 0);
    return v / len;
  }

  void _marcaEje(Canvas canvas, Offset punto, String etiqueta, Color color) {
    canvas.drawCircle(punto, 3.2, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(text: etiqueta, style: GoogleFonts.sourceCodePro(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, punto + const Offset(-4, 8));
  }

  void _dibujarFlechaObjeto(Canvas canvas, Offset base, Offset punta, Color color, {bool dashed = false}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;

    if (dashed) {
      _dibujarLineaPunteada(canvas, Path()..moveTo(base.dx, base.dy)..lineTo(punta.dx, punta.dy), paint);
    } else {
      canvas.drawLine(base, punta, paint);
    }

    final double angulo = math.atan2(punta.dy - base.dy, punta.dx - base.dx);
    const double tamanoPunta = 9;
    final Path puntaFlecha = Path()
      ..moveTo(punta.dx, punta.dy)
      ..lineTo(punta.dx - tamanoPunta * math.cos(angulo - math.pi / 7), punta.dy - tamanoPunta * math.sin(angulo - math.pi / 7))
      ..lineTo(punta.dx - tamanoPunta * math.cos(angulo + math.pi / 7), punta.dy - tamanoPunta * math.sin(angulo + math.pi / 7))
      ..close();
    canvas.drawPath(puntaFlecha, Paint()..color = color);
  }

  void _dibujarSegmento(Canvas canvas, Offset a, Offset b, Color color, {required bool dashed}) {
    final paint = Paint()
      ..color = color.withOpacity(dashed ? 0.65 : 0.9)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    if (dashed) {
      _dibujarLineaPunteada(canvas, Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy), paint);
    } else {
      canvas.drawLine(a, b, paint);
    }
  }

  void _dibujarLineaPunteada(Canvas canvas, Path path, Paint paint, {double dashWidth = 5, double gapWidth = 4}) {
    for (final metric in path.computeMetrics()) {
      double distancia = 0;
      bool dibujar = true;
      while (distancia < metric.length) {
        final double siguiente = distancia + (dibujar ? dashWidth : gapWidth);
        if (dibujar) {
          final double fin = math.min(siguiente, metric.length);
          canvas.drawPath(metric.extractPath(distancia, fin), paint);
        }
        distancia = siguiente;
        dibujar = !dibujar;
      }
    }
  }

  @override
  bool shouldRepaint(covariant EspejoCurvoPainter oldDelegate) => true;
}