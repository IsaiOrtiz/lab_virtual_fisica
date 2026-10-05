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
    final invF = factor * (1 / radio1 - 1 / radio2);
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
                        _slider('R₁', radio1, -20, 20, (v) => setState(() => radio1 = v.abs() < 0.5 ? (v < 0 ? -0.5 : 0.5) : v), 1),
                        _slider('R₂', radio2, -20, 20, (v) => setState(() => radio2 = v.abs() < 0.5 ? (v < 0 ? -0.5 : 0.5) : v), 1),
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
    final double f = focal.isFinite ? focal : 1000;
    final double minX = math.min(-distanciaObjeto, math.min(-f.abs() * 1.15, distanciaImagen == null ? 0 : -distanciaImagen!.abs())) - 4;
    final double maxX = math.max(distanciaObjeto * 0.15, math.max(f.abs() * 1.15, distanciaImagen == null ? 0 : -distanciaImagen!.abs())) + 4;
    final double rangeX = math.max(1, maxX - minX);
    final double rangeY = math.max(15, alturaObjeto * 2 + 7);
    final double scale = math.min((size.width - 80) / rangeX, (size.height - 110) / rangeY).clamp(8.0, 25.0).toDouble();
    final double axisY = size.height * 0.56;
    final double originX = (size.width - rangeX * scale) / 2 - minX * scale;
    Offset p(double x, double y) => Offset(originX + x * scale, axisY - y * scale);

    canvas.drawLine(Offset(20, axisY), Offset(size.width - 20, axisY), Paint()..color = eje.withOpacity(0.55)..strokeWidth = 1.2);

    // Lente biconvexa / bicóncava estilizada, manteniendo el eje óptico.
    final double lensH = math.min(7.0, math.max(4.5, alturaObjeto * 0.9));
    final Path lentePath = Path();
    if (tipo == TipoLente.convergente) {
      lentePath.moveTo(p(0, lensH).dx, p(0, lensH).dy);
      lentePath.quadraticBezierTo(p(1.8, lensH * 0.35).dx, p(1.8, lensH * 0.35).dy, p(0, 0).dx, p(0, 0).dy);
      lentePath.quadraticBezierTo(p(1.8, -lensH * 0.35).dx, p(1.8, -lensH * 0.35).dy, p(0, -lensH).dx, p(0, -lensH).dy);
      lentePath.quadraticBezierTo(p(-1.8, -lensH * 0.35).dx, p(-1.8, -lensH * 0.35).dy, p(0, 0).dx, p(0, 0).dy);
      lentePath.quadraticBezierTo(p(-1.8, lensH * 0.35).dx, p(-1.8, lensH * 0.35).dy, p(0, lensH).dx, p(0, lensH).dy);
    } else {
      lentePath.moveTo(p(0, lensH).dx, p(0, lensH).dy);
      lentePath.quadraticBezierTo(p(-1.8, lensH * 0.35).dx, p(-1.8, lensH * 0.35).dy, p(0, 0).dx, p(0, 0).dy);
      lentePath.quadraticBezierTo(p(-1.8, -lensH * 0.35).dx, p(-1.8, -lensH * 0.35).dy, p(0, -lensH).dx, p(0, -lensH).dy);
      lentePath.quadraticBezierTo(p(1.8, -lensH * 0.35).dx, p(1.8, -lensH * 0.35).dy, p(0, 0).dx, p(0, 0).dy);
      lentePath.quadraticBezierTo(p(1.8, lensH * 0.35).dx, p(1.8, lensH * 0.35).dy, p(0, lensH).dx, p(0, lensH).dy);
    }
    canvas.drawPath(lentePath, Paint()..color = lente.withOpacity(0.16)..style = PaintingStyle.fill);
    canvas.drawPath(lentePath, Paint()..color = lente..style = PaintingStyle.stroke..strokeWidth = 2.5);

    if (focal.isFinite) {
      _marca(canvas, p(-f, 0), 'F', const Color(0xFF00695C));
      _marca(canvas, p(f, 0), 'F′', const Color(0xFF00695C));
      if (mostrarEtiquetas) {
        _marca(canvas, p(0, 0), 'O', eje);
      }
    }

    _flecha(canvas, p(-distanciaObjeto, 0), p(-distanciaObjeto, alturaObjeto), objeto);

    if (mostrarRayos && focal.isFinite) {
      // Rayo 1: paralelo al eje antes de la lente.
      final hit1 = p(0, alturaObjeto);
      _linea(canvas, p(-distanciaObjeto, alturaObjeto), hit1, rayo1);
      final double targetF = tipo == TipoLente.convergente ? f : f;
      final Offset fin1 = tipo == TipoLente.convergente
          ? p(targetF + 30, -(alturaObjeto / math.max(0.1, targetF)) * 30)
          : p(targetF, 0);
      if (tipo == TipoLente.convergente) {
        _linea(canvas, hit1, fin1, rayo1);
      } else {
        // En una divergente el rayo sale paralelo a la línea que apunta
        // hacia el foco virtual del lado del objeto.
        final dir = _norm(Offset(-f, alturaObjeto));
        _linea(canvas, hit1, hit1 + dir * 42 * scale, rayo1);
        _punteada(canvas, hit1, p(f, 0), rayo1);
      }

      // Rayo 2: pasa por el centro óptico sin desviarse.
      _linea(canvas, p(-distanciaObjeto, alturaObjeto), p(35, -alturaObjeto * 35 / math.max(1, distanciaObjeto)), rayo2);

      // Rayo 3: por el foco (convergente) o dirigido al foco lejano
      // (divergente), y después paralelo.
      final Offset focoIncidente = tipo == TipoLente.convergente ? p(-f, 0) : p(-f, 0);
      final Offset objetoP = p(-distanciaObjeto, alturaObjeto);
      final double denomX = focoIncidente.dx - objetoP.dx;
      if (denomX.abs() > 1e-6) {
        final double t = (p(0, 0).dx - objetoP.dx) / denomX;
        final Offset hit3 = Offset(objetoP.dx + (focoIncidente.dx - objetoP.dx) * t, objetoP.dy + (focoIncidente.dy - objetoP.dy) * t);
        _linea(canvas, objetoP, hit3, rayo3);
        if (tipo == TipoLente.convergente) {
          _linea(canvas, hit3, p(35, hit3PhysicalY(hit3, axisY, scale)), rayo3);
        } else {
          _linea(canvas, hit3, p(35, hit3PhysicalY(hit3, axisY, scale)), rayo3);
          _punteada(canvas, hit3, focoIncidente, rayo3);
        }
      }
    }

    if (distanciaImagen != null && alturaImagen != null && distanciaImagen!.abs() < 100) {
      _flecha(canvas, p(distanciaImagen!, 0), p(distanciaImagen!, alturaImagen!), imagen, punteada: distanciaImagen! < 0);
    }

    final title = tipo == TipoLente.convergente ? 'Lente convergente' : 'Lente divergente';
    final tp = TextPainter(
      text: TextSpan(text: title, style: GoogleFonts.sourceCodePro(fontSize: 11, color: eje, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, 12));
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
