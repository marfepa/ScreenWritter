# Arquitectura

ScreenWritter esta organizada en cuatro capas: shell SwiftUI, renderizado de contenido, capa PencilKit y servicios de persistencia/importacion/exportacion.

## Flujo principal

1. El usuario crea una sesion desde una URL, archivo, drag and drop o Share Extension.
2. `SessionStore` crea un `AnnotationSession` con `ContentSource`.
3. `AnnotationWorkspaceView` renderiza el contenido base con `ContentRenderer`.
4. `ContentRenderer` coloca un `PKCanvasView` transparente dentro del renderer nativo de cada contenido y lo activa segun el modo `Navegar` / `Anotar`.
5. Al dibujar, `PKDrawing` se serializa y se guarda en disco.
6. Al reabrir la sesion, el dibujo se restaura desde `drawingData` o desde `pdfPageDrawingData` para PDF multipagina.

## Tipos publicos principales

- `AnnotationSession`: sesion editable con titulo, fuente de contenido y datos PencilKit.
- `ContentSource`: enum para `web(URL)`, `pdf(URL)` e `image(URL)`.
- `SessionStore`: estado raiz observable, carga/guarda sesiones y coordina importaciones.
- `ImportCoordinator`: normaliza URLs, archivos locales e inbox compartido.
- `AnnotationExporter`: genera salidas PNG/PDF.

## Vistas principales

- `RootView`: shell con lista lateral e importadores.
- `SessionSidebarView`: lista de sesiones locales.
- `AnnotationWorkspaceView`: compone toolbar, controles flotantes, exportacion y renderer anotable.
- `ContentRenderer`: selecciona `WKWebView`, `PDFView` o imagen segun el tipo de contenido.
- `AnnotationCanvasRepresentable`: puente UIKit/SwiftUI para PencilKit en contenidos SwiftUI.

## PencilKit

Los canvases de PencilKit se configuran como `PKCanvasView` normales. La seleccion manual `Navegar` / `Anotar` decide si el canvas recibe interaccion o deja pasar los gestos al contenido.

- En `Navegar`, los overlays web/PDF desactivan interaccion del canvas para que `WKWebView` y `PDFView` reciban scroll, taps y zoom.
- En `Anotar`, el canvas activa el recognizer de dibujo y muestra el `PKToolPicker`.
- En imagenes, el `PKCanvasView` sigue siendo la superficie de scroll/zoom; `Navegar` desactiva solo el gesto de dibujo.
- En DEBUG, `drawingPolicy = .anyInput` para permitir pruebas con dedo o simulador.
- En Release, `drawingPolicy = .pencilOnly` para reducir trazos accidentales.

Para web, `WebAnnotationContainerView` mantiene `WKWebView` y `PKCanvasView` como vistas hermanas. El canvas no se inserta dentro del `scrollView` de WebKit; se desplaza visualmente con `contentOffset`, para que las anotaciones sigan el documento sin interferir con webs que usan touch handlers o scroll interno. El wrapper solo recarga la URL cuando cambia la URL solicitada por la app, no cuando la pagina redirige o cambia internamente, evitando refrescos al cambiar de modo.

Para PDF, `PDFContentView` usa `PDFPageOverlayViewProvider` y crea un canvas independiente por pagina.

`AnnotationWorkspaceView` mantiene los controles principales en la esquina inferior derecha: selector flotante de modo y boton `Limpiar` separado. En iOS 26+ usan Liquid Glass nativo; en iOS 17-25 usan `.ultraThinMaterial` como fallback.

Para imagenes, `ImageAnnotationCanvasView` usa el propio `PKCanvasView` como superficie `UIScrollView`. Este es el patron mas estable cuando no hay una vista UIKit interactiva debajo que deba recibir taps.

## Persistencia

Las sesiones se guardan en:

- `Documents/Sessions/*.json`
- `Documents/Imports/*`

El contenido importado se copia al sandbox de la app. Las anotaciones se guardan como datos binarios de PencilKit dentro del JSON de la sesion. `drawingData` se conserva para web/imagen y compatibilidad legacy de PDF; `pdfPageDrawingData` guarda los trazos por indice de pagina.

Durante el dibujo, los delegates de PencilKit no mutan `@State` por cada punto del trazo ni escriben en `SessionStore`. `AnnotationWorkspaceView` mantiene un caché no observable y persiste al salir o exportar para evitar ciclos de AttributeGraph y recargas de `WKWebView`.

## Share Extension

La extension escribe elementos compartidos en el App Group:

- `group.com.screenwritter.shared/Inbox`

Al abrir la app principal, `SessionStore.importSharedItems()` mueve esos elementos al sandbox local y crea sesiones.
