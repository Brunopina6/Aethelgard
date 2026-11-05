---
name: aet-fisica-recorrido
description: Colisiones y recorrido del protagonista en las escenas 3D de Aethelgard; evita atascos en ríos, barrancos, paredes y puentes.
---

# aet-fisica-recorrido — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía en Godot con exploración 3D en pruebas (`prototipos/vista3d.gd`, `prototipos/sendero_puente.gd`). Control táctil (tocar o arrastrar) y teclado. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario.

## Procedimiento
1. Reproducir primero el atasco con una batería de casos (posición inicial, destino, FPS) y anotar «llega», «se para en sitio seguro» o «atascado».
2. Andabilidad: la misma regla de pendiente para subir y para bajar (ángulo máximo de la normal del suelo, p. ej. 40°) y un desnivel máximo por escalón.
3. Zonas prohibidas: agua, barrancos y canales marcados (función de zona o máscara); no se entra aunque el paso sea pequeño.
4. Destino táctil: si se toca un punto no andable, se usa el último punto andable de la línea hacia él.
5. Último punto seguro: se guarda al pisar suelo andable; si el personaje no avanza en 1 s o acaba fuera de zona, vuelve a él.
6. Pasos fijos: el movimiento de cada fotograma se divide en tramos cortos (≤ 0,15 m) para que sea igual a 20 que a 60 FPS.

## Criterios de aceptación
- La batería (río, canal, cascada, paredes, puente, bordes del mapa) termina siempre en «llega» o «se para en sitio seguro» a 20, 30 y 60 FPS. Ningún «atascado».
- El recorrido del camino y del puente sigue funcionando.

## Pruebas
- `pruebas/prueba_rio.gd` (batería) y `pruebas/prueba_sendero.gd` (recorrido), a 20, 30 y 60 FPS.

## Seguridad
- No tocar el movimiento de las zonas 2D del juego (`zona.gd`, `mapa.gd`) sin permiso.
- Cambios solo en los prototipos hasta que se apruebe integrarlos.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
