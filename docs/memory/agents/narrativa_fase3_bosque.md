# Narrativa, fase 3: «El bosque que no recuerda» (diálogos y avisos)

## 10/11/2026, 15:30. Rama `claude/f3-dialogos` (`D:\Aethelgard_f3_dialogos`), desde `bbda8c2`

Encargo: los 15 diálogos de la tabla de `docs/fase3_bosque/AVENTURA_JUGABLE.md`, su registro en Dialogic, los avisos
cortos de la región y una prueba sin ventana. Solo textos: no se ha tocado la lógica del juego.

### Archivos y commits

| Commit | Qué |
|---|---|
| `8c176d3` | 13 `aethelgard/dialogos/bosque/bq_*.dtl`, `oakhaven/oak_encina_bosque_{purificado,derrotado}.dtl`, `personajes/guardian_bosque.dch` y `project.godot` (solo 16 líneas añadidas: 15 en `dtl_directory` y 1 en `dch_directory`, en orden alfabético) |
| `98e5010` | `aethelgard/dialogos/notas/bosque.gd`: `const TEXTOS` con las 16 claves del encargo |
| `0d1ca53` | `aethelgard/pruebas/prueba_dialogos_bosque.gd` y su línea en `lista_pruebas.txt` |
| `1cf4b38` | los `.uid` de los dos scripts nuevos (generados por la importación aislada) |

**El Guardián habla** (en `bq_guardian` y `bq_purificado`): personaje nuevo `guardian_bosque`, «Guardián del Bosque»,
verde, sin retrato (como Tilo, Garon y Encina). En el desenlace B calla: el silencio es parte de la victoria amarga.

### Pruebas (comprobado ejecutando, aislado, 10/11, sobre `0d1ca53`)

- Importación aislada: `D:\REBELUM_diagnostico\importaciones\narrativa_f3_2026-11-10_152144` (código 0). La
  importación borró el registro de Dialogic de `project.godot`, como siempre; se restauró con `git restore` a la versión
  confirmada, que **sí lleva** las 16 entradas (comprobado con `git diff HEAD~3 -- aethelgard/project.godot`: 16 líneas
  añadidas, ninguna quitada).
- `prueba_dialogos_bosque`: **SUPERADA**, FALLOS: 0, sin nada en el registro de errores. Resumen:
  `D:\REBELUM_diagnostico\pruebas\2026-11-10_152245\resumen.md`. Comprueba: las 15 rutas registradas y cargadas como
  `DialogicTimeline`; el Guardián en `dch_directory`; de 2 a 6 frases; solo hablan los presentes; ≤ 110 letras; gesto de
  Kael y Lya de la lista antes de cada frase suya; sin comentarios, corchetes ni llaves; sin Érebo, corazón(es),
  recuerdo(s), memoria ni nombres de Final Fantasy X; en `bq_guardian`, `bq_purificado` y `bq_derrotado` hablan los
  tres; cada diálogo **abierto por su nombre** (`Dialogic.start("bq_…")`) y recorrido entero, con tantas frases como el
  archivo y cada una con su personaje; los avisos con sus claves exactas, ≤ 90 letras, y el `%d` del objetivo
  («Busca más señales del olvido (2/3).»).
- Pruebas vecinas, misma tanda (`D:\REBELUM_diagnostico\pruebas\2026-11-10_152329\resumen.md`):
  `prueba_charlas_posada` y `prueba_notas_exploracion` **SUPERADAS**; `prueba_ciudad_datos` **FALLIDA** con 2 fallos,
  ambos esperados: «oak_encina_bosque_{derrotado,purificado}.dtl no lo usa ningún vecino ni la posada». Esa prueba no
  admite archivos en `dialogos/oakhaven/` sin enganchar en `ciudades/oakhaven.gd`. Se arregla al enganchar a Encina
  (cambio exacto abajo); no es mío.
- La partida real, sin cambios (lo comprueba el ejecutor).

### Tabla de intenciones y gestos

Gestos de la lista acordada (`voces_heroes.md`): Kael `ligero`, `brazalete`, `sorpresa`, `decidido`, `duda`; Lya
`inquieta`, `preocupada`, `decidida`, `duda`, `firme`. Garon, Tilo, Encina y el Guardián, sin retrato. Retratos de Kael
y Lya: `vivo_pv` (como `pv_*`), con el resaltado de quien habla de siempre.

