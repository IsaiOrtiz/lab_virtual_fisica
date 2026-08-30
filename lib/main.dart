import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E), // Indigo profundo académico
          brightness: Brightness.light,
          background: const Color(0xFFF8F9FA),
        ),
      ),
      home: const MenuPrincipal(),
    );
  }
}

class ModuloData {
  final String titulo;
  final String archivoTeoria;
  // En lugar de un Widget fijo, usamos una función "constructora" que
  // recibe los callbacks para saltar a la pestaña de Teoría o de
  // Cuestionario, y devuelve el widget de simulación ya configurado.
  final Widget Function(VoidCallback irATeoria, VoidCallback irACuestionario) construirSimulacion;
  final String categoria;

  ModuloData({
    required this.titulo,
    required this.archivoTeoria,
    required this.construirSimulacion,
    required this.categoria,
  });
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    // Forzar vertical en el menú principal por seguridad
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final List<ModuloData> listaModulos = [
      ModuloData(
        titulo: 'Ondas Viajeras',
        archivoTeoria: 'assets/teoria/ondas_viajeras.txt',
        construirSimulacion: (irATeoria, irACuestionario) => OndaViajeraSim(onIrATeoria: irATeoria, onIrACuestionario: irACuestionario),
        categoria: 'Acústica y Ondas',
      ),
      ModuloData(
        titulo: 'Interferencia de Ondas',
        archivoTeoria: 'assets/teoria/interferencia.txt',
        construirSimulacion: (irATeoria, irACuestionario) => InterferenciaSim(onIrATeoria: irATeoria, onIrACuestionario: irACuestionario),
        categoria: 'Acústica y Ondas',
      ),
      ModuloData(
        titulo: 'Ondas Estacionarias',
        archivoTeoria: 'assets/teoria/estacionarias.txt',
        construirSimulacion: (irATeoria, irACuestionario) => OndasEstacionariasSim(onIrATeoria: irATeoria, onIrACuestionario: irACuestionario),
        categoria: 'Acústica y Ondas',
      ),
      ModuloData(
        titulo: 'Ondas Longitudinales',
        archivoTeoria: 'assets/teoria/longitudinales.txt',
        construirSimulacion: (irATeoria, irACuestionario) => OndasLongitudinalesSim(onIrATeoria: irATeoria, onIrACuestionario: irACuestionario),
        categoria: 'Acústica y Ondas',
      ),
      ModuloData(
        titulo: 'Modos Normales',
        archivoTeoria: 'assets/teoria/modos_normales.txt',
        construirSimulacion: (irATeoria, irACuestionario) => ModosNormalesSim(onIrATeoria: irATeoria, onIrACuestionario: irACuestionario),
        categoria: 'Acústica y Ondas',
      ),
      ModuloData(
        titulo: 'Reflexión de la Luz',
        archivoTeoria: 'assets/teoria/reflexion.txt',
        construirSimulacion: (irATeoria, irACuestionario) => const Placeholder(),
        categoria: 'Óptica',
      ),
      ModuloData(
        titulo: 'Refracción de la Luz',
        archivoTeoria: 'assets/teoria/refraccion.txt',
        construirSimulacion: (irATeoria, irACuestionario) => const Placeholder(),
        categoria: 'Óptica',
      ),
      ModuloData(
        titulo: 'Espejos Curvos',
        archivoTeoria: 'assets/teoria/espejos.txt',
        construirSimulacion: (irATeoria, irACuestionario) => const Placeholder(),
        categoria: 'Óptica',
      ),
      ModuloData(
        titulo: 'Lentes Delgadas',
        archivoTeoria: 'assets/teoria/lentes.txt',
        construirSimulacion: (irATeoria, irACuestionario) => const Placeholder(),
        categoria: 'Óptica',
      ),
      ModuloData(
        titulo: 'Principio de Bernoulli',
        archivoTeoria: 'assets/teoria/bernoulli.txt',
        construirSimulacion: (irATeoria, irACuestionario) => const Placeholder(),
        categoria: 'Fluidos',
      ),
      ModuloData(
        titulo: 'Conservación del Gasto',
        archivoTeoria: 'assets/teoria/gasto.txt',
        construirSimulacion: (irATeoria, irACuestionario) => const Placeholder(),
        categoria: 'Fluidos',
      ),
      ModuloData(
        titulo: 'Conservación de la Energía',
        archivoTeoria: 'assets/teoria/energia.txt',
        construirSimulacion: (irATeoria, irACuestionario) => const Placeholder(),
        categoria: 'Fluidos',
      ),
      ModuloData(
        titulo: 'Ecuación de Poiseuille',
        archivoTeoria: 'assets/teoria/poiseuille.txt',
        construirSimulacion: (irATeoria, irACuestionario) => const Placeholder(),
        categoria: 'Fluidos',
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Header moderno colapsable
          SliverAppBar.large(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Laboratorio Virtual',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A237E),
                  fontSize: 22,
                ),
              ),
            ),
          ),
          // Listado de tarjetas de ingeniería
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final modulo = listaModulos[index];
                  final colorCategoria = _obtenerColorCategoria(modulo.categoria);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DetalleModulo(modulo: modulo)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Indicador numérico estilizado
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorCategoria.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.bold,
                                      color: colorCategoria,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Textos principales
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      modulo.titulo,
                                      style: GoogleFonts.lato(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: const Color(0xFF212121),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: colorCategoria.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        modulo.categoria.toUpperCase(),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: colorCategoria,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black26, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: listaModulos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _obtenerColorCategoria(String cat) {
    switch (cat) {
      case 'Acústica y Ondas': return const Color(0xFF0288D1); // Azul
      case 'Óptica': return const Color(0xFFE65100); // Naranja quemado
      case 'Fluidos': return const Color(0xFF00897B); // Esmeralda / Teal
      default: return Colors.indigo;
    }
  }
}

