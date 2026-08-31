import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'generador_pdf.dart';
import 'modelo_pregunta.dart';

/// Pantalla de cuestionario para un módulo: muestra las preguntas de
/// opción múltiple, permite calificarlas y genera un PDF que combina el
/// resultado con las capturas de pantalla tomadas en la simulación.
class CuestionarioScreen extends StatefulWidget {
  final String tituloModulo;
  final List<PreguntaCuestionario> preguntas;
  final List<Uint8List> capturas;

  const CuestionarioScreen({
    super.key,
    required this.tituloModulo,
    required this.preguntas,
    required this.capturas,
  });

  @override
  State<CuestionarioScreen> createState() => _CuestionarioScreenState();
}

class _CuestionarioScreenState extends State<CuestionarioScreen> {
  final Map<int, int?> _respuestas = {};
  bool _enviado = false;
  bool _generandoPdf = false;

  int get _totalPreguntas => widget.preguntas.length;

  int get _correctas {
    int c = 0;
    for (int i = 0; i < widget.preguntas.length; i++) {
      if (_respuestas[i] == widget.preguntas[i].indiceCorrecta) c++;
    }
    return c;
  }

  double get _porcentaje => _totalPreguntas == 0 ? 0 : (_correctas / _totalPreguntas) * 100;

  bool get _todasContestadas =>
      widget.preguntas.isNotEmpty && widget.preguntas.asMap().keys.every((i) => _respuestas[i] != null);

  Future<void> _generarPdf() async {
    setState(() => _generandoPdf = true);
    try {
      await GeneradorReportePdf.generarYCompartir(
        tituloModulo: widget.tituloModulo,
        preguntas: widget.preguntas,
        respuestas: _respuestas,
        capturas: widget.capturas,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

  void _reintentar() {
    setState(() {
      _respuestas.clear();
      _enviado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preguntas.isEmpty) {
      return _buildSinPreguntas();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            itemCount: widget.preguntas.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildEncabezado();
              return _buildPregunta(index - 1, widget.preguntas[index - 1]);
            },
          ),
        ),
        _buildBarraInferior(),
      ],
    );
  }

  Widget _buildSinPreguntas() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.quiz_outlined, size: 48, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              'Preguntas pendientes de configurar',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Este módulo todavía no tiene preguntas cargadas. Mientras tanto, puedes generar un PDF con las capturas que hayas tomado en la simulación.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: widget.capturas.isEmpty || _generandoPdf ? null : _generarPdf,
              icon: _generandoPdf
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(widget.capturas.isEmpty ? 'No hay capturas todavía' : 'Generar PDF con capturas'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezado() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuestionario',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF1A237E)),
          ),
          const SizedBox(height: 4),
          Text(
            widget.capturas.isEmpty
                ? 'Aún no has tomado capturas en la simulación. Puedes volver y usar el botón de cámara antes de generar tu PDF.'
                : '${widget.capturas.length} captura(s) de la simulación se incluirán en tu PDF.',
            style: GoogleFonts.lato(fontSize: 12, color: Colors.black54),
          ),
          if (_enviado) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Obtuviste $_correctas de $_totalPreguntas correctas (${_porcentaje.toStringAsFixed(0)}%).',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPregunta(int indice, PreguntaCuestionario p) {
    final int? seleccion = _respuestas[indice];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${indice + 1}. ${p.enunciado}', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...List.generate(p.opciones.length, (i) {
            final bool esCorrecta = i == p.indiceCorrecta;
            final bool esElegida = i == seleccion;
            Color? colorFondo;
            if (_enviado) {
              if (esCorrecta) {
                colorFondo = Colors.green.withOpacity(0.08);
              } else if (esElegida) {
                colorFondo = Colors.red.withOpacity(0.08);
              }
            }
            return Container(
              decoration: BoxDecoration(color: colorFondo, borderRadius: BorderRadius.circular(8)),
              child: RadioListTile<int>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: i,
                groupValue: seleccion,
                onChanged: _enviado ? null : (v) => setState(() => _respuestas[indice] = v),
                title: Text(p.opciones[i], style: GoogleFonts.lato(fontSize: 13)),
                secondary: !_enviado
                    ? null
                    : (esCorrecta
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                        : (esElegida ? const Icon(Icons.cancel, color: Colors.red, size: 18) : null)),
              ),
            );
          }),
          if (_enviado && p.explicacion != null) ...[
            const SizedBox(height: 4),
            Text(p.explicacion!, style: GoogleFonts.lato(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
          ],
        ],
      ),
    );
  }

  Widget _buildBarraInferior() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!_enviado)
              Expanded(
                child: FilledButton(
                  onPressed: _todasContestadas ? () => setState(() => _enviado = true) : null,
                  child: const Text('Enviar respuestas'),
                ),
              )
            else ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reintentar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _generandoPdf ? null : _generarPdf,
                  icon: _generandoPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: const Text('Generar PDF'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}