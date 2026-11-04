# Marble Overdrive — Shared Track Duel

Juego local **3D para dos jugadores** en Godot 4.4+. Canicas luminosas, pista compartida elevada, 30 segundos de preparación y dos acciones en carrera: Poder y Freno. Funciona sin conexión y sin servicios externos.

Rediseño visual: portada 3D, ciudad industrial modular, tres distritos urbanos, pista técnica, HUD unificado y efectos acotados. Incluye modos **Equilibrada / Ahorro**, español e inglés y tema claro por defecto para perfiles nuevos. Consulta [cambios, presupuesto y validación visual](docs/ART_DIRECTION.md).

## Ejecutar

Haz doble clic en **Play.cmd**. En este equipo usa el Godot 4.4.1 portátil de `tools/godot/`. También puedes importar `project.godot` en Godot 4.4 o superior y pulsar **F5**. Del directorio `tools/` solo se versiona `.gdignore`; el motor y los datos de desarrollo se mantienen locales. Al compartir el proyecto, instala Godot o exporta desde el editor con sus plantillas oficiales. El lanzador también admite `GODOT_BIN` y Godot instalado en PATH.

No hay un ejecutable exportado independiente: el lanzador ejecuta el proyecto con el motor portátil. Los registros se guardan en `logs/game.log`.

En **Linux y macOS**, abre `project.godot` en Godot o usa `sh Play.sh` con Godot instalado. Hay presets de Windows x64, Linux x64 y macOS Universal; las instrucciones y las pruebas pendientes por plataforma están en [exportación de escritorio](docs/DESKTOP_EXPORTS.md).

## Copia ligera para GitHub

El repositorio conserva el código, los 13 escenarios, colores, patrones, traducciones y pruebas. El motor, las descargas, los perfiles de pruebas, las capturas y las cachés se excluyen con `.gitignore`; no son parte del juego como código fuente.

```powershell
powershell -ExecutionPolicy Bypass -File maintenance/Export-Source.ps1
```

El resultado es `dist/MarbleOverdrive-source.zip`, acompañado de `source-manifest.json` con tamaños y SHA-256. Para subirlo mediante la web de GitHub, descomprime el ZIP y usa el contenido de `MarbleOverdrive/` como carpeta del repositorio. Si trabajas directamente aquí con Git, las exclusiones ya están preparadas. No hace falta añadir el ZIP al historial.

En una copia nueva sin el motor local se necesita Godot 4.4+. Abre `project.godot` con el editor para importar y ejecutar. El código y sus dependencias se conservan; el ejecutable de Godot se instala aparte. Consulta [las optimizaciones y mediciones](docs/OPTIMIZATION.md).

`maintenance/Clear-Caches.ps1` elimina únicamente cachés de shaders bajo `tools/` y el ZIP del motor cuando sus dos ejecutables extraídos coinciden por SHA-256. Conserva motor, perfiles, capturas y funciones; admite `-WhatIf` para inspeccionar su alcance. No toca los datos del usuario fuera del proyecto.

## Controles

| Acción | Jugador 1 | Jugador 2 |
| --- | --- | --- |
| Avanzar / retroceder por la pista al colocar | A / D | Izquierda / Derecha |
| Ajustar dentro de la mitad asignada | W / S | Arriba / Abajo |
| Colocar el siguiente objeto | Espacio | Intro |
| Usar poder | Q | O |
| Frenar mientras se mantiene pulsado | E | P |

**Escape:** pausar/reanudar o volver. **F11:** pantalla completa. Las teclas de carrera se pueden reasignar en Ajustes; los diagramas se actualizan. Durante la carrera no hay dirección manual: avance, giro y recuperación son automáticos. El freno no tiene recarga ni duración máxima; al soltar vuelve la aceleración. Las paradas voluntarias no activan la recuperación por atasco.

Pantalla completa usa el monitor entero, en modo exclusivo. El lienzo y la cámara expanden su proporción para evitar franjas negras, también en ventanas anchas o altas. La UI tiene paneles con circuitos, iluminación de bordes, sombras, vistas 3D y navegación separada por categorías.

## Dos perfiles, dos nombres

Hay siempre **dos perfiles activos distintos**, uno por jugador. En Perfiles puedes crear o seleccionar cada uno de forma independiente. La biblioteca conserva perfiles guardados anteriormente; no se eliminan para limitar los dos puestos activos.

