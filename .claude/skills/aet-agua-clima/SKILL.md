---
name: aet-agua-clima
description: Propone agua, cascadas, lluvia, día/noche y clima atractivo y económico.
---

# aet-agua-clima — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Revisar shaders y sonidos existentes. Diseñar superficie de agua estilizada, cascada mediante mallas/partículas limitadas, lluvia por zonas y fog ligero compatible. Para día/noche, distinguir apariencia de ciclo real; revisar gastos de luz dinámica y alternativos horneados.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Entrega requerida
Tabla de efectos y coste visual, prototipo acotado y variante móvil de cada efecto.

## Restricciones especiales
No integrar clima global ni sistemas de ciclo temporal si el usuario no lo ha aprobado.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
