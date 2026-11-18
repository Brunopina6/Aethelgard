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