class DetalleModulo extends StatefulWidget {
  final ModuloData modulo;
  const DetalleModulo({super.key, required this.modulo});
  @override
  State<DetalleModulo> createState() => _DetalleModuloState();
}

class _DetalleModuloState extends State<DetalleModulo> with SingleTickerProviderStateMixin {
  String contenidoTeoria = "Cargando teoría...";
  late TabController _tabController;
  int _indiceActual = 0;

  // Índice de la pestaña de Simulación dentro del TabBar (Teoría=0, Simulación=1, Test=2)
  static const int _indiceSimulacion = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Solo reaccionamos cuando el índice realmente cambió, para evitar
      // reconstrucciones innecesarias durante el arrastre del TabBar.
      if (_tabController.index != _indiceActual) {
        setState(() => _indiceActual = _tabController.index);
      }
    });
    _cargarTexto();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTexto() async {
    try {
      final texto = await rootBundle.loadString(widget.modulo.archivoTeoria);
      setState(() => contenidoTeoria = texto);
    } catch (e) {
      setState(() => contenidoTeoria = "# Próximamente\nContenido de **${widget.modulo.titulo}** en desarrollo.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enSimulacion = _indiceActual == _indiceSimulacion;

    return Scaffold(
      // Cuando se entra a la Simulación se oculta el AppBar completo
      // (título + las 3 pestañas de Teoría / Simulación / Test) para que
      // la simulación use toda la pantalla en horizontal.
      appBar: enSimulacion
          ? null
          : AppBar(
              title: Text(widget.modulo.titulo, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 18)),
              bottom: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1A237E),
                unselectedLabelColor: Colors.black45,
                indicatorColor: const Color(0xFF1A237E),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [Tab(text: 'Teoría'), Tab(text: 'Simulación'), Tab(text: 'Test')],
              ),
            ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Evita conflictos de arrastre con los sliders del simulador
        children: [
          _buildTeoriaView(),
          // Construimos la simulación pasándole funciones que le permiten
          // saltar directamente a la pestaña de Teoría (índice 0) o de
          // Cuestionario (índice 2) desde un botón dentro de la propia
          // simulación, sin necesidad de mostrar la barra de pestañas.
          widget.modulo.construirSimulacion(
            () => _tabController.animateTo(0),
            () => _tabController.animateTo(2),
          ),
          const Center(child: Text("Cuestionario disponible próximamente")),
        ],
      ),
    );
  }

  Widget _buildTeoriaView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MarkdownBody(
        data: contenidoTeoria,
        imageDirectory: 'assets/imagenes',
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.lato(fontSize: 16, height: 1.6, color: const Color(0xFF333333)),
          h1: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E), height: 1.8),
          h2: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0288D1), height: 1.6),
          code: GoogleFonts.sourceCodePro(backgroundColor: Colors.grey.shade100, fontSize: 14, color: Colors.red.shade900),
        ),
        onTapLink: (text, href, title) {
          if (href != null) _abrirEnlace(href);
        },
      ),
    );
  }

  Future<void> _abrirEnlace(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) debugPrint('Error al abrir $url');
  }
}