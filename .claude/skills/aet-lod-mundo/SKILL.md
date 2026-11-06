---
name: aet-lod-mundo
description: Niveles de detalle, agrupación, MultiMesh por zonas, culling y memoria para que las zonas 3D de Aethelgard crezcan sin perder FPS en móvil.
---

# aet-lod-mundo — Aethelgard

## Contexto obligatorio
Godot 4.7.2, renderizador Compatibility (OpenGL ES 3). Móvil de pruebas: Redmi A7 Pro (Unisoc UMS9230E, Mali-G57,
4 GB). El perfil medio debe mantener 30 FPS con tope y 0–1 % de tirones (banco «TOPE»). Solo lectura hasta aprobación.

## Lo que ya sabemos (medido en Aethelgard)
- La CPU del Redmi sufre con las **llamadas de dibujo**: pasar de ~600 a ~150 dibujos fue la mayor mejora del PC.
- Agrupar piezas estáticas del mismo material (puente, rocas, montañas) en una malla: sin cambio visual.
- Cada copa de árbol en una malla, pero cada árbol independiente: se recorta solo y se vuelve transparente solo.
- Hierba en trozos de 12 m con `visibility_range_end` por perfil: no se dibuja lo que está fuera o lejos.

## Procedimiento
1. Medir antes (banco «TOPE» y «PRUEBA», dibujos y triángulos) en el sitio más cargado de la zona.
2. **Agrupar** solo lo estático, cercano entre sí y del mismo material (función `_al_lote` de
   `prototipos/sendero_puente.gd`). No agrupar cosas repartidas por toda la zona si son caras: se pierde el recorte.
3. **MultiMesh** para lo repetido (hierba, flores, losas, arbustos, rocas pequeñas), en trozos con su centro como
   origen (si no, `visibility_range` no funciona por trozo).
4. **Niveles de detalle**: usar las LOD automáticas del importador de Godot para modelos de Meshy; comprobar el
   nivel elegido con `mesh_get_surface` y fijar un presupuesto (ver `aet-meshy-blender`).
5. **HLOD**: lo lejano (montañas, castillos, la isla) como mallas simples o tarjetas pintadas; nunca el modelo real.
6. **Ocultación**: probar OccluderInstance3D solo en zonas cerradas (pueblos, mazmorras) y medir; en campo abierto
   apenas ayuda.
7. **Memoria y carga**: texturas 1024 como máximo cerca y 512 lejos; zonas grandes divididas en trozos que se cargan
   al acercarse (carga en segundo plano como `Recursos.cambiar_escena`). Medir memoria de vídeo con el panel.

## Herramientas y documentación
- Godot: MultiMeshInstance3D, GeometryInstance3D.visibility_range_*, importador 3D (LOD), OccluderInstance3D,
  ResourceLoader.load_threaded_request. Documentación oficial «Optimizing 3D performance».

## Limitaciones y compatibilidad
- Sin GPU timing fiable en el Mali del Redmi (el driver devuelve basura): medir por tiempo de fotograma.
- La ocultación por oclusión usa CPU; en móviles débiles puede costar más de lo que ahorra (medir).

## Riesgos Android / iOS
- Agrupar demasiado = mallas enormes siempre visibles. Trocear demasiado = demasiados dibujos.
- iOS (futuro, Metal): mismas reglas; medir en el dispositivo.

## Cómo medir y aceptar
- Tabla antes/después del banco con dibujos, triángulos, mediana, p95 y tirones; capturas sin cambio visual.

## Reversión
- Cada técnica detrás de una constante o un parámetro del perfil; un commit por técnica.

## Formato de respuesta
**Medición antes → Técnica → Medición después → Impacto visual → Aprobación**. En español.
