import 'package:flutter/material.dart';

/// Pequeño panel flotante que se muestra DENTRO de una simulación y
/// permite saltar directamente a la pestaña de "Teoría" o de
/// "Cuestionario", sin tener que salir de la simulación (la barra de
/// pestañas está oculta mientras se simula).
class BotonesNavegacionTabs extends StatelessWidget {
  final VoidCallback? onIrATeoria;
  final VoidCallback? onIrACuestionario;

  const BotonesNavegacionTabs({
    super.key,
    this.onIrATeoria,
    this.onIrACuestionario,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _boton(Icons.menu_book_rounded, "Ir a Teoría", onIrATeoria),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Divider(height: 1, color: Colors.white24),
          ),
          _boton(Icons.quiz_rounded, "Ir a Cuestionario", onIrACuestionario),
        ],
      ),
    );
  }

  Widget _boton(IconData icon, String tooltip, VoidCallback? onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
