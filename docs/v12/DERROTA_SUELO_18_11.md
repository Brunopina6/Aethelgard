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

**También heredan este desplome** (no tienen `morir()` propio): ~~Naira, Nix y~~ Érebo. ~~Medido con 0,3:~~ Naira, lo más bajo
−0,11 m (cadera y astrolabio~~; con 0,1 serían unos −0,31~~); Nix, +0,03 m (prácticamente apoyada~~; con 0,1, unos −0,17~~).
~~El cambio mejora a los tres; Naira sigue algo hundida y queda anotado.~~ Érebo no se ha medido (su derrota es la de su
combate propio).
*(19/11: lo tachado es falso. Naira y Nix tienen su propio `morir()` desde el 12-13/11 y no usan el desplome; las dos
cifras sin tachar eran de sus clips y se repiten hoy. Ver «Naira y Nix medidas el 19/11», al final.)*

## Érebo: no se mide, porque nunca cae (18/11, tarde)

Comprobado en el código antes de medir nada: **Érebo nunca ejecuta `morir()` en el juego.**
- Solo se crea en la invocación de Lya: `invocacion_erebo.gd` (`_preparar`, `load("res://erebo_3d.gd").new()`), y la
  híbrida crea el suyo (`invocacion_erebo_hibrida.gd`). Ninguna invocación (`invocacion_base.gd`, `invocacion_erebo*.gd`,
  `vfx/erebo_cabeza_firme.gd`, `erebo_orbe_v12.gd`) llama a `morir()` sobre él. Al acabar, sale con su clip y se libera.
- No es un combatiente: no está en `heroes` ni en `enemigos` de `combate.gd`, ni en `MODELOS`, ni en ningún grupo de
  enemigos. Por eso no tiene vida que pueda llegar a 0. No existe un «combate propio» de Érebo (lo que se decía arriba
  era incorrecto).
- El único `morir()` dentro de la invocación (`combate.gd`, `_resultado_erebo`, `doble.morir()`) es el del **doble del
  enemigo** que recibe el golpe, no el de Érebo.

Que herede el desplome de `maga_3d.gd` no tiene efecto visible: **no se mide** con `diag_derrota_suelo.gd`.

## Cómo ver las derrotas en el teléfono (18/11, tarde)

Desde hoy, el banco de pruebas tiene dos casos nuevos. Solo existen en la APK de Auditoría y en el editor.
- «Derrotas: los héroes empiezan casi sin vida» (Kael, Lya y Garon).
- «Derrotas de Naira y Nix (casi sin vida)» (Kael, Naira y Nix).

Cómo funcionan (`banco_pruebas.gd`, `preparar_combate`, clave `casi_sin_vida`):
- Los héroes entran con 1 PV y casi sin velocidad.
- Los tres slimes empiezan con la barra de turno llena, así que golpean antes de que se abra ningún menú.
- Cada golpe derriba a un héroe y se ve su `morir()`. Frostfang no cuenta porque Kael no llega a atacar: D-017 sigue igual.
- Al caer todos llega la derrota de siempre («Derrota...») y se vuelve solo al banco. Todo queda en la partida del banco.

Para comparar versiones se usa el selector «Protagonistas». Pasos en `GUION_REDMI_19_11.md`.

Comprobado en el PC con `prueba_banco_derrotas` (sin ventana). Clip que suena en el instante de `morir()`:

| Versión | Kael | Lya | Garon |
|---|---|---|---|
| Originales | `dying_backwards` | desplome con tween, sin clip | `Morir` |
| v2 | `derribo` | `derribo` | `derribo` |
| v3 | `derribo` | `derribo` | `derribo` |

En el caso de Naira y Nix: Kael `dying_backwards`, Naira `derrota` y Nix `derribo`.

**Ojo con lo de arriba:** en el combate, Naira y Nix ejecutan su **propio** `morir()`, que reproduce sus clips
(`personajes/naira/naira_3d.gd` y `personajes/nix/nix_3d.gd`). No usan el desplome de `maga_3d.gd`. Por tanto, la frase
«heredan este desplome» y sus cifras (con 0,3 frente a 0,1) quedan en duda. No se ha vuelto a medir: hay que revisarlo
con `diag_derrota_suelo` (`solo=naira` y `solo=nix`) antes de tomar decisiones con esas cifras.
*(Revisado el 19/11: sección siguiente.)*

## Naira y Nix medidas el 19/11

