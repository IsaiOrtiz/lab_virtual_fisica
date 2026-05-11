import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart'; // Requiere: flutter pub add flutter_markdown
import 'package:url_launcher/url_launcher.dart'; // Opcional para abrir links externos
import 'package:google_fonts/google_fonts.dart';

// IMPORTS DE TODAS LAS SIMULACIONES
import 'simulaciones/refraccion.dart';
import 'simulaciones/estacionaria.dart';
import 'simulaciones/espejo_curvo.dart';
import 'simulaciones/longitudinales.dart';
import 'simulaciones/lente_delg.dart';
import 'simulaciones/bernoulli.dart';
import 'simulaciones/interferencia.dart';
import 'simulaciones/modo_normal.dart';
import 'simulaciones/onda.dart';
import 'simulaciones/reflexion.dart';
import 'simulaciones/poiseuille.dart';
import 'simulaciones/conservacion_energia.dart';
import 'simulaciones/conservacion_gasto.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const MenuPrincipal(),
    );
  }
}

class ModuloData {
  final String titulo;
  final String archivoTeoria;
  final Widget scriptSimulacion;
  final Color color;

  ModuloData({
    required this.titulo,
    required this.archivoTeoria,
    required this.scriptSimulacion,
    this.color = Colors.indigo,
  });
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {

    final List<ModuloData> listaModulos = [
      ModuloData(titulo: 'Ondas Viajeras', archivoTeoria: 'assets/teoria/ondas_viajeras.txt', scriptSimulacion: const Objeto3DSim()),
      ModuloData(titulo: 'Interferencia de Ondas', archivoTeoria: 'assets/teoria/interferencia.txt', scriptSimulacion: const InterferenciaSim()),
      ModuloData(titulo: 'Ondas Estacionarias', archivoTeoria: 'assets/teoria/estacionarias.txt', scriptSimulacion: const Placeholder()),
      ModuloData(titulo: 'Ondas Longitudinales', archivoTeoria: 'assets/teoria/longitudinales.txt', scriptSimulacion: const Placeholder()),
      ModuloData(titulo: 'Modos Normales', archivoTeoria: 'assets/teoria/modos_normales.txt', scriptSimulacion: const Placeholder()),
      ModuloData(titulo: 'Reflexión de la Luz', archivoTeoria: 'assets/teoria/reflexion.txt', scriptSimulacion: const Placeholder()),
      ModuloData(titulo: 'Refracción de la Luz', archivoTeoria: 'assets/teoria/refraccion.txt', scriptSimulacion: const Placeholder()),
      ModuloData(titulo: 'Espejos Curvos', archivoTeoria: 'assets/teoria/espejos.txt', scriptSimulacion: const Placeholder()),
      ModuloData(titulo: 'Lentes Delgadas', archivoTeoria: 'assets/teoria/lentes.txt', scriptSimulacion: const Placeholder()),
      ModuloData(titulo: 'Principio de Bernoulli', archivoTeoria: 'assets/teoria/bernoulli.txt', scriptSimulacion: const Placeholder()),
      ModuloData(titulo: 'Conservación del Gasto', archivoTeoria: 'assets/teoria/gasto.txt', scriptSimulacion: const Placeholder()),
      ModuloData(titulo: 'Conservación de la Energía', archivoTeoria: 'assets/teoria/energia.txt', scriptSimulacion: const Placeholder()),
      ModuloData(titulo: 'Ecuación de Poiseuille', archivoTeoria: 'assets/teoria/poiseuille.txt', scriptSimulacion: const Placeholder()),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Laboratorio Virtual', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: listaModulos.length,
        itemBuilder: (context, index) {
          final modulo = listaModulos[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              // Muestra el número del tema en lugar de un icono
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.withOpacity(0.1),
                child: Text("${index + 1}", style: const TextStyle(color: Colors.indigo)),
              ),
              title: Text(modulo.titulo, style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 17)),
              subtitle: const Text('Teoría y Simulador'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetalleModulo(modulo: modulo)),
              ),
            ),
                      );
        },
      ),
    );
  }
}

class DetalleModulo extends StatefulWidget {
  final ModuloData modulo;
  const DetalleModulo({super.key, required this.modulo});
  @override
  State<DetalleModulo> createState() => _DetalleModuloState();
}

class _DetalleModuloState extends State<DetalleModulo> {
  String contenidoTeoria = "Cargando teoría...";

  @override
  void initState() {
    super.initState();
    _cargarTexto();
  }

  Future<void> _cargarTexto() async {
    try {
      final texto = await rootBundle.loadString(widget.modulo.archivoTeoria);
      setState(() => contenidoTeoria = texto);
    } catch (e) {
      setState(() => contenidoTeoria = "# Próximamente\nContenido de **${widget.modulo.titulo}** en construcción.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.modulo.titulo),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Teoría'), Tab(text: 'Simulación'), Tab(text: 'Test')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTeoriaView(),
            Padding(padding: const EdgeInsets.all(16), child: widget.modulo.scriptSimulacion),
            const Center(child: Text("Cuestionario no disponible")),
          ],
        ),
      ),
    );
  }

  Widget _buildTeoriaView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: MarkdownBody(
        data: contenidoTeoria,
        imageDirectory: 'assets/imagenes',
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.lato(fontSize: 16, height: 1.5, color: Colors.black87),
          h1: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
          code: GoogleFonts.sourceCodePro(backgroundColor: Colors.grey.shade200, fontSize: 14, color: Colors.red.shade900),
        ),
        onTapLink: (text, href, title) {
          if (href != null) _abrirEnlace(href);
        },
      ),
    );
  }

  Future<void> _abrirEnlace(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) debugPrint('No se pudo abrir $url');
  }
}