# Narrativa y exploración V12: un rincón opcional del Mar de Cristal, «el hito del cobijo»

## 12/11/2026, 10:40-11:40 · rama LOCAL `claude/v12-hito-mc-interaccion` (`D:\Aethelgard_v12_mc_interaccion`, desde `claude/rebelum-v12` @ `a0bab37`)

Encargo: **una** interacción opcional del Mar de Cristal, terminada y con sentido, sobre un lugar ya construido; se
encuentra por composición o por sonido, con reacción breve del grupo, un descubrimiento con sentido para el mundo,
recompensa modesta una sola vez y estado guardado. Sin push ni merge.

Leído antes: `D:\Aethelgard\CLAUDE.md`, `docs/v12/RETOMAR.md`, `docs/v12/NARRATIVA_DESIERTO.md`, `docs/v12/DISENO_V12.md`,
`docs/memory/agents/narrativa_v12_exploracion.md` (patrón de los rincones de Pastos), `graficos_v12_desierto2.md` (lugares
nuevos), `narrativa_v12_naira_mision.md` (no se usa ni se duplica), `docs/narrativa/voces_heroes.md` y el código de la
región (`mar_cristal_3d.gd`, `mision.gd`, `trazado.gd`, `paisaje.gd`, `clima.gd`, `buscador.gd`, `examinables_3d.gd`,
`progreso.gd`, `sonido.gd`).

### Qué había ya (observado en el código, `a0bab37`)

| Qué | Dónde | Interacción | Premio / estado |
|---|---|---|---|
| «La caravana perdida» (8 hitos `mc_*`) | campamento, restos, ruinas, trampilla | diálogos según grupo | 150 monedas, buscador nivel 2, Aguja de Resonancia (una vez) |
| Buscador | `mar_de_cristal_1`: 14 comunes, 6 falsas, únicos sello y llave | excavar | inventario, `buscador` |
| Esqueleto con nota | nicho (9, 30) | aviso | — |
| Espejismo y su cofre | (82, 30) | aviso y cofre | 80 monedas, Reliquia de vidrio, Éter (`cofres_abiertos` `mc_cofre_espejismo`) |
| Mural y Oren | ruinas, campamento | diálogo / aviso | — |
| Misión de Naira | observatorio (APAGADA) | — | no se toca |
| Paisaje de gráficos: humo, **hito con trapo azul**, cristales, oasis, surcos, costillar, remolino, barril | varios | **ninguna** | — |

Ningún sitio del paisaje nuevo tenía interacción. Se eligió el **hito del cobijo** porque ya tiene función (señala dónde
esperar la tormenta), está en el camino de la misión sin ser de la misión y se puede explicar *dentro del mundo*.

### Qué es

- **El sitio:** el hito de `paisaje.gd` (`_hito`: cinco lajas, palo y trapo azul desteñido), en (19,6; 46,6), a 5,8 m del
  cobijo. No se mueve ni se cambia: el módulo le **cuelga tres vidrios** del palo (formas propias, el vidrio de gráficos
  `mat_vidrio()`, sin sombra) que se mecen con el viento.
- **Cómo se encuentra (sin marcador):**
  - **Oído:** a 24 m o menos, los vidrios tintinean cada 6-10 s (clave existente `orbe_cierra`, la copa de cristal, con
    posición 3D y el tono subido ×1,18-1,42 para que suene a vidrio pequeño).
  - **Vista:** al sonar, un destello breve (el sol en el vidrio) que se ve de lejos; el trapo azul ya se veía.
  - **Con tormenta** suenan cada 2,6-4,2 s, 3 dB más y hasta 42 m: el destello atraviesa la arena cuando el trapo casi no
    se ve (captura `*_6_tormenta`). Es la razón *del mundo* para el vidrio, y ayuda de verdad a encontrar el cobijo en
    la tormenta de la misión sin cambiar la misión.
