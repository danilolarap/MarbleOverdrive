# Importacion organizada del trabajo existente

Esta entrega importa el juego ya desarrollado en una secuencia de 66 commits
tematicos. No representa fechas historicas de desarrollo: cada commit se crea
en el momento de la importacion, sin commits vacios ni fechas retroactivas.

Los scripts grandes de escenarios y pantallas se incorporan por funciones.
Los commits intermedios de ensamblaje pueden referirse a funciones o recursos
que se agregan mas adelante. La unidad ejecutable y validada es el estado final
de la serie completa.

La rama de entrega es `main`. El motor portatil, los perfiles personales, las
capturas, los registros y las caches permanecen fuera del historial.

## Secuencia de commits

| N. | Cambio |
| --- | --- |
| 01 | chore(repo): definir archivos de fuente y excluir motores y caches |
| 02 | chore(godot): configurar proyecto 3D y escalado de pantalla |
| 03 | feat(branding): incorporar icono vectorial del juego |
| 04 | feat(catalog): definir equipo equilibrado, colores y escenarios |
| 05 | feat(i18n): incorporar traducciones base en ingles y espanol |
| 06 | feat(i18n): traducir mundos, equipo y nuevas interfaces |
| 07 | feat(profiles): gestionar dos pilotos, preferencias y controles |
| 08 | perf(geometry): compartir primitivas con cache acotada |
| 09 | feat(shaders): agregar resplandor de luces |
| 10 | feat(shaders): renderizar colores y patrones de las canicas |
| 11 | feat(shaders): representar apariencias en las interfaces |
| 12 | feat(shaders): iluminar la pista futurista |
| 13 | feat(shaders): animar superficies de agua |
| 14 | feat(track): generar circuitos reproducibles y consultas optimizadas |
| 15 | feat(city): construir pista, ciudad y senales luminosas |
| 16 | feat(worlds): preparar infraestructura de escenarios procedurales |
| 17 | feat(worlds): construir escenario de parque de juegos |
| 18 | feat(worlds): construir escenario de zoologico |
| 19 | feat(worlds): construir escenario de puerto espacial |
| 20 | feat(worlds): construir escenario de volcan |
| 21 | feat(worlds): construir escenario de mundo de hielo |
| 22 | feat(worlds): construir escenario de oceano |
| 23 | feat(worlds): construir escenario de jungla |
| 24 | feat(worlds): construir escenario de desierto |
| 25 | feat(worlds): construir escenario de mundo de dulces |
| 26 | feat(worlds): construir escenario de fabrica |
| 27 | feat(worlds): construir escenario de jardines del cielo |
| 28 | feat(physics): implementar canicas, freno sostenido y poderes |
| 29 | feat(equipment): aplicar trampas y mejoras con efectos limitados |
| 30 | feat(race): coordinar colocacion por carril y carreras locales |
| 31 | feat(audio): sintetizar efectos originales del juego |
| 32 | feat(ui): dibujar fondo futurista para los menus |
| 33 | feat(ui): estilizar botones de la interfaz |
| 34 | feat(ui): dibujar paneles con detalles luminosos |
| 35 | feat(controls): mostrar un mapa visual del teclado |
| 36 | perf(ui): actualizar las insignias solo al cambiar apariencia |
| 37 | feat(ui): animar la vista previa del menu principal |
| 38 | feat(ui): representar miniaturas de los escenarios |
| 39 | feat(map): mostrar carriles y colocacion con contraste adaptable |
| 40 | feat(menu): construir portada futurista y accesos principales |
| 41 | feat(profiles): construir seleccion de nombres para ambos pilotos |
| 42 | feat(setup): ofrecer colores, patrones y configuracion local |
| 43 | feat(loadout): explicar categorias y validar el presupuesto |
| 44 | feat(gallery): permitir elegir entre doce escenarios |
| 45 | feat(guide): explicar equipo, trampas y poderes |
| 46 | feat(interface): integrar ajustes, HUD, pausa y resultados |
| 47 | feat(game): conectar el flujo de menus y partidas |
| 48 | feat(scene): incorporar escena principal ejecutable |
| 49 | chore(windows): facilitar el inicio y registrar errores de Godot |
| 50 | docs(readme): explicar instalacion, controles y modos del juego |
| 51 | test(race): validar generacion y carreras completas |
| 52 | test(display): verificar pantalla completa y preferencias |
| 53 | test(features): comprobar perfiles, equipo y doce mundos |
| 54 | test(optimization): comparar busquedas y caches de recursos |
| 55 | test(performance): medir recursos y tiempos de consulta |
| 56 | test(stability): comprobar ciclos de vida de las partidas |
| 57 | test(ui): recorrer perfiles, configuracion y galeria |
| 58 | test(visual): capturar interfaces y mapas tacticos |
| 59 | test(3d): capturar la representacion de las carreras |
| 60 | test(worlds): capturar cada escenario seleccionable |
| 61 | chore(maintenance): limpiar solo caches y descargas duplicadas |
| 62 | chore(validation): ejecutar comprobaciones con perfiles aislados |
| 63 | chore(packaging): exportar fuente ligera con manifiesto verificable |
| 64 | docs(optimization): documentar medidas y conservacion de funcionalidades |
| 65 | docs(history): documentar la importacion organizada en 66 commits |
| 66 | docs(validation): registrar verificaciones de la entrega a GitHub |