Cada perfil conserva nombre, apariencia, poder, equipo y estadísticas individuales de victorias, derrotas y empates. Los nombres aparecen en configuración, HUD, canicas y resultados. Idioma, tema, pantalla completa, sonido, música y asignaciones de teclado son ajustes compartidos del perfil anfitrión (jugador 1). Los perfiles nuevos heredan los ajustes actuales para no salir accidentalmente de pantalla completa.

Los datos viven en `user://profiles.cfg`, normalmente `%APPDATA%/Godot/app_userdata/Marble Overdrive/profiles.cfg`. Son perfiles locales de conveniencia, sin contraseñas ni cuentas en línea. Los archivos anteriores se migran conservando la biblioteca, las estadísticas antiguas y los ajustes. Las combinaciones de equipo antiguas que exceden las reglas nuevas se sustituyen por el equipo inicial válido.

## Preparación y lados

1. En Jugar duelo local, elige un escenario y configura cada jugador.
2. **Taller de canicas (paso 1 de 2):** 12 colores principales/secundarios en muestras y **12 diseños** elegibles con recuadros de vista previa animada: sólido, líneas, dos colores, bandas orbitales, cuadros, circuito eléctrico, galaxia, escamas hexagonales, núcleo de lava, gema facetada, ojo de gato y fibra de carbono. Varios tienen relieve real y la gema tiene silueta facetada. La vista previa y la canica 3D usan el mismo shader (`shaders/marble_designs.gdshaderinc`), así que el recuadro muestra exactamente el acabado de carrera.
3. **Estrategia de carrera (paso 2 de 2, pantalla propia):** tarjetas con icono para el poder y los objetos, separados en Equipo y Trampas. Al pulsar una tarjeta se añade al siguiente espacio (1, 2, 3); al pulsarla otra vez se quita. La barra de energía muestra el gasto, y las tarjetas que no caben se atenúan. Máximo **6 puntos de energía**; no se puede iniciar una combinación inválida.
4. En los 30 segundos de colocación, cada panel muestra el icono del siguiente objeto, a qué mitad va, el estado de los tres objetos (colocado, siguiente, pendiente) y el motivo concreto si no se puede colocar (mitad incorrecta, muy cerca de un objeto, de un peligro, de un hueco, de la salida o de la meta). El cursor del mapa lleva el icono del objeto, la mitad de destino se resalta y una barra marca el tiempo, en rojo los últimos 5 s. El cursor cambia automáticamente al lado permitido para el siguiente objeto. Las **trampas van a la mitad rival**; el **equipo va a la propia**. No puedes cruzar el cursor a la mitad incorrecta.
5. Las bandas muestran los lados de cada piloto. Los puntos de color y OK indican colocaciones válidas; rojo/X y las rayas indican bloqueos. No se puede colocar cerca de salida, meta, peligros u otro objeto en la misma mitad. Mitades distintas pueden usar la misma altura de pista si dejan la separación física necesaria.
6. Cada objeto se consume una sola vez y afecta exclusivamente a su destinatario. No hay robo de turbo ni daño de tus propias trampas. Salto y Fase atraviesan los objetos sin consumirlos.

El mapa táctico se deriva de la pista 3D real y amplía su ancho para hacerlo legible. No depende de iluminación, niebla o bloom. Escape pausa también su reloj. La Guía de equipo separa Equipo, Trampas y Poderes y explica efectos, costes y contramedidas.

## Equipo y balance inicial

| Objeto | Categoría / destino | Coste | Efecto |
| --- | --- | --- | --- |
| Rampa turbo | Equipo / propio | 3 | Hasta +10 m/s de impulso y objetivo de 48 m/s durante 2,5 s; las ralentizaciones siguen afectando |
| Plataforma de reparación | Equipo / propio | 2 | +18 salud, sin superar 100 |
| Puerta de escudo | Equipo / propio | 3 | Absorbe hasta 20 de daño durante 5 s; no evita frenadas |
| Estabilizador | Equipo / propio | 1 | Limpia y evita ralentizaciones durante 3 s; no protege del daño |
| Imán de frenado | Trampa / rival | 2 | 8 de daño y 1,4 s de ralentización |
| Barrera | Trampa / rival | 3 | 20 de daño y pérdida del 40 % del impulso |
| Campo de fricción | Trampa / rival | 1 | 0,85 s de ralentización, sin daño |
| Mina eléctrica | Trampa / rival | 2 | 18 de daño, sin ralentización |

El límite de energía, los objetos sin repetir, los efectos acotados y las contramedidas impiden acumular una combinación ilimitada. Los valores están implementados y probados; el balance competitivo definitivo requiere partidas humanas.

