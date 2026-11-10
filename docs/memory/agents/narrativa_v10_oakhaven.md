# Narrativa V10: los vecinos nuevos de Oakhaven (Ferro, Hilda y Mirta)

## 10/11/2026, 20:50 · rama `claude/v10-narrativa` (`D:\Aethelgard_v10_narrativa`)

Encargo: los vecinos y diálogos del contrato `docs/v10/DISENO_V10.md` («Oakhaven, el corazón vivo del reino»).
Base: `66692c3`. Sin push ni fusión.

### Commits

| Commit | Qué |
|---|---|
| `2fa3c38` | Personajes `ferro`, `hilda` y `mirta` (`aethelgard/dialogos/personajes/oakhaven/*.dch`), los 11 diálogos de Oakhaven del contrato (`aethelgard/dialogos/oakhaven/`), `gg_veta` (`aethelgard/dialogos/garganta/`, carpeta nueva) y su registro en `aethelgard/project.godot` (orden alfabético, **15 líneas añadidas y 0 quitadas**, comprobado con `git diff --numstat`). |
| `213218c` | `aethelgard/ciudades/oakhaven.gd`: los tres en `NPCS`, `oak_pip_paginas` en Pip y los tres `.dch` en `PERSONAJES`. `aethelgard/ciudades/oakhaven_vida.gd`: sus frases al pasar (`VECINOS`) y sus rutinas (`RUTINAS`). 92 líneas añadidas, 0 quitadas. |
| (este) | Este informe. |

No he tocado `aplicar_senal`, `SENALES` ni la lógica. **Sí he tocado `PERSONAJES`** (3 líneas de datos, fuera de `NPCS`):
`prueba_ciudad_datos` exige que cada `.dch` de `dialogos/personajes/oakhaven/` esté ahí, y `registrar_dialogic()` lo
usa para dar a conocer el personaje si `project.godot` pierde el registro. Si prefieres otra cosa, se quita.

### Datos (observado en el código y comprobado ejecutando)

| Vecino | Casilla 2D | Dónde | Muñeco provisional | Diálogos («si») |
|---|---|---|---|---|
| `ferro`, Maese Ferro | (70.5, 26) | herrería: la casa del final de la Calle del Mercado, al pie de la Calle de la Torre | `caballero.png`, tinte (1, 0.74, 0.56) | `oak_ferro_veta` prioridad [`hito:enc_herrero_veta`, `!hito:enc_herrero_fin`] · `oak_ferro_pedido` prioridad [`hito:pv_05`, `!hito:enc_herrero_pedido`] · `oak_ferro_despues` [`hito:enc_herrero_fin`] · `oak_ferro_v` [`hito:bq_resuelto`] o [`decision:hierro_ferro=kael`, `!hito:bq_resuelto`] · `oak_ferro` |
| `hilda`, Hilda la Armera | (47, 25.6) | su puesto, a la entrada de la Calle del Mercado (su taller, la casa de enfrente del mercado) | `aldeana.png`, tinte (0.8, 0.84, 0.92) | `oak_hilda` |
| `mirta`, Mirta la Boticaria | (33.5, 41.5) | Plazuela de la Botica, a un lado de Selene (que no se mueve) | `maga.png`, tinte (0.9, 0.8, 1) | `oak_mirta_formula` prioridad [`hito:enc_formula_paginas`, `!hito:enc_formula_fin`, `grupo:Lya`] · `oak_mirta_pedido` prioridad [`hito:pv_03`, `!hito:enc_formula_pedido`] · `oak_mirta_despues` [`hito:enc_formula_fin`] · `oak_mirta` |
| `pip` (añadido) | — | — | — | `oak_pip_paginas` prioridad [`hito:enc_formula_pedido`, `!hito:enc_formula_pip`], tras los del perro |

- **`hecha:frostfang_falla`:** `cumple()` no lo entiende (`TIPOS_CONDICION` no tiene `hecha`). En su lugar,
  `decision:hierro_ferro=kael` (Ferro le enseña el Acero de la Falla). Si quieres la condición exacta, añade `hecha` a
  `TIPOS_CONDICION` y a `cumple()` y cambio las dos condiciones.
- **Arranque de los encargos:** el A, desde `pv_05` (Garon ya está: lee las piedras escritas); el B, desde `pv_03`
  (Lya ya está: es quien recompone la fórmula). El cierre del B pide además `grupo:Lya`; sin ella, Mirta atiende normal.
- **Reacciones** (contrato, «Reacciones»): no hay ids de diálogo para ellas, así que van como **frases al pasar**
  (`oakhaven_vida.gd`, `VECINOS`) con su condición: Ferro y Hilda, `hito:bq_purificado` / `hito:bq_derrotado`; Ferro,
  `decision:hierro_ferro=kael` / `=entregado`; Mirta, el cuaderno perdido y el bálsamo hecho. `oak_ferro_v` está escrito
  para valer en los dos casos (bosque resuelto o técnica aprendida) sin nombrar ninguno.
