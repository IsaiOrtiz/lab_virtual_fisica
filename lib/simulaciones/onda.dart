import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';

class Objeto3DSim extends StatefulWidget {
  const Objeto3DSim({super.key});

  @override
  State<Objeto3DSim> createState() => _Objeto3DSimState();
}

class _Objeto3DSimState extends State<Objeto3DSim> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Text(
            "Manipulación de Sólido 3D",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black, // Fondo oscuro para resaltar el objeto
              borderRadius: BorderRadius.circular(20),
            ),
            child: Cube(
              onSceneCreated: (Scene scene) {
                // En lugar de cargar un archivo, creamos un objeto vacío
                // y le asignamos una forma predefinida si es posible, 
                // o cargamos un objeto simple desde una URL para probar.
                final objetoPrueba = Object(
                  name: 'cubo',
                  scale: Vector3(5.0, 5.0, 5.0),
                  // Usaremos un modelo de muestra de la librería para asegurar que cargue
                  fileName: 'assets/cube.obj', 
                );
                
                scene.world.add(objetoPrueba);
                
                // Ajustar la luz para que el objeto no se vea negro
                scene.light.position.setFrom(Vector3(0, 10, 10));
              },
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(15.0),
          child: Text(
            "Arrastra para rotar. Si sigue vacío, verifica el pubspec.yaml",
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ),
      ],
    );
  }
}