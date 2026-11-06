---
name: aet-meshy-blender
description: Prepara un pipeline de Meshy/Blender a Godot para personajes y props 3D.
---

# aet-meshy-blender — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Partir de turnaround limpio frontal/lateral/trasero, pose A/T, fondo blanco, accesorios y vestuario separados cuando convenga. Revisar licencia de modelos, orientación Y-up, escala, triángulos, UV, materiales, export glTF/GLB y topología del resultado de IA. Usar Blender para reparación, no asumir rig correcto desde foto.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Ampliación (Fase 2): proceso real ya probado en Aethelgard
Importar modelos de Meshy al escenario 3D sin que hundan el móvil:
1. Descomprimir el zip en una carpeta nueva del scratchpad (nunca dentro del proyecto) y abrirlo en un **mini
   proyecto de Godot aparte** para medir: triángulos, mallas, materiales, tamaño de texturas, huesos.
2. Presupuesto por tipo (perfil medio, Redmi A7 Pro): árbol grande ≤ 6 000 triángulos, arbusto ≤ 1 500,
   roca ≤ 800, casa ≤ 8 000, prop pequeño ≤ 500; texturas 1024 (512 en lejanía), formato importado ETC2/ASTC.
3. Reducir con el sistema de detalle de Godot (las LOD que genera el importador): elegir el nivel que cumple el
   presupuesto y guardarlo como malla propia (método de `pruebas/herramientas/reducir_modelo.gd`).
4. Follaje: alfa **recortado** (alpha scissor), nunca mezcla semitransparente masiva (overdraw en móvil).
5. Animaciones de otro esqueleto: redireccionar con BoneMap + SkeletonProfileHumanoid en el mini proyecto y
   hornear a los huesos originales (hecho con Garon: `garon_espadas.res`). Revisar los clips: los del pack
   «Dual-Blade» venían rotos (0,2 s) y se descartaron.
6. Licencias: anotar origen y licencia de cada modelo en `docs/recursos.md`; no subir FBX de paquetes que
   prohíban redistribuir (solo el resultado convertido).
7. Material: si la textura de emisión deja el modelo blanco en Compatibility, usar `material_arma.gd`.

### Cómo medir
- Captura en el mismo sitio antes/después y banco «TOPE» en el Redmi (30 FPS con 0 % de tirones en medio).

### Criterios de aceptación
- Cada modelo dentro de su presupuesto, sin parpadeos ni blancos, y el perfil medio sigue a 30 FPS estables.

### Reversión
- Los modelos nuevos se cargan por ruta; si falta el archivo, la escena usa la forma provisional actual.

## Entrega requerida
Checklist de importación de un personaje chibi y un prop pequeño, con fallos conocidos.

## Restricciones especiales
No sustituir los personajes Érebo y Garon ni riggear un único dibujo como si fuera modelo terminado.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