- **Rutinas:** Ferro, siempre en el yunque (trabaja); Hilda, quieta en su puesto por la tarde y, al anochecer, pasea del
  puesto a su taller (47→57, 25.6); Mirta, con los estantes por la mañana y la tarde y, al anochecer, buscando algo por la
  plazuela (33.5→37, 41.5). Todas a ≥ 2,5 casillas de lo que se examina y de los demás vecinos a esa hora.
- **Servicio en cada visita:** `oak_ferro_v` y `oak_ferro_despues` acaban también con `oak:servicio_forja`, y
  `oak_mirta_despues` con `oak:servicio_botica`, para que el taller se abra hable lo que hable (se turnan). Señales
  del contrato, sin nombres nuevos.
- **Pregunta de `oak_ferro_veta`:** el formato de `oak_pip_secreto` (`- opción` y la rama con tabulador; la señal,
  primera línea de la rama). Dialogic no ha necesitado otro.
- **`gg_veta`:** sin señal (el contrato no le da ninguna; el hito `enc_herrero_veta` lo pondrá quien coja la veta).
  Hablan Kael, Garon y Lya: lánzalo solo con Garon en el grupo. La línea de Garon («Hierro de la Falla. Como el de las
  piedras escritas.») sirve de pista (`enc_herrero_pista`) si la quieres poner ahí.

### Pruebas (comprobado ejecutando, aislado; 10/11, sobre `2fa3c38` + los datos de `213218c` sin confirmar aún)

1. Importación aislada: `D:\REBELUM_diagnostico\importaciones\narrativa_v10_2026-11-10_204554` (código 0). Borró el
   registro de Dialogic de `project.godot`, como siempre; mis líneas ya estaban confirmadas y lo devolví con
   `git restore`. No genera `.uid` para los `.dtl`/`.dch` nuevos (los hará el editor).
