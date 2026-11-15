# Revisión de personajes (V12, 15/11/2026)

Rama local `claude/v12-revision-personajes` (desde `claude/rebelum-v12` @ `7de9482`), sin subir. Encargo: comprobar con
capturas (revisadas una a una) que se conserva lo aprobado de Nix (FBX), de la capa articulada de Garon y de los
protagonistas v2/v3, y reparar solo defectos concretos y evidentes, sin rediseñar.

Todas las pruebas, con datos aislados (`ejecutar_pruebas.ps1`): `partida.save` real y carpeta real de datos **sin
cambios** en todas las pasadas. Había otros Godot de otras copias (otros agentes) abiertos, anotados en cada
`resumen.md`. **No se midió rendimiento.**

Capturas de la entrega: `D:\REBELUM_diagnostico\revision_personajes_15_11\` (`nix\`, `garon\`, `protagonistas\`).

## 1. Qué se ve bien (comprobado en capturas de Godot en el PC)

| Rasgo | Estado | Captura |
|---|---|---|
| Nix: diseño del vestuario (capucha con forro, capa corta, corpiño, faldones, medias, botas) | bien, igual que lo aprobado el 14/11 | `nix\hoja_estudio_1.png`, `hoja_estudio_despues_completa.png` |
| Nix: cara de cerca (ojos amatista, boca, flequillo, mechones) | bien; en el estudio de luz fuerte el pelo se ve muy claro (ya conocido, §9.5 del doc del piloto) | `nix\cara_estudio.png` |
| Nix: iris con emisión suave (combate y anochecer: dos puntos violetas, sin «faro») | bien | `nix\hoja_iris.png` |
| Nix: canalización (mechones arriba con retraso, faldones abiertos) | bien | `nix\hoja_estudio_2.png` (10-22) |
| Nix: emblema de la espalda (Horus en estrella de seis puntas) | bien | `nix\hoja_estudio_2.png` (24) |
| Nix: cetro en el socket al andar y correr (vertical, con el braceo; arreglo del §10) | bien; de perfil queda detrás de la cabeza y el brazo | `nix\correr_perfil_cetro.png` |
| Nix: combate real en la llanura (guardia, Ascuas, Aguja, Colapso) | bien; pies en el suelo, traje negro y púrpura | `nix\hoja_combate.png`, `nix\combate_guardia_cerca.png` |
| Nix: exploración en Pastos con Kael y Garon | bien | `nix\hoja_exploracion.png`, `nix\exploracion_cerca_quietos_zoom.png` |
| Nix: magia negra y **sin INVOCACIÓN** | bien: su menú es ATACAR/DEFENDER, MAGIA, OBJETO y HUIR con la Armonía llena; `_invocar` con Nix de actor vuelve al menú sin Érebo (comprobación nueva en `prueba_nix_v12`, con y sin `nix_fbx`) | registro de `prueba_nix_v12` |
| Garon: capa articulada, pieza independiente | bien: su propio `Skeleton3D` (EsqueletoCapa, 21 huesos) y `Skin`; «una sola capa» al crear, cambiar de versión, escena y padre (`prueba_capa_garon_estados`, 541 comprobaciones) | — |
| Garon: capa anclada a los hombros | bien: distancia capa-clavículas 0,172-0,173 / 0,179-0,180 / 0,155-0,156 m (original / v2 / v3), **varía 0,000 m (< 1 mm)** en todo el guion (`prueba_capa_garon`, 15/11 01:48) | — |
| Garon: capa móvil (arranque, parada, giros, ataque) | bien en las tres variantes: se queda atrás al arrancar, ondea al correr, se abre al girar, se asienta al parar; cruces 2 / 0 / 0 de 173 capturas (lo mismo que el 14/11: la espada izquierda roza en `giro_180_028` del original, dentro de la tolerancia) | `garon\hoja_movimiento_{originales,v2,v3}.png`, `garon\hoja_combate_{originales,v2,v3}.png` |
| Garon: dos espadas visibles en combate y en exploración | bien en las tres variantes (guardia, Juicio, Giro, victoria, andar, correr, parado) | `garon\hoja_combate_*.png`, `garon\garon_victoria_dos_espadas.png`, `protagonistas\garon_original_v2_v3_reposo_dos_espadas.png` |
| Garon: una sola ranura de arma (la segunda espada es visual) | sin cambios: `garon_3d.gd:22-23` (`RUTA_ESPADA_IZQ`, `DOS_ESPADAS`), `_nueva_espada` lee `inventario.arma_de("Garon")` para las dos | — |
| Kael, Lya y Garon (original, v2 y v3) de pie | bien: de pie, sin piezas sueltas | `protagonistas\hoja_de_pie.png` y una por héroe |
| Pies en el suelo (sonda nueva) | bien: hueso más bajo de cada pie a +0,023…+0,048 m (la altura de la articulación sobre la suela) en guardia y reposo, salvo lo anotado en §2 | `protagonistas\sonda_pies_espadas.log` |
| Puntas de las espadas de Garon v2/v3 en reposo de exploración | bien: +0,020 y +0,007 m (rozan el suelo, no lo atraviesan; en la foto parecen más bajas por la perspectiva) | mismo registro |

## 2. Defectos encontrados

| Defecto | Causa (demostrada) | Estado | Captura |
|---|---|---|---|
| **Nix: la mano del cetro no lo agarra** (dedos abiertos, el asta atraviesa la mano) en guardia, reposo y ataque | Pesos. Medido en Blender (`fuente_blender/p12_mano_medir.py`): el esqueleto común solo tiene en los dedos la cadena del corazón y la del pulgar; `RightHandMiddle1` tenía **0 vértices** y los cuatro dedos (11-19 cm desde la muñeca) iban casi todos a `RightHand`. Los clips sí cierran la mano (48° de media en los dedos de la derecha en 18 de 23 clips), pero la malla no los seguía | **ARREGLADO** (§3) | `nix\hoja_manos_antes.png`, `nix\godot_mano_antes_despues.png`, `nix\blender_mano_antes_despues.png` |
| Garon original: el pie derecho no baja de +0,096 m en guardia | la pose de guardia del original (mezcla de dos poses de su clip) | sin tocar: es el Garon original aprobado; no se nota en las capturas (pie atrasado) | `protagonistas\sonda_pies_espadas.log` |
| Nix: la capucha y el flequillo tapan a menudo un ojo en exploración (cámara alta) | forma de la capucha y del flequillo | **conocido**, necesita decisión artística | `nix\hoja_iris.png` (exploración) |
| Nix: más alta que los chibi del grupo | el juego la normaliza a la altura de los héroes adultos (1,7 m por los huesos) | **conocido**, decisión del usuario (§6 del doc del piloto) | `nix\combate_guardia_cerca.png` |

## 3. Arreglado: la mano del cetro de Nix (antes / después)

- `fuente_blender/p12_mano.py` (sobre una copia de `p11_capa.blend`, la fuente del GLB vigente): los vértices de los
  cuatro dedos de la mano derecha (no los del pulgar ni los de la palma) reparten su peso a lo largo del dedo:
  `RightHand` → `RightHandMiddle1` entre 10,8 y 13,2 cm (nudillo a 12 cm) y `Middle1` → `Middle2` entre 13,5 y
  15,9 cm (segunda falange a 14,7 cm). 57 vértices tocados; ≤ 4 pesos, normalizados, 0 sin peso.
- **Solo pesos:** misma malla (11.968 + 7.513 triángulos), mismos 54 huesos, mismos 23 clips, mismas texturas (los
  `.webp` no cambian) y la ropa igual. Comparando los GLB por vistas de búfer: solo cambian `cuerpo_nix.JOINTS_0` y
  `cuerpo_nix.WEIGHTS_0`; el JSON del GLB es idéntico. Tamaño 3.195.836 bytes (igual).
- **Determinista:** `p10_exportar.py` sobre la copia de `p11_capa.blend` reproduce el GLB vigente byte a byte
  (`69027f55…398a9d`); el nuevo sale igual dos veces (`b9b65e92…37fcc3`).
- **Reversible:** el GLB anterior, con su `.import` y el JSON, en `aethelgard/personajes/nix/fbx/anterior_15_11/`
  (con `.gdignore`, versionado como `anterior_14_11b/`). Para volver: copiar `anterior_15_11/nix_fbx.glb` encima e
  importar.
- Resultado: la mano se cierra en puño alrededor del asta en guardia, reposo y ataque (capturas arriba). La mano
  izquierda no se tocó (tiene `LeftHandMiddle1/2` con peso; en la guardia va abierta, como debe).
- Rehacer: `blender -b --factory-startup -P p12_mano.py -- <p11_capa.blend> <p12_mano.blend> <renders>` y
  `p10_exportar.py -- <p12_mano.blend> <glb>`; copiar el GLB a `personajes/nix/fbx/` e importar. Trabajo y renders:
  `D:\REBELUM_diagnostico\revision_personajes_15_11\nix\trabajo\`.
- **Queda** (fino, no evidente a la distancia del juego): visto desde dentro, el asta pasa por delante de los dedos
  cerrados en vez de por el hueco del puño; afinarlo pide mover el socket `arma_d` 1-2 cm hacia la palma en las pistas
  de los clips (23 clips), que no se ha hecho.

## 4. Pruebas (resultados literales)

Antes de los cambios (`D:\REBELUM_diagnostico\pruebas\2026-11-15_013519\resumen.md`):
`prueba_garon SUPERADA 7,2 s · prueba_magia_negra SUPERADA 15 s · prueba_nix_v12 SUPERADA 8,2 s ·
prueba_solo_lya_invoca SUPERADA 4,3 s · prueba_nix_fbx SUPERADA 2,7 s (63 OK, FALLOS: 0) ·
prueba_capa_garon_estados SUPERADA 46,4 s` → «SUPERADAS 6 · FALLIDAS 0».

Después (mano arreglada y comprobaciones nuevas):

| Pasada | Resultado | Resumen |
|---|---|---|
| `prueba_garon`, `prueba_magia_negra`, `prueba_nix_v12`, `prueba_solo_lya_invoca`, `prueba_nix_fbx`, `prueba_capa_garon_estados` | «SUPERADAS 6 · FALLIDAS 0 · MANUALES 0 · NO SEGURAS 0» | `2026-11-15_020009\resumen.md` |
| `prueba_nix_v12 -- nix_fbx` (combate real con la Nix del FBX) | «SUPERADAS 1 · FALLIDAS 0»; `OK A: menú de Nix ["carta", "MAGIA", "OBJETO", "HUIR"], sin INVOCACIÓN con la Armonía llena` | `2026-11-15_020122\resumen.md` |
| `prueba_nix_fbx` con la comprobación de los dedos | «SUPERADAS 1 · FALLIDAS 0»; `OK dedos de la mano del cetro con peso (vértices > 0,3: { "RightHandMiddle2": 69, "RightHandMiddle1": 71, "LeftHandMiddle1": 29 })`, 64 OK, `FALLOS: 0` | `2026-11-15_020217\resumen.md` |
| `prueba_capa_garon` (anclaje y resto de medidas de la capa) | «SUPERADA», `FALLOS: 0` | `2026-11-15_014845\resumen.md` |
| `herramientas/sonda_pies_espadas` (nueva) | «SUPERADA», `FALLOS: 0` | `2026-11-15_015012\resumen.md` |
| Capturas (MANUAL, revisadas): `fotos_nix_fbx` antes y después, `fotos_nix_fbx_combate`, `fotos_nix_iris`, `fotos_nix_revision`, `fotos_capa_garon_combate`, `fotos_capa_garon_movimiento` (+ `_v2`, `_v3`), `fotos_heroes_v3 partes=cerca,combate` | MANUAL | `2026-11-15_015134` (antes), `015900` (después), `014006`, `014145`, `014221`, `014329`, `014431`, `014802` |

`fotos_nix_iris` no está en `lista_pruebas.txt` (se lanzó con una lista propia); las listas propias están en la carpeta
temporal de la sesión.

No se hizo la contraprueba en Godot de la comprobación de los dedos con el GLB anterior (pide reimportar dos veces);
el antes está medido en Blender (`RightHandMiddle1`: 0 vértices) y visto en `hoja_manos_antes.png`.

## 5. Pendiente

**Redmi** (nada de esto se ha visto en el teléfono):
- Nix del FBX: aspecto y coste (19.481 triángulos, 2 materiales, iris) y la mano cerrada a la distancia del combate.
- Capa articulada: aspecto (4 pesos por vértice en Mali-G57) y coste de `colocar()` con subpasos en los giros
  (en el PC ~0,5 ms, medido de pasada con otros Godot: no es una medida de rendimiento).

**Decisión del usuario:**
- Altura de Nix junto al grupo chibi.
- Capucha y flequillo que tapan un ojo en exploración.
- Si encender por defecto `nix_fbx` y `capa_garon` (siguen APAGADOS; no se han tocado).

**Conocidos, sin corregir (sin cambios desde el 14/11):** texeles de la mandíbula bajo el cuello alto (solo de muy
cerca); faldones de 2 huesos que no se pliegan al arrodillarse (la derrota roza el suelo); rozamiento de una hoja con el
borde de la capa en Juicio/Giro (1-2 muestras, tolerado); derrota de Garon v2/v3 hundida por el clip (no es de la capa);
el asta por delante de los dedos cerrados vista desde dentro (§3).

**Para el coordinador (fuera de mis archivos):**
- `NIX_PILOTO_FBX.md` §9.7 y §6 dicen «`RightHandMiddle1` sigue sin pesos»: propongo añadir una línea «15/11:
  arreglado, ver `REVISION_PERSONAJES_15_11.md` §3».
- Al importar el proyecto, el editor reordena `oak_ferro_v` y `oak_ferro_sin_hierro` en `project.godot` y crea `.uid`
  que faltan en la rama (`oak_ferro_sin_hierro.dtl`, `invocacion_erebo_video.gd`, `fotos_erebo_video.gd`,
  `medir_erebo_teatro.gd`, `prueba_erebo_video.gd` y los dos `.ogv` de `videos/`). Los deshice; no son de esta área.
