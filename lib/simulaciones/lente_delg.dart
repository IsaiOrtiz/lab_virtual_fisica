import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/navegacion_simulacion.dart';

enum TipoLente { convergente, divergente }

class LenteDelgadaSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;
  final void Function(Uint8List bytes, String nota)? onCapturar;

  const LenteDelgadaSim({
    super.key,
    this.onIrATeoria,
    this.onIrACuestionario,
    this.onCapturar,
  });

  @override
  State<LenteDelgadaSim> createState() => _LenteDelgadaSimState();
}

class _LenteDelgadaSimState extends State<LenteDelgadaSim> {
  TipoLente tipo = TipoLente.convergente;
  double indice = 1.52;
  double radio1 = 10;
  double radio2 = -10;
  double distanciaObjeto = 22;
  double alturaObjeto = 5;
  bool mostrarRayos = true;
  bool mostrarEtiquetas = true;

  void _seleccionarTipo(TipoLente nuevo) {
    setState(() {
      tipo = nuevo;
      if (nuevo == TipoLente.convergente) {
        radio1 = 10;
        radio2 = -10;
      } else {
        radio1 = -10;
        radio2 = 10;
      }
    });
  }

  double get _focal {
    // Ecuación del fabricante, suponiendo aire como medio exterior:
    // 1/f = (n_lente/n_medio - 1) (1/R1 - 1/R2)
    final factor = indice / 1.0 - 1.0;
    final r1 = tipo == TipoLente.convergente ? radio1.abs() : -radio1.abs();
    final r2 = tipo == TipoLente.convergente ? -radio2.abs() : radio2.abs();
    final invF = factor * (1 / r1 - 1 / r2);
    if (invF.abs() < 1e-9) return double.infinity;
    return 1 / invF;
  }

  double? get _imagen {
    if (!_focal.isFinite) return null;
    final denom = 1 / _focal - 1 / distanciaObjeto;
    if (denom.abs() < 1e-7) return null;
    return 1 / denom;
  }

  double? get _aumento => _imagen == null ? null : -_imagen! / distanciaObjeto;
  double? get _alturaImagen => _aumento == null ? null : _aumento! * alturaObjeto;

  @override
  Widget build(BuildContext context) {
    final f = _focal;
    final di = _imagen;
    final m = _aumento;
    final hi = _alturaImagen;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final anchoPanel = 280.0;
          return Row(
            children: [
              SizedBox(
                width: anchoPanel,
                child: Container(
                  color: const Color(0xFFF4F5F7),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lentes delgadas', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Divider(),
                        Text('Tipo de lente', style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('Convergente'),
                              selected: tipo == TipoLente.convergente,
                              onSelected: (_) => _seleccionarTipo(TipoLente.convergente),
                            ),
                            ChoiceChip(
                              label: const Text('Divergente'),
                              selected: tipo == TipoLente.divergente,
                              onSelected: (_) => _seleccionarTipo(TipoLente.divergente),
                            ),
                          ],
                        ),
                        const Divider(height: 22),
                        _slider('n', indice, 1.30, 1.80, (v) => setState(() => indice = v), 2),
                        _slider('R₁', radio1.abs(), 3, 20, (v) => setState(() => radio1 = v), 1),
                        _slider('R₂', radio2.abs(), 3, 20, (v) => setState(() => radio2 = v), 1),
                        _slider('dₒ', distanciaObjeto, 4, 35, (v) => setState(() => distanciaObjeto = v), 1),
                        _slider('hₒ', alturaObjeto, 2, 8, (v) => setState(() => alturaObjeto = v), 1),
                        const Divider(height: 22),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Mostrar rayos principales', style: TextStyle(fontSize: 11)),
                          value: mostrarRayos,
                          onChanged: (v) => setState(() => mostrarRayos = v ?? true),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Mostrar F y F′', style: TextStyle(fontSize: 11)),
                          value: mostrarEtiquetas,
                          onChanged: (v) => setState(() => mostrarEtiquetas = v ?? true),
                        ),
                        const Divider(height: 22),
                        Text('Ecuación del fabricante', style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 5),
                        Text('1/f = (n − 1)(1/R₁ − 1/R₂)', style: GoogleFonts.sourceCodePro(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Signos: convergente (+R₁, −R₂); divergente (−R₁, +R₂).', style: GoogleFonts.lato(fontSize: 9, color: Colors.blueGrey[700])),
                        const SizedBox(height: 8),
                        _dato('Distancia focal f:', f.isFinite ? f.toStringAsFixed(2) : '∞'),
                        _dato('Distancia imagen dᵢ:', di == null ? '∞' : di.toStringAsFixed(2)),
                        _dato('Aumento m:', m == null ? '—' : m.toStringAsFixed(2)),
                        _dato('Altura imagen hᵢ:', hi == null ? '—' : hi.toStringAsFixed(2)),
                        const SizedBox(height: 6),
                        Text(
                          f > 0 ? 'La lente es convergente: f > 0.' : 'La lente es divergente: f < 0.',
                          style: GoogleFonts.lato(fontSize: 10, color: Colors.blueGrey[700], fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: LenteDelgadaPainter(
                        tipo: tipo,
                        indice: indice,
                        radio1: radio1,
                        radio2: radio2,
                        distanciaObjeto: distanciaObjeto,
                        alturaObjeto: alturaObjeto,
                        focal: f,
                        distanciaImagen: di,
                        alturaImagen: hi,
                        mostrarRayos: mostrarRayos,
                        mostrarEtiquetas: mostrarEtiquetas,
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
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _slider(String etiqueta, double valor, double min, double max, ValueChanged<double> onChanged, int decimales) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 26, child: Text(etiqueta, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(
            child: Slider(
              value: valor.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: 48, child: Text(valor.toStringAsFixed(decimales), textAlign: TextAlign.right, style: GoogleFonts.sourceCodePro(fontSize: 9))),
        ],
      ),
    );
  }

  Widget _dato(String etiqueta, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(etiqueta, style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[600]))),
        Text(valor, style: GoogleFonts.sourceCodePro(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo[700])),
      ],
    ),
  );
}

class LenteDelgadaPainter extends CustomPainter {
  final TipoLente tipo;
  final double indice;
  final double radio1;
  final double radio2;
  final double distanciaObjeto;
  final double alturaObjeto;
  final double focal;
  final double? distanciaImagen;
  final double? alturaImagen;
  final bool mostrarRayos;
  final bool mostrarEtiquetas;

