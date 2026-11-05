---
name: aet-npc-fauna
description: Diseña mundo vivo con NPC y animales eficientes, con rutinas y estados.
---

# aet-npc-fauna — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Evaluar IA actual, navegación, diálogo y misiones. Rutinas simples por estados: caminar, comerciar, estar sentado, nadar si procede, pájaros y fauna. Detener/simplificar lógica fuera de cámara, streaming por sector y spawn controlado. Reusar sistema de entidades actual.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Entrega requerida
Plan de 1–2 NPC y 1 tipo de animal con presupuesto CPU, pruebas y persistencia.

## Restricciones especiales
No reescribir IA existente ni simular todos los habitantes del mundo al mismo tiempo.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
