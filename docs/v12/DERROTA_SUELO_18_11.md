# Derrota de los protagonistas bajo el suelo: diagnóstico (18/11)

Pendiente de `REVISION_PERSONAJES_15_11.md` («derrota de Garon v2/v3 hundida por el clip»). Herramienta nueva:
`aethelgard/pruebas/diag_derrota_suelo.gd` (diagnóstico, no está en la lista de pruebas). Para cada héroe y versión
llama a `morir()` y, durante 6 s, mide el vértice con piel más bajo respecto al punto más bajo de pie, la cadera y el
hueso que manda en ese vértice. PC, sin ventana, `--fixed-fps 30`.

| Héroe | Versión | Hundido al final (derrota) | Peor de paso | Cadera tumbado | Lo más bajo |
|---|---|---|---|---|---|
| Kael | originales | 0,127 m | 0,13 m | 0,166 m | cabeza |
| Kael | v2 | 0,221 m | 0,22 m | 0,091 m | cabeza |
| Kael | v3 | 0,283 m | 0,28 m | 0,091 m | cabeza |
| Lya | originales | 0,265 m | 0,27 m | 0,223 m | `Bone_005` |
| Lya | v2 | 0,071 m | 0,38 m (derribo, 0,7 s) | 0,355 m | `Bone_005` |
| Lya | v3 | 0,143 m | 0,49 m (derribo, 0,7 s) | 0,355 m | `Bone_005` |
| Garon | originales | 0,018 m | 0,06 m | 0,202 m | cabeza |
| Garon | v2 | 0,293 m | 0,29 m | 0,039 m | cabeza |
| Garon | v3 | 0,557 m | 0,56 m | 0,039 m | cabeza |

**Causa en los v2 y v3** (`heroes_v2/fuentes_blender/biblioteca_clips.py`, `_suelo_base`): la pose tumbada gira la
cadera −86°, la columna −4° y la cabeza −6° hacia atrás: la cabeza queda por debajo de la horizontal y atraviesa el suelo.
La bajada de la cadera (−0,74 m para 1,7 m) es la misma para todos, así que a Garon, más ancho, le deja la cadera a 4 cm
del suelo. En los v3 la cabeza es más grande (y el yelmo de Garon más aún): por eso se hunden más que los v2 con el mismo
clip. No es de Garon solo: Kael y Lya también se hunden.

**Arreglo propuesto (sin hacer):** en `_suelo_base`, la cabeza hacia delante (barbilla al pecho) en vez de hacia atrás y,
en el constructor, apoyar la pose tumbada en el suelo midiendo el vértice más bajo del modelo ya deformado (la altura de
la cadera sale sola para cada héroe y versión). Exige reconstruir los 3 GLB v2 (`construir_heroe.py`) y los 3 v3, volver a
importar y repetir esta medida y las pruebas de héroes y de la capa. **No se ha hecho**: los v2 y v3 son prototipos que
se eligen en Ajustes (por defecto, los originales) y seguir o no con los v3 espera la decisión del usuario
(`INFORME_EXPANSION.md`). Además, `garon_v2.glb` es de antes del último cambio de la biblioteca (`cb82455`): al
reconstruirlo entrarían también esos cambios.

**En los originales** (los que se ven por defecto) los clips son de captura (Meshy): Kael mete la cabeza 0,13 m y Lya el
hueso `Bone_005` 0,27 m. Corregirlos exigiría tocar esos clips o subir el modelo en Godot durante la derrota; queda anotado.

## Detalle de los originales (por defecto en el juego)

Por hueso, en el último instante de la derrota (metros bajo los pies; negativo = bajo el suelo):
- **Kael** (clip de captura «Death», `kael_3d.gd`): solo la cabeza, −0,13; lo demás, de +0,03 a +0,07 (piernas, brazos).
  Subir el cuerpo entero lo dejaría flotando unos 10 cm: lo que hace falta es levantar la cabeza (un gesto en el hueso
  `Head` mientras está muerto, como los gestos que ya usa `maga_3d.gd`).
- **Lya** (sin clip: `maga_3d.gd.morir()` la desploma entera con un tween, −84° en z y posición (−0,88, 0,1, 0)): se hunde
  todo el lado izquierdo: `Bone_005` −0,26, `Bone_018` −0,23 (falda o pelo), muslo izquierdo −0,21, pierna −0,15, pie
  −0,10. Subir el destino del tween unos 0,2 m la apoyaría; habría que mirar que el resto no flote.
- **Garon**: −0,02, no se ve.

Capturas (sin suelo, solo la pose): `D:\REBELUM_diagnostico\derrota_suelo_18_11\antes\` (16_kael_combate_ko,
45_lya_combate_ko). Para decidir hace falta verlo en el combate con su terreno: a 12° desde arriba, lo que queda bajo el
suelo se recorta. Siguiente paso: capturas en el combate real antes y después de cada corrección.

## Hecho: Lya original apoyada en el suelo (18/11)

`maga_3d.gd.morir()`: el destino del desplome pasa de y 0,1 a **0,3** (un solo número). Medido (`diag_derrota_suelo`,
`solo=lya`): lo más bajo pasa de −0,26 a **−0,07 m** (borde de `Bone_005`, falda o pelo); muslo izquierdo de −0,21 a −0,01.
En el combate real (`fotos_derrota_combate.gd`, nueva, 1600×720): antes, el borde de abajo del cuerpo salía cortado en
recto contra la hierba (medio enterrada); después se ve entera, tumbada encima. Capturas: `D:\REBELUM_diagnostico\derrota_suelo_18_11\antes_combate`
y `D:\REBELUM_diagnostico\derrota_suelo_18_11\despues_combate_0.3` (hoja_derrota_lya_originales.png). `revivir()` vuelve a la posición 0 como antes.
Kael original (la cabeza, −0,13 m) no se ha tocado: en esta cámara cae detrás de Garon y no se distingue.
