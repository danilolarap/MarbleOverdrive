# Marble Overdrive · dirección visual

Implementación del 1 de noviembre de 2026 sobre Godot 4.4.1 / Compatibility.

La identidad usa metal grafito, hormigón, maquinaria y transporte elevado.
Cian y magenta identifican a los pilotos nuevos, con etiquetas P1/P2 que
permanecen legibles aunque se personalicen los colores. El amarillo ácido
se reserva para acciones, señalización y marcas de seguridad. Los diseños,
la geometría y los materiales son originales y no necesitan descargas.

## Lo que cambió

- Portada 3D con movimiento lento de cámara, trenes y anuncios animados;
  tipografía de marca, acceso principal y navegación secundaria. El fondo
  se actualiza a un máximo de 30 Hz y se renderiza a media resolución
  por eje; ahorro usa un tercio. La UI conserva su resolución.
- Tema claro predeterminado para perfiles nuevos; los perfiles existentes
  conservan el tema guardado. Paneles, botones, HUD, pausa, perfiles,
  taller y resultados comparten materiales visuales y estados de foco.
  La fuente incluida en Godot evita depender de las fuentes de cada SO.
- Kit de tres distritos: Centro neón, Distrito energético industrial y
  Terminal del horizonte. El último es un escenario adicional. Se conservan
  los otros escenarios y los identificadores de los perfiles guardados.
- Asfalto técnico con juntas, áreas de agarre y márgenes industriales;
  barandillas metálicas opacas, soportes y tres arcos de sector por pista.
  Los arcos indican progreso visual: no cambian puntuación ni recuperación.
- Canicas con acabado metálico, identificación P1/P2 y estela breve;
  siluetas de imán y escudo más claras, etiquetas de destinatario en
  los objetos, pulsos y chispas limitadas para impactos, uso y meta.
- Traducciones nuevas en español e inglés. Se conservan reglas,
  inventarios, 30 segundos de colocación, controles, perfiles y estadísticas.

## Organización y presupuesto

`environments/*.tres` configura los distritos mediante `DistrictProfile`.
`DistrictKit` construye edificios, ventanas, equipos de azotea, plataformas,
anuncios, calles inferiores y trenes. No crea colisiones. Los edificios
laterales están fuera del corredor; la ciudad inferior queda por debajo
de la menor altura de pista. Los detalles se agrupan por material y celdas
de 80 m en MultiMesh para permitir descarte por cámara y distancia.

Las piezas estáticas de carretera y trenes también comparten lotes. Los
materiales se reutilizan por escenario. No hay texturas raster nuevas,
reflejos en pantalla, niebla volumétrica ni luces dinámicas en edificios.
Se mantienen dos luces cortas de canica en calidad equilibrada. Los
edificios no proyectan sombras; las sombras cercanas de pista sí.

Los efectos usan como máximo 48 chispas en una malla y 10 pulsos simultáneos.
Las estelas guardan siete muestras a 30 Hz. El brillo nocturno pasa de
16 muestras periféricas a cuatro, con umbral alto. El fondo de los menús
secundarios solo se redibuja al cambiar tamaño o preferencias.

En Ajustes, **Ahorro** elimina sombras, MSAA, luces de canicas y brillo,
reduce una capa de edificios, distancia del decorado y resolución de
portada. No reduce los 120 pasos de física ni cambia las reglas.

## Verificación realizada

En Windows, Godot 4.4.1 y AMD Radeon integrada con OpenGL 3.3:

- `smoke`: 300 semillas, controles, perfiles, temas/idiomas, pausa,
  poderes, freno y finales de carrera.
- `expansion`: carreras completas en los 13 escenarios y 16 combinaciones
  objeto/dueño, restricciones de colocación y estadísticas individuales.
- `ui_expansion`, `optimization`: navegación y talleres, presupuesto,
  8960 comparaciones de posición cercana y caché de mallas acotada.
- `art_contract`: preferencias persistentes, traducciones, límites de
  efectos y separación de decorado. Con render gráfico comprueba 84582
  instancias en tres semillas, tres distritos y dos calidades, además de
  conservar los límites geométricos al agrupar una pieza girada.
  Sin render omite explícitamente los límites de MultiMesh porque el
  servidor gráfico simulado devuelve transformaciones identidad.
- `art_review`: 31 capturas; portada a 1280×720 y 1920×1080 en ambos temas
  e idiomas, pantallas secundarias, colocación, tres distritos, pausa,
  resultados y ahorro. Capturas y métricas quedan excluidas en `tools/`.
- `stability`: 12 ciclos gráficos de navegación, tema, colocación,
  pausa, carrera, resultados y audio.
- Exportación de datos de los tres presets y apertura gráfica del paquete
  de Windows desde `dist/`, sin depender de la carpeta de código fuente.
  Los ZIP contienen 76 entradas de ejecución y excluyen pruebas y herramientas.

Se revisaron capturas para ajustar encuadre, lectura, tamaño de título y
visibilidad de pilotos. No se observaron errores de script ni shader en
las ejecuciones finales. Godot muestra un error de lectura del almacén de
certificados del entorno restringido, también presente antes del cambio;
el juego funciona sin servicios de red.

### Medición reproducible

`art_benchmark.tscn`, sin `--fixed-fps`: misma semilla 42, posición 100 m,
ventana 1280×720, tema oscuro, cámara fija, física de carrera detenida,
VSync desactivado; 60 cuadros de calentamiento y 180 muestras.
Son intervalos de cuadros del proceso, no una medición aislada de GPU
ni una garantía de rendimiento durante toda una partida.

| Distrito | Equilibrada: mediana / p95 | Ahorro: mediana / p95 | Dibujos equilibrada / ahorro |
| --- | --- | --- | --- |
| Centro | 5,477 / 6,871 ms | 1,200 / 1,358 ms | 281 / 158 |
| Energía | 5,334 / 6,024 ms | 1,208 / 1,400 ms | 281 / 159 |
| Terminal | 5,402 / 5,915 ms | 1,213 / 1,361 ms | 265 / 150 |

`tools/art-benchmark.json` conserva las mediciones de esta máquina.
Durante carreras en movimiento las capturas registraron hasta 394 dibujos
en los tres distritos; la perspectiva, los objetos y las sombras cambian
ese total. No extrapolar estas cifras a otras máquinas.

Queda pendiente ejecutar versiones nativas en macOS y Linux y revisar
rendimiento en más equipos. La configuración de exportación y sus límites
están documentados en [DESKTOP_EXPORTS.md](DESKTOP_EXPORTS.md).
