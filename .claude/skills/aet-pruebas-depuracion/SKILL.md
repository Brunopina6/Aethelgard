---
name: aet-pruebas-depuracion
description: Establece tests GDScript, depuración sistemática y regresiones.
---

# aet-pruebas-depuracion — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Comprobar versión Godot, cobertura de tests y potencial GUT compatible. Proponer pruebas para movimiento, combate, inventario, diálogo, transiciones, slots, estados NPC y export. Usar metodología reproducir-aislar-hipótesis-verificar y revisar importación de proyecto cuando se autorice.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Entrega requerida
Plan de tests priorizados con comandos/entornos exactos solo si son verificables.

## Restricciones especiales
No instalar GUT ni ejecutar comandos que escriban dentro del proyecto durante auditoría.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
