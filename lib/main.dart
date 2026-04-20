import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laboratorio de Física',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const MenuPrincipal(),
    );
  }
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  final List<String> modulos = const [
    'Cinemática', 'Leyes de Newton', 'Energía y Trabajo',
    'Óptica', 'Electromagnetismo', 'Termodinámica',
    'Movimiento Circular', 'Estática', 'Acústica', 'Física Moderna'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laboratorio Virtual'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: modulos.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.science, color: Colors.indigo.shade400),
              title: Text(modulos[index]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalleModulo(titulo: modulos[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DetalleModulo extends StatelessWidget {
  final String titulo;
  const DetalleModulo({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Las 3 secciones: Introducción, Funciones, Cuestionario
      child: Scaffold(
        appBar: AppBar(
          title: Text(titulo),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: 'Introducción'),
              Tab(icon: Icon(Icons.calculate_outlined), text: 'Funciones'),
              Tab(icon: Icon(Icons.quiz_outlined), text: 'Cuestionario'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildIntroduccion(),
            _buildFunciones(),
            _buildCuestionario(),
          ],
        ),
      ),
    );
  }

  // Sección 1: Introducción
  Widget _buildIntroduccion() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Conceptos Teóricos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Text('Aquí se escribe la teoría de $titulo.',
              style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Sección 2: Implementación de Funciones (Simulación)
  Widget _buildFunciones() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.precision_manufacturing, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text('Área de Simulación de $titulo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const Text('Aquí se pueden mostrar las ecuaciones.'),
        ],
      ),
    );
  }

  // Sección 3: Cuestionario
  Widget _buildCuestionario() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Evaluación de Aprendizaje', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            title: Text('Pregunta 1: ...?'),
            subtitle: Text('Toca para seleccionar respuesta'),
          ),
        ),
      ],
    );
  }
}