| Diálogo | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| bq_tilo_1 | Tilo | ¡Menuda tormenta anoche! Rayos hasta el alba. Casi me apaga el farol. | engancha: un recuerdo falso, contado con naturalidad | — |
| | Kael | ¿Qué tormenta? Anoche no cayó ni una gota. | directo, descoloca | duda |
| | Tilo | Pues mirad ese árbol. Amaneció así, gris como la ceniza. Algún rayo, digo yo. | señala el objetivo | — |
| | Lya | Kael… la tierra está seca. Aquí no ha llovido. | el dato que inquieta | preocupada |
| | Tilo | Me empapé hasta los huesos. Lo sé. Lo… sé. Echadle un ojo, ¿queréis? | la grieta: duda de sí mismo, sin explicarlo | — |
| | Garon | Yo vigilo el camino. | protector, parco | — |
| bq_arbol | Lya | Estas runas no están talladas. Salen de dentro, como venas pálidas. | conocimiento mágico, misterio | duda |
| | Kael | Laten. Como si el árbol respirara muy despacio. | asombro | sorpresa |
| | Lya | Es magia, pero al revés. No crea nada: borra. Le está quitando el color. | la clave del misterio | inquieta |
| | Garon | Hay más corteza gris. Hacia el norte. | la dirección | — |
| | Lya | Llevo mis frascos y mi mortero. Si esto tiene cura, saldrá de ahí. | abre la alquimia | decidida |
| | Kael | Pues a buscar más árboles tristes. | remate ligero | decidido |
| bq_pista_planta | Lya | Lirios. Vivos, pero sin color. Y no huelen a nada. | pista | duda |
| | Kael | Flores grises. Tilo diría que ha sido la tormenta. | humor que inquieta (eco de Tilo) | ligero |
| | Lya | Una flor que olvida su color acaba olvidando para qué florece. | el olvido como amenaza | firme |
| | Garon | Las abejas pasan de largo. | la observación seca | — |
| bq_pista_rastro | Kael | ¿Esto es de un arado? Va campo a través, sin ton ni son. | curiosidad | sorpresa |
| | Lya | Son raíces. Algo grande se ha arrastrado por aquí, bajo la tierra. | inquietud | inquieta |
| | Lya | Las raíces no vagan. Estas parecen no saber volver a casa. | el olvido en lo vivo | duda |
| | Garon | Van hacia las ruinas. Tras esas ramas caídas. | la dirección (prepara la senda) | — |
| | Kael | Raíces perdidas. Ya me caen bien. | se ríe de sí mismo | ligero |
| bq_senda | Garon | Atrás. | acción | — |
| | Kael | Siempre dice eso justo antes de lucirse. | le provoca con cariño | ligero |
| | Garon | Abierto. Hay una senda. | parte militar | — |
| | Lya | Losas de peregrino. Esta senda llevaba a algún sitio importante. | anticipa las ruinas | duda |
| bq_pista_inscripcion | Lya | Escritura antigua. Dice «Quien vela no olvida». | la lee | duda |
| | Kael | ¿Quién vela? ¿Un guarda? ¿Otro farolero? | pregunta directa, broma suave | duda |
| | Lya | Un guardián. Un espíritu de raíces que cuidaba de este bosque. | conocimiento | firme |
| | Garon | Cuidaba. | el subtexto en una palabra | — |
| | Lya | Hay más escrito, pero la piedra está borrada. Como el árbol de Tilo. | inquietud, enlaza pistas | preocupada |
| bq_pistas | Lya | El árbol, los lirios, las raíces… Todo apunta al claro del noreste. | conclusión | firme |
| | Lya | El guardián ha olvidado su juramento. Y su olvido se contagia. | descubre la amenaza | preocupada |
| | Kael | ¿Se contagia? ¿Como un catarro? | quita hierro | duda |
| | Lya | La savia de los árboles sanos aún sabe lo que fue el bosque. Déjame estudiarla. | abre la investigación | decidida |
| | Garon | Estudia deprisa. | urgencia seca | — |
| | Kael | Y si no, se lo explicamos de otra manera. | anuncia los dos caminos | decidido |
| bq_guardian | Lya | Kael… no te acerques. Está despertando. | tensión | preocupada |
| | Guardián | Quien vela… ¿quién vela? Lo tenía aquí… y se ha ido. | el juramento perdido (eco de la inscripción) | — |
| | Guardián | ¿Quiénes sois? Este bosque no os conoce. | amenaza | — |
| | Garon | Yo, delante. | se pone delante | — |
| | Kael | Venimos a devolverte algo que se te olvidó. | decidido, doble sentido | decidido |
| | Lya | Si tenemos el elixir, espera a que flaquee. Entonces, dáselo. | pista de juego (fase 2) sin tecnicismos | firme |
| bq_purificado | Guardián | Quien vela… no olvida. Ahora lo sé otra vez. | alivio: recupera el juramento | — |
| | Lya | Mirad las hojas. Vuelve el verde. | esperanza | inquieta |
| | Guardián | Tomad este brote. Que crezca con vosotros. | recompensa (Brote del Guardián) | — |
| | Kael | Primera vez que un árbol me da las gracias. | ligereza | ligero |
| | Garon | El bosque respira. | calma | — |
| | Lya | Volvamos a Oakhaven. Esta vez llevamos buenas noticias. | siguiente paso | decidida |
| bq_derrotado | Lya | Se ha quedado quieto. Ya no late nada. | silencio | preocupada |
| | Kael | Hemos ganado. ¿Por qué no lo parece? | victoria amarga | duda |
| | Garon | Ganar no es salvar. | la verdad en tres palabras | — |
| | Lya | Las runas se apagan… pero los árboles siguen grises. | consecuencia clara | duda |
| | Kael | Ha dejado su madera, dura como el hierro. La llevaremos con respeto. | recompensa (material) con respeto | decidido |
| | Lya | Volvamos a Oakhaven. Alguien tendrá que plantar algo aquí. | una luz al lado de lo oscuro | decidida |
| bq_tilo_durante | Tilo | Esa tormenta… Juraría que el farol se me cayó al barro. Y mirad: ni una mancha. | inquietante, sin explicar | — |
| | Tilo | Id con cuidado. Hoy los pájaros no cantan donde siempre. | el olvido en los animales | — |
| bq_tilo_purificado | Tilo | ¡Ha vuelto el verde! El árbol de aquí echó flores esta mañana. | alegría | — |
| | Tilo | Qué cosa… Ya no me acuerdo de ninguna tormenta. | el recuerdo falso se va (sin explicarlo) | — |
| | Tilo | Buen camino, chicos. Hoy el farol brilla casi solo. | despedida luminosa | — |
| bq_tilo_derrotado | Tilo | El árbol ya no late. Pero sigue gris, como mis canas. | amargo, con humor | — |
| | Tilo | Anoche volvió a tronar. Lo oí clarito. ¿Vosotros no? | el olvido sigue en él | — |
| | Tilo | Bah. Cosas de viejo. Buen camino, chicos. | se lo quita de encima | — |
| oak_encina_bosque_purificado | Encina | Esta mañana el roble olía a savia nueva. Hacía años que no. | consecuencia en la ciudad | — |
| | Encina | Dicen que el bosque del noreste vuelve a florecer. Algo habéis hecho, muchacho. | reconocimiento | — |
| | Encina | Me sobran hierba lunar y savia clara. Si os hacen falta, os las vendo. | abre su tienda | — |
| oak_encina_bosque_derrotado | Encina | Ese bosque ya no canta. El roble lo nota: hoy tiene la corteza fría. | consecuencia amarga | — |
| | Encina | No os culpo. A veces solo se elige entre malo y peor. | sin juicio | — |
| | Encina | Si traéis madera de aquel guardián, os la pago bien. Merece un sitio donde la respeten. | abre la compra del Corazón de roble | — |

