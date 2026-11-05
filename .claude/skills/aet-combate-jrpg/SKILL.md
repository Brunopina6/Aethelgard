---
name: aet-combate-jrpg
description: Refina feedback de combates JRPG manteniendo scripts y reglas originales.
---

# aet-combate-jrpg — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Mapear turnos/tiempo real real del juego, control de daño, estados, IA de enemigos, UI, cámara y transición, sin inferir sistema no visto. Proponer golpes, partículas, hit-stop moderado, claridad de ataques, sonidos y cámara de combate 3D solo si viable. Planificar tests para reglas/guardados.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Entrega requerida
Tabla de regresiones más mejora pequeña aprobable y criterios de combate.

## Restricciones especiales
No reemplazar el sistema de combate existente por otro elegido arbitrariamente.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
