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
  
  // Parámetros independientes de la Onda Azul (Derecha)
  double freqAzul = 1.0;
  double ampAzul = 30.0;
  bool mostrarAzul = true;

  // Parámetros independientes de la Onda Roja (Izquierda)
  double freqRoja = 1.0;
  double ampRoja = 30.0;
  bool mostrarRoja = true;

  // Control de la Onda Resultante (Púrpura)
  bool mostrarSuma = true;

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
          child: Text(
            "Superposición Personalizada de Ondas", 
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
          ),
        ),
        
        // Panel de Controles Avanzados
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // --- CONTROLES ONDA AZUL ---
                _buildControlSection(
                  titulo: "Onda Azul (Hacia la derecha)",
                  color: Colors.blue,
                  checkboxValue: mostrarAzul,
                  onCheckboxChanged: (v) => setState(() => mostrarAzul = v!),
                  sliders: [
                    _buildSliderRow("Frecuencia", freqAzul, 0.5, 3.0, (v) => setState(() => freqAzul = v)),
                    _buildSliderRow("Amplitud", ampAzul, 0.0, 60.0, (v) => setState(() => ampAzul = v)),
                  ],
                ),
                const Divider(),

                // --- CONTROLES ONDA ROJA ---
                _buildControlSection(
                  titulo: "Onda Roja (Hacia la izquierda)",
                  color: Colors.red,
                  checkboxValue: mostrarRoja,
                  onCheckboxChanged: (v) => setState(() => mostrarRoja = v!),
                  sliders: [
                    _buildSliderRow("Frecuencia", freqRoja, 0.5, 3.0, (v) => setState(() => freqRoja = v)),
                    _buildSliderRow("Amplitud", ampRoja, 0.0, 60.0, (v) => setState(() => ampRoja = v)),
                  ],
                ),
                const Divider(),

                // --- CONTROL RESULTANTE ---
                CheckboxListTile(
                  title: const Text("Mostrar Onda Resultante (Púrpura)", style: TextStyle(fontWeight: FontWeight.bold)),
                  activeColor: Colors.purple,
                  value: mostrarSuma,
                  onChanged: (v) => setState(() => mostrarSuma = v!),
                ),
              ],
            ),
          ),
        ),

        // Área de renderizado visual de la simulación
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95), // Fondo oscuro para resaltar señales
              borderRadius: BorderRadius.circular(15),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: InterferenciaPainter(
                tiempo: tiempo,
                freqAzul: freqAzul,
                ampAzul: ampAzul,
                mostrarAzul: mostrarAzul,
                freqRoja: freqRoja,
                ampRoja: ampRoja,
                mostrarRoja: mostrarRoja,
                mostrarSuma: mostrarSuma,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper para construir las secciones de control de forma limpia
  Widget _buildControlSection({
    required String titulo,
    required Color color,
    required bool checkboxValue,
    required ValueChanged<bool?> onCheckboxChanged,
    required List<Widget> sliders,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text(titulo, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          activeColor: color,
          value: checkboxValue,
          onChanged: onCheckboxChanged,
        ),
        if (checkboxValue) ...sliders,
      ],
    );
  }

  // Helper para renderizar cada fila de deslizadores
  Widget _buildSliderRow(String label, double valor, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text("$label: ${valor.toStringAsFixed(1)}")),
        Expanded(
          child: Slider(
            value: valor,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class InterferenciaPainter extends CustomPainter {
  final double tiempo;
  final double freqAzul;
  final double ampAzul;
  final bool mostrarAzul;
  final double freqRoja;
  final double ampRoja;
  final bool mostrarRoja;
  final bool mostrarSuma;

  InterferenciaPainter({
    required this.tiempo,
    required this.freqAzul,
    required this.ampAzul,
    required this.mostrarAzul,
    required this.freqRoja,
    required this.ampRoja,
    required this.mostrarRoja,
    required this.mostrarSuma,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    final k = 2 * math.pi / 200; // Número de onda base común

    // Frecuencias angulares independientes
    final omegaAzul = 2 * math.pi * freqAzul;
    final omegaRoja = 2 * math.pi * freqRoja;

    final pAzul = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final pRoja = Paint()
      ..color = Colors.red.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final pSuma = Paint()
      ..color = Colors.purpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final pPunto = Paint()..color = Colors.white;

    Path pathAzul = Path();
    Path pathRoja = Path();
    Path pathSuma = Path();

    for (double x = 0; x <= size.width; x++) {
      // Onda 1 (Azul): Viaja a la derecha (kx - wt)
      double y1 = ampAzul * math.sin(k * x - tiempo * omegaAzul);
      // Onda 2 (Roja): Viaja a la izquierda (kx + wt)
      double y2 = ampRoja * math.sin(k * x + tiempo * omegaRoja);
      // Resultante matemática pura
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

    // Dibujar caminos condicionalmente basado en la UI
    if (mostrarAzul) canvas.drawPath(pathAzul, pAzul);
    if (mostrarRoja) canvas.drawPath(pathRoja, pRoja);
    if (mostrarSuma) {
      canvas.drawPath(pathSuma, pSuma);
      
      // Dibujar los nodos/puntos sobre la línea resultante
      for (double x = 0; x <= size.width; x += 40) {
        double y1 = ampAzul * math.sin(k * x - tiempo * omegaAzul);
        double y2 = ampRoja * math.sin(k * x + tiempo * omegaRoja);
        canvas.drawCircle(Offset(x, centroY + y1 + y2), 3, pPunto);
      }
    }
  }

  @override
  bool shouldRepaint(covariant InterferenciaPainter oldDelegate) => true;
}