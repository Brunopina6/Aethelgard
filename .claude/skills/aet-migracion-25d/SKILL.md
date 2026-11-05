---
name: aet-migracion-25d
description: Planifica transición paulatina de escenas 2D actuales a exploración 2.5D sin romper sistemas.
---

# aet-migracion-25d — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Identificar qué lógica debe seguir siendo 2D y qué vistas pueden ser 3D; revisar patrones de nodos, señales, coordenadas, interacción, colisiones, guardados, navegación y combates. Comparar mundo híbrido/2D enriquecido/3D real. Evaluar adaptadores y compartición de datos en vez de reescribir autoloads.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Entrega requerida
Mapa de compatibilidad, matriz impacto, primer módulo aislado y estrategia de vuelta atrás.

## Restricciones especiales
Prohibido migrar todos los mapas o reemplazar escenas heredadas de golpe.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
