# Verificacion de la entrega

Fecha: 2026-10-29. Motor: Godot 4.4.1, renderizador GL Compatibility.

Se ejecuto `powershell -NoProfile -ExecutionPolicy Bypass -File maintenance/Run-Checks.ps1`
con datos de pruebas aislados. El comando termino con codigo 0.

- Importacion del proyecto: correcta.
- Optimizacion: 8960 comparaciones exactas de puntos cercanos; reutilizacion
  de mallas, independencia de colores y limite de cache comprobados.
- Prueba funcional: 300 semillas deterministas; pantallas en ambos idiomas y
  temas, perfiles, entrada, colocacion, poderes, fisica, victoria, revancha y pausa.
- Expansion: los 12 escenarios completan carreras; dos perfiles, estadisticas,
  persistencia de apariencias, 16 combinaciones de objeto y propietario,
  restricciones de carril y presupuestos comprobados.

El entorno imprime `Failed to read the root certificate store` al iniciar
Godot. Las comprobaciones anteriores finalizan correctamente con ese mensaje.

Los 99 archivos originales se comparan con las huellas SHA256 del paquete
de fuente previo a la importacion. La entrega agrega este registro y el plan
de commits sin modificar el funcionamiento del juego. Git normaliza los
saltos de linea segun `.gitattributes`.

La serie contiene exactamente 66 commits con cambios, una sola raiz y una
historia lineal. El plan se encuentra en [COMMIT_PLAN.md](COMMIT_PLAN.md).
El historial excluye motores, caches, capturas, perfiles de pruebas y paquetes
generados. Esas exclusiones conservan las fuentes necesarias para reconstruir
el juego, incluidos sus escenarios, colores, patrones y equipo.
