import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/navegacion_simulacion.dart';

/// Tubo de Venturi: continuidad y Bernoulli para un fluido ideal e incompresible.
class VenturiSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;
  final void Function(Uint8List bytes, String nota)? onCapturar;
  const VenturiSim({super.key, this.onIrATeoria, this.onIrACuestionario, this.onCapturar});
  @override
  State<VenturiSim> createState() => _VenturiSimState();
}

class _VenturiSimState extends State<VenturiSim> with SingleTickerProviderStateMixin {
  late final AnimationController _flowController;
  @override
  void initState() { super.initState(); _flowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override
  void dispose() { _flowController.dispose(); super.dispose(); }
  double velocidadEntrada = 1.5; // m/s
  double relacionDiametros = 0.50; // D garganta / D entrada
  double densidad = 1000; // kg/m³
  double presionEntrada = 180000; // Pa
  double diametroEntrada = 0.16; // m

  double get velocidadGarganta => velocidadEntrada / (relacionDiametros * relacionDiametros);
  double get presionGarganta => presionEntrada + 0.5 * densidad * (velocidadEntrada * velocidadEntrada - velocidadGarganta * velocidadGarganta);
  double get areaEntrada => math.pi * diametroEntrada * diametroEntrada / 4;
  double get caudal => areaEntrada * velocidadEntrada;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 6), child: Row(children: [
          const Icon(Icons.water, color: Color(0xFF176B87), size: 26),
          const SizedBox(width: 9),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Principio de Bernoulli · Tubo de Venturi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF183247))),
            Text('La garganta estrecha aumenta la velocidad y reduce la presión estática.', style: TextStyle(fontSize: 12, color: Color(0xFF607786))),
          ])),
          BotonesNavegacionTabs(onIrATeoria: widget.onIrATeoria, onIrACuestionario: widget.onIrACuestionario),
        ])),
        Expanded(child: compact ? Column(children: [Expanded(child: _dibujo()), Flexible(child: SingleChildScrollView(child: _panelControl(compacto: true)))]) : Row(children: [SizedBox(width: 280, child: SingleChildScrollView(child: _panelControl())), Expanded(child: _dibujo())])),
      ])),
    );
  }

  Widget _panelControl({bool compacto = false}) => Container(
    margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDCE5EA))),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Parámetros del fluido', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF183247))),
      _control('Velocidad de entrada', velocidadEntrada, 0.5, 2.5, 'm/s', (v) => setState(() => velocidadEntrada = v)),
      _control('Diámetro de entrada', diametroEntrada, 0.10, 0.24, 'm', (v) => setState(() => diametroEntrada = v)),
      _control('Relación D₂ / D₁', relacionDiametros, 0.38, 0.78, '', (v) => setState(() => relacionDiametros = v)),
      _control('Densidad', densidad, 700, 1200, 'kg/m³', (v) => setState(() => densidad = v)),
      _control('Presión de entrada', presionEntrada / 1000, 120, 250, 'kPa', (v) => setState(() => presionEntrada = v * 1000)),
      _panelResultados(),
    ]),
  );

  Widget _control(String label, double value, double min, double max, String unit, ValueChanged<double> change) => Padding(
    padding: const EdgeInsets.only(top: 9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF526875)))), Text('${value.toStringAsFixed(2)} $unit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
      Slider(value: value.clamp(min, max).toDouble(), min: min, max: max, onChanged: change, activeColor: const Color(0xFF176B87)),
    ]),
  );

  Widget _panelResultados() => Container(
    margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFEAF3F7), borderRadius: BorderRadius.circular(12)),
    child: Wrap(spacing: 18, runSpacing: 8, children: [
      _dato('Velocidad v₁', '${velocidadEntrada.toStringAsFixed(2)} m/s'),
      _dato('Velocidad v₂', '${velocidadGarganta.toStringAsFixed(2)} m/s'),
      _dato('Presión p₁', '${(presionEntrada / 1000).toStringAsFixed(1)} kPa'),
      _dato('Presión p₂', '${(presionGarganta / 1000).toStringAsFixed(1)} kPa'),
      _dato('Caudal Q', '${(caudal * 1000).toStringAsFixed(2)} L/s'),
    ]),
  );
  Widget _dato(String label, String value) => SizedBox(width: 112, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF526875))), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF155E75)))]));

  Widget _dibujo() => Padding(padding: const EdgeInsets.fromLTRB(8, 4, 16, 14), child: Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDCE5EA))),
    child: AnimatedBuilder(animation: _flowController, builder: (context, _) => CustomPaint(size: Size.infinite, painter: _VenturiPainter(v1: velocidadEntrada, ratio: relacionDiametros, p1: presionEntrada, p2: presionGarganta, phase: _flowController.value))),
  ));
}