Poderes: **PEM** (16 m, 12 de daño, empuje y breve ralentización, recarga 6 s); **Salto** (impulso vertical real, protección 1 s, recarga 5 s); **Fase** (atraviesa obstáculos con impulso durante 0,8 s, recarga 6 s). Todos conservan la colisión con suelo y barandillas. Los peligros neutrales se generan en pares simétricos, uno por mitad, para dar el mismo riesgo a ambos jugadores. Afectan a cualquiera: 18 de daño con espera de 1,1 s por peligro.

## 13 escenarios elegibles

1. **Metrópolis neón:** torres, fachadas, azoteas, anuncios, luces de calle y transporte elevado móvil.
2. **Parque de diversiones orbital:** ruedas de observación móviles y carruseles.
3. **Zoológico biodomo:** hábitats elevados con jirafas, elefantes, árboles y cercas.
4. **Puerto estelar:** cohetes, plataformas, radares y estructuras de lanzamiento.
5. **Caldera volcánica:** montañas, cráteres, lava y brasas.
6. **Glaciar de cristal:** grupos de agujas de hielo facetado.
7. **Archipiélago de mareas:** agua animada, islas y torres de navegación.
8. **Ruinas esmeralda:** árboles grandes y portales entre vegetación.
9. **Dunas solares:** pirámides, dunas y cactus.
10. **Mundo de dulces cromático:** piruletas, dulces gigantes y plataformas de color.
11. **Distrito energético industrial:** fábricas modulares, chimeneas, conductos, pasarelas y señales ámbar.
12. **Jardines flotantes:** islas suspendidas con árboles y cascadas.
13. **Terminal del horizonte:** plataformas elevadas, estaciones y trenes sobre una ciudad estratificada.

Los escenarios contienen geometría propia, no solo cambios de paleta. El trazado procedural, las reglas, los efectos y la física son comunes a los 13 para conservar la misma competición. El selector incluye ilustraciones de cada mundo y el menú presenta una vista 3D del seleccionado.

## Física y generación

`RigidBody3D`, colisiones continuas, esferas, gravedad, fuerza de apoyo y guiado lateral por muelle. Las pendientes son geometría real. La cámara encuadra a ambos pilotos y se aleja al separarse. La recuperación devuelve una canica atascada o caída al punto más cercano, sin adelantarla. Las colisiones de las barreras usan capas específicas por destinatario; ambos pilotos colisionan con el suelo.

El diseñador de pistas (`scripts/track_ai.gd`) es una **IA local evolutiva**: un algoritmo genético con semilla cría ocho módulos de rectas, curvas, rampas, bajadas, peligros, **saltos con huecos** y **desplomes** de hasta 0,6 de pendiente, y se queda con la pista que mejor cumple la dificultad objetivo, la variedad y el ritmo. La semilla reproduce trazado, huecos y peligros. Se validan continuidad, pendiente, curvatura, límites, espacio útil y que cada hueco sea franqueable a velocidad de crucero. El curso avanza en Z para evitar intersecciones. La semilla se muestra en el HUD y los resultados. No usa red, claves ni modelos externos; si la validación fallara, el generador clásico de módulos actúa como respaldo. Detalles en [docs/TRACK_AI.md](docs/TRACK_AI.md).

## Organización

- `scripts/session.gd`: dos perfiles activos, persistencia, controles y pantalla completa.
- `scripts/game_catalog.gd`: catálogo de objetos, costes, apariencias y escenarios.
- `scripts/interface.gd`, `workshop_screens.gd`: HUD, ajustes, pausa, resultados, menú, perfiles, taller y catálogos.
- `scripts/arcade_panel.gd`, `arcade_button.gd`, `backdrop.gd`: lenguaje visual de la interfaz.
- `scripts/track_generator.gd`, `race.gd`: geometría, colocación por lados, fases y victorias.
- `scripts/marble.gd`, `tactical_item.gd`: física, poderes y efectos de los ocho objetos.
- `scripts/track_view.gd`, `scenario_world.gd`, `neon_geometry.gd`: pista, ciudad mejorada y escenarios.
- `scripts/district_kit.gd`, `district_profile.gd`, `environments/`: kit urbano y presets reutilizables.
- `scripts/race_effects.gd`: chispas limitadas y señales visuales sin efectos sobre la física.
- `scripts/tactical_map.gd`, `keyboard_diagram.gd`: mapa y controles gráficos.
- `scripts/marble_badge.gd`, `scenario_thumbnail.gd`, `menu_preview.gd`: vistas previas e ilustraciones originales.
- `shaders/`: patrones 3D/2D, pista PBR, agua y resplandor nocturno.
- `localization/catalog.gd`, `expansion.gd`, `art_direction.gd`: inglés y español, usando `TranslationServer` de Godot.

