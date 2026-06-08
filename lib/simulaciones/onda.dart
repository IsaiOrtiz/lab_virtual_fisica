import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';

class OndaViajeraSim extends StatefulWidget {
  const OndaViajeraSim({super.key});

  @override
  State<OndaViajeraSim> createState() => _OndaViajeraSimState();
}

class _OndaViajeraSimState extends State<OndaViajeraSim> {
  double tiempo = 0.0;
  Timer? _timer;

  // Parámetros de la Onda Única
  double amplitud = 40.0;
  double frecuencia = 1.0;
  double k = 0.03;      // Número de onda
  double phi = 0.0;     // Fase inicial
  bool derecha = true;  // Dirección de movimiento (+x o -x)

  @override
  void initState() {
    super.initState();
    // Forzar modo horizontal al entrar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Timer para la animación continua (aprox 60 FPS)
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
          final ampMaxDinamica = (altoDisponible / 2) - 15;

          // Corrección de rango dinámico preventivo
          if (amplitud > ampMaxDinamica) amplitud = ampMaxDinamica;

          return Row(
            children: [
              // PANEL DE CONTROLES (IZQUIERDA)
              Container(
                width: 280,
                color: Colors.grey[100],
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Análisis de Onda", 
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                      const Divider(),
                      const SizedBox(height: 5),
                      
                      _slider("A", amplitud, 0, ampMaxDinamica, (v) => setState(() => amplitud = v), decimales: 0),
                      _slider("f", frecuencia, 0.1, 3.0, (v) => setState(() => frecuencia = v), decimales: 1, sufijo: " Hz"),
                      _slider("k", k, 0.01, 0.1, (v) => setState(() => k = v), decimales: 3),
                      _slider("φ", phi, 0, 2 * math.pi, (v) => setState(() => phi = v), decimales: 2, sufijo: " rad"),
                      
                      const Divider(height: 24),
                      Text(
                        "Dirección de Propagación", 
                        style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)
                      ),
                      const SizedBox(height: 4),
                      
                      // Selector de dirección estilizado
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Center(child: Text('Hacia la Derecha (+x)', style: GoogleFonts.lato(fontSize: 10))),
                              selected: derecha,
                              onSelected: (val) { if (val) setState(() => derecha = true); },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Center(child: Text('Hacia la Izquierda (-x)', style: GoogleFonts.lato(fontSize: 10))),
                              selected: !derecha,
                              onSelected: (val) { if (val) setState(() => derecha = false); },
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 24),
                      // Datos calculados en tiempo real (Útil para el laboratorio)
                      _buildDatoCalculado("Longitud de onda (λ):", "${(2 * math.pi / k).toStringAsFixed(1)} px"),
                      _buildDatoCalculado("Periodo (T):", "${(1 / frecuencia).toStringAsFixed(2)} s"),
                      _buildDatoCalculado("Velocidad de fase (v):", "${((2 * math.pi * frecuencia) / k).toStringAsFixed(1)} px/s"),
                    ],
                  ),
                ),
              ),
              
              // ÁREA DE SIMULACIÓN (DERECHA)
              Expanded(
                child: Container(
                  color: const Color(0xFF0D1117), // Fondo oscuro estilo osciloscopio
                  child: CustomPaint(
                    painter: SingleWavePainter(
                      tiempo: tiempo,
                      amplitud: amplitud,
                      frecuencia: frecuencia,
                      k: k,
                      phi: phi,
                      haciaDerecha: derecha,
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

  Widget _slider(String txt, double val, double min, double max, ValueChanged<double> cb, {int decimales = 2, String sufijo = ""}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(txt, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
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

  Widget _buildDatoCalculado(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600])),
          Text(valor, style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[700])),
        ],
      ),
    );
  }
}

class SingleWavePainter extends CustomPainter {
  final double tiempo, amplitud, frecuencia, k, phi;
  final bool haciaDerecha;

  SingleWavePainter({
    required this.tiempo,
    required this.amplitud,
    required this.frecuencia,
    required this.k,
    required this.phi,
    required this.haciaDerecha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    final w = 2 * math.pi * frecuencia; // Frecuencia angular (omega)

    // Dibujar línea de referencia central (Eje X)
    final ejePaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, centroY), Offset(size.width, centroY), ejePaint);

    final path = Path();

    for (double x = 0; x <= size.width; x++) {
      // Física del cambio de dirección: 
      // Hacia la derecha (+x): kx - wt
      // Hacia la izquierda (-x): kx + wt
      double argumentoTerminoTemporal = haciaDerecha ? (tiempo * w) : -(tiempo * w);
      double y = amplitud * math.sin(k * x - argumentoTerminoTemporal + phi);

      if (x == 0) {
        path.moveTo(x, centroY + y);
      } else {
        path.lineTo(x, centroY + y);
      }
    }

    final wavePaint = Paint()
      ..color = const Color(0xFF00E676) // Verde brillante tipo fósforo de osciloscopio
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant SingleWavePainter oldDelegate) => true;
}