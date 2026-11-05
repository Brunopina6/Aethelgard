---
name: aet-rendimiento-android
description: Mide el rendimiento real del JRPG 2.5D y propone escalones gráficos.
---

# aet-rendimiento-android — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Establecer baseline Android gama media, FPS 30 objetivo inicial no medido (60 opcional), tiempos frame CPU/GPU, memoria, batería, cargas, tamaño APK. Evaluar LOD, MultiMesh, lightmaps, visibilidad, textura, tamaño pantalla, overdraw, simulación de NPC y streaming. Probar en dispositivo real.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Ampliación: medición real (perfilador)
1. Medir con los monitores de Godot (`Performance.get_monitor`): `TIME_FPS`, `TIME_PROCESS`, `TIME_PHYSICS_PROCESS`, `RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `RENDER_TOTAL_PRIMITIVES_IN_FRAME`, `RENDER_VIDEO_MEM_USED` y `OBJECT_COUNT`.
2. Registrar cada medio segundo en `user://rendimiento_<escena>_<perfil>.csv` (tiempo, fps, ms_fotograma, ms_proceso, ms_fisica, dibujos, primitivas, memoria_video_mb). En Pastos Verdes lo hace el panel de rendimiento (tecla F3 o botón «RND»).
3. Siempre el mismo recorrido (`pruebas/prueba_sendero.gd`) y el mismo perfil de calidad. Anotar dispositivo, perfil y commit.
4. Aislar costes quitando UNA cosa cada vez (sombras, hierba, luces puntuales, relieve del terreno) y comparar la mediana de ms por fotograma, no un FPS suelto.
5. CPU o GPU: si ms_proceso + ms_fisica es bajo pero el FPS cae, el cuello es la GPU (relleno de píxeles, luces, sombreados).

### Criterios de aceptación
- Toda optimización trae tabla antes/después con mediana y percentil 95 de ms por fotograma, medidos en el dispositivo indicado.
- Ninguna rebaja visual sin demostrar que ese elemento era el cuello de botella.

### Pruebas
- Recorrido automático en PC (regresión) + sesión manual de 2 minutos en el móvil con su CSV.

## Entrega requerida
Informe con métricas efectivamente medidas, cuellos de botella y optimización coste/beneficio.

## Restricciones especiales
Nunca inventar FPS ni asumir que funciona en móvil solo porque corre en Windows.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