## Validación

Usa datos aislados para no tocar tus perfiles reales:

```powershell
$env:APPDATA = Join-Path (Get-Location) 'tools/test-data'
& './tools/godot/Godot_v4.4.1-stable_win64_console.exe' --headless --editor --path . --quit
& './tools/godot/Godot_v4.4.1-stable_win64_console.exe' --headless --path . --fixed-fps 120 res://tests/smoke.tscn
& './tools/godot/Godot_v4.4.1-stable_win64_console.exe' --headless --path . --fixed-fps 120 res://tests/expansion.tscn
```

- `smoke.tscn`: 300 semillas deterministas, perfiles, locales, temas, controles, 30 s, pausa, salto, freno continuo y en pendiente, resultados y ocho carreras completas.
- `expansion.tscn`: dos perfiles distintos y estadísticas, persistencia de diseños, 16 combinaciones objeto/dueño, lados, destinatarios, costes y carreras completas en los 13 escenarios.
- `ui_expansion.tscn`: botones reales de perfiles, recuadros de diseño y muestras de color, tarjetas de poder y objetos, espacios y energía (quitar, cuarto objeto, sobrecoste), navegación taller ↔ estrategia y guías. Con render gráfico guarda capturas.
- `display.tscn`: tres proporciones de ventana y pantalla completa exacta al monitor; requiere render gráfico.
- `world_capture.tscn`: captura los 13 mundos, perfiles, taller, guía y selector; requiere render gráfico.
- `stability.tscn`: doce ciclos gráficos de menús, temas, colocación, pausa, carrera, resultados y audio.
- `optimization.tscn`: 8960 comparaciones contra la búsqueda exhaustiva, mallas compartidas, colores independientes y caché acotada.
- `music.tscn`: la música es determinista, dura exactamente 16 compases, no tiene costura al repetirse, mantiene un volumen bajo y parejo, se silencia con el ajuste y está traducida.
- `track_ai.tscn`: 300 semillas válidas y deterministas, el nivel de dificultad cambia las pistas, y las canicas cruzan los huecos con física real sin recuperaciones.
- `performance.tscn`: medición reproducible de CPU, mallas, materiales y geometría de los 13 escenarios.
- `art_contract.tscn`: límites de efectos, persistencia visual, traducciones y separación del decorado; los límites de instancias requieren render gráfico.
- `art_review.tscn`: 31 capturas de temas, idiomas, resoluciones, distritos, menús, colocación, pausa y resultados.
- `art_benchmark.tscn`: comparación gráfica de ambas calidades con escena fija; ejecutar sin `--fixed-fps`.

Para pruebas gráficas omite `--headless` y cambia la escena. Las capturas quedan en `tools/`.

## Alcance

Versión estilizada con geometría original de Godot. Los escenarios son decorados propios de un prototipo, no recreaciones fotorrealistas. No requiere modelos, música o texturas externos. La **música de fondo** (`scripts/music_synth.gd`) también se compone en código: un bucle futurista y tranquilo de 16 compases (43 s, La menor, 90 BPM) con pad suave, pulso grave, arpegio con eco, campanas y un tic ligero. Se genera una sola vez en un hilo (unos 3 s la primera vez), se guarda en caché en `user://music_v1.pcm` y desde entonces carga al instante. El final enlaza con el inicio sin corte, baja 6 dB mientras ruedan las canicas y se apaga desde Ajustes con «Música de fondo» (independiente de los efectos). El sonido (`scripts/audio.gd`) sintetiza en código 24 efectos con nombre (interfaz, colocación, cuenta atrás, cada objeto y poder, peligros, saltos, aterrizajes y meta), con varias voces simultáneas y una rodadura en bucle que sube de tono y volumen con la velocidad de cada canica. No usa archivos de audio. No incluye red, campaña, mandos ni autenticación segura. El freno sostenido y la recuperación son de estilo arcade; la esfera visual gira, mientras se bloquea la rotación del cuerpo para estabilizar la física.

El cierre nativo de Godot comunicado anteriormente no tiene una causa confirmada; las pruebas de estabilidad no lo reprodujeron. Si vuelve a aparecer, el registro de `logs/game.log` permite continuar el diagnóstico.


