---
name: aet-texturas-materiales
description: Diseña materiales y texturas estilizadas de alta calidad con presupuesto móvil.
---

# aet-texturas-materiales — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Auditar resolución actual, filtros, mips, atlas, formatos/compression ETC2/ASTC según dispositivo y renderer, repetición, anisotropía, albedo, normal y roughness cuando convenga. Comparar coste visual de materiales transparentes, vegetación y sombras. Priorizar caminos, piedras, madera, agua y ropa de personajes.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Entrega requerida
Guía de materiales con variantes de calidad y plan de transición asset por asset.

## Restricciones especiales
No aumentar todas las texturas a 4K ni cambiar imports globalmente sin mediciones.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
