# ScreenWritter

ScreenWritter es una app iPadOS en SwiftUI que simula una capa invisible de anotacion sobre contenido real. iPadOS no permite que una app normal dibuje encima de otras apps del sistema, asi que la solucion trae el contenido dentro de ScreenWritter y superpone un lienzo transparente de PencilKit.

La app permite abrir web, PDF e imagenes/capturas, navegar por ese contenido y cambiar a modo anotacion para escribir encima con Apple Pencil.

## Estado del proyecto

Incluido en este PR:

- App iPadOS SwiftUI con `NavigationSplitView`.
- Renderizado de contenido web con `WKWebView`.
- Renderizado de PDF con `PDFKit`.
- Renderizado de imagenes importadas.
- Capa transparente `PKCanvasView` con `PKToolPicker`.
- Selector de modo `Navegar` / `Anotar`.
- Persistencia local de sesiones editables.
- Importacion desde archivos, URLs, drag and drop y Share Extension.
- Exportacion PNG y exportacion PDF basica para documentos.
- Targets de unit tests y UI tests.
- Proyecto Xcode generado con XcodeGen.

## Requisitos

- Xcode 27 o compatible con iOS 17+.
- iPadOS 17+ como deployment target.
- Apple Pencil para validar la experiencia final.
- XcodeGen si se quiere regenerar `ScreenWritter.xcodeproj`.
- Una cuenta de desarrollo Apple para instalar en iPad fisico y habilitar App Groups.

## Como ejecutar

1. Abre `ScreenWritter.xcodeproj` en Xcode.
2. Selecciona el scheme `ScreenWritter`.
3. Selecciona un iPad fisico o simulador iPad.
4. En `Signing & Capabilities`, configura tu Team en estos targets:
   - `ScreenWritter`
   - `ScreenWritterShareExtension`
5. Para usar la extension de compartir, habilita el App Group en ambos targets:
   - `group.com.screenwritter.shared`
6. Ejecuta `Product > Clean Build Folder` si Xcode conserva builds antiguos.
7. Pulsa Run.

## Como probar la Share Extension

La extension no se ejecuta sola. Si lanzas el scheme `ScreenWritterShareExtension`, Xcode pedira una app host.

Usa una de estas apps:

- Safari para compartir una URL.
- Files para compartir un PDF.
- Photos para compartir una imagen.

Flujo esperado:

1. Ejecuta el scheme `ScreenWritterShareExtension`.
2. Elige Safari, Files o Photos como host.
3. Abre el menu compartir.
4. Selecciona ScreenWritter.
5. Abre la app ScreenWritter.
6. La sesion importada debe aparecer en la lista lateral.

## Arquitectura

Documentacion detallada:

- [Arquitectura](docs/ARCHITECTURE.md)
- [Setup y signing](docs/SETUP.md)
- [Pruebas y validacion](docs/TESTING.md)
- [Limitaciones de iPadOS](docs/IPADOS_LIMITATIONS.md)

## Regenerar el proyecto

El proyecto Xcode se genera desde `project.yml`:

```bash
xcodegen generate
```

El archivo `ScreenWritter.xcodeproj` se incluye para que el proyecto pueda abrirse directamente en Xcode.

## Comandos utiles

```bash
# Validar plists
plutil -lint ScreenWritter/Info.plist ScreenWritterShareExtension/Info.plist ScreenWritterTests/Info.plist ScreenWritterUITests/Info.plist

# Regenerar proyecto
xcodegen generate
```

## Notas de implementacion

- En DEBUG, el canvas usa `.anyInput` para poder probar con dedo o simulador.
- En Release, el canvas usa `.pencilOnly` para reducir trazos accidentales y mejorar la experiencia con Apple Pencil.
- Las anotaciones se guardan como `PKDrawing.dataRepresentation()`, separadas del contenido de fondo.
- La exportacion PDF actual aplica la anotacion sobre la primera pagina como base funcional inicial. Mejorar la alineacion por pagina queda como siguiente iteracion.
