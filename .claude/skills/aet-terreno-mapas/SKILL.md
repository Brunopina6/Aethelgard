---
name: aet-terreno-mapas
description: Evalúa y produce planes de terreno y mapas de fantasía Godot compatibles con Android.
---

# aet-terreno-mapas — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Comparar Terrain3D, ArrayMesh, MeshInstance3D y módulos de niveles, medir relieve, coste de materiales, colisiones, navegación, LOD, streaming y límite de altura/escala. Revisar versión exacta de Terrain3D, soporte Mobile/Compatibility y comportamiento Android; preparar alternativa ligera de camino, loma, puente y cascada.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Entrega requerida
Tabla de decisión con licencias/compatibilidad, layout de vertical slice y métricas propuestas.

## Restricciones especiales
No instalar Terrain3D ni importar terrenos grandes sin aprobar y probar dispositivo.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