**Lo que pasaba.** `naira_3d.gd` y `nix_3d.gd` tienen su `morir()` desde el 12-13/11 (`73a4cef`, `04077ef`), así que
`diag_derrota_suelo` ya medía el 18/11 sus clips y no el desplome de `maga_3d.gd`: las cifras de entonces (Naira −0,11,
Nix +0,03) eran buenas, pero lo de «heredan», «con 0,3 / con 0,1» y «el cambio mejora a los tres» era falso (tachado
arriba). El paso de 0,1 a 0,3 en `maga_3d.gd` **no les afecta**.
- Naira (`naira_3d.gd`, l. 194): clip `derrota` (1,6 s, sin bucle): **cae de rodillas y se queda así**, no se tumba.
- Nix (`nix_3d.gd`, l. 299): `derribo` (1,5 s) y después `derrota` en bucle (3 s): **también de rodillas**.

**Herramientas tocadas (no el juego).**
- `pruebas/diag_derrota_suelo.gd`: mide además **por partes** (cabeza, manos, pies, cadera, arma y resto) respecto al
  suelo (y = 0, el origen del nodo): lo más bajo en toda la caída, lo más bajo ya en el suelo (de 2 s a 6 s, más de una
  vuelta del bucle de Nix) y, en el último instante, qué parte de los vértices de cada parte queda bajo el suelo. Cada
  vértice va a la parte de su hueso principal o de sus padres (el pelo y el sombrero cuentan como cabeza). El arma incluye
  los huesos `arma_d` y `astrolabio` y las mallas sin piel colgadas del esqueleto (el cetro por socket). Nuevo caso
  `nix fbx` (la Nix del FBX, interruptor `nix_fbx`, que en Auditoría se puede encender en Ajustes). La cadera de Naira se
  llama `cadera`: antes salía `+inf`. Las líneas de Kael, Lya y Garon siguen saliendo igual, con la línea de partes
  añadida (comprobado con `solo=lya`).
- `pruebas/fotos_derrota_combate.gd`: `heroe=Naira|Nix` monta el caso del banco «Derrotas de Naira y Nix» (Kael, Naira y
  Nix con sus interruptores solo en esa sesión, nivel 12, grupo 1 de slimes y la llanura) y `versiones=originales,fbx`.
  Para ellas toma más instantes: 0,5 · 0,7 · 0,8 · 0,9 · 2 · 4 s. En «ko» guarda también la pantalla entera.

**Cifras** (PC, sin ventana, `--fixed-fps 30`, en metros del modelo normalizado a 1,7 m, como el resto del documento;
negativo = bajo el suelo):

| Personaje | Parte | Peor en la caída | Ya en el suelo (2-6 s) | Último instante: bajo el suelo |
|---|---|---|---|---|
| Naira | cabeza | +0,746 | +0,746 | 0 % |
| Naira | manos | +0,190 | +0,190 | 0 % |
| Naira | pies | **−0,143** (a los 0,8 s) | +0,004 | 0 % |
| Naira | cadera | **−0,109** (1,2 s) | **−0,109** | 7 % (de −0,109 a +0,556) |
| Naira | astrolabio (su «arma») | **−0,097** (1,3 s) | **−0,097** | **48 %** (de −0,097 a +0,085) |
| Naira | resto (piernas…) | −0,004 | −0,004 | 0 % |
| Nix (`nix.glb`, la de siempre) | cabeza (con el sombrero) | +0,765 | +0,765 | 0 % |
| Nix | manos | +0,399 | +0,399 | 0 % |
| Nix | pies | −0,031 (0,5 s) | +0,078 | 0 % |
| Nix | cadera | +0,269 | +0,269 | 0 % |
| Nix | bastón (`arma_d`) | +0,165 (0,2 s) | +0,375 | 0 % |
| Nix | resto (piernas) | +0,027 | +0,028 | 0 % |
| Nix del FBX (`nix_fbx`) | cabeza | +0,912 | +0,912 | 0 % |
| Nix del FBX | manos | +0,469 | +0,469 | 0 % |
| Nix del FBX | pies | −0,030 (0,5 s) | +0,056 | 0 % |
| Nix del FBX | cadera | +0,431 | +0,432 | 0 % |
| Nix del FBX | cetro (por socket, `cetro_nix`) | +0,471 | +0,471 | 0 % |
| Nix del FBX | resto (piernas, faldones) | +0,058 | +0,075 | 0 % |