Avisos (`dialogos/notas/bosque.gd`): ver el archivo; todos ≤ 90 letras. `fase2` es «¡El bosque entero despierta!».

### Decisiones de canon que el usuario debe revisar

1. **«Corazón».** El diseño llama a la fase 2 «El corazón del bosque», propone el aviso «¡El corazón del bosque
   despierta!» y el material «Corazón de roble». No tiene que ver con Érebo, pero las pruebas de narrativa tratan
   «corazón» y «recuerdo» como palabras vetadas para no rozar la revelación del acto III. En mis textos **no aparece**:
   el aviso de fase 2 es «¡El bosque entero despierta!», y en los diálogos el material es «su madera» o «madera de aquel
   guardián». Quedan el nombre de la fase y el del material (archivos de combate y datos, no míos). Propuesta: mantenerlos
   si el usuario no ve riesgo, o llamarlos «El alma de raíces» y «Duramen de roble».
2. **El Guardián habla** (dos frases antes del combate y dos tras purificarlo) y es un personaje de Dialogic nuevo, sin
   retrato. Su voz recoge la inscripción «Quien vela no olvida». Nada de Érebo.
3. **Tilo**: su tormenta no se explica. En el desenlace A la olvida («Ya no me acuerdo de ninguna tormenta») y en el B
   la oye otra vez. Es una consecuencia del olvido del diseño, sin canon nuevo.
4. La niebla como olvido (biblia, opción A) es **propuesta**: en pantalla solo dice «olvido» y «se contagia», sin afirmar
   qué es la niebla.

### Límites

- Comprobado sin ventana: carga, registro, recorrido y longitudes. **No** comprobado en el juego: que la lógica los abra
  en su momento (no existe todavía en esta rama), ni cómo se ven en el móvil.
- `prueba_ciudad_datos` fallará hasta que se enganche a Encina.

### Cambios que necesito en archivos de otros

- `aethelgard/ciudades/oakhaven.gd`, NPC `encina`, lista `"dialogos"`, al principio (condición `decision` existente):

  ```gdscript
  {"dialogo": "oak_encina_bosque_purificado", "si": "decision:guardian_bosque=purificado", "prioridad": true},
  {"dialogo": "oak_encina_bosque_derrotado", "si": "decision:guardian_bosque=derrotado", "prioridad": true},
  ```

  (si «prioridad» hace que se repita siempre, mejor sin ella para que se turne con las otras dos). Con eso
  `prueba_ciudad_datos` vuelve a pasar.
- Lógica del bosque (Pastos Verdes 3D y combate): abrir cada diálogo por su nombre (`bq_…`) y usar
  `preload("res://dialogos/notas/bosque.gd").TEXTOS[...]`; `objetivo_pistas` con `% n`.
