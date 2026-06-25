# Limitaciones de iPadOS

## No hay overlay global para apps normales

iPadOS no permite que una app normal coloque una capa tactil y dibujable encima de otras apps del sistema. Por eso ScreenWritter no intenta dibujar encima de Safari, Pages, Maps u otras apps externas.

La solucion implementada es un supercontenedor:

- La web se abre dentro de la app con `WKWebView`.
- Los PDF se abren dentro de la app con `PDFKit`.
- Las imagenes y capturas se importan dentro de la app.
- PencilKit dibuja encima de ese contenido dentro del sandbox de ScreenWritter.

## Picture in Picture no sirve para dibujar

Picture in Picture puede mostrar contenido flotante, pero no proporciona una superficie interactiva completa para dibujar con PencilKit encima de otras apps. No es una base viable para esta herramienta.

## Share Extension como puente con el sistema

Para contenido externo, la ruta compatible con App Store es:

1. El usuario comparte una URL, PDF o imagen desde otra app.
2. La Share Extension de ScreenWritter recibe el contenido.
3. La app principal lo importa como una sesion editable.
4. El usuario anota dentro de ScreenWritter.

## Slide Over y multitarea

ScreenWritter puede beneficiarse de la multitarea de iPadOS, pero sigue sin convertir la app en un overlay global. Drag and drop permite traer contenido desde otra app hacia ScreenWritter de forma compatible con el sistema.