De pie: Naira −0,003, Nix −0,012 y Nix del FBX +0,014. La Nix del FBX lleva el cetro propio porque en la medida no tiene
arma equipada; con otra arma del inventario no se ha medido.

Salidas literales (`D:\REBELUM_diagnostico\derrotas_19_11\diag_naira.txt` y `diag_nix.txt`; `diag_lya.txt` es la
comprobación de que los demás siguen igual):
```
naira  originales de pie -0.003 m · cuerpo más bajo -0.143 m (a los 0.8 s) · al final -0.109 m · hundido bajo los pies 0.106 m · cadera más baja +0.413 m · lo más bajo, del hueso cadera
    bajo los pies, por hueso: cadera -0.11, astrolabio -0.09, pierna.L -0.00, pierna.R -0.00, pie.L +0.01, pie.R +0.02, muslo.R +0.03, muslo.L +0.03
    por partes, respecto al suelo (y = 0), peor en la caída · peor tumbado (2-6 s) · en el último instante: cabeza +0.746 (a los 1.7 s) · tumbado +0.746 (cabeza) · al final 0 % bajo el suelo, de +0.746 a +1.177; manos +0.190 (a los 1.7 s) · tumbado +0.190 (mano.L) · al final 0 % bajo el suelo, de +0.190 a +0.314; pies -0.143 (a los 0.8 s) · tumbado +0.004 (pie.L) · al final 0 % bajo el suelo, de +0.004 a +0.195; cadera -0.109 (a los 1.2 s) · tumbado -0.109 (cadera) · al final 7 % bajo el suelo, de -0.109 a +0.556; arma -0.097 (a los 1.3 s) · tumbado -0.097 (astrolabio) · al final 48 % bajo el suelo, de -0.097 a +0.085; resto -0.004 (a los 1.7 s) · tumbado -0.004 (pierna.L) · al final 0 % bajo el suelo, de -0.004 a +0.936
nix    originales de pie -0.012 m · cuerpo más bajo -0.031 m (a los 0.5 s) · al final +0.029 m · hundido bajo los pies 0.000 m · cadera más baja +0.520 m · lo más bajo, del hueso mixamorig_RightLeg
    bajo los pies, por hueso: mixamorig_RightLeg +0.04, mixamorig_LeftLeg +0.05, mixamorig_RightFoot +0.09, mixamorig_LeftFoot +0.09, mixamorig_RightToeBase +0.12, mixamorig_LeftToeBase +0.13, mixamorig_RightUpLeg +0.16, mixamorig_LeftUpLeg +0.17
    por partes, respecto al suelo (y = 0), peor en la caída · peor tumbado (2-6 s) · en el último instante: cabeza +0.765 (a los 1.5 s) · tumbado +0.765 (mixamorig_Head) · al final 0 % bajo el suelo, de +0.775 a +1.766; manos +0.399 (a los 1.5 s) · tumbado +0.399 (mixamorig_RightHand) · al final 0 % bajo el suelo, de +0.403 a +0.620; pies -0.031 (a los 0.5 s) · tumbado +0.078 (mixamorig_RightFoot) · al final 0 % bajo el suelo, de +0.078 a +0.218; cadera +0.269 (a los 1.5 s) · tumbado +0.269 (mixamorig_Hips) · al final 0 % bajo el suelo, de +0.273 a +0.689; arma +0.165 (a los 0.2 s) · tumbado +0.375 (arma_d) · al final 0 % bajo el suelo, de +0.378 a +0.623; resto +0.027 (a los 1.5 s) · tumbado +0.028 (mixamorig_RightLeg) · al final 0 % bajo el suelo, de +0.031 a +0.950
nix    fbx        de pie +0.014 m · cuerpo más bajo -0.030 m (a los 0.5 s) · al final +0.056 m · hundido bajo los pies 0.000 m · cadera más baja +0.550 m · lo más bajo, del hueso mixamorig_LeftFoot
    bajo los pies, por hueso: mixamorig_LeftFoot +0.04, mixamorig_RightFoot +0.04, mixamorig_RightLeg +0.06, mixamorig_LeftLeg +0.07, faldon_i_2 +0.07, faldon_d_2 +0.08, mixamorig_LeftToeBase +0.13, mixamorig_RightToeBase +0.14
    por partes, respecto al suelo (y = 0), peor en la caída · peor tumbado (2-6 s) · en el último instante: cabeza +0.912 (a los 1.5 s) · tumbado +0.912 (mixamorig_Head) · al final 0 % bajo el suelo, de +0.927 a +1.322; manos +0.469 (a los 1.5 s) · tumbado +0.469 (mixamorig_RightHand) · al final 0 % bajo el suelo, de +0.480 a +0.632; pies -0.030 (a los 0.5 s) · tumbado +0.056 (mixamorig_LeftFoot) · al final 0 % bajo el suelo, de +0.057 a +0.211; cadera +0.431 (a los 1.5 s) · tumbado +0.432 (mixamorig_Hips) · al final 0 % bajo el suelo, de +0.437 a +0.670; arma +0.471 (a los 1.5 s) · tumbado +0.471 (malla cetro_nix) · al final 0 % bajo el suelo, de +0.481 a +0.604; resto +0.058 (a los 0.7 s) · tumbado +0.075 (mixamorig_RightLeg) · al final 0 % bajo el suelo, de +0.076 a +1.099
```