2. `ejecutar_pruebas.ps1 -Solo prueba_ciudad_datos,prueba_oakhaven,prueba_oakhaven_vida,prueba_oakhaven_rutinas,prueba_dialogos_bosque`
   desde PowerShell. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-10_204657\resumen.md`.
   **SUPERADAS 4 · FALLIDAS 1** (partida real, datos reales y proyecto sin cambios; ningún otro Godot).
   - `prueba_oakhaven` SUPERADA: entra, habla con los **11** vecinos y recorre sus diálogos (avisos «señal
     desconocida» de `oak:servicio_*`, esperados).
   - `prueba_oakhaven_vida`, `prueba_oakhaven_rutinas` y `prueba_dialogos_bosque`: SUPERADAS.
   - `prueba_ciudad_datos` FALLIDA con **10 fallos**:
     - 9 «la señal … no la entiende aplicar_senal()»: `oak:servicio_forja`, `oak:servicio_armaduras`,
       `oak:servicio_botica`, `oak:herrero_pedido`, `oak:hierro_entregar`, `oak:hierro_kael`, `oak:formula_pedido`,
       `oak:formula_pip`, `oak:formula_fin`. Las implementa el coordinador.
     - 1 «oak_mirta_formula: hablan ["mirta", "lya"] (un vecino por diálogo)». Es a propósito: el encargo pide que Lya
       intervenga en el B, y la prueba solo admite al vecino (salvo en la posada). Ver «Cambio que pido».
     - Todo lo demás pasa: casillas, distancias, condiciones, frases de respaldo, D-033, D-073, ≤ 110 letras, de 2 a 4
       frases por camino, las dos ramas de la pregunta de Ferro y cada señal llegando.
3. `gg_veta` (no la cubre ninguna prueba): recorrido con Dialogic con una prueba temporal (borrada, sin commit),
   `D:\REBELUM_diagnostico\pruebas\2026-11-10_204757`: registrada en `dtl_directory`, 4 frases, cada una de su `.dch`
   (kael, garon, lya, kael), 0 fallos.

### Cambio que pido en archivos de otros

- **`aethelgard/ciudades/oakhaven.gd` (coordinador):** las 9 señales en `SENALES` y `aplicar_senal()`.
- **`aethelgard/pruebas/prueba_ciudad_datos.gd`, `_acabar_recorrido()`:** admitir en un diálogo de vecino a los héroes
  que su condición exige con `grupo:`. Por ejemplo, antes de `if hablan.size() != 1`:
  ```gdscript
  var exigidos: Array = []                     # héroes con «grupo:X» en el «si» de ese diálogo
  for n in Oak.NPCS:
      for d in n["dialogos"]:
          if d["dialogo"] == id:
              for c in (d.get("si", []) if d.get("si", []) is Array else [d["si"]]):
                  if str(c).begins_with("grupo:"):
                      exigidos.append(str(c).trim_prefix("grupo:").to_lower())
  for q in exigidos:
      hablan.erase(q)
  ```
  Si no se acepta, la alternativa es que Mirta lo diga sola («Tu amiga ha visto el orden en un momento…») y Lya no hable.

### Texto: antes y después

Todo es nuevo (no había «antes»). Los textos, en los archivos del commit `2fa3c38`; resumen de lo más largo: la frase
más larga mide 89 letras (`oak_ferro_pedido`), y todas caben en dos líneas de la caja.

### Intenciones y gestos

Ferro, Hilda y Mirta no tienen retrato (como Doña Encina): el gesto es lo que pediría su retrato cuando exista.

| Diálogo | Quién | Frase (abreviada) | Intención | Gesto / retrato |
|---|---|---|---|---|
| `oak_ferro` | Ferro | «¿Vienes a mirar o a trabajar?» | Rudo; pone a prueba | (brazos cruzados) |
| | Ferro | «La has tratado como a una pala.» | Orgullo de oficio; reproche | (mira el filo) |
| | Ferro | «…que corte el viento.» | Promesa de artesano | (martillo al hombro) |
| `oak_ferro_v` | Ferro | «En la fragua ya se habla de ti, chico.» | Respeto que no admite | (media sonrisa) |
| | Ferro | «…eso es medio trabajo.» / «La otra mitad es sudar.» | Lo acepta a su manera | (tiende la mano) |
| `oak_ferro_pedido` | Ferro | «Necesito un hierro que cante.» | Pasión por el oficio | (golpea el yunque) |
| | Ferro | «El de antes salía de la Falla…» / «…piedras escritas.» | Da la pista sin rodeos | (señala al este) |
| `oak_ferro_veta` | Ferro | «Escucha. Canta. Treinta años sin oír uno así.» | Emoción contenida | (lo golpea y escucha) |
| | Ferro | «Tú decides.» | Respeta al que se arriesgó | (lo devuelve) |
| | Ferro | (ciudad) «Rejas nuevas para la muralla.» / (Kael) «Esto no se lo enseño a cualquiera.» | Orgullo cívico / maestro que elige alumno | (asiente) |
| `oak_ferro_despues` | Ferro | «Todavía me suena en los oídos.» | Gratitud seca | (martillo al hombro) |
| `oak_hilda` | Hilda | «Ni un remache de más, ni uno de menos.» | Meticulosa; se presenta por su regla | (se ajusta los guantes) |
| | Hilda | «Tres anillas abiertas… Cuatro.» | Lo ve todo; precisión | (cuenta con el dedo) |
| | Hilda | «Lo que se ajusta hoy no se rompe mañana.» | Sabiduría práctica | (abre el taller) |
| `oak_mirta` | Mirta | «No, el otro verde.» | Despiste cómico | (busca en el estante) |
| | Mirta | «Las etiquetas… casi todo tiene.» | Despiste | (frasco en la mano) |
| | Mirta | «La mejor cura es la que llega a tiempo.» | La sabia bajo la despistada | (se queda quieta, seria) |
| `oak_mirta_pedido` | Mirta | «¿Un cuaderno? …De algo.» / «Muy lista, Mirta.» | Se ríe de sí misma | (se da en la frente) |
| `oak_pip_paginas` | Pip | «Esta te la regalo.» | Pícaro que se ablanda | (retrato de Pip) |
| `oak_mirta_formula` | Mirta | «¡Mis páginas! Aunque… desordenadas.» | Alegría y lío | — |
| | Lya | «Esta va primero… Lo pone en el margen.» | Precisa; cita el texto | `duda` |
| | Mirta | «Niña, tú has leído más libros que yo.» | Admiración | — |
| | Lya | «Pocos, pero enteros. … Ya está.» | Firme y concreta: el paso siguiente | `decidida` |
| `oak_mirta_despues` | Mirta | «Leer bien es medio remedio.» | Agradece y enseña | — |
| `gg_veta` | Kael | «¿Oís eso? Aquí la piedra suena distinta.» | Curiosidad | `sorpresa` |
| | Garon | «Hierro de la Falla. Como el de las piedras escritas.» | Parte seco; reconoce | (sin retrato) |
| | Lya | «Con razón decía Ferro que canta.» | Une el dato con lo oído | `duda` |
| | Kael | «Pues que cante de camino a Oakhaven.» | Remate ligero | `ligero` |

### Decisiones de canon pendientes (propuestas, no canon)

- Los tres personajes (nombres, oficios y carácter) son propuesta del contrato V10.
- Ferro: «treinta años sin oír un hierro así» (su edad y oficio); el hierro de la Falla «canta».
- Hilda tiene su taller en la casa de la Calle del Mercado y un puesto a la entrada; Ferro, la herrería al final de la
  calle. En la ciudad 2D no hay herrería ni taller dibujados: es la casa de relleno de (70, 20) y la de (52, 21)
  (`oakhaven_piezas.gd`, `RELLENO`). Arte pendiente de gráficos.
- Mirta atiende en la plazuela, no dentro de la botica (la ciudad 2D no tiene interiores).
- Lya: «Pocos, pero enteros» (sobre los libros que ha leído): coherente con `voces_heroes.md`, sin revelar nada de lo
  propuesto sobre su pasado. Nada de Érebo ni de Final Fantasy X.

### Siguiente paso propuesto

1. Coordinador: las 9 señales y el cambio de la prueba (o decidir que Lya no hable).
2. Gráficos: herrería, taller y retratos (o muñecos) de los tres.
3. Pasar `prueba_ciudad_datos` y `prueba_oakhaven` otra vez con las señales hechas, y abrir el editor una vez para que
   genere los `.uid` de los archivos nuevos.