  const LenteDelgadaPainter({
    required this.tipo,
    required this.indice,
    required this.radio1,
    required this.radio2,
    required this.distanciaObjeto,
    required this.alturaObjeto,
    required this.focal,
    required this.distanciaImagen,
    required this.alturaImagen,
    required this.mostrarRayos,
    required this.mostrarEtiquetas,
  });

  static const Color eje = Color(0xFF374151);
  static const Color lente = Color(0xFF546E7A);
  static const Color objeto = Color(0xFF1565C0);
  static const Color imagen = Color(0xFFC62828);
  static const Color rayo1 = Color(0xFFB45309);
  static const Color rayo2 = Color(0xFF2E7D32);
  static const Color rayo3 = Color(0xFF6A1B9A);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 60 || size.height < 80) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final cx = size.width * 0.5;
    final axisY = size.height * 0.56;
    final maxWorldX = ((size.width * 0.5 - 36) / 9.0).clamp(5.0, 40.0).toDouble();
    final maxWorldY = ((size.height * 0.5 - 44) / 9.0).clamp(4.0, 18.0).toDouble();
    final scale = math.min((size.width * 0.5 - 36) / maxWorldX, (size.height * 0.5 - 44) / maxWorldY).clamp(5.0, 18.0).toDouble();
    double safeX(double x) => x.clamp(-maxWorldX, maxWorldX).toDouble();
    double safeY(double y) => y.clamp(-maxWorldY, maxWorldY).toDouble();
    Offset p(double x, double y) => Offset(cx + safeX(x) * scale, axisY - safeY(y) * scale);

    // El lente es una figura ovalada estática; los rayos se trazan sobre un único eje vertical.
    canvas.drawLine(Offset(16, axisY), Offset(size.width - 16, axisY), Paint()..color = eje.withOpacity(0.62)..strokeWidth = 1.3);
    final lensRect = Rect.fromCenter(center: Offset(cx, axisY), width: 30, height: math.min(size.height * 0.62, 220));
    canvas.drawOval(lensRect, Paint()..color = lente.withOpacity(0.16)..style = PaintingStyle.fill);
    canvas.drawOval(lensRect, Paint()..color = lente..style = PaintingStyle.stroke..strokeWidth = 2.3);
    canvas.drawLine(Offset(cx, lensRect.top - 8), Offset(cx, lensRect.bottom + 8), Paint()..color = lente.withOpacity(0.4)..strokeWidth = 1);

    final f = focal.isFinite ? focal : (tipo == TipoLente.convergente ? 10.0 : -10.0);
    if (mostrarEtiquetas) {
      _marca(canvas, p(-f.abs(), 0), 'F', const Color(0xFF00695C));
      _marca(canvas, p(f.abs(), 0), "F′", const Color(0xFF00695C));
      _marca(canvas, Offset(cx, axisY), 'O', eje);
    }

    final xo = -safeX(distanciaObjeto);
    final yo = safeY(alturaObjeto.clamp(1.0, maxWorldY * 0.72));
    final objectTip = p(xo, yo);
    _flecha(canvas, p(xo, 0), objectTip, objeto);