**En la cámara del combate** (`fotos_derrota_combate.gd`, con ventana, 1600×720; el caso del banco con sus slimes).
Capturas en `D:\REBELUM_diagnostico\derrotas_19_11\combate\`:
- hojas: `hoja_derrota_naira_originales.png`, `hoja_derrota_nix_originales.png`, `hoja_derrota_nix_fbx.png`, con reposo y
  los instantes 0,5 · 0,7 · 0,8 · 0,9 · 2 · 4 s;
- pantallas enteras a los 2 s: `*_ko_pantalla.png`;
- ampliaciones de Naira: `zoom_naira_cae_0.7.png`, `zoom_naira_cae_0.8.png`, `zoom_naira_cae_0.9.png` y
  `zoom_naira_ko_astrolabio.png`. Las demás `zoom_*` de la carpeta son de una primera pasada con otros enemigos (Grimfang):
  no cuentan.

Lo que se ve:
- **Naira.** Cae de rodillas con la cabeza gacha. El astrolabio queda delante de la rodilla y **se ve entero** sobre la
  hierba, sin corte. Los pies hacia los 0,8 s no se ven cortados. La cadera (−0,11) queda tapada por la capa y las
  piernas.
- **Nix y la Nix del FBX.** De rodillas; nada bajo el suelo al final. Ocupa el sitio de Garon, delante (`combate.gd`,
  `SITIO_DE_RECLUTA`), y el slime más cercano le tapa parte de las piernas y del bastón. Eso es de la colocación, no de la
  derrota.

**Por qué no se ve lo hundido** (deducido del código, no medido aparte): la ventana 3D de cada héroe en el combate
(`combate.gd`, `estudio_3d`) tiene el fondo transparente y **no tiene suelo**. Lo que baja de y = 0 se dibuja encima de la
hierba pintada y parece apoyado un poco más cerca de la cámara. Solo lo corta en recto el borde de abajo de esa ventana.
Con la cámara a 12° y su encuadre, ese borde queda en y ≈ centro_y − alto_vista / (2 · cos 12°) a la profundidad del
origen: **unos −0,10 m para Naira** (centro 1,05, alto 2,25) y **−0,13 m para Nix** (1,12 y 2,45). Más cerca de la cámara,
el corte llega antes. Encaja con el corte en recto que se vio el 18/11 en Lya (−0,26). El astrolabio de Naira (−0,097) y
su cadera (−0,109) quedan cerca de ese límite (no se ha medido a qué profundidad). En las capturas no se cortan, pero
el margen es pequeño.

**Fallo visible en el PC: ninguno.** No se ha cambiado nada del juego.

**Propuesta para el coordinador (sin hacer, solo si el Redmi muestra el corte):** levantar el astrolabio y la cadera de
Naira unos 0,12 m en la pose final de su clip `derrota`. Se haría con el guion de Blender de `naira_provisional.glb`,
sobre una copia; Naira es una propuesta provisional, no canon. Otra opción: un gesto en `naira_3d.gd.morir()` que suba el
hueso `astrolabio`. Después habría que repetir esta medida y las capturas. Para Nix no hace falta nada.

**Pendiente:** verlo en el Redmi (`GUION_REDMI_19_11.md`, «Para la próxima APK»). En el teléfono, la ventana 3D puede
tener otra resolución (calidad), pero el encuadre es el mismo; no se ha comprobado.
