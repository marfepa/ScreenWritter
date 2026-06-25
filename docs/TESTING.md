# Pruebas y validacion

## Unit tests incluidos

`ScreenWritterTests/AnnotationSessionTests.swift` cubre:

- Serializacion y restauracion de `AnnotationSession`.
- Restauracion de un `PKDrawing` vacio.
- Normalizacion de URLs en `ImportCoordinator`.

## UI tests incluidos

`ScreenWritterUITests/ScreenWritterUITests.swift` cubre:

- Lanzamiento de la app.
- Estado inicial sin sesiones.

## Validacion manual recomendada

### App principal

1. Ejecuta el scheme `ScreenWritter`.
2. Importa una URL con el boton Web.
3. Cambia a modo `Anotar`.
4. Dibuja con Apple Pencil.
5. Cambia a modo `Navegar`.
6. Verifica que el contenido inferior vuelve a recibir interaccion.
7. Cierra y reabre la app.
8. Verifica que los trazos siguen visibles.

### PDF

1. Importa un PDF desde Files.
2. Navega por el documento.
3. Cambia a modo `Anotar`.
4. Dibuja encima.
5. Exporta como PDF.

### Imagen

1. Importa una imagen o captura.
2. Dibuja encima.
3. Exporta como PNG.

### Share Extension

1. Ejecuta el scheme `ScreenWritterShareExtension`.
2. Elige Safari, Files o Photos como host.
3. Comparte una URL, PDF o imagen hacia ScreenWritter.
4. Abre la app principal.
5. Verifica que se crea una sesion.

## Limitaciones de validacion automatizada

La experiencia real de Apple Pencil debe validarse en iPad fisico. El simulador permite validar layout y flujos generales, pero no prueba palm rejection ni latencia real del Pencil.