- **El descubrimiento:** «Mirar el hito» (botón a 2 m). Bajo la laja de arriba, una bolsa de cuero encerado con un **paño
  de signos de las caravanas: azul, cobijo; rojo, camino de vuelta** (los postes de la salida ya llevan un trapo rojo, «como
  el toldo de la caravana») y **dos Pociones** que dejaron otros viajeros: «coges lo que te falta y dejas lo que te sobra».
  El jugador aprende a leer el desierto (lo podrán usar los sectores siguientes) sin ninguna revelación.
- **Recompensa:** 2 Pociones, una sola vez (los cofres de la región dan 40-120 monedas; el del espejismo, más).
- **Estado:** hito `mc_rin_hito` (`progreso.gd`, `HITOS_MC_RINCONES`, en la clave «hitos» que ya existe). Primero el hito,
  luego las Pociones y se guarda. Después, el botón solo da un aviso. Si Dialogic no puede abrir el diálogo, el efecto se
  aplica igual; si el diálogo se corta, también (una vez).
- **No toca:** la misión (`mision.gd`, sus 8 hitos), el buscador, Bramavidrio (`gusano.gd`), la Aguja, Ismena, Oren, el
  cofre del espejismo ni Naira. No nombra a Ismena ni a Oren: vale en cualquier punto de la misión.

### Diálogos (Dialogic; Kael `left` y Lya `right` con `vivo_pv`; Garon sin `join`, como en el resto del desierto)

`dialogos/mar_cristal/mc_rin_hito.dtl` (grupo), `_lya` (Kael y Lya), `_solo` (Kael); se elige con `Mision.dialogo_mc`.
Antes no había texto: todo es nuevo (la columna «antes» sería «—»). Todas ≤ 70 letras (medido por la prueba).

**`mc_rin_hito` (Kael, Lya y Garon)**

| # | Quién | Frase | Letras | Intención | Gesto (`extra_data`) |
|---|---|---|---|---|---|
| 1 | Kael | Bajo la laja de arriba hay un hueco. Y una bolsa de cuero encerado. | 67 | curiosidad: encuentra algo que alguien dejó | `sorpresa` |
| 2 | Lya | Un paño con signos cosidos: azul es cobijo; rojo, camino de vuelta. | 67 | lee y nombra, precisa | `duda` |
| 3 | Garon | Con tormenta, el trapo no se ve. El vidrio se oye. | 50 | parte militar: entiende la señal | — (sin retrato) |
| 4 | Kael | También hay dos pociones. ¿Quién deja pociones entre piedras? | 61 | pregunta para devolver la pelota | `ligero` |
| 5 | Lya | Las caravanas. Coges lo que te falta y dejas lo que te sobra. | 61 | la costumbre, dicha como dato | `decidida` |
| 6 | Garon | Dejo mi ración. Tengo otra. | 27 | el corazón escondido en la última palabra | — |
| 7 | Kael | Pues yo le dejo al trapo un nudo bien prieto. Me sobran nudos. | 62 | quita hierro y aun así cumple la costumbre | `ligero+risa` |

**`mc_rin_hito_lya` (Kael y Lya)**: 1, 2, 4, 5 y 7 iguales; la 3 la dice Lya:

| # | Quién | Frase | Letras | Intención | Gesto |
|---|---|---|---|---|---|
| 3 | Lya | Kael… es por la tormenta. Si el trapo no se ve, el vidrio se oye. | 65 | le preocupa la tormenta («Kael…» de su voz) | `preocupada` |

**`mc_rin_hito_solo` (Kael)**

| # | Frase | Letras | Intención | Gesto |
|---|---|---|---|---|
| 1 | Bajo la laja de arriba hay un hueco. Y una bolsa de cuero encerado. | 67 | curiosidad | `sorpresa` |
| 2 | Un paño con signos cosidos. Azul, cobijo; rojo, camino… ¿Y el vidrio? | 69 | piensa en voz alta | `duda` |
| 3 | Claro: con tormenta el trapo no se ve, pero el vidrio suena. | 60 | lo entiende solo | `decidido` |
| 4 | Me llevo dos pociones y le dejo un nudo bien prieto. Me sobran nudos. | 69 | la broma de siempre | `ligero` |

