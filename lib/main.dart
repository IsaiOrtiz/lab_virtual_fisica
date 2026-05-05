import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart'; // Requiere: flutter pub add flutter_markdown
import 'package:url_launcher/url_launcher.dart'; // Opcional para abrir links externos
import 'package:google_fonts/google_fonts.dart';

// IMPORTS DE TODAS LAS SIMULACIONES
import 'simulaciones/mru_simulador.dart';
import 'simulaciones/electro_simulador.dart';
import 'simulaciones/newton_sim.dart';
import 'simulaciones/energia_sim.dart';
import 'simulaciones/optica_sim.dart';
import 'simulaciones/termo_sim.dart';
import 'simulaciones/circular_sim.dart';
import 'simulaciones/estatica_sim.dart';
import 'simulaciones/acustica_sim.dart';
import 'simulaciones/moderna_sim.dart';

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
        // Configuración para que el texto Markdown se vea bien
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16)),
      ),
      home: const MenuPrincipal(),
    );
  }
}

class ModuloData {
  final String titulo;
  final String archivoTeoria;
  final Widget scriptSimulacion;
  final String? youtubeId; // Nuevo campo para videos de YouTube

  ModuloData({
    required this.titulo, 
    required this.archivoTeoria, 
    required this.scriptSimulacion,
    this.youtubeId,
  });
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ModuloData> listaModulos = [
      ModuloData(
        titulo: '1. Cinemática', 
        archivoTeoria: 'assets/teoria/cinematica.txt', 
        scriptSimulacion: const MRUSimulador(),
        youtubeId: 'Wp_P9EsqY_A', // Ejemplo: ID de video de cinemática
      ),
      ModuloData(titulo: '2. Leyes de Newton', archivoTeoria: 'assets/teoria/newton.txt', scriptSimulacion: const NewtonSim()),
      ModuloData(titulo: '3. Energía y Trabajo', archivoTeoria: 'assets/teoria/energia.txt', scriptSimulacion: const EnergiaSim()),
      ModuloData(titulo: '4. Óptica', archivoTeoria: 'assets/teoria/optica.txt', scriptSimulacion: const OpticaSim()),
      ModuloData(titulo: '5. Electromagnetismo', archivoTeoria: 'assets/teoria/electromagnetismo.txt', scriptSimulacion: const ElectroSimulador()),
      ModuloData(titulo: '6. Termodinámica', archivoTeoria: 'assets/teoria/termo.txt', scriptSimulacion: const TermoSim()),
      ModuloData(titulo: '7. Movimiento Circular', archivoTeoria: 'assets/teoria/circular.txt', scriptSimulacion: const CircularSim()),
      ModuloData(titulo: '8. Estática', archivoTeoria: 'assets/teoria/estatica.txt', scriptSimulacion: const EstaticaSim()),
      ModuloData(titulo: '9. Acústica', archivoTeoria: 'assets/teoria/acustica.txt', scriptSimulacion: const AcusticaSim()),
      ModuloData(titulo: '10. Física Moderna', archivoTeoria: 'assets/teoria/moderna.txt', scriptSimulacion: const ModernaSim()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Laboratorio Virtual'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listaModulos.length,
        itemBuilder: (context, index) {
          final modulo = listaModulos[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text("${index + 1}")),
              title: Text(modulo.titulo),
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => DetalleModulo(modulo: modulo))
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
      setState(() => contenidoTeoria = "# Próximamente\nContenido de ${widget.modulo.titulo} en construcción.");
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
            tabs: [Tab(text: 'Teoría'), Tab(text: 'Simulación'), Tab(text: 'Test')],
          ),
        ),
        body: TabBarView(
          children: [
            // PARTE 1: TEORÍA CON FORMATO
            _buildTeoriaView(),
            // PARTE 2: SIMULACIÓN
            Padding(padding: const EdgeInsets.all(16), child: widget.modulo.scriptSimulacion),
            // PARTE 3: TEST
            const Center(child: Text("Cuestionario no disponible")),
          ],
        ),
      ),
    );
  }

  Widget _buildTeoriaView() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: contenidoTeoria,
          imageDirectory: 'assets/imagenes',
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.lato(
              fontSize: 16, 
              height: 1.5, 
              color: Colors.black87,
            ),
            h1: GoogleFonts.montserrat(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: Colors.indigo,
            ),
            code: GoogleFonts.sourceCodePro(
              backgroundColor: Colors.grey.shade200,
              fontSize: 14,
              color: Colors.red.shade900,
            ),
          ),
          onTapLink: (text, href, title) {
            if (href != null) _abrirEnlace(href);
          },
        ),
        ]// ... aquí iría el botón de YouTube 
    ),
  );
  
}

// Función auxiliar para abrir los links del Markdown
Future<void> _abrirEnlace(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri)) {
    debugPrint('No se pudo abrir $url');
  }
}
}