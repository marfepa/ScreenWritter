# Pruebas y validacion

## Unit tests incluidos

`ScreenWritterTests/AnnotationSessionTests.swift` cubre:

- Serializacion y restauracion de `AnnotationSession`.
- Compatibilidad con sesiones antiguas sin dibujos PDF por pagina.
- Persistencia de dibujos PDF por pagina.
- Restauracion de un `PKDrawing` vacio.
- Normalizacion de URLs en `ImportCoordinator`.
- Exportacion PDF multipagina basica.

## UI tests incluidos

`ScreenWritterUITests/ScreenWritterUITests.swift` cubre:

- Lanzamiento de la app.
- Estado inicial sin sesiones.
- Creacion de una sesion web desde la UI.
- Presencia del selector flotante `Navegar` / `Anotar`.
- Presencia del boton flotante `Limpiar`.

## Validacion manual recomendada

### App principal

1. Ejecuta el scheme `ScreenWritter`.
2. Importa una URL con el boton Web.
3. En modo `Navegar`, haz scroll con el dedo.
4. Cambia a `Anotar`.
5. Dibuja con Apple Pencil.
6. Cambia de nuevo a `Navegar` y verifica que la pagina no se recarga.
7. Verifica que los trazos se desplazan junto al contenido.
8. Cierra y reabre la app.
9. Verifica que los trazos siguen visibles.
10. Pulsa `Limpiar` y confirma que se borran las anotaciones.

### PDF

1. Importa un PDF desde Files.
2. Navega por el documento.
3. Dibuja con Apple Pencil en varias paginas.
4. Verifica que cada trazo permanece asociado a su pagina al desplazarte.
5. Exporta como PDF y revisa que las paginas anotadas conservan sus trazos.

### Imagen

1. Importa una imagen o captura.
2. Haz scroll con el dedo si el contenido excede la pantalla.
3. Dibuja encima con Apple Pencil.
4. Exporta como PNG.

### Share Extension

1. Ejecuta el scheme `ScreenWritterShareExtension`.
2. Elige Safari, Files o Photos como host.
3. Comparte una URL, PDF o imagen hacia ScreenWritter.
4. Abre la app principal.
5. Verifica que se crea una sesion.

## Limitaciones de validacion automatizada

La experiencia real de Apple Pencil debe validarse en iPad fisico. El simulador permite validar layout y flujos generales, pero no prueba palm rejection ni latencia real del Pencil. En DEBUG el canvas acepta `.anyInput`, por lo que puede probarse dibujo con dedo o simulador.
