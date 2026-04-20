import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laboratorio de Física',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const MenuPrincipal(),
    );
  }
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  // Lista de los 10 módulos
  final List<String> modulos = const [
    'Cinemática', 'Leyes de Newton', 'Energía y Trabajo',
    'Óptica', 'Electromagnetismo', 'Termodinámica',
    'Movimiento Circular', 'Estática', 'Acústica', 'Física Moderna'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio Virtual de Física'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: modulos.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(modulos[index]),
              subtitle: const Text('Simulación interactiva'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Aquí navegarás a cada módulo después
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Abriendo ${modulos[index]}...')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laboratorio de Física',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const MenuPrincipal(),
    );
  }
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  // Lista de los 10 módulos
  final List<String> modulos = const [
    'Cinemática', 'Leyes de Newton', 'Energía y Trabajo',
    'Óptica', 'Electromagnetismo', 'Termodinámica',
    'Movimiento Circular', 'Estática', 'Acústica', 'Física Moderna'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio Virtual de Física'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: modulos.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(modulos[index]),
              subtitle: const Text('Simulación interactiva'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Aquí navegarás a cada módulo después
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Abriendo ${modulos[index]}...')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}