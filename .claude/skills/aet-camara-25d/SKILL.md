---
name: aet-camara-25d
description: Diseña una cámara elevada inclinada 3/4 siguiendo al personaje para un JRPG 2.5D.
---

# aet-camara-25d — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Revisar cámara y movimiento originales. Comparar cámara ortográfica vs perspectiva suave con prototipo separado; interpolación, encuadre, límites, cambio de altura, oclusiones por árboles y paredes, zoom táctil si procede, interiores y transición a batalla. Mantener escala legible en pantalla Android.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Entrega requerida
Dos configuraciones justificadas, diagrama de rig y pruebas de casos difíciles con plan reversible.

## Restricciones especiales
No reemplazar la cámara de juego de producción sin prototipo aprobado.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