class _VenturiPainter extends CustomPainter {
  Size _canvasSize = Size.zero;
  final double v1, ratio, p1, p2, phase;
  _VenturiPainter({required this.v1, required this.ratio, required this.p1, required this.p2, required this.phase});
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 20 || size.height < 20) return;
    canvas.save(); canvas.clipRect(Offset.zero & size);
    _canvasSize = size;
    final w = size.width, h = size.height;
    final cy = h * 0.48;
    final left = w * 0.07, right = w * 0.94;
    final inletHalf = math.min(h * 0.22, 100.0);
    final throatHalf = inletHalf * ratio;
    final x1 = w * 0.34, x2 = w * 0.45, x3 = w * 0.61, x4 = w * 0.72;
    final top = Path()..moveTo(left, cy-inletHalf)..lineTo(x1, cy-inletHalf)..cubicTo(x1+25, cy-inletHalf, x2-20, cy-throatHalf, x2, cy-throatHalf)..lineTo(x3, cy-throatHalf)..cubicTo(x3+20, cy-throatHalf, x4-25, cy-inletHalf, x4, cy-inletHalf)..lineTo(right, cy-inletHalf);
    final bottom = Path()..moveTo(left, cy+inletHalf)..lineTo(x1, cy+inletHalf)..cubicTo(x1+25, cy+inletHalf, x2-20, cy+throatHalf, x2, cy+throatHalf)..lineTo(x3, cy+throatHalf)..cubicTo(x3+20, cy+throatHalf, x4-25, cy+inletHalf, x4, cy+inletHalf)..lineTo(right, cy+inletHalf);
    // Filled passage with clipped streamlines.
    final area = Path()..moveTo(left, cy-inletHalf)..lineTo(x1, cy-inletHalf)..cubicTo(x1+25, cy-inletHalf, x2-20, cy-throatHalf, x2, cy-throatHalf)..lineTo(x3, cy-throatHalf)..cubicTo(x3+20, cy-throatHalf, x4-25, cy-inletHalf, x4, cy-inletHalf)..lineTo(right, cy-inletHalf)..lineTo(right, cy+inletHalf)..lineTo(x4, cy+inletHalf)..cubicTo(x4-25, cy+inletHalf, x3+20, cy+throatHalf, x3, cy+throatHalf)..lineTo(x2, cy+throatHalf)..cubicTo(x2-20, cy+throatHalf, x1+25, cy+inletHalf, x1, cy+inletHalf)..lineTo(left, cy+inletHalf)..close();
    canvas.drawPath(area, Paint()..color = const Color(0xFFE7F5FA));
    canvas.drawPath(top, Paint()..color = const Color(0xFF426879)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawPath(bottom, Paint()..color = const Color(0xFF426879)..style = PaintingStyle.stroke..strokeWidth = 3);
    // Tubos piezométricos abiertos: la altura representa la presión estática.
    final tubeXs = <double>[left + (x1-left)*0.48, (x2+x3)/2, x4 + (right-x4)*0.48];
    final tubePressures = <double>[p1, p2, p1];
    final tubeYs = <double>[cy-inletHalf, cy-throatHalf, cy-inletHalf];
    final pMin = math.min(p1, p2);
    final pMax = math.max(p1, p2);
    final tubePaint = Paint()..color = const Color(0xFF426879)..style = PaintingStyle.stroke..strokeWidth = 2.4;
    final waterPaint = Paint()..color = const Color(0xFF64B5D2)..style = PaintingStyle.fill;
    for (var i = 0; i < tubeXs.length; i++) {
      final tx = tubeXs[i], pipeY = tubeYs[i], pressure = tubePressures[i];
      final topY = cy - inletHalf - 86 - ((pressure-pMin)/(math.max(1.0, pMax-pMin))) * 28;
      final tube = Path()..moveTo(tx-9, pipeY)..lineTo(tx-9, topY)..quadraticBezierTo(tx-9, topY-5, tx-4, topY-5)..lineTo(tx+4, topY-5)..quadraticBezierTo(tx+9, topY-5, tx+9, topY)..lineTo(tx+9, pipeY);
      canvas.drawPath(tube, tubePaint);
      canvas.drawRect(Rect.fromLTRB(tx-6.5, topY+2, tx+6.5, pipeY-2), waterPaint);
      canvas.drawLine(Offset(tx-10, topY), Offset(tx+10, topY), Paint()..color=const Color(0xFF0B7189)..strokeWidth=2);
      _text(canvas, '${i==1 ? 'p₂' : 'p₁'}', Offset(tx-10, topY-22), 11, const Color(0xFF155E75));
    }
    // Flow arrows: fewer/shorter at inlet, denser/faster in throat to emphasize v₂ > v₁.
    final arrowPaint = Paint()..strokeWidth = 2.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final lanes = [-0.62, -0.30, 0.0, 0.30, 0.62];
    for (final lane in lanes) {
      final y1 = cy + lane * inletHalf * 0.72;
      _arrow(canvas, Offset(left+w*0.04, y1), Offset(left+w*0.04+w*0.10, y1), const Color(0xFF2686A6), arrowPaint);
      final yt = cy + lane * throatHalf * 0.65;
      final start = Offset(x2 + (x3-x2)*0.24, yt);
      final len = (w * 0.15 / ratio.clamp(0.38, 0.78)).clamp(w*0.13, w*0.27).toDouble();
      _arrow(canvas, start, Offset(math.min(x3-3, start.dx+len), yt), const Color(0xFF0B7189), arrowPaint..strokeWidth = 2.8);
    }
    // Partículas animadas: la fase avanza más deprisa en la garganta, mostrando mayor velocidad.
    final particlePaint = Paint()..color = const Color(0xFF087F8C);
    for (var i = 0; i < 15; i++) {
      final t = (phase + i / 15) % 1.0;
      final px = left + t * (right-left);
      double half;
      if (px < x1) { half = inletHalf; }
      else if (px < x2) { final q=(px-x1)/(x2-x1); half=inletHalf-(inletHalf-throatHalf)*q; }
      else if (px < x3) { half=throatHalf; }
      else if (px < x4) { final q=(px-x3)/(x4-x3); half=throatHalf+(inletHalf-throatHalf)*q; }
      else { half=inletHalf; }
      final lane = ((i % 5)-2) * 0.23;
      canvas.drawCircle(Offset(px, cy + lane*half), 3.0, particlePaint);
    }
        _text(canvas, 'ENTRADA', Offset(left, cy-inletHalf-28), 11, const Color(0xFF426879));
    _text(canvas, 'GARGANTA', Offset((x2+x3)/2-30, cy-throatHalf-28), 11, const Color(0xFF0B7189));
    _text(canvas, 'SALIDA', Offset(right-48, cy-inletHalf-28), 11, const Color(0xFF426879));
    _text(canvas, 'Área grande\nv baja', Offset(left+w*0.08, cy+inletHalf+13), 10, const Color(0xFF526875));
    _text(canvas, 'Área menor\nv alta', Offset((x2+x3)/2-32, cy+throatHalf+13), 10, const Color(0xFF0B7189));
    _text(canvas, 'v₁ = ${v1.toStringAsFixed(2)} m/s', Offset(left+w*0.02, cy+inletHalf*0.35), 11, const Color(0xFF155E75));
    _text(canvas, 'v₂ = ${(v1/(ratio*ratio)).toStringAsFixed(2)} m/s', Offset((x2+x3)/2-38, cy-throatHalf*0.1), 11, const Color(0xFF075985));
    _text(canvas, 'p₁ ${(p1/1000).toStringAsFixed(0)} kPa', Offset(left, cy+inletHalf+42), 10, const Color(0xFF64748B));
    _text(canvas, 'p₂ ${(p2/1000).toStringAsFixed(0)} kPa', Offset((x2+x3)/2-32, cy+throatHalf+42), 10, const Color(0xFF64748B));
    canvas.restore();
  }
  void _arrow(Canvas c, Offset a, Offset b, Color color, Paint paint) { c.drawLine(a,b,paint..color=color); final ang=math.atan2(b.dy-a.dy,b.dx-a.dx); const s=7.0; final path=Path()..moveTo(b.dx,b.dy)..lineTo(b.dx-s*math.cos(ang-math.pi/6),b.dy-s*math.sin(ang-math.pi/6))..moveTo(b.dx,b.dy)..lineTo(b.dx-s*math.cos(ang+math.pi/6),b.dy-s*math.sin(ang+math.pi/6)); c.drawPath(path,paint..color=color); }
  void _text(Canvas c, String s, Offset at, double font, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: font, color: color, fontWeight: FontWeight.w700, height: 1.15)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    )..layout(maxWidth: math.max(40.0, math.min(180.0, _canvasSize.width - 8)));
    // Mantiene las etiquetas completas dentro del área visible del dibujo.
    final maxX = math.max(2.0, _canvasSize.width - tp.width - 2);
    final maxY = math.max(2.0, _canvasSize.height - tp.height - 2);
    tp.paint(c, Offset(at.dx.clamp(2.0, maxX).toDouble(), at.dy.clamp(2.0, maxY).toDouble()));
  }
  @override bool shouldRepaint(covariant _VenturiPainter old) => old.v1!=v1||old.ratio!=ratio||old.p1!=p1||old.p2!=p2||old.phase!=phase;
}
