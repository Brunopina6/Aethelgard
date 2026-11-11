# Narrativa y exploración V12: rincones de Pastos Verdes 3D

## 2026-11-12, 00:00 (noche del 11 al 12/11) · rama LOCAL `claude/v12-exploracion` (`D:\Aethelgard_v12_exploracion`)

Encargo: que el jugador no se limite a entrar y combatir. Mejoras pequeñas, completas y comprobables en **Pastos
Verdes 3D**, sin tocar la misión, el Mar de Cristal, el combate, los enemigos, el sonido, la música ni los menús. Desde
`claude/rebelum-v12` @ `9f85e77`. Sin push ni merge.

Leído antes: `D:\Aethelgard\CLAUDE.md`, `docs/v12/RETOMAR.md`, la biblia v2 y v3 (`D:\Aethelgard\docs\biblia\`, solo
como referencia: PV-08 a PV-16 siguen siendo propuesta), `docs/biblia/rebelum_propuesta.md`,
`docs/narrativa/voces_heroes.md`, `docs/v11/HISTORIA.md` y el código de la región (`pastos_verdes_3d.gd`,
`bosque_pastos.gd`, `sendero_puente.gd`, `fauna_simple.gd`, `comentarios.gd`, `progreso.gd`).

### Qué había ya en la región (observado en el código)

Tilo, la estela, el cofre del árbol mágico, la lavanda de Rosa, tres notas, conejos, dos pájaros que planean,
mariposas y, tras PV-14, toda «El bosque que no recuerda» (pistas, materiales, manantial, orbe, Canela). Lo que faltaba
era **entre la entrada y el puente**: el camino de la misión no tenía nada que no fuera misión, y el entorno no
reaccionaba a Kael (salvo los conejos).

### Las cuatro mejoras

Todo vive en un módulo propio, `zonas3d/pastos_rincones.gd`, que la región crea como crea el bosque (no en los bancos
de medida). Se guarda con claves que ya existen («hitos» e inventario): las partidas antiguas cargan igual.

| # | Dónde (x, z) | Qué hace | Recompensa o momento | Se guarda | Diálogo |
|---|---|---|---|---|---|
| 1 | Tres bandadas: (−10,5, −0,5), (1,7, 4,3) y (19,5, −0,5), en prados sin un árbol al sur | Pajarillos posados que picotean; si Kael se acerca a 4,2 m, salen volando lejos de él (aleteo, sombra en el aire, `rafaga_hierba` y `pajaro` en su sitio) y vuelven a posarse unos 22 s después, con Kael a más de 9 m | El mundo reacciona a Kael | Nada (ambiente) | — |
| 2 | Montón de los peregrinos, (−14,6, 11,6), al principio del camino, al otro lado de la cinta de los peregrinos | «Dejar una piedra»: la piedra de Kael, más clara, cae arriba del todo y se queda | Un momento; el comentario de quien esté | `rin_piedra` (la piedra sigue al volver) | Kael solo, con Lya o con Garon |
| 3 | Nido de la urraca, en un árbol seco propio, (18,5, 8,5), a la vista desde el cofre del árbol mágico | Un brillo se enciende un momento cada 3 s en lo alto (señal que no invade). Sin Garon: «No llegas». Con Garon: él aúpa a Kael (diálogo y fundido corto) | **25 monedas y 1 Moneda antigua**, una vez; el botón se queda en el nido | `rin_nido` | `res://dialogos/pastos/rincon_nido.dtl` (Kael y Garon) y comentario de Lya |
| 4 | Centro del puente, (9, −2) | «Asomarse»: Kael se vuelve hacia la cascada y hay una charla breve | Una charla distinta según el grupo; cada una, una vez por partida | `rin_puente_solo`, `rin_puente_lya`, `rin_puente_grupo` | Kael solo, Lya y Kael, Kael y Garon |

Por qué así:
- **Bandadas:** la región ya tenía conejos que huyen, pero nada que respondiera al paso de Kael por el camino. Tres
  sitios, en una sola llamada de dibujo cada uno (MultiMesh).
- **Montón:** los peregrinos ya existen en el juego (`pv_05`, la nota del mojón «A casa, siempre», la cinta). El montón
  los pone en el paisaje sin contar nada nuevo de ellos; la piedra que se queda es la recompensa de volver.
- **Nido:** es la razón para volver cuando llega Garon (PV-05) y la acción de un personaje (Garon aúpa). Recompensa
  modesta (un cofre de la región da de 40 a 120 monedas).
- **Puente:** un mirador sin misión. Lo que se dice crece con el grupo: el mismo sitio da tres momentos.

No bloquea nada: el montón y el árbol seco están fuera del sendero, lejos de lo que ya se examina (Tilo, estela, cofre,
lavanda, notas, el bosque) y del círculo del centinela; el botón del puente es solo un botón en su centro. Ninguna
mejora pone ni quita hitos de la misión.

### Textos e intenciones (para animaciones)

Comentarios (caja de `comentarios.gd`, abajo a la derecha, no paran el juego), todos de 70 letras o menos y en dos
líneas de su caja (comprobado con `prueba_rincones_pastos`):

| Momento | Grupo | Quién | Texto | Intención | Gesto | Espera |
|---|---|---|---|---|---|---|
| Piedra | solo | Kael | Una piedra más. Ahora tendré que volver a por ella. | Se hace una promesa en broma | ligero | espera_brazalete |
| Piedra | Lya | Lya | Los peregrinos dejaban una al irse y la recogían al volver. | Lo sabe de los libros y se lo regala | duda | espera_flor |
| | | Kael | Entonces esa es mía. Que nadie me la quite. | Se apunta a volver sin decirlo en serio | ligero | espera_brazalete |
| Piedra | grupo | Garon | Muchas piedras. Pocos vuelven a por ellas. | El veterano que ha contado ausencias | — | espera_hombros |
| | | Kael | Yo volveré. Aunque sea por llevarte la contraria. | Le da la luz a lo oscuro con una provocación | decidido | espera_empunadura |
| Nido, sin Garon | solo | Kael | Un palmo más y era mío. Un palmo, nada más. | Se ríe de su propia altura | ligero | espera_impaciencia |
| Nido, sin Garon | Lya | Lya | Es de urraca. Se llevan todo lo que brilla. | Nombra lo que ve, precisa | duda | espera_cetro |
| | | Kael | Hoy no llego. Volveré con alguien más alto. | Deja la puerta abierta a volver | ligero | espera_vigilar |
| Nido, premio | grupo | Lya | Le has dejado el botón. Bien hecho. | Le premia lo tierno que no admite | — | espera_pelo |
| | | Kael | Era feo. No te emociones. | Lo niega para que no se note | ligero | espera_brazalete |
| Puente | solo | Kael | Agua arriba, agua abajo. Y yo en medio, seco. De momento. | Se quita el vértigo con una broma | ligero | espera_vigilar |
| Puente | Lya | Lya | Mira la cascada. Desde aquí parece que no cae: que cuelga. | Le enseña algo bonito con precisión de estudiosa | — | espera_pelo |
| | | Kael | Mientras no caigamos nosotros. | Le quita solemnidad al asombro | ligero | espera_vigilar |
| Puente | grupo | Kael | Podría quedarme aquí toda la tarde. | Se le escapa que este sitio le gusta | — | espera_vigilar |
| | | Garon | Cruje. …Cinco minutos. | Protege y cede a la vez | — | espera_apoyarse |

Diálogo del nido (`dialogos/pastos/rincon_nido.dtl`, Dialogic, abierto por su ruta: **no hace falta registrarlo en
`project.godot`**; la importación lo registra sola, sin efecto):

| # | Quién | Frase | Intención | Retrato (`extra_data`) |
|---|---|---|---|---|
| 1 | Kael | Ahí arriba brilla algo. Es un nido. | Curiosidad | duda |
| 2 | Garon | De urraca. Sube. | Orden con su motivo, telegráfico | (sin retrato) |
| 3 | Kael | ¿Que suba? ¿Cómo que suba? | Sorpresa cómica | sorpresa |
| 4 | Garon | Pie en mis manos. Luego, la rama. | Instrucción de soldado | (sin retrato) |
| 5 | Kael | Si me caigo, que conste que fue idea tuya. | Acepta riéndose del riesgo | ligero |
| 6 | Garon | No te caes. Te sujeto. | El corazón escondido en la última palabra | (sin retrato) |

Avisos: «Dejas una piedra en lo alto del montón, como los peregrinos.» · «Tu piedra sigue arriba del todo.» · «Algo
brilla en un nido, en lo alto del árbol seco. No llegas.» · «Bajas con 25 monedas y una moneda antigua. El botón se
queda en el nido.» · «El nido de la urraca. Solo queda su botón.» Botones: «Dejar una piedra», «Mirar el montón»,
«Mirar arriba», «Asomarse».

Canon: nada de Érebo ni de lo que guarda, nada de Final Fantasy X, ningún pasado propuesto de los héroes. La costumbre
de la piedra (dejarla al irse, recogerla al volver) es color local nuevo, pequeño y coherente con la nota del mojón:
**propuesta**, se quita cambiando una frase si el usuario no la quiere.

### Comprobaciones (comprobado ejecutando, aislado, 11-12/11, sobre los commits de abajo)

Todas con `ejecutar_pruebas.ps1` (datos aislados; `partida.save` real con la misma huella antes y después en cada
pasada). Antes, `--import` con `APPDATA` aislado; la primera importación vació los directorios de Dialogic de
`project.godot` (como avisaba la orden): `git restore` y otra importación.

- **Batería de la región, la misión y el guardado** (22 de 22 SUPERADAS):
  `D:\REBELUM_diagnostico\pruebas\2026-11-11_224556\resumen.md` — `prueba_zona3d`, `prueba_ruta_alpha`,
  `prueba_grupo3d`, `prueba_cofre3d`, `prueba_centinela`, `prueba_comentarios_3d`, `prueba_notas_exploracion`,
  `prueba_bosque_pastos`, `prueba_integridad`, `prueba_guardado`, `prueba_partida`, `prueba_guardado_protegido`,
  `prueba_guardado_fallos`, `prueba_formato_regiones`, `prueba_comentarios`, `prueba_dialogos_bosque`,
  `prueba_esperas`, `prueba_anim_pies`, `prueba_encargos`, `prueba_musica_pastos`, `prueba_calidad_auto` y
  `prueba_rincones_pastos`. (Esa pasada marca «proyecto: CAMBIADO» porque cambié el temporizador de los comentarios
  mientras corría; por eso se repitió después.)
- **Con el código final:** `prueba_rincones_pastos` SUPERADA y capturas
  (`D:\REBELUM_diagnostico\pruebas\2026-11-11_224859\resumen.md`); `prueba_zona3d`, `prueba_ruta_alpha`,
  `prueba_integridad` y `prueba_comentarios_3d` SUPERADAS (`D:\REBELUM_diagnostico\pruebas\2026-11-11_225006\resumen.md`).
- **Qué mira `prueba_rincones_pastos`** (nueva): textos (15 frases de comentario en dos líneas, gestos, esperas e
  intenciones de la lista, avisos en dos líneas, el diálogo del nido solo con Kael y Garon); sitios (fuera del camino y
  de lo prohibido, lejos de Tilo, la estela, el cofre, la lavanda, las notas, todos los puntos del bosque, el centinela
  y las salidas); Kael solo deja su piedra una vez, no llega al nido sin Garon y se asoma al puente; una bandada sale
  volando, sube, se pierde, no vuelve con Kael cerca y vuelve a posarse; la partida guardada lleva los hitos y la piedra
  sigue en el montón al volver a entrar; con Garon, el diálogo del nido recorrido entero con Dialogic (6 frases), el
  premio una sola vez (también pulsando otra vez), guardado con la moneda antigua, el comentario de Lya y la charla del
  grupo en el puente; una partida antigua sin estos hitos carga con el nido brillando y sin la piedra.

### Capturas

`D:\REBELUM_diagnostico\narrativa\2026-11-12_exploracion\` (36, alto y bajo, de `fotos_rincones_pastos`): montón desde
el camino, de cerca y con la piedra y el comentario; el brillo del nido desde el cofre; el nido sin Garon; el diálogo
con Garon; subiendo (fundido); el premio con el comentario de Lya; las tres bandadas posadas y volando; el puente
(botón, solo y grupo). Las capturas me hicieron cambiar cuatro cosas (commit `4eb656f`): el nido bajo una copa no se
veía (ahora en un árbol seco propio), el montón de 0,6 m lo tapaba Kael (ahora 1 m), los pájaros de 12 cm no se veían y
dos bandadas quedaban bajo copas (ahora unos 30 cm y en otros sitios), y el aviso y el comentario se pisaban.

### Commits (rama LOCAL `claude/v12-exploracion`)

- `7c7f930` Pastos Verdes 3D: rincones para explorar fuera de la misión (módulo, textos, diálogo, enganches, prueba).
- `4eb656f` Árbol seco para el nido, montón más grande, pájaros que se ven (tras revisar las capturas).
- El último (temporizador de los comentarios en vez de `await`, las capturas y este informe): ver `git log`.

### Archivos para integrar (copiando)

- Nuevos: `aethelgard/zonas3d/pastos_rincones.gd` (+ `.uid`), `aethelgard/dialogos/notas/pastos_rincones.gd` (+ `.uid`),
  `aethelgard/dialogos/pastos/rincon_nido.dtl` (+ `.uid`), `aethelgard/pruebas/prueba_rincones_pastos.gd` (+ `.uid`),
  `aethelgard/pruebas/fotos_rincones_pastos.gd` (+ `.uid`).
- Cambiado: `aethelgard/zonas3d/pastos_verdes_3d.gd` (23 líneas: crear el módulo, `comprobar`, `cerca_de` con prefijo
  `rin:`, `accion`, `tras_dialogo` por ruta `res://dialogos/pastos/` y `ocupado`).
- `aethelgard/pruebas/lista_pruebas.txt`: dos líneas al final (`prueba_rincones_pastos` y `fotos_rincones_pastos`); mejor
  añadirlas a mano que copiar el archivo, por si otro especialista añade las suyas.
- **No** se confirma `project.godot` (la importación añade `"rincon_nido"` al directorio de Dialogic; no hace falta).

### Límites y pendientes

- **Sin medir en el Redmi.** Coste añadido: 3 MultiMesh de pájaros (sombra solo en vuelo), el montón en una malla, el
  árbol seco (5 piezas) y el nido (2). En el PC no se nota; falta medirlo en el teléfono, sobre todo en bajo.
- **Sonido:** los pájaros usan `rafaga_hierba` y `pajaro` del catálogo; no hay aleteo propio (petición para sonido).
- **Garon aúpa a Kael con un fundido**, sin animación de subir (petición para animaciones, si se quiere ver).
- Formas sencillas, sin modelos (como Tilo, la estela y el cofre): el árbol seco y los pajarillos son provisionales.
- «Moneda antigua» es un material del buscador de metales del desierto: si el coordinador prefiere otra cosa en el
  nido, se cambia `NIDO_OBJETO` en `dialogos/notas/pastos_rincones.gd`.
- Los comentarios del puente son uno por grupo y por partida; los de la piedra y el nido salen al hacer la acción.
- Oakhaven 3D no se ha tocado esta noche.
- Incidencia ajena: durante dos pasadas, otros Godot (de otras copias, con `--import` sin datos aislados) crearon y
  borraron `.recovery_mode_lock` en la carpeta real de datos. `partida.save` no cambió nunca (huella igual antes y
  después en todas las pasadas). Mis importaciones usaron siempre `APPDATA` aislado.

### Siguiente paso propuesto

1. Integrar copiando los archivos de arriba y pasar `prueba_rincones_pastos` y las de la región.
2. Medir Pastos Verdes en el Redmi (bajo y medio) con los rincones.
3. Si gustan: llevar la misma idea a Oakhaven 3D (un rincón con vista, una reacción de las palomas de la plaza) y a la
   Garganta 3D.
