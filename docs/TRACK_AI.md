# IA de generación de pistas

Diseñador evolutivo **local**: sin red, claves de API ni modelos. La misma semilla y el mismo nivel producen siempre la misma pista, de modo que las semillas se pueden compartir.

## Cómo funciona

1. **Genoma.** Una pista son 8 secciones: salida recta + **6 genes libres** + meta. Cada gen es `{kind, dy, cells, pairs}`: tipo, desnivel, ancho del hueco en celdas de 2 m y pares de peligros.
2. **Tipos.** `straight`, `curve`, `ramp`, `drop`, `hazard` (clásicos) y los nuevos `jump` (hueco real en la pista) y `plunge` (bajada muy empinada, 18-27 m en 68 m).
3. **Evolución** (`TrackAI.evolve`): población de 24, 14 generaciones, elitismo 2, torneo de 3, cruce uniforme y mutación. Todo con `RandomNumberGenerator` sembrado.
4. **Aptitud** (`TrackAI.evaluate`):
   - acercar la dificultad media al objetivo `0.25 + 0.5 * nivel`;
   - premiar variedad de tipos y la presencia de salto/desplome según el nivel;
   - penalizar tipos repetidos, dos secciones extremas seguidas (sin respiro), más de 2 saltos, más de 3 pares de peligros y salirse de la banda de altura 9-40 m.
5. **Geometría** (`TrackGenerator._build`): convierte el genoma en puntos 3D y valida.
6. **Respaldo.** Si la validación fallara, se usa `TrackAI.legacy_genome` (la pista clásica). En las 300 semillas de prueba no ocurre ninguna vez.

`TrackGenerator.generate(semilla, nivel)` acepta `nivel` de 0 (suave) a 1 (extremo); por defecto `DEFAULT_LEVEL = 0.7`.

## Huecos

Los `points` de la pista siguen **continuos** a través del hueco (así `closest()`, `sample_at()`, la guía de la canica y el mapa táctico no cambian), pero no se crean suelo, barandillas, colisión ni soportes entre `gap.start` y `gap.end`.

La altura de aterrizaje se calcula con la física real de la canica (`TrackAI.landing_drop`): gravedad 9,8 + 15 m/s² de fuerza hacia abajo que la canica mantiene en el aire = 24,8 m/s². Una canica que llega al borde a **22 m/s o más** cruza siempre; la velocidad de crucero es 39 m/s. Ir frenada o ralentizada (16 m/s) hace caer, lo que da valor táctico a poner trampas antes de un hueco.

- La canica que cae se **recupera 24 m antes del borde** (`recovery_distance`), con carrerilla suficiente para volver a intentarlo.
- No se pueden colocar objetos desde 10 m antes del borde hasta 4 m después del aterrizaje (`is_placement_blocked`).
- Los peligros neutrales quedan a ≥ 40 m antes de un borde y ≥ 12 m después.
- Los huecos se muestran con barras ámbar y chevrones en 3D, y cortados con línea discontinua ámbar en el mapa táctico.

## Pruebas

```powershell
& './tools/godot/Godot_v4.4.1-stable_win64_console.exe' --headless --path . --fixed-fps 120 res://tests/track_ai.tscn
```

Valida 300 semillas (válidas, deterministas, sin respaldo), que el nivel 1 sea claramente más difícil que el 0, que el trazado clásico siga válido, y 8 carreras con huecos en física real sin ninguna recuperación y sin que decida la salud.

## Pendiente / ideas

- Menú para elegir el nivel (hoy es una constante) y mostrarlo junto a la semilla.
- Estrechamientos de pista y barandillas parciales (hoy el ancho es fijo).
- Bifurcaciones: requieren que `closest()` y el mapa admitan más de una ruta.
- Afinar la aptitud con partidas humanas; el balance actual sale de simulación.
