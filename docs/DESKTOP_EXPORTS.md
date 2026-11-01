# Windows, macOS y Linux

El código del juego usa GDScript y recursos nativos de Godot 4.4.1. Mantiene
el renderizador Compatibility y no depende de DLL, GDExtension, Python,
fuentes instaladas ni rutas de Windows. Los perfiles siguen usando
`user://profiles.cfg`, que Godot resuelve para cada sistema.

## Ejecutar el proyecto

- Windows: `Play.cmd` o importar `project.godot` en Godot 4.4.1.
- Linux: instalar Godot 4.4.1 y ejecutar `sh Play.sh`.
- macOS: instalar Godot 4.4.1 y ejecutar `sh Play.sh`; detecta
  `/Applications/Godot.app/Contents/MacOS/Godot`.

Los lanzadores aceptan `GODOT_BIN` si el motor está en otra ubicación.
El editor también permite abrir y ejecutar el mismo proyecto en los tres SO.
La base gráfica exige un controlador compatible con OpenGL 3.3; los mínimos
del motor no equivalen a un objetivo de FPS de este juego. Véanse los
[requisitos oficiales de Godot 4.4](https://docs.godotengine.org/en/4.4/about/system_requirements.html).

## Exportar aplicaciones

`export_presets.cfg` incluye:

| Preset | Destino | Arquitectura |
| --- | --- | --- |
| Windows | `builds/windows/MarbleOverdrive.exe` y PCK | x86_64 |
| Linux | `builds/linux/MarbleOverdrive.x86_64` y PCK | x86_64 |
| macOS | `builds/macos/MarbleOverdrive.zip` | Universal: Intel + Apple Silicon |

Instala las **plantillas de exportación 4.4.1** desde el editor, crea las
carpetas de destino y usa Proyecto → Exportar, o:

```sh
godot --headless --path . --export-release Windows
godot --headless --path . --export-release Linux
godot --headless --path . --export-release macOS
```

En Windows puede usarse la ruta del ejecutable local en lugar de `godot`.
Las plantillas no están incluidas ni se descargaron con este rediseño.
Todos los presets excluyen pruebas, capturas, registros y herramientas.
`builds/`, `dist/` y las credenciales de exportación están fuera de Git.

Para macOS se usa ZIP, que conserva los permisos requeridos al exportar
desde Windows. Las plantillas oficiales generan un binario Universal 2.
Los presets actuales no firman ni notarizan aplicaciones: esa configuración
y sus credenciales se preparan antes de distribuir públicamente en macOS.
Consultar la [guía oficial de exportación para macOS](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_macos.html).

## Qué está comprobado

Se generaron los paquetes de datos de los tres presets con `--export-pack`
y se verificó que excluyen archivos de desarrollo. Cada ZIP ocupa unos
160 KiB **sin el ejecutable del motor**. El paquete de Windows abre con
render gráfico usando el motor instalado. Esto valida recursos y rutas,
pero un ZIP de datos no es una aplicación independiente.

No hay aplicaciones nativas finales de macOS/Linux comprobadas en esta
máquina. Antes de publicar, exportar con las plantillas correctas y probar
en cada SO: inicio, perfiles, controles, audio, pantalla completa, los dos
temas, español/inglés, carreras, pausa y cierre. En Mac probar Intel y
Apple Silicon si ambos se incluyen en la distribución.
