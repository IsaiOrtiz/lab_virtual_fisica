
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../widgets/navegacion_simulacion.dart';


// Falta habilitar onCapturar en el widget
// BotonesNavegacionTabs, para que se pueda
// capturar la pantalla de la simulación y guardarla como imagen.

class PoiseuilleSim extends StatefulWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;
  final void Function(Uint8List bytes, String nota)? onCapturar;

  const PoiseuilleSim({
    super.key,
    this.onIrATeoria,
    this.onIrACuestionario,
    this.onCapturar,
  });

  @override
  State<PoiseuilleSim> createState() => _PoiseuilleSimState();
}

class _PoiseuilleSimState extends State<PoiseuilleSim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  double viscosidad = 0.001;
  double radio = 0.01;
  double longitud = 1.0;
  double presion = 1000;

  String fluido = 'Agua';

  final Map<String, double> fluidos = {
    'Agua': 0.001,
    'Aceite': 0.1,
    'Glicerina': 1.0,
    'Miel': 5.0,
  };

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  double get caudal {
    return math.pi *
        math.pow(radio, 4) *
        presion /
        (8 * viscosidad * longitud);
  }

  double get velocidadMedia => caudal / (math.pi * radio * radio);

  double get velocidadMaxima => 2 * velocidadMedia;

  double get resistencia =>
      (8 * viscosidad * longitud) /
      (math.pi * math.pow(radio, 4));

  double get reynolds =>
      (1000 * velocidadMedia * 2 * radio) / viscosidad;

  void seleccionarFluido(String? valor) {
    if (valor == null) return;
    setState(() {
      fluido = valor;
      viscosidad = fluidos[valor]!;
    });
  }

  Widget control(
    String titulo,
    double valor,
    double minimo,
    double maximo,
    int divisiones,
    String unidad,
    ValueChanged<double> cambio,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text('${valor.toStringAsFixed(3)} $unidad'),
          ],
        ),
        Slider(
          value: valor.clamp(minimo, maximo),
          min: minimo,
          max: maximo,
          divisions: divisiones,
          onChanged: cambio,
        ),
      ],
    );
  }

  Widget resultado(String nombre, String valor, IconData icono) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icono, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nombre,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatoCaudal = caudal * 1000000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ecuación de Poiseuille'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flujo laminar en un tubo',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Modifica las propiedades del fluido y las dimensiones '
              'del tubo para observar cómo cambia el caudal.',
            ),
            const SizedBox(height: 16),

            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CustomPaint(
                    painter: _TuboPainter(
                      progreso: _animation.value,
                      viscosidad: viscosidad,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            const Text(
              'Propiedades del fluido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: fluido,
              decoration: const InputDecoration(
                labelText: 'Seleccionar fluido',
                border: OutlineInputBorder(),
              ),
              items: fluidos.keys.map((nombre) {
                return DropdownMenuItem(
                  value: nombre,
                  child: Text(nombre),
                );
              }).toList(),
              onChanged: seleccionarFluido,
            ),

            const SizedBox(height: 12),
            control(
              'Viscosidad dinámica',
              viscosidad,
              0.001,
              5.0,
              999,
              'Pa·s',
              (v) => setState(() {
                viscosidad = v;
                fluido = 'Personalizado';
              }),
            ),

            const Divider(height: 28),
            const Text(
              'Parámetros del tubo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            control(
              'Radio',
              radio,
              0.005,
              0.03,
              100,
              'm',
              (v) => setState(() => radio = v),
            ),
            control(
              'Longitud',
              longitud,
              0.2,
              5.0,
              96,
              'm',
              (v) => setState(() => longitud = v),
            ),
            control(
              'Diferencia de presión',
              presion,
              100,
              10000,
              99,
              'Pa',
              (v) => setState(() => presion = v),
            ),

            const Divider(height: 28),
            const Text(
              'Resultados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            resultado(
              'Caudal',
              '${formatoCaudal.toStringAsFixed(3)} mL/s',
              Icons.water_drop,
            ),
            resultado(
              'Velocidad media',
              '${velocidadMedia.toStringAsFixed(5)} m/s',
              Icons.speed,
            ),
            resultado(
              'Velocidad máxima',
              '${velocidadMaxima.toStringAsFixed(5)} m/s',
              Icons.bolt,
            ),
            resultado(
              'Resistencia hidráulica',
              '${resistencia.toStringAsFixed(2)} Pa·s/m³',
              Icons.compress,
            ),
            resultado(
              'Número de Reynolds',
              reynolds.toStringAsFixed(2),
              Icons.analytics,
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: reynolds < 2300
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reynolds < 2300
                    ? 'Régimen laminar: el modelo de Poiseuille es aplicable '
                        'bajo las condiciones ideales del modelo.'
                    : 'Advertencia: el número de Reynolds supera 2300. '
                        'El flujo podría dejar de ser laminar y la ecuación '
                        'ideal de Poiseuille puede no representar el flujo real.',
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Ecuación utilizada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Q = π r⁴ ΔP / 8 μ L',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 20),
            BotonesNavegacionTabs(
              onIrATeoria: widget.onIrATeoria,
              onIrACuestionario: widget.onIrACuestionario,
              // onCapturar: widget.onCapturar,
            ),
          ],
        ),
      ),
    );
  }
}

class _TuboPainter extends CustomPainter {
  final double progreso;
  final double viscosidad;

  _TuboPainter({
    required this.progreso,
    required this.viscosidad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centroY = size.height / 2;
    const alto = 90.0;
    final izquierda = 20.0;
    final derecha = size.width - 20;

    final tubo = Paint()
      ..color = Colors.blue.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawLine(
      Offset(izquierda, centroY - alto / 2),
      Offset(derecha, centroY - alto / 2),
      tubo,
    );
    canvas.drawLine(
      Offset(izquierda, centroY + alto / 2),
      Offset(derecha, centroY + alto / 2),
      tubo,
    );

    final fluidoPaint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.22);

    canvas.drawRect(
      Rect.fromLTRB(
        izquierda,
        centroY - alto / 2 + 3,
        derecha,
        centroY + alto / 2 - 3,
      ),
      fluidoPaint,
    );

    final particula = Paint()..color = Colors.blue.shade800;
    final velocidadVisual = 1.0 / (1.0 + viscosidad * 2);

    for (int i = 0; i < 9; i++) {
      final x = izquierda +
          ((progreso * size.width * velocidadVisual + i * 65) %
              (derecha - izquierda));

      for (int j = -2; j <= 2; j++) {
        final y = centroY + j * 13.0;
        final factor = 1 - (j.abs() / 3);
        canvas.drawCircle(
          Offset(x, y),
          2.5 + factor,
          particula,
        );
      }
    }

    final texto = TextPainter(
      text: const TextSpan(
        text: 'Perfil de velocidad: máximo en el centro',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 20);

    texto.paint(canvas, Offset(10, size.height - 22));
  }

  @override
  bool shouldRepaint(covariant _TuboPainter oldDelegate) {
    return oldDelegate.progreso != progreso ||
        oldDelegate.viscosidad != viscosidad;
  }
}
