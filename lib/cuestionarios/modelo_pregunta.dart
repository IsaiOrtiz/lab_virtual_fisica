/// Una pregunta de opción múltiple para el cuestionario de un módulo.
///
/// [opciones] debe tener al menos 2 elementos y [indiceCorrecta] debe ser
/// un índice válido dentro de esa lista (0-based).
class PreguntaCuestionario {
  final String enunciado;
  final List<String> opciones;
  final int indiceCorrecta;

  /// Texto opcional que se muestra tras responder, explicando por qué la
  /// respuesta correcta lo es. Útil como refuerzo teórico.
  final String? explicacion;

  const PreguntaCuestionario({
    required this.enunciado,
    required this.opciones,
    required this.indiceCorrecta,
    this.explicacion,
  });
}