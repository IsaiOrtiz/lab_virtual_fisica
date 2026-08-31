import 'modelo_pregunta.dart';

/// Banco de preguntas de todos los módulos, organizado por el TÍTULO
/// exacto del módulo (el mismo `titulo` que usas en `ModuloData` dentro
/// de `main.dart`).
///
/// CÓMO AGREGAR PREGUNTAS
/// -----------------------
/// Agrega una entrada al mapa con el título del módulo como llave y una
/// lista de [PreguntaCuestionario] como valor. Ejemplo:
///
/// ```dart
/// 'Ondas Viajeras': [
///   PreguntaCuestionario(
///     enunciado: '¿Qué representa la variable k en y = A·sin(kx - ωt)?',
///     opciones: [
///       'El número de onda (2π/λ)',
///       'La frecuencia angular',
///       'La amplitud máxima',
///       'La fase inicial',
///     ],
///     indiceCorrecta: 0,
///     explicacion: 'k = 2π/λ describe cuántos radianes de fase hay '
///         'por unidad de longitud a lo largo de la onda.',
///   ),
///   // ... más preguntas
/// ],
/// ```
///
/// Si un módulo no tiene una entrada aquí (o su lista está vacía), la
/// pantalla de Cuestionario usa automáticamente [preguntasPlaceholder]
/// como contenido de ejemplo, para que la app nunca se vea vacía
/// mientras se van redactando las preguntas reales.
final Map<String, List<PreguntaCuestionario>> bancoPreguntas = {
  'Ondas Viajeras': [],
  'Interferencia de Ondas': [],
  'Ondas Estacionarias': [],
  'Ondas Longitudinales': [],
  'Modos Normales': [],
  'Modos Normales: Fronteras Mixtas y Libres': [],
  'Reflexión de la Luz': [],
  'Refracción de la Luz': [],
  'Espejos Curvos': [],
  'Lentes Delgadas': [],
  'Principio de Bernoulli': [],
  'Conservación del Gasto': [],
  'Conservación de la Energía': [],
  'Ecuación de Poiseuille': [],
};

/// Preguntas de ejemplo genéricas que se muestran para cualquier módulo
/// cuya lista en [bancoPreguntas] todavía esté vacía. Reemplázalas por
/// las preguntas reales de cada módulo cuando estén listas; una vez que
/// agregues preguntas propias a un módulo en [bancoPreguntas], estas de
/// aquí dejan de usarse para ese módulo.
const List<PreguntaCuestionario> preguntasPlaceholder = [
  PreguntaCuestionario(
    enunciado: '(Ejemplo) Esta es una pregunta de muestra. Reemplázala en banco_preguntas.dart.',
    opciones: ['Opción A', 'Opción B', 'Opción C', 'Opción D'],
    indiceCorrecta: 0,
    explicacion: 'Este texto explicativo también es de ejemplo.',
  ),
  PreguntaCuestionario(
    enunciado: '(Ejemplo) Segunda pregunta de muestra.',
    opciones: ['Verdadero', 'Falso'],
    indiceCorrecta: 1,
  ),
];

/// Devuelve las preguntas de un módulo por su título, o
/// [preguntasPlaceholder] si ese módulo aún no tiene preguntas propias.
List<PreguntaCuestionario> preguntasDeModulo(String tituloModulo) {
  final propias = bancoPreguntas[tituloModulo];
  if (propias == null || propias.isEmpty) return preguntasPlaceholder;
  return propias;
}