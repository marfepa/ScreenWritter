# Arquitectura

ScreenWritter esta organizada en cuatro capas: shell SwiftUI, renderizado de contenido, capa PencilKit y servicios de persistencia/importacion/exportacion.

## Flujo principal

1. El usuario crea una sesion desde una URL, archivo, drag and drop o Share Extension.
2. `SessionStore` crea un `AnnotationSession` con `ContentSource`.
3. `AnnotationWorkspaceView` renderiza el contenido base con `ContentRenderer`.
4. `AnnotationCanvasRepresentable` coloca un `PKCanvasView` transparente encima.
5. Al dibujar, `PKDrawing` se serializa y se guarda en disco.
6. Al reabrir la sesion, el dibujo se restaura desde `drawingData`.

## Tipos publicos principales

- `AnnotationSession`: sesion editable con titulo, fuente de contenido y datos PencilKit.
- `ContentSource`: enum para `web(URL)`, `pdf(URL)` e `image(URL)`.
- `AnnotationMode`: enum `navigate` / `annotate`.
- `SessionStore`: estado raiz observable, carga/guarda sesiones y coordina importaciones.
- `ImportCoordinator`: normaliza URLs, archivos locales e inbox compartido.
- `AnnotationExporter`: genera salidas PNG/PDF.

## Vistas principales

- `RootView`: shell con lista lateral e importadores.
- `SessionSidebarView`: lista de sesiones locales.
- `AnnotationWorkspaceView`: compone contenido, canvas y toolbar.
- `ContentRenderer`: selecciona `WKWebView`, `PDFView` o imagen segun el tipo de contenido.
- `AnnotationCanvasRepresentable`: puente UIKit/SwiftUI para PencilKit.

## PencilKit

`PKCanvasView` se configura con:

- `isOpaque = false`
- `backgroundColor = .clear`
- `PKToolPicker` retenido por el `Coordinator`
- `drawingPolicy = .anyInput` en DEBUG
- `drawingPolicy = .pencilOnly` en Release

El toolbar de ScreenWritter controla si el canvas captura interaccion:

- `Navegar`: el contenido inferior recibe toques, scroll y zoom.
- `Anotar`: el canvas captura eventos y aparece la paleta PencilKit.

## Persistencia

Las sesiones se guardan en:

- `Documents/Sessions/*.json`
- `Documents/Imports/*`

El contenido importado se copia al sandbox de la app. Las anotaciones se guardan como datos binarios de PencilKit dentro del JSON de la sesion.

## Share Extension

La extension escribe elementos compartidos en el App Group:

- `group.com.screenwritter.shared/Inbox`

Al abrir la app principal, `SessionStore.importSharedItems()` mueve esos elementos al sandbox local y crea sesiones.
