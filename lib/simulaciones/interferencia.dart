import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la rotación
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';

class InterferenciaSim extends StatefulWidget {
  const InterferenciaSim({super.key});

  @override
  State<InterferenciaSim> createState() => _InterferenciaSimState();
}

class _InterferenciaSimState extends State<InterferenciaSim> {
  double tiempo = 0.0;
  Timer? _timer;

  // Parámetros Onda 1 (Azul)
  double amp1 = 30.0;
  double freq1 = 1.0;
  double k1 = 0.03;   // Número de onda
  double phi1 = 0.0; // Fase inicial
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
    // 1. FORZAR MODO HORIZONTAL AL ENTRAR
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        tiempo += 0.05;
      });
    });
  }

  @override
  void dispose() {
    // 2. REGRESAR A MODO VERTICAL AL SALIR
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // PANEL DE CONTROLES (IZQUIERDA)
          Container(
            width: 250,
            color: Colors.grey[100],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text("Parámetros", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildWaveControls("Onda Azul", Colors.blue, amp1, freq1, k1, phi1, vis1, 
                    (v) => setState(() => amp1 = v), (v) => setState(() => freq1 = v), 
                    (v) => setState(() => k1 = v), (v) => setState(() => phi1 = v),
                    (v) => setState(() => vis1 = v!)),
                  const SizedBox(height: 10),
                  _buildWaveControls("Onda Roja", Colors.red, amp2, freq2, k2, phi2, vis2, 
                    (v) => setState(() => amp2 = v), (v) => setState(() => freq2 = v), 
                    (v) => setState(() => k2 = v), (v) => setState(() => phi2 = v),
                    (v) => setState(() => vis2 = v!)),
                  CheckboxListTile(
                    title: const Text("Suma"),
                    value: visSuma, 
                    onChanged: (v) => setState(() => visSuma = v!)
                  ),
                ],
              ),
            ),
          ),
          // ÁREA DE SIMULACIÓN (DERECHA)
          Expanded(
            child: Container(
              color: Colors.black,
              child: CustomPaint(
                painter: WavePainter(
                  tiempo: tiempo,
                  a1: amp1, f1: freq1, k1: k1, p1: phi1, v1: vis1,
                  a2: amp2, f2: freq2, k2: k2, p2: phi2, v2: vis2,
                  vSuma: visSuma,
                ),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveControls(String label, Color color, double a, double f, double k, double p, bool v,
      ValueChanged<double> onA, ValueChanged<double> onF, ValueChanged<double> onK, ValueChanged<double> onP, ValueChanged<bool?> onV) {
    return Column(
      children: [
        Row(children: [
          Checkbox(value: v, onChanged: onV, activeColor: color),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ]),
        _slider("A", a, 0, 100, onA),
        _slider("f", f, 0.1, 100, onF),
        // Rango de frecuencia 
        _slider("k", k, 0.01, 1, onK),
        _slider("φ", p, 0, 2 * math.pi, onP),
      ],
    );
  }

  Widget _slider(String txt, double val, double min, double max, ValueChanged<double> cb) {
    return Row(
      children: [
        Text(txt, style: const TextStyle(fontSize: 10)),
        Expanded(child: Slider(value: val, min: min, max: max, onChanged: cb)),
      ],
    );
  }
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

    final path1 = Path();
    final path2 = Path();
    final pathSuma = Path();

    for (double x = 0; x <= size.width; x++) {
      // Ecuación: y = A * sin(kx ± wt + phi)
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

    if (v1) canvas.drawPath(path1, Paint()..color = Colors.blue.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
    if (v2) canvas.drawPath(path2, Paint()..color = Colors.red.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
    if (vSuma) canvas.drawPath(pathSuma, Paint()..color = Colors.purpleAccent..style = PaintingStyle.stroke..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}