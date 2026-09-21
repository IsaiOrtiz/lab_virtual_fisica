import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'modelo_captura.dart';
import 'modelo_pregunta.dart';

/// Genera un PDF por módulo con:
///  1. Una página por cada captura de pantalla que el usuario tomó en la
///     simulación de ese módulo (con su interpretación, si escribió una).
///  2. El resultado del cuestionario (puntaje + cada pregunta con la
///     respuesta elegida, la correcta y su explicación).
///
/// Las capturas van primero porque son el registro de lo que el
/// estudiante observó durante la simulación; el cuestionario, que
/// evalúa esa observación, se presenta después.
///
/// Usa la fuente Noto Sans embebida en assets/fonts para que los acentos
/// y la "ñ" se vean correctamente (las fuentes base de la librería `pdf`
/// no cubren bien el alfabeto latino extendido).
class GeneradorReportePdf {
  static pw.Font? _fuenteRegular;
  static pw.Font? _fuenteBold;

  static Future<void> _asegurarFuentes() async {
    _fuenteRegular ??= await fontFromAssetBundle('assets/fonts/NotoSans-Regular.ttf');
    _fuenteBold ??= await fontFromAssetBundle('assets/fonts/NotoSans-Bold.ttf');
  }

  /// Construye el PDF y abre el diálogo nativo de compartir/guardar
  /// (funciona igual en Android, iOS, Web, Windows, macOS y Linux).
  static Future<void> generarYCompartir({
    required String tituloModulo,
    required List<PreguntaCuestionario> preguntas,
    required Map<int, int?> respuestas,
    required List<CapturaSimulacion> capturas,
  }) async {
    final bytes = await _construirBytes(
      tituloModulo: tituloModulo,
      preguntas: preguntas,
      respuestas: respuestas,
      capturas: capturas,
    );
    final nombreArchivo = 'reporte_${_sanitizar(tituloModulo)}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
  }

  static Future<Uint8List> _construirBytes({
    required String tituloModulo,
    required List<PreguntaCuestionario> preguntas,
    required Map<int, int?> respuestas,
    required List<CapturaSimulacion> capturas,
  }) async {
    await _asegurarFuentes();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: _fuenteRegular!, bold: _fuenteBold!),
    );

    final int total = preguntas.length;
    int correctas = 0;
    for (int i = 0; i < preguntas.length; i++) {
      if (respuestas[i] == preguntas[i].indiceCorrecta) correctas++;
    }
    final double porcentaje = total == 0 ? 0 : (correctas / total) * 100;

    final ahora = DateTime.now();
    final String fechaTexto =
        "${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year} "
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    // --- 1) Una página por cada captura, a tamaño grande, con su
    //        interpretación (si el usuario escribió una) debajo de la
    //        imagen. El encabezado del reporte (título del módulo y
    //        fecha) se muestra solo una vez, en la primera captura.
    for (int i = 0; i < capturas.length; i++) {
      final captura = capturas[i];
      final imagen = pw.MemoryImage(captura.bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          // pw.Page no tiene parámetros header/footer (esos solo existen
          // en pw.MultiPage), así que los incorporamos como parte del
          // propio contenido de la página.
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (i == 0) _encabezado(tituloModulo, fechaTexto),
              pw.Text('Captura ${i + 1} de ${capturas.length} — $tituloModulo', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              pw.SizedBox(height: 8),
              pw.Expanded(child: pw.Center(child: pw.Image(imagen, fit: pw.BoxFit.contain))),
              if (captura.nota.trim().isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Interpretación del estudiante:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text(captura.nota.trim(), style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // --- 2) Resultado del cuestionario. Si no hubo capturas, esta
    //        sección es la primera del documento y muestra el
    //        encabezado; si ya hubo capturas antes, el encabezado no se
    //        repite (context.pageNumber solo vale 1 cuando esta es la
    //        primera página de todo el documento).
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => capturas.isEmpty && context.pageNumber == 1 ? _encabezado(tituloModulo, fechaTexto) : pw.SizedBox(),
        footer: (context) => _pie(context),
        build: (context) => [
          if (capturas.isNotEmpty) ...[
            pw.Text(
              'Cuestionario — $tituloModulo',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Las ${capturas.length} captura(s) de la simulación se muestran en las páginas anteriores de este reporte.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 12),
          ],
          if (total > 0) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.indigo50, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Resultado del cuestionario', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    '$correctas / $total   (${porcentaje.toStringAsFixed(0)}%)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            for (int i = 0; i < preguntas.length; i++) _bloquePregunta(i, preguntas[i], respuestas[i]),
          ] else
            pw.Text('Este módulo todavía no tiene preguntas configuradas.', style: const pw.TextStyle(color: PdfColors.grey700)),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _encabezado(String tituloModulo, String fechaTexto) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Laboratorio Virtual de Física', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(tituloModulo, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Generado el $fechaTexto', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
        ],
      );

  static pw.Widget _pie(pw.Context context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      );

  static pw.Widget _bloquePregunta(int indice, PreguntaCuestionario p, int? elegida) {
    final bool contestada = elegida != null;
    final bool correcta = elegida == p.indiceCorrecta;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('${indice + 1}. ${p.enunciado}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            contestada ? 'Tu respuesta: ${p.opciones[elegida]}' : 'Sin responder',
            style: pw.TextStyle(color: contestada ? (correcta ? PdfColors.green800 : PdfColors.red800) : PdfColors.grey600),
          ),
          if (!correcta)
            pw.Text('Respuesta correcta: ${p.opciones[p.indiceCorrecta]}', style: const pw.TextStyle(color: PdfColors.green800)),
          if (p.explicacion != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(p.explicacion!, style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
          ],
        ],
      ),
    );
  }

  static String _sanitizar(String s) {
    final base = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    return base.isEmpty ? 'modulo' : base;
  }
}