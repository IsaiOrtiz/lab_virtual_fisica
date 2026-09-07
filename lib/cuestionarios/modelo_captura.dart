import 'dart:typed_data';

/// Una captura de pantalla de una simulación, junto con la interpretación
/// en texto que el usuario escribió sobre lo que observó. Ambas cosas
/// viajan juntas hasta el PDF del cuestionario.
class CapturaSimulacion {
  final Uint8List bytes;
  final String nota;

  const CapturaSimulacion({required this.bytes, required this.nota});
}