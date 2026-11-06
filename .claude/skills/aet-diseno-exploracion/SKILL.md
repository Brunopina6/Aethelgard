---
name: aet-diseno-exploracion
description: Diseño de niveles y exploración para las zonas 3D de Aethelgard (Pastos Verdes y siguientes) - lugares con sentido, secretos, caminos y decoración que sirve al juego.
---

# aet-diseno-exploracion — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía en Godot 4.7.2 (Compatibility), Android primero, iOS y PC después. Las zonas 3D se
prueban en `aethelgard/prototipos/` (Pastos Verdes: `sendero_puente.gd`); las zonas 2D del juego no se tocan sin
permiso. Cada tarea empieza en **solo lectura** hasta aprobación explícita. Respetar a Kael, Lya, Garon y Érebo.

## Principio
La decoración debe **decir algo al jugador**: guiarle, esconder algo, contar una historia o darle un sitio donde
pararse. Si un objeto no hace nada de eso, o no se pone o es barato (MultiMesh).

## Procedimiento
1. **Mapa de intención** antes de construir: dibujo en planta (texto o imagen) con el camino principal, 2–3
   desvíos, un punto de interés por cada ~20 m de recorrido y dónde mira la cámara de 45°.
2. **Tipos de lugar** (cada zona elige 3–5): mirador (vista lejana preparada), ruina con secreto, cruce de caminos
   con señal, refugio (NPC, descanso, guardado), obstáculo natural (río, barranco) con un paso, rincón escondido
   tras vegetación con recompensa.
3. **Guiado visual** sin flechas: luz cálida (halo de farol), contraste de color, caminos de losas, aves que
   vuelan hacia el destino, agua que señala la dirección.
4. **Secretos**: visibles desde lejos pero de acceso no evidente (como el cofre raro de la Garganta, visible desde
   los puentes). Cada secreto apunta a Progreso (lore, objeto) solo cuando se apruebe la integración.
5. **Recorrido seguro**: todo acceso nuevo pasa la batería de `aet-fisica-recorrido` (`pruebas/prueba_rio.gd`
   ampliada) a 20/30/60 FPS; los límites de zona no enseñan el borde del terreno.
6. **Densidad**: medir el coste de cada lugar con el banco «TOPE»; si baja de 30 FPS en el perfil medio del
   Redmi, se simplifica la decoración lejana antes que la cercana.

## Ejemplos para Aethelgard
- Pastos Verdes: mirador junto a la cascada desde el que se ve la isla flotante; ruinas de arcos con un altar de
  Érebo (secreto de lore); pequeño puesto con un mercader (NPC); conejos que huyen hacia una madriguera escondida.
- Garganta del Diablo 3D (futuro): los puentes como camino principal, cornisas como desvío, el nido visible.

## Herramientas y documentación
- Solo Godot: escenas de prueba en `prototipos/`, `pruebas/prueba_sendero.gd` (recorrido con fotos).
- Referencia: documentación de Godot sobre nodos 3D, `visibility_range` y MultiMesh.

## Limitaciones y compatibilidad
- Compatibility: nada de luces reales para guiar (cuestan ~3,5 ms cada una en el Redmi); usar emisión y halos.

## Riesgos Android / iOS
- Muchos objetos únicos = muchas llamadas de dibujo (CPU débil). Agrupar o usar MultiMesh (`aet-lod-mundo`).

## Cómo medir y aceptar
- Recorrido completo sin atascos (batería + `prueba_sendero.gd`), banco «TOPE» en el Redmi (medio a 30 FPS,
  0–1 % de tirones) y capturas de cada lugar desde la cámara de juego.

## Reversión
- Cada lugar en una función propia de la escena de prueba y un commit propio; quitarlo = no llamar a la función.

## Formato de respuesta
**Hechos → Mapa de intención → Lugares propuestos → Costes medidos → Riesgos → Aprobación**. En español.
