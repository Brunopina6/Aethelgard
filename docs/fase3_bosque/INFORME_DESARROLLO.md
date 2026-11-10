# INFORME DE DESARROLLO — Fase 3, «El bosque que no recuerda» (10/11/2026)

Rama LOCAL `claude/rebelum-bosque-fase3` (`D:\Aethelgard_fase3`), desde `integracion-experimental` @ `b4e26e2`. Sin push
ni fusión. Antes de empezar se cerró la fase 2: fusionada y subida a `integracion-experimental` (`b4e26e2`, batería
87/0).

## Estado de cada parte

| Parte | Estado | Dónde |
|---|---|---|
| Inicio con Tilo, árbol marcado y objetivo | **Implementado y probado** (automático, en la región real) | `zonas3d/bosque_pastos.gd`, `prueba_bosque_pastos` |
| Tres pistas en sitios distintos y conclusión de Lya | **Implementado y probado** | ídem |
| Senda oculta (Garon aparta las ramas tras la pista del rastro) | **Implementado y probado** | ídem |
| Nueve puntos de materiales (Hierba lunar, Musgo de piedra, Savia clara), cada uno una vez | **Implementado y probado** | ídem |
| Manantial (cura una vez por visita; +1 Hierba lunar la primera vez) | **Implementado y probado** | ídem |
| Ciervo de niebla (acontecimiento sin combate) | **Implementado**; probado que no rompe nada; su aspecto, en capturas | ídem, `fotos_bosque.gd` |
| Cofre de la senda (Esencia + 60 monedas, una vez) | **Implementado y probado** | ídem |
| Alquimia de Lya: pantalla, recetas, investigaciones, materiales, fabricar | **Implementado y probado** (en la región; capturas) | `alquimia_menu.gd`, `investigacion.gd`, `talleres.gd`, `datos/` |
| Objetos con efecto real: Poción, Esencia de enfoque, Elixir de savia purificada | **Implementado y probado** | `combate.gd`, `combate_bosque.gd`, `prueba_guardian_bosque` |
| Guardián: dos fases, avisos, coraza de raíces, debilidad al fuego, ventaja de Lya | **Implementado y probado** (combates automáticos) | `combate.gd`, `prueba_guardian_bosque` |
| Desenlace A (purificar con el Elixir en la fase 2) y B (derrotar) | **Implementado y probado** | ídem |
| Premios exclusivos sin duplicar; reintento tras perder | **Implementado y probado** (no duplicar); reintento por el sistema de combate fijo | ídem |
| Persistencia de todo (hitos, decisiones, inventario, investigaciones) | **Implementado y probado** (volcar, escribir, leer y recargar la región) | `prueba_bosque_pastos`, `prueba_investigacion` |
| Claro, árbol, Tilo y objetivo según el desenlace | **Implementado y probado** (purificado); derrotado, implementado sin prueba de la región | `bosque_pastos.gd` |
| Oakhaven: Encina según el desenlace y sus hierbas en la tienda | **Implementado y probado** (datos y diálogos); la tienda, sin prueba propia | `ciudades/oakhaven.gd`, `tienda.gd` |
| 15 diálogos y textos de avisos | **Implementado y probado** (narrativa) | `dialogos/bosque/`, `dialogos/notas/bosque.gd`, `prueba_dialogos_bosque` |
| Modelo 3D del Guardián | ver «Modelo 3D» abajo | `enemigos/guardian_bosque/` |
| Todo en el Redmi | **Pendiente de Redmi** | `PENDIENTES_REDMI.md` |

## Decisiones tomadas (sin preguntar, como pidió el usuario)

- **Canon:** el olvido que se contagia, sin decir qué es la niebla. Ni Érebo, ni recuerdos ni corazones en los textos
  de la aventura. El centinela del mirador no cambia. El orbe del altar no se usa: no tiene canon claro.
- **La aventura empieza tras `pv_14`.** Tilo deja de decir su despedida y abre el bosque. Por eso se actualizaron
  `prueba_ruta_alpha` y `prueba_centinela`, que esperaban el final de antes.
- **Purificar = usar el Elixir sobre el Guardián en su segunda fase.**
  - Es una acción jugable, en el menú OBJETO del combate.
  - En la primera fase no se gasta: avisa de que aún está demasiado fuerte.
  - Derrotarlo es el desenlace B.
- **Premios:**
  - **A:** el Brote del Guardián (regeneración y 2 PM por turno) y 2 Savias claras.
  - **B:** el Corazón de roble (material, se vende por 120) y la Corteza del Guardián (coraza pequeña al empezar).
  - Sin armas nuevas: la «Raíz de hierro» del diseño se cambió por la Corteza, que usa efectos que ya existen.
- **Equilibrio:** no se tocaron Kael, Lya ni Garon. El Guardián tiene 420 PV y 17 de ataque (Gorthor, 460 y 22): es
  un jefe temprano.
- **La investigación «La savia que recuerda» avanza con los combates ganados** (2), como proponía el diseño de la
  fase 2.
- **Economía:** todo lo fabricado o comprado cuesta más de lo que se saca vendiendo sus materiales. Ninguna receta da
  dinero.
- **El árbol marcado** reutiliza el árbol de copa con viento de la región. Las pistas, el manantial y las ruinas son
  formas sencillas, sin modelos de terceros.

## Correcciones durante el desarrollo

- **Al Guardián le faltaba su fila en `ANIM`:** el combate no podía moverlo.
- **Puntos de recogida demasiado cerca** del cofre de siempre y de las ruinas: el botón ofrecía lo otro. Ahora se
  separaron y el botón ofrece el más cercano.
- **Errores de sintaxis de GDScript** en el módulo nuevo y en la alquimia, encontrados por la prueba del recorrido.
- **El título de la alquimia se partía letra a letra**, y el árbol marcado parecía una seta. Visto en las capturas y
  corregido.
- **Sonido de cura inexistente:** se usa el del frasco.

## Modelo 3D del Guardián

Encargado al especialista de animaciones: Blender, geometría propia y gratis, sin Meshy. Rama `claude/f3-guardian-modelo`.
Hasta integrarlo:
- en el combate, el Guardián usa el respaldo 2D (el guardián de piedra grande y teñido de verde musgo);
- en la región, una figura de madera hecha con formas.

(Este apartado se completa al integrar su trabajo.)

## Sin hacer en esta fase

- Acceso a la alquimia desde el menú del juego. Hoy está en Pastos Verdes 3D, con Lya en el grupo.
- Forja de Kael y armaduras de Garon jugables. La base técnica sirve para ellas.
- Sonidos propios del Guardián (usa los de jefe) y música propia.
