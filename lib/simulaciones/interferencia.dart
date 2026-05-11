import 'package:flutter/material.dart';
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
  double frecuencia = 1.0;
  double amplitud = 35.0;
  bool mostrarComponentes = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text("Superposición de Ondas", 
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
        ),
        
        Row(
          children: [
            const SizedBox(width: 20),
            const Text("Frecuencia"),
            Expanded(
              child: Slider(
                value: frecuencia, min: 0.5, max: 3.0,
                onChanged: (v) => setState(() => frecuencia = v),
              ),
            ),
          ],
        ),
        CheckboxListTile(
          title: const Text("Mostrar ondas viajeras (Roja/Azul)"),
          value: mostrarComponentes, 
          onChanged: (v) => setState(() => mostrarComponentes = v!)
        ),

        Expanded(
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: InterferenciaPainter(
                tiempo: tiempo, 
                frecuencia: frecuencia, 
                amplitud: amplitud,
                mostrarBase: mostrarComponentes
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InterferenciaPainter extends CustomPainter {
  final double tiempo;
  final double frecuencia;
  final double amplitud;
  final bool mostrarBase;

  InterferenciaPainter({
    required this.tiempo, 
    required this.frecuencia, 
    required this.amplitud,
    required this.mostrarBase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    final k = 2 * math.pi / 200; // Número de onda
    final omega = 2 * math.pi * frecuencia;

    final pAzul = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final pRoja = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final pSuma = Paint()
      ..color = Colors.purpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    Path pathAzul = Path();
    Path pathRoja = Path();
    Path pathSuma = Path();

    for (double x = 0; x <= size.width; x++) {
      // Onda 1: Viaja a la derecha (kx - wt)
      double y1 = amplitud * math.sin(k * x - tiempo * omega);
      // Onda 2: Viaja a la izquierda (kx + wt)
      double y2 = amplitud * math.sin(k * x + tiempo * omega);
      // Resultante
      double yTotal = y1 + y2;

      if (x == 0) {
        pathAzul.moveTo(x, centroY + y1);
        pathRoja.moveTo(x, centroY + y2);
        pathSuma.moveTo(x, centroY + yTotal);
      } else {
        pathAzul.lineTo(x, centroY + y1);
        pathRoja.lineTo(x, centroY + y2);
        pathSuma.lineTo(x, centroY + yTotal);
      }
    }

    if (mostrarBase) {
      canvas.drawPath(pathAzul, pAzul);
      canvas.drawPath(pathRoja, pRoja);
    }
    canvas.drawPath(pathSuma, pSuma);
    
    // Dibujamos pequeños nodos en la suma para ver las "partículas"
    final pPunto = Paint()..color = Colors.white;
    for (double x = 0; x <= size.width; x += 40) {
      double yTotal = amplitud * math.sin(k * x - tiempo * omega) + 
                      amplitud * math.sin(k * x + tiempo * omega);
      canvas.drawCircle(Offset(x, centroY + yTotal), 3, pPunto);
    }
  }

  @override
  bool shouldRepaint(covariant InterferenciaPainter oldDelegate) => true;
}