    double? di = distanciaImagen;
    double? hi = alturaImagen;
    if (di == null || hi == null || !di.isFinite || !hi.isFinite) {
      di = tipo == TipoLente.convergente ? maxWorldX : -maxWorldX * 0.7;
      hi = 0;
    }
    final xi = safeX(di);
    final yi = safeY(hi.clamp(-maxWorldY * 0.8, maxWorldY * 0.8));
    final imageBase = p(xi, 0);
    final imageTip = p(xi, yi);

    if (mostrarRayos) {
      final hitParallel = Offset(cx, objectTip.dy);
      _linea(canvas, objectTip, hitParallel, rayo1);
      if ((distanciaImagen ?? 1) > 0) {
        _linea(canvas, hitParallel, imageTip, rayo1);
      } else {
        final slopeY = yo * (1 - maxWorldX / math.max(0.1, distanciaObjeto));
        final outgoing = p(maxWorldX, slopeY);
        _linea(canvas, hitParallel, outgoing, rayo1);
        _punteada(canvas, hitParallel, imageTip, rayo1);
      }

      // Rayo central: atraviesa el centro óptico sin desviarse.
      if ((distanciaImagen ?? 1) > 0) {
        _linea(canvas, objectTip, imageTip, rayo2);
      } else {
        final endY = -yo * maxWorldX / math.max(0.1, distanciaObjeto);
        _linea(canvas, objectTip, p(maxWorldX, endY), rayo2);
        _punteada(canvas, p(0, 0), imageTip, rayo2);
      }

      // Tercer rayo principal: hacia el foco objeto en convergente; dirigido al foco imagen virtual en divergente.
      final focusX = tipo == TipoLente.convergente ? -f.abs() : f.abs();
      final focus = p(focusX, 0);
      final den = focus.dx - objectTip.dx;
      if (den.abs() > 1e-6) {
        final t = (cx - objectTip.dx) / den;
        final hit = Offset(cx, objectTip.dy + (focus.dy - objectTip.dy) * t);
        _linea(canvas, objectTip, hit, rayo3);
        if ((distanciaImagen ?? 1) > 0) {
          _linea(canvas, hit, imageTip, rayo3);
        } else {
          _linea(canvas, hit, Offset(size.width - 18, hit.dy + (hit.dy - focus.dy) * 0.8), rayo3);
          _punteada(canvas, hit, imageTip, rayo3);
        }
      }
    }
    // La imagen se mantiene dentro del lienzo incluso cuando |di| o |hi| son enormes.
    _flecha(canvas, imageBase, imageTip, imagen, punteada: (distanciaImagen ?? 0) < 0);

    final title = tipo == TipoLente.convergente ? 'Lente convergente' : 'Lente divergente';
    final tp = TextPainter(text: TextSpan(text: title, style: GoogleFonts.sourceCodePro(fontSize: 11, color: eje, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout(maxWidth: size.width - 20);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, 12));
    canvas.restore();
  }

  double hit3PhysicalY(Offset point, double axisY, double scale) => (axisY - point.dy) / scale;

  void _marca(Canvas canvas, Offset point, String label, Color color) {
    canvas.drawCircle(point, 3, Paint()..color = color);
    final tp = TextPainter(text: TextSpan(text: label, style: GoogleFonts.sourceCodePro(fontSize: 10, color: color, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, point + const Offset(-4, 8));
  }

  void _flecha(Canvas canvas, Offset base, Offset tip, Color color, {bool punteada = false}) {
    final paint = Paint()..color = color..strokeWidth = 2.6..style = PaintingStyle.stroke;
    if (punteada) _punteada(canvas, base, tip, color); else canvas.drawLine(base, tip, paint);
    final a = math.atan2(tip.dy - base.dy, tip.dx - base.dx);
    final path = Path()..moveTo(tip.dx, tip.dy)..lineTo(tip.dx - 9 * math.cos(a - math.pi / 7), tip.dy - 9 * math.sin(a - math.pi / 7))..lineTo(tip.dx - 9 * math.cos(a + math.pi / 7), tip.dy - 9 * math.sin(a + math.pi / 7))..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _linea(Canvas canvas, Offset a, Offset b, Color color) => canvas.drawLine(a, b, Paint()..color = color.withOpacity(0.9)..strokeWidth = 1.8);

  void _punteada(Canvas canvas, Offset a, Offset b, Color color) {
    final path = Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy);
    final paint = Paint()..color = color.withOpacity(0.48)..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      bool on = true;
      while (d < metric.length) {
        final next = d + (on ? 5 : 4);
        if (on) canvas.drawPath(metric.extractPath(d, math.min(next, metric.length)), paint);
        d = next;
        on = !on;
      }
    }
  }

  Offset _norm(Offset v) => v.distance < 1e-9 ? const Offset(1, 0) : v / v.distance;

  @override
  bool shouldRepaint(covariant LenteDelgadaPainter oldDelegate) => true;
}
