---
name: aet-iluminacion-shaders
description: Mejora iluminación y shaders de fantasía sin depender de Forward+ en Android.
---

# aet-iluminacion-shaders — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Verificar renderer real. Comparar luz direccional, shadows, LightmapGI/baked lighting, fog, tonemapping y shaders estilizados; identificar SSAO, GI, sombras costosas y características incompatibles con Mobile/Compatibility. Proponer escena comparativa día dorado y zonas umbrías.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Ampliación: render móvil (terreno, agua, vegetación, luz)
1. Comprobar el renderizador real (`rendering/renderer/rendering_method` y su variante `.mobile`). Compatibility (OpenGL ES 3) es el actual; el renderizador Mobile (Vulkan/Metal) solo se propone para el perfil alto tras medirlo.
2. En Compatibility cada luz puntual u omni que toca un objeto lo vuelve a dibujar: preferir emisión y texturas de brillo, limitar `omni_range` y las luces visibles; apagarlas en el perfil bajo.
3. Terreno: una malla con color por vértice y textura de detalle; el relieve triplanar es caro (varias lecturas por píxel): solo en perfiles medio y alto.
4. Vegetación: MultiMesh, viento en el sombreado de vértices, sin transparencias masivas; densidad y `visibility_range_end` según el perfil.
5. Agua: un sombreado con normales de ruido; la refracción (textura de pantalla) solo en el perfil alto.
6. Cada técnica nueva: captura comparativa y coste medido con el perfilador de `aet-rendimiento-android`.

### Criterios de aceptación
- Tabla de efectos con coste medido y su versión por perfil (bajo, medio, alto).

## Entrega requerida
Perfiles de iluminación móvil y PC, riesgos por renderer y pruebas visuales/performance.

## Restricciones especiales
No prometer volumetric fog, SSAO o SDFGI sobre Android Mobile sin soporte comprobado.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