## Verificacion

El registro de la comprobacion final figura en [VALIDATION.md](VALIDATION.md).
Las instrucciones de ejecucion estan en [README.md](../README.md).

## Serie adicional: rediseño visual en 30 commits

Esta serie continúa los 66 commits originales desde `c39a225`. Agrupa los
cambios del rediseño por recursos y responsabilidades, con contenido real en
cada commit. No cambia las fechas ni reescribe el historial anterior.

| N. | Cambio |
| --- | --- |
| 01 | Normalizar finales de línea para recursos y lanzadores |
| 02 | Excluir credenciales de exportación del repositorio |
| 03 | Incorporar el lanzador para macOS y Linux |
| 04 | Crear el material procedural de arquitectura |
| 05 | Animar los paneles de señalización urbana |
| 06 | Definir recursos configurables de distrito |
| 07 | Configurar los tres distritos urbanos |
| 08 | Conservar calidad visual y tema claro inicial |
| 09 | Agrupar geometría estática por material |
| 10 | Construir el kit de ciudad e infraestructura |
| 11 | Limitar chispas y efectos de carrera |
| 12 | Traducir la nueva identidad y los ajustes |
| 13 | Integrar la terminal en el catálogo y selector |
| 14 | Dibujar superficies técnicas de carretera |
| 15 | Refinar el acabado metálico de las canicas |
| 16 | Identificar pilotos y acortar las estelas |
| 17 | Diferenciar siluetas y destinatarios de objetos |
| 18 | Integrar distritos, barandillas y arcos de sector |
| 19 | Conectar activaciones, impactos y meta con efectos |
| 20 | Reducir el coste del brillo nocturno |
| 21 | Aplicar el modo de ahorro a los efectos globales |
| 22 | Crear el contraste de lectura de la portada |
| 23 | Unificar paneles, botones y fondo técnico |
| 24 | Rediseñar portada, navegación, temas y HUD |
| 25 | Validar separación de decorado y límites visuales |
| 26 | Capturar temas, idiomas, resoluciones y distritos |
| 27 | Medir ambas calidades en una escena reproducible |
| 28 | Incluir recursos nuevos en comprobaciones y paquetes |
| 29 | Preparar la exportación para Windows, macOS y Linux |
| 30 | Documentar el rediseño, su rendimiento y validación |

Las comprobaciones del estado final y los límites de la verificación por
plataforma se describen en [ART_DIRECTION.md](ART_DIRECTION.md) y
[DESKTOP_EXPORTS.md](DESKTOP_EXPORTS.md).
