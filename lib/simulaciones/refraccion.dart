import 'package:flutter/material.dart';
import 'dart:async';

class MRUSimulador extends StatefulWidget {
  const MRUSimulador({super.key});

  @override
  State<MRUSimulador> createState() => _MRUSimuladorState();
}

class _MRUSimuladorState extends State<MRUSimulador> {
  double _posicionX = 0.0;
  double _velocidad = 5.0; // Unidades por paso
  Timer? _timer;
  bool _estaCorriendo = false;

  void _iniciarSimulacion() {
    if (_estaCorriendo) return;
    setState(() => _estaCorriendo = true);
    
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _posicionX += _velocidad;
        // Reiniciar si se sale del cuadro (loop)
        if (_posicionX > 280) _posicionX = 0;
      });
    });
  }

  void _detenerSimulacion() {
    _timer?.cancel();
    setState(() => _estaCorriendo = false);
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
        Text("Velocidad: ${_velocidad.toInt()} m/s"),
        Slider(
          value: _velocidad,
          min: 1,
          max: 20,
          onChanged: (val) => setState(() => _velocidad = val),
        ),
        const SizedBox(height: 20),
        // "Pista" de la simulación
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo),
          ),
          child: Stack(
            children: [
              Positioned(
                left: _posicionX,
                top: 25,
                child: const Icon(Icons.directions_car, size: 40, color: Colors.indigo),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: _iniciarSimulacion, child: const Text("Play")),
            ElevatedButton(onPressed: _detenerSimulacion, child: const Text("Stop")),
          ],
        )
      ],
    );
  }
}