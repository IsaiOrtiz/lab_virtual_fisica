import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';

class OndasEstacionariasSim extends StatefulWidget {
  const OndasEstacionariasSim({super.key});

  @override
  State<OndasEstacionariasSim> createState() => _OndasEstacionariasSimState();
}

class _OndasEstacionariasSimState extends State<OndasEstacionariasSim> {
  double tiempo = 0.0;
  Timer? _timer;

  // Parámetros de la Onda Estacionaria
  double amplitudComponente = 25.0; // Amplitud A de cada onda viajera
  double frecuencia = 1.0;
  double k = 0.03;                   // Número de onda
  
  bool mostrarComponentes = true;    // Mostrar las dos ondas viajeras base

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
          // La onda resultante tendrá amplitud máxima de 2 * amplitudComponente
          final ampMaxDinamica = (altoDisponible / 4) - 10;

          if (amplitudComponente > ampMaxDinamica) {
            amplitudComponente = ampMaxDinamica;
          }

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
                        "Ondas Estacionarias", 
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                      const Divider(),
                      const SizedBox(height: 5),
                      
                      _slider("A", amplitudComponente, 5, ampMaxDinamica, (v) => setState(() => amplitudComponente = v), decimales: 0),
                      _slider("f", frecuencia, 0.1, 2.5, (v) => setState(() => frecuencia = v), decimales: 1, sufijo: " Hz"),
                      _slider("k", k, 0.01, 0.08, (v) => setState(() => k = v), decimales: 3),
                      
                      const Divider(height: 20),
                      
                      CheckboxListTile(
                        title: Text("Mostrar ondas componentes", style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: mostrarComponentes,
                        activeColor: Colors.teal,
                        onChanged: (v) => setState(() => mostrarComponentes = v!),
                      ),
                      
                      const Divider(height: 20),
                      Text("Propiedades Físicas:", style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 6),
                      
                      // Datos analíticos clave para el reporte de laboratorio
                      _buildDatoCalculado("Distancia Nodo-Nodo (λ/2):", "${(math.pi / k).toStringAsFixed(1)} px"),
                      _buildDatoCalculado("Amplitud Máxima (2A):", "${(amplitudComponente * 2).toStringAsFixed(0)} px"),
                      _buildDatoCalculado("Nodos visibles aprox:", "${((constraints.maxWidth - 280) / (math.pi / k)).toStringAsFixed(1)}"),
                    ],
                  ),
                ),
              ),
              
              // ÁREA DE SIMULACIÓN (DERECHA)
              Expanded(
                child: Container(
                  color: const Color(0xFF0F172A), // Azul pizarra oscuro premium
                  child: CustomPaint(
                    painter: StandingWavePainter(
                      tiempo: tiempo,
                      a: amplitudComponente,
                      f: frecuencia,
                      k: k,
                      dibujarComponentes: mostrarComponentes,
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
            child: Text(txt, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal[700])),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                activeTrackColor: Colors.teal,
                thumbColor: Colors.teal,
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600])),
          Text(valor, style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo[700])),
        ],
      ),
    );
  }
}

class StandingWavePainter extends CustomPainter {
  final double tiempo, a, f, k;
  final bool dibujarComponentes;

  StandingWavePainter({
    required this.tiempo,
    required this.a,
    required this.f,
    required this.k,
    required this.dibujarComponentes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    final omega = 2 * math.pi * f;

    // Eje de referencia central
    canvas.drawLine(
      Offset(0, centroY), 
      Offset(size.width, centroY), 
      Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1
    );

    final pathDerecha = Path();
    final pathIzquierda = Path();
    final pathEstacionaria = Path();

    for (double x = 0; x <= size.width; x++) {
      // Componente viajera hacia la derecha
      double y1 = a * math.sin(k * x - tiempo * omega);
      // Componente viajera hacia la izquierda
      double y2 = a * math.sin(k * x + tiempo * omega);
      // Onda Estacionaria resultante
      double yEstacionaria = y1 + y2;

      if (x == 0) {
        pathDerecha.moveTo(x, centroY + y1);
        pathIzquierda.moveTo(x, centroY + y2);
        pathEstacionaria.moveTo(x, centroY + yEstacionaria);
      } else {
        pathDerecha.lineTo(x, centroY + y1);
        pathIzquierda.lineTo(x, centroY + y2);
        pathEstacionaria.lineTo(x, centroY + yEstacionaria);
      }
    }

    // Dibujar las ondas componentes si el switch está activo (líneas punteadas/delgadas)
    if (dibujarComponentes) {
      canvas.drawPath(
        pathDerecha, 
        Paint()..color = Colors.blueAccent.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5
      );
      canvas.drawPath(
        pathIzquierda, 
        Paint()..color = Colors.orangeAccent.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5
      );
    }

    // Dibujar la Onda Estacionaria Resultante (Línea principal robusta)
    final standingPaint = Paint()
      ..color = const Color(0xFF00E5FF) // Cyan eléctrico hiper-visible
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawPath(pathEstacionaria, standingPaint);

    // Dibujar pequeños marcadores visuales para denotar los Nodos estables en el eje X
    final nodoPaint = Paint()..color = Colors.redAccent.withOpacity(0.4)..style = PaintingStyle.fill;
    double pasoNodo = math.pi / k;
    for (double nx = 0; nx <= size.width; nx += pasoNodo) {
      canvas.drawCircle(Offset(nx, centroY), 3.0, nodoPaint);
    }
  }

  @override
  bool shouldRepaint(covariant StandingWavePainter oldDelegate) => true;
}