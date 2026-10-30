# Proyecto ligero para GitHub

El juego se distribuye como codigo fuente Godot: los 12 escenarios, las
apariencias y los sonidos se construyen con geometria, shaders y PCM originales.
No hace falta subir el ejecutable del motor para conservar estas funciones.

## Contenido del repositorio

Se versionan escenas, scripts, shaders, traducciones, pruebas, identificadores
`.uid`, icono, lanzador, documentacion y herramientas de mantenimiento.

Quedan fuera el motor portatil de `tools/godot/`, descargas, capturas, perfiles
de pruebas, caches `.godot/`, registros y paquetes generados de `dist/`.
`tools/.gdignore` se conserva para que Godot tampoco importe esos archivos.
El motor local sigue disponible para ejecutar `Play.cmd` en este equipo.

Para preparar una copia limpia, desde PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File maintenance/Export-Source.ps1
```

Genera `dist/MarbleOverdrive-source.zip` y `dist/source-manifest.json`. El
manifiesto enumera los archivos, sus tamanos y SHA-256. La lista permitida y las
fechas fijas del ZIP evitan incluir caches y hacen reproducible el paquete en
el mismo entorno. El ZIP no se debe anadir al historial Git; puede compartirse
como descarga o extraerse para subir los archivos del proyecto.

En una copia nueva se necesita Godot 4.4 o superior. Abre `project.godot` en el
editor y pulsa F5. En Windows, `Play.cmd` admite un Godot instalado en PATH,
la variable `GODOT_BIN` o el motor portatil local. No hay descargas automaticas.

## Cambios de rendimiento sin recortar calidad

- Mallas primitivas compartidas con los mismos parametros exactos, resolucion
  y vertices. Las referencias debiles y el limite de 512 entradas evitan retener
  escenarios terminados o acumular metadatos sin limite.
- Materiales inmutables reutilizados dentro de cada escenario. Los materiales
  que pueden modificarse por separado siguen siendo independientes.
- Busqueda exacta del punto cercano con limites por Z y expansion acotada,
  aprovechando la monotonia ya validada de la pista. Conserva la recuperacion
  incluso lejos de la carretera y el criterio anterior de desempate.
- Una malla persistente para cada estela, evitando crear un recurso por cuadro.
- Mapa tactico con geometria proyectada en cache y redibujado cuando cambian
  cursores, colocaciones, tamano, idioma o colores.
- Uniformes del acabado y las vistas previas actualizados cuando cambian.
- Diagramas de teclado redibujados al cambiar teclas, colores o disposicion,
  conservando el resaltado de las teclas mantenidas.

No se redujeron los 120 pasos fisicos por segundo, el antialiasing, las sombras,
los efectos, la resolucion de las mallas, los escenarios ni los catalogos.

## Medicion de esta optimizacion

Godot 4.4.1, misma maquina, medicion sin render. Mediana de cinco grupos de
1000 consultas de posicion cercana:

| Consulta | Antes | Despues |
| --- | ---: | ---: |
| 1000 puntos cercanos | 29,775 ms | 3,516 ms |

Es una mejora de aproximadamente **8,5 veces en esa consulta**, no una promesa
de FPS para todo el juego.

| Escenario | Mallas unicas antes | Mallas unicas despues |
| --- | ---: | ---: |
| Ciudad | 266 | 41 |
| Parque | 609 | 40 |
| Zoologico | 909 | 46 |
| Puerto estelar | 345 | 39 |
| Volcan | 357 | 248 |
| Hielo | 285 | 199 |
| Oceano | 346 | 38 |
| Jungla | 501 | 322 |
| Desierto | 297 | 37 |
| Dulces | 429 | 35 |
| Fabrica | 381 | 36 |
| Jardines | 381 | 37 |

Los recuentos suman 5106 frente a 1118 recursos de malla en los 12 entornos
medidos por separado. Los materiales pasan de 2285 a 308. Se comprobaron los
mismos vertices, nodos, instancias y huellas de posiciones y limites en cada
escenario: compartir recursos no elimina decorados ni geometria.

## Comprobarlo

```powershell
powershell -ExecutionPolicy Bypass -File maintenance/Run-Checks.ps1
```

Se puede pasar `-Godot 'ruta/al/ejecutable'`. Las comprobaciones incluyen las
reglas y carreras anteriores, junto a 8960 comparaciones del punto cercano
contra la busqueda exhaustiva, independencia de colores y limite de la cache.

`tests/performance.tscn` permite repetir las mediciones de CPU y recursos. Sus
JSON se escriben en `tools/`, fuera del repositorio. En otra maquina o version
del motor los tiempos pueden variar.
