import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
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
      setState(() {
        tiempo += 0.05;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final altoDisponible = constraints.maxHeight;
          final ampMaxDinamica = (altoDisponible / 2) - 10;

          if (amp1 > ampMaxDinamica) amp1 = ampMaxDinamica;
          if (amp2 > ampMaxDinamica) amp2 = ampMaxDinamica;

          return Row(
            children: [
              // PANEL DE CONTROLES (IZQUIERDA)
              Container(
                width: 280, 
                color: Colors.grey[100],
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        "Parámetros Dinámicos", 
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                      const Divider(),
                      _buildWaveControls(
                        "Onda Azul", Colors.blue[700]!, amp1, freq1, k1, phi1, vis1, ampMaxDinamica,
                        (v) => setState(() => amp1 = v), (v) => setState(() => freq1 = v), 
                        (v) => setState(() => k1 = v), (v) => setState(() => phi1 = v),
                        (v) => setState(() => vis1 = v!)
                      ),
                      const SizedBox(height: 10),
                      _buildWaveControls(
                        "Onda Roja", Colors.red[700]!, amp2, freq2, k2, phi2, vis2, ampMaxDinamica,
                        (v) => setState(() => amp2 = v), (v) => setState(() => freq2 = v), 
                        (v) => setState(() => k2 = v), (v) => setState(() => phi2 = v),
                        (v) => setState(() => vis2 = v!)
                      ),
                      const Divider(),
                      CheckboxListTile(
                        title: Text("Mostrar Suma (Resultante)", style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold)),
                        dense: true,
                        activeColor: Colors.indigo[900],
                        value: visSuma, 
                        onChanged: (v) => setState(() => visSuma = v!)
                      ),
                    ],
                  ),
                ),
              ),
              // ÁREA DE SIMULACIÓN (DERECHA) - ESTILO PAPEL MILIMÉTRICO
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC), // Fondo Slate muy claro texturizado por la malla
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
          );
        }
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
            width: 24,
            height: 24,
            child: Checkbox(value: v, onChanged: onV, activeColor: color),
          ),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.lato(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 4),
        _slider("A", a, 0, maxAmp, onA, decimales: 0),
        _slider("f", f, 0.1, 3.0, onF, decimales: 1, sufijo: " Hz"),
        _slider("k", k, 0.01, 0.1, onK, decimales: 3),
        _slider("φ", p, 0, 2 * math.pi, onP, decimales: 2, sufijo: " rad"),
      ],
    );
  }

  Widget _slider(String txt, double val, double min, double max, ValueChanged<double> cb, {int decimales = 2, String sufijo = ""}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(txt, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(value: val, min: min, max: max, onChanged: cb),
            ),
          ),
          SizedBox(
            width: 55,
            child: Text(
              "${val.toStringAsFixed(decimales)}$sufijo", 
              style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.black87),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
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

    // ---- RENDERIZADO DEL PAPEL MILIMÉTRICO ----
    final pinturaMallaFina = Paint()
      ..color = Colors.indigo.withOpacity(0.04) // Líneas secundarias muy tenues
      ..strokeWidth = 0.5;

    final pinturaMallaPrincipal = Paint()
      ..color = Colors.indigo.withOpacity(0.12) // Líneas principales (cada 5 subdivisiones)
      ..strokeWidth = 1.0;

    const double pasoMalla = 10.0; // Subdivisiones de 10 píxeles

    // Cuadrícula Vertical
    for (double x = 0; x <= size.width; x += pasoMalla) {
      final esPrincipal = (x / pasoMalla) % 5 == 0;
      canvas.drawLine(
        Offset(x, 0), 
        Offset(x, size.height), 
        esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina
      );
    }

    // Cuadrícula Horizontal
    for (double y = 0; y <= size.height; y += pasoMalla) {
      final esPrincipal = (y / pasoMalla) % 5 == 0;
      canvas.drawLine(
        Offset(0, y), 
        Offset(size.width, y), 
        esPrincipal ? pinturaMallaPrincipal : pinturaMallaFina
      );
    }

    // Eje X Central de referencia (Marcado en el centro geométrico)
    final pinturaEjeCentral = Paint()
      ..color = Colors.indigo.withOpacity(0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, centroY), Offset(size.width, centroY), pinturaEjeCentral);


    // ---- CÁLCULO DE LOS PATHS MATEMÁTICOS ----
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

    // ---- DIBUJAR ONDAS CON CONTRASTE ALTO ----
    // Onda 1: Azul Oscuro con opacidad balanceada
    if (v1) {
      canvas.drawPath(
        path1, 
        Paint()
          ..color = Colors.blue[700]!.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
      );
    }
    
    // Onda 2: Rojo Quemado para evitar fatiga visual
    if (v2) {
      canvas.drawPath(
        path2, 
        Paint()
          ..color = Colors.red[700]!.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
      );
    }
    
    // Onda Resultante: Índigo Profundo y de mayor grosor para denotar jerarquía
    if (vSuma) {
      canvas.drawPath(
        pathSuma, 
        Paint()
          ..color = Colors.indigo[900]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}