Avisos (caja de la región, 1000 px y letra de 28; una línea cada uno, medido):
- premio: «Coges dos Pociones de la bolsa. El paño de los signos vuelve a su sitio.»
- después: «El hito del cobijo: trapo azul, nudo prieto y vidrio que suena.»
- botón: «Mirar el hito».

Canon: nada de Érebo, la niebla, el anillo de Kael, los pasados de Lya y Garon, Morgath, el final, Naira, la Reina ni el
Lente (la prueba lo busca). El código de colores y la costumbre del hito son **color local nuevo: propuesta**; se quitan
cambiando dos frases. Garon dejando su ración y Lya sabiendo la costumbre no revelan nada de su pasado.

### Archivos y commits (rama LOCAL `claude/v12-hito-mc-interaccion`)

| Commit | Qué |
|---|---|
| `206e9d5` | `zonas3d/mar_cristal/rincones.gd` (+ `.uid`), las tres timelines `dialogos/mar_cristal/mc_rin_hito*.dtl` (+ `.uid`), enganche en `zonas3d/mar_cristal_3d.gd` (10 líneas marcadas «V12 (12/11), rincón») y `progreso.gd` (solo `HITOS_MC_RINCONES`, 3 líneas) |
| `1d69d7e` | `pruebas/prueba_mc_rincon.gd`, `pruebas/fotos_mc_rincon.gd` (+ `.uid`) y dos líneas al final de `pruebas/lista_pruebas.txt` |
| (este) | este informe |

**Para integrar copiando** (`git checkout claude/v12-hito-mc-interaccion -- <rutas>`), bajo `aethelgard/`:
`zonas3d/mar_cristal/rincones.gd(.uid)`, `dialogos/mar_cristal/mc_rin_hito.dtl(.uid)`, `mc_rin_hito_lya.dtl(.uid)`,
`mc_rin_hito_solo.dtl(.uid)`, `pruebas/prueba_mc_rincon.gd(.uid)`, `pruebas/fotos_mc_rincon.gd(.uid)`; y
`zonas3d/mar_cristal_3d.gd` y `progreso.gd` (si nadie más los ha cambiado; si no, aplicar a mano los bloques marcados).
`lista_pruebas.txt`: añadir a mano las dos líneas del final. **No** se confirma `project.godot`: la importación añade las
tres timelines al directorio de Dialogic, pero se abren por su ruta y no hace falta.

### Pruebas (comprobado ejecutando, aislado, 12/11, sobre `1d69d7e`; `partida.save` real sin cambios en todas)

Antes, `--import` con `APPDATA`/`LOCALAPPDATA`/`TEMP` aislados: la primera vació Dialogic en `project.godot` (como
avisaba la orden): `git restore` y otra importación, que solo añadió las tres timelines (restaurado también).

- `prueba_mc_rincon` (nueva) SUPERADA: `D:\REBELUM_diagnostico\narrativa\2026-11-12_mc_rincon\pruebas\2026-11-12_110232\resumen.md`.
  Mira: textos (17 frases, quién habla y entra, gestos, ≤ 70, palabras reservadas; avisos en dos líneas; botón ≤ 16);
  sitio (el trapo de `paisaje.gd` está en el palo, ni prohibido ni camino, su botón no pisa el cobijo ni ningún otro, nada
  del buscador a menos de 1,5 m, en pantalla desde el cobijo, (24, 55) y (27, 50)); oído (calla a 42+ m; a 15 m suena con
  posición en el hito y destella; a 34 m, en calma 0 veces en 12 s y con tormenta 4 en 14 s); con el grupo, el diálogo
  entero con Dialogic (7 frases: kael, lya, garon, kael, lya, garon, kael), el premio al acabar y no antes, +2 Pociones
  una vez, sin oro, ningún hito de la misión ni de Naira, partida guardada con el hito y las Pociones, la segunda vez solo
  el aviso (y `premio()`/`dialogo_terminado()` llamados otra vez no dan nada); recarga sin premio; `_lya` recorrida (6
  frases, sin Garon) y `_solo` cortada (premio igual, una vez); partida antigua (formato 2, misión en `mc_caravana`) carga
  con el rincón por descubrir y la misión sin tocar; perfil bajo con su botón.
- Región y guardado, **9 de 9 SUPERADAS**: `prueba_mc_rincon`, `prueba_mar_cristal`, `prueba_buscador`,
  `prueba_naira_mision`, `prueba_guardado`, `prueba_partida`, `prueba_guardado_protegido`, `prueba_guardado_fallos`,
  `prueba_integridad` — `D:\REBELUM_diagnostico\narrativa\2026-11-12_mc_rincon\pruebas\2026-11-12_110520\resumen.md`.
- **Batería completa: 131 · 0 · 59 · 0** (SUPERADAS · FALLIDAS · MANUALES · NO SEGURAS), `partida.save` y la carpeta
  real de datos sin cambios — `D:\REBELUM_diagnostico\narrativa\2026-11-12_mc_rincon\bateria\2026-11-12_110630\resumen.md`.
  Marca «proyecto: CAMBIADO» solo porque escribí este informe (sin seguimiento) mientras corría; ningún archivo del juego.
  Había otros Godot de otras copias abiertos durante la pasada; no estorban al aislamiento.
- Una lección: cortar un diálogo justo al abrirse (antes de que entren los retratos) da `SCRIPT ERROR` de Dialogic
  (`subsystem_portraits.gd:309`, `fade_up_in_out.gd:6`); la prueba espera 2 s antes de cortar, como `prueba_mar_cristal`.

### Capturas (`D:\REBELUM_diagnostico\narrativa\2026-11-12_mc_rincon\capturas\2026-11-12_110418\fotos_mc_rincon\`)

`bajo_*` y `alto_*`: `1_desde_canon` (a unos 8 m al sureste: el hito y su trapo arriba a la izquierda), `1b_desde_este`,
`2_destello` (el vidrio al sonar), `3_boton`, `4_dialogo`, `5_premio` y `6_tormenta` (el trapo casi no se ve; el destello,
sí). La primera pasada (`..\2026-11-12_110302\`) tenía a Kael demasiado al sur (la cámara mira al norte y solo enseña unos
8 m por delante): reencuadrada. Los vidrios se leen en los dos perfiles.

### Límites y propuestas (pendientes de decisión)

1. **Sonido provisional:** `orbe_cierra` es la copa de cristal del orbe del bosque, subida de tono. Petición para sonido:
   una clave propia `vidrio_hito` (tres o cuatro tintineos cortos de vidrio colgado, en Efectos o Ambiente, con
   `en_3d`). Se cambia en `rincones.gd`, `SONIDO`. Nadie lo ha escuchado (una prueba muda no demuestra cómo se oye).
2. **Composición:** con la cámara que mira al norte, el hito se ve solo cuando está a unos 8 m por delante o 10 m de lado;
   de más lejos guía el oído (24 m; 42 con tormenta). Si se quiere que se vea antes, gráficos podría hacer el palo más
   alto (es de `paisaje.gd`, no lo he tocado).
3. **Propuesta de mundo, no canon:** el código de trapos de las caravanas (azul, cobijo; rojo, camino) y la costumbre de
   la bolsa. Si gusta, los sectores siguientes del desierto pueden tener más hitos (otro color: agua; otro: peligro) y el
   paño podría ir al Diario (eso necesita `CIUDADES` para el lugar 4 en `progreso.gd`, que no he tocado).
4. Sin medir en el Redmi: añade 7 mallas pequeñas (3 cordeles, 3 vidrios, 1 destello) y un sonido cada 6-10 s cerca.
5. Gestos: `ligero+risa` (pose `ligero`, movimiento `risa`) ya se usa en otras timelines; si el coordinador prefiere solo
   gestos simples, cambiar a `ligero`.

### Siguiente paso propuesto

1. Integrar copiando los archivos de arriba y pasar `prueba_mc_rincon` con las de la región.
2. Pedir a sonido la clave `vidrio_hito`.
3. Probar en el Redmi el bajo junto al cobijo con tormenta (FPS y si el destello se ve en el teléfono).
