# Laboratorio Virtual de Física

![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white)
![Versión](https://img.shields.io/badge/versi%C3%B3n-1.0.0-blue)
![Licencia](https://img.shields.io/badge/licencia-MIT-green)
![Plataforma](https://img.shields.io/badge/Android-APK-3DDC84?logo=android&logoColor=white)

Aplicación educativa hecha con Flutter que reúne **14 simulaciones interactivas de física**, con teoría y cuestionarios por cada módulo. Está pensada para que el estudiante manipule los parámetros de un experimento, observe el resultado y refuerce lo aprendido sin necesidad de un laboratorio físico.

<!-- Agrega aquí capturas de pantalla o un GIF de la app:
![Menú principal](docs/img/menu.png)
-->

## Contenido

- [Características](#características)
- [Módulos](#módulos)
- [Descarga](#descarga)
- [Ejecutar desde el código fuente](#ejecutar-desde-el-código-fuente)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Tecnologías](#tecnologías)
- [Cómo agregar contenido](#cómo-agregar-contenido)
- [Hoja de ruta](#hoja-de-ruta)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

## Características

- Simulaciones interactivas con zoom y desplazamiento.
- Teoría de cada módulo con formato Markdown y ecuaciones en LaTeX.
- Cuestionarios con generación de reporte en PDF.
- Captura de pantalla de la simulación con una nota de interpretación, que se incluye en el reporte.

## Módulos

| Categoría | Simulaciones |
|---|---|
| **Acústica y Ondas** | Ondas viajeras, interferencia de ondas, ondas estacionarias, ondas longitudinales, modos normales, modos normales con fronteras mixtas y libres |
| **Óptica** | Reflexión de la luz, refracción de la luz, espejos curvos, lentes delgadas |
| **Fluidos** | Principio de Bernoulli, conservación del gasto, conservación de la energía, ecuación de Poiseuille |

## Descarga

Descarga el APK de la última versión desde la sección de [Releases](https://github.com/IsaiOrtiz/lab_virtual_fisica/releases/latest) e instálalo en tu dispositivo Android. Si el sistema lo pide, permite la instalación desde orígenes desconocidos.

## Ejecutar desde el código fuente

**Requisitos:** [Flutter](https://docs.flutter.dev/get-started/install) con Dart `^3.11.5`.

```bash
git clone https://github.com/IsaiOrtiz/lab_virtual_fisica.git
cd lab_virtual_fisica
flutter pub get
flutter run
```

Para generar el APK de Android:

```bash
flutter build apk --release
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Estructura del proyecto

```
lib/
├── main.dart              # Menú principal y registro de módulos
├── simulaciones/          # Una simulación por archivo
├── cuestionarios/         # Preguntas, pantalla de cuestionario y PDF
└── widgets/               # Lienzos, zoom y navegación reutilizables
assets/
├── teoria/                # Teoría de cada módulo (.txt en Markdown)
├── fonts/                 # Tipografías
└── modelos/               # Modelos 3D
android/ ios/ web/ windows/ linux/ macos/   # Plataformas generadas por Flutter
```

## Tecnologías

Flutter y Dart, con los paquetes `flutter_markdown`, `flutter_markdown_latex`, `google_fonts`, `pdf`, `printing`, `url_launcher`, `youtube_player_flutter` y `flutter_cube`.

## Cómo agregar contenido

**Teoría.** Crea el archivo en `assets/teoria/` con el nombre que aparece en `archivoTeoria` dentro de `lib/main.dart`.

**Preguntas.** Agrega las preguntas del módulo en `lib/cuestionarios/banco_preguntas.dart`, usando como llave el título exacto del módulo. El archivo incluye un ejemplo comentado.

**Nueva simulación.** Crea el archivo en `lib/simulaciones/` y regístralo como un `ModuloData` en `lib/main.dart`.

## Hoja de ruta

- [ ] Completar los archivos de teoría de todos los módulos.
- [ ] Redactar el banco de preguntas de cada módulo.
- [ ] Agregar capturas de pantalla al README.
- [ ] Publicar nuevas versiones con su APK en Releases.

## Contribuir

Las sugerencias y correcciones son bienvenidas. Abre un [issue](https://github.com/IsaiOrtiz/lab_virtual_fisica/issues) para reportar un error o proponer una mejora.

## Licencia

Distribuido bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE).

## Autor

**Isai Ortiz** — [@IsaiOrtiz](https://github.com/IsaiOrtiz)
