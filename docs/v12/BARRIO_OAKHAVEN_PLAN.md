> Plan del barrio experimental de Oakhaven (15/11, noche). Estudio previo (5 lectores + arquitecto, solo lectura) en
> `D:\REBELUM_diagnosticoarrio_oakhaven\estudio\`. Encargo del usuario: ampliar la calle aprobada a un barrio jugable
> (caravanas → calle comercial → plaza → talleres → residencial → atajo), 3 interiores, 3 rutinas, misión «Antes de
> que se enfríe». El paquete «Oakhaven: La Corona Viva» NO está en el disco: todo es PROPUESTA.
>
> **Decisiones técnicas reversibles tomadas por el coordinador (documentadas; las de canon quedan para el usuario):**
> - Nombre de trabajo «Arrabal de las Carretas» [P] (se evita «Corona», que roza la corona del Sello).
> - Arrabal extramuros al oeste, escena propia `zonas3d/barrio/`, solo desde el banco; Oakhaven 3D no se toca.
> - Se conserva la TARDE DORADA aprobada de la muestra (el canon de Oakhaven es la hora azul: decisión del usuario).
> - Recompensa única de la misión: «Éter» ×2 (catálogo real; sin el conflicto de precio/lore del Farol del Peregrino).
> - Choques: un cuerpo por caja (lo medido como mejor). Sombreados de la muestra reutilizados sin cambios.

# PLAN DE DISEÑO: barrio experimental de Oakhaven (solo Auditoría, apagado por defecto)

Marcas: **[C]** canon que está en el código o en los documentos; **[P]** PROPUESTA del arquitecto, sin aprobar. Todo el barrio es **[P]**: el paquete «La Corona Viva» no está en el disco (estudio de canon), así que nada de esto se puede presentar como sacado de él.

## 0. Lo que he comprobado en el código (solo lectura)

- `equipo_extra.gd`:
  - `farol_peregrino` está en la l.94 (`atb_inicio` 35, gancho C1, en HECHOS) y se vende en la tienda de Oakhaven por 220 (EN_TIENDA, l.263).
  - `conseguir()` (l.458-465) **no comprueba `disponible()`** y devuelve "" si ya lo tienes.
  - La tanda v12 está apagada sin su interruptor (l.308, l.489).
- `progreso.gd`:
  - `estado()` devuelve `-> bool` (l.223).
  - CLAVES está en l.60-63. No hace falta ninguna clave nueva.
- `encargos.gd`:
  - FUENTES está en l.22-24.
  - `estado_de:` lo entiende `encargos` (l.77). Lo demás va a `load(fuente).cumple` (l.79-80).
- `banco_pruebas.gd`:
  - METAS_SESION en l.30-32, el caso `muestra_calle` en l.101-103, `en_banco()` en l.117.
  - `salir()` suelta las cachés de la muestra (l.181-182).
  - `_explorar` (l.337-343) **no pone metas por caso**: el barrio tiene que activarse a sí mismo en su `_ready` si `en_banco()`.
- `zonas3d/mapamundi/datos.gd`: INDICE 100 y INDICE_CUEVA 101 (l.18-19). El prólogo se exige en l.141. **102 está libre** (grep).
- `prototipos/vista3d.gd`:
  - `GIRO := 0.0` en l.24. Las teclas y el mando van en ejes del mundo (l.571-582).
  - CAL vuelve a cargar la escena con `reload_current_scene()` (l.119-122).
- `carga.gd` l.357-364: precalienta solo `muestra_calle.precalentar_en`.
- `oakhaven_3d.gd` l.623-627: guarda la PUERTA de fuera si estás dentro de la posada.
- `posada3d.gd` l.11: ORIGEN es (200,0,200).
- `crear_calle.py` **llama a `main()` al final sin guarda**: no se puede importar. El kit tiene que ser una COPIA en otro archivo y `crear_calle.py` no se toca. `crear_npc_chibi.py` recorre `OFICIOS` con `SOLO`.
- `npc_chibi.gd`: `crear` en l.37, `existe` en l.46, `clip` en l.101, `avanzar` en l.115, `andar` en l.121. `EN_BUCLE` está fijo en l.16.
- **Mejor plantilla de región que la muestra:** `zonas3d/sunken_3d.gd` junto con `zonas3d/sunken/trazado.gd`:
  - trazado como datos estáticos (ANDABLE en Rect2, `altura()`, `PIEZAS`, `en_mundo()`);
  - `_crear_vecino` con chibi o cápsula de reserva (l.319-354);
  - `hablar`, `_al_senal` con prefijo y `_al_terminar_dialogo` con guardado (l.357-396);
  - `piezas_al_alcance`, `_comprobar_cerca` y `_accion` (l.453-543).
  - Ojo: Sunken 3D también está a «tarde dorada». Con el barrio, el riesgo de confundir las dos ciudades es doble.
- `pruebas/prueba_ciudad_datos.gd`:
  - PROHIBIDO_D033 (l.35), PROHIBIDO_NEUTRO (l.37-38) y SENTIDO `corazon/recuerd/record/memoria` (l.39);
  - MAX_CARACTERES 110, MIN_DISTANCIA 2,5 y **MAX_VALOR_MISION 100** (l.28-32). El Farol vale 220.
- Nombres propuestos sin ningún uso en el repositorio: Maela, Tobías, Brena, Damián, Odila, Nela, Avena.
- Sin uso: `oak_barrio`, el prefijo de señal `bar:` y `barrio_v12`.

## 1. Ubicación y conexión con Oakhaven

- **[P] Es un arrabal extramuros, en su propia escena** `zonas3d/barrio/barrio.tscn`. Queda al oeste, pegado a la muralla oeste de Oakhaven, detrás de un postigo al final de la Calle del Cuervo (x≈0,8; y 25-27 del 80×56).
- **No toca nada de `oakhaven.gd` ni de Oakhaven 3D**: ningún LUGAR, NPC, cofre ni pieza.
- En el barrio, la muralla oeste de Oakhaven es el borde este de la plaza, con el **postigo cerrado de decorado** (ancla `postigo_oak`).
- **Hoy no se enlaza desde ninguna escena.** Solo se entra desde el banco, con un caso nuevo en `EXPLORAR["barrio"]` y los activos `["Kael","Lya","Garon"]`. No se toca la formación ni a Nix.
- **Sin salida al mapamundi:**
  - la puerta de caravanas es decorado (rastrillo bajado);
  - el atajo vuelve dentro del barrio;
  - la única salida es «Volver al banco» (Recursos).
- **Guardia del prólogo** en toda puerta o pasaje: `puede_pasar() = prologo_visto and hito("pv_02")`. Usa el mismo criterio que `cond:kael_salio` (`oakhaven.gd` l.670) y que `datos.motivo_bloqueo` (l.141).
- Fuera del banco, `_ready` hace `Recursos.cambiar_escena(banco_pruebas.CARGA)` y no sigue.
- **Decisiones del usuario:**
  - (a) Un arrabal extramuros con muro propio. Choca con el tono de «fuera de la muralla no os puedo proteger».
  - (b) El nombre. Evitar «Corona», que roza la corona del Sello. Nombre de trabajo [P]: «Arrabal de las Carretas».
  - (c) La tarde dorada horneada, cuando el canon de Oakhaven es la hora azul.

## 2. Recorrido de 6 tramos [P]

Coordenadas locales en metros: x hacia el este, z hacia el sur, y hacia arriba; el origen es el centro de la plaza. Unos 128 m de bucle.

Reglas por la cámara, que nunca gira:
- en los tramos de este a oeste (E-O), las fachadas altas solo al norte y el lado sur ≤ 1,6 m a menos de 4 m del paso;
- en los tramos de norte a sur (N-S), la cámara va fija en el eje.

| # | Tramo (sector) | Rect sector (x0,z0,w,h) | Paso andable | Cota y | Qué hay | Vista (siempre al norte) | Cámara |
|---|---|---|---|---|---|---|---|
| T1 | `caravanas` | (-52,-14, 20,22) | patio 18×12 | 0 | Arco de caravanas en el muro oeste con el rastrillo bajado (decorado). Carro de caravana con cajas y sacos (reutiliza `modelos/desierto/caravana_carro/_cajas/_barril _ligero.glb`). **Establo** al norte con Avena atada, abrevadero y gancho del cepillo. Pozo en el lado sur, bajo. | Establo y heno; arranque de la escalera del atajo | riel `x` [-49,-36] |
| T2 | `comercial` | (-32,-9, 22,16) | calle 22×6 (z -1..5) | 0→0,4 suave | Fachadas al norte: **horno de Maela** (x -26..-18) con mostrador a la calle y chimenea con humo, más 2 tiendas. Lado sur bajo: puestos y cajones. **Carro de reparto del horno parado** en (-13,5; 3,5). | El tejado del horno; detrás, las casas del T5, más altas | riel `x` [-29,-13] |
| T3 | `plaza` | (-10,-12, 20,20) | 19×15 | 0,4 | Mercado: puesto del pan de Maela, puestos bajos y una lonja con soportal al noreste (x 5..10). **Sin fuente**, que es de la Plaza del Tapiz. Borde este: la muralla de Oakhaven con el postigo cerrado. | Boca del patio de talleres y rampa | `libre` (x y z con límites) |
| T4 | `talleres` | (-13,-30, 24,18) | patio 10×18 (x -5..5) | rampa 0,4→1,4 (z -8→-18, 10 %) | **Taller de Damián, carretero de ruedas** (x -13..-5, z -24..-14), con portón doble al este. Ruedas apoyadas, potro de radios y pila de cajas de Tobías. Tonelería de decorado al este. **No hay forja** (Ferro e Hilda ya cubren el hierro). | Rampa y tejados del T5 | `eje` x=0 |
| T5 | `residencial` | (-40,-40, 27,16) | calle 39×4 (x -44..-5, z -30..-26) | 1,4; la vivienda a 1,75 (2 escalones) | Casas al norte con tendederos. **Vivienda de Odila y Nela** (x -26..-18). Lado sur: huertos cercados (bajos) detrás de las casas del T2. | Muro del arrabal y campos al norte | riel `x` [-41,-8] |
| T6 | `atajo` | (-46,-30, 6,24) | callejón 4×24 (x -44..-40) | 1,4→0 (dos tramos de escalones, z -22..-19 y -13..-10; altura en rampa continua, como el callejón de la muestra) | Callejón estrecho con un arco de paso (sin techo cerrado) y una hornacina con farol. Baja al T1 junto al establo y **cierra el bucle**. | Fondo del callejón | `eje` x=-42 |

Transiciones de cámara: por pesos con smoothstep de 2-3 m en los solapes, generalizando `peso_callejon`. Misma altura, inclinación (-25°) y campo (38°) que `camara_muestra` (`muestra_calle.gd` l.156).

## 3. Interiores [P]

Los tres van en la MISMA escena (patrón posada mejorado), cada uno en un ORIGEN lejano y oculto cuando no se usa. Al cruzar hay un fundido de 0,35 s + 0,15 s + 0,35 s, sin cambio de escena. Son «casa de muñecas» (sin muro sur ni techo) con cámara propia más cercana.

| Interior | ORIGEN | Tamaño | Distribución (distinta en cada uno) | Actividad | Puerta / condición / retorno |
|---|---|---|---|---|---|
| **Horno** | (-300,0,200) | 10×7 | **En L**: obrador delante (boca del horno de bóveda en la pared norte con luz POINT por ancla; artesa; estantes de enfriar; mostrador hacia la ventana de la calle). Detrás de una cortina, al este, **la zona doméstica** de Maela: mesa, alacena, escalera a la alcoba (decorado) y hogar pequeño. | Maela amasa y hornea; el estante de enfriar se llena y se vacía según su programa | Puerta `puerta_horno` (-22; 0,2; -1), **siempre abierta**. La cortina es un paso interno siempre abierto. Al salir aparece en (-22; 0,2; -0,3) mirando al sur. |
| **Taller** | (-300,0,240) | nave 9×7 alta + trastienda 4×7 al oeste | **Nave alta con portón lateral**: potro con una rueda a medio hacer, torno, banco de gubias y **un clavo con la silueta pintada de la galga, vacío** (pista). **La trastienda** tiene fresno apilado, pasadores en bruto y el banco de cortar. | Damián trabaja en el potro | Portón `puerta_taller` (-4,6; 1,4; -19,5), siempre abierto. **Trastienda**: paso interno cerrado hasta `estado:enf_taller`. Sin él aparece el aviso «Damián guarda ahí la madera buena.». Al salir aparece fuera del portón mirando al este. |
| **Vivienda** | (-300,0,280) | 8×8 **en profundidad** | Cocina y hogar delante, con **la galga sobre la repisa**, la mesa familiar y un cántaro. Dos escalones más arriba (+0,35), la alcoba del fondo: camas, arcón y el rincón de Nela con **una rueda de juguete tallada por Damián** (eco del taller). | Odila cose; Nela juega | Puerta `puerta_vivienda` (-22; 1,4; -30). La primera vez sale «Llamar a la puerta»: Odila abre (diálogo corto) y se pone `viv_llamado`. Después se entra directamente. Al salir aparece en (-22; 1,4; -29,4) mirando al sur. |

**Pista vivienda↔taller [P]:**
- En el taller, el clavo vacío con la silueta. Damián: «A ojo no corto un pasador. La galga está en casa.»
- En la vivienda, la galga en la repisa. Odila: «Damián se trae el trabajo a casa. Mira la repisa.»
- La rueda de juguete de Nela une los dos sitios.
- La galga es un **ESTADO** (`enf_galga`), no un objeto de inventario: `menus.gd` l.453 lo enseñaría y la tienda podría venderlo.

## 4. Las 3 rutinas [P]

El reloj es local de la escena, con un ciclo fijo por NPC: el paso actual es `(t − retraso_npc) mod ciclo`, con coste O(1). No se escribe `oak_franja`. Solo hay una meta de sesión, `barrio_reloj`, para sobrevivir a la recarga de CAL.

Los objetos tienen **UNA ubicación lógica** (`ubic[obj] = "sitio:<ancla>" | "mano:<npc>"`). Cada sitio tiene su copia y se enseña o se oculta; las copias de mano cuelgan de un `BoneAttachment3D` ("pecho" para lo que se lleva con dos manos, "mano.R" para el resto). El cambio se hace con el temporizador del paso, nunca con la pose del clip.

1. **Maela, la panadera** (ciclo de 120 s):
   - amasar en `int_horno_artesa`;
   - hornear en `int_horno_boca` (10 s);
   - *coger* `bandeja` (`int_horno_boca` → `mano:maela`);
   - cruzar el umbral `paso_horno` sin pararse;
   - *dejar* en `mostrador_horno`; con el reparto en marcha, en `carro_horno`;
   - *coger* `cesta_pan` (`mostrador_horno` → mano);
   - ir por T2 hasta `puesto_plaza` y *dejar*;
   - volver.
   - **Programa «carro_parado»** (misión empezada y `!enf_reparado`): deja la bandeja en el mostrador y espera junto a `carro_horno` mirando la rueda.
2. **Tobías, el porteador** (ciclo de 90 s):
   - en `carro_caravana` (T1) *coger* `caja`;
   - llevarla por T2, T3 y T4 hasta `pila_patio` y *dejar*;
   - volver de vacío;
   - *coger* `saco_harina` y llevarlo a `puerta_horno` (pila junto al umbral, fuera de su eje).
   - **«carro_parado»**: sentado junto a `carro_horno`.
   - **«reparto»** (`enf_reparado`): carga la `bandeja` del mostrador en `carro_horno`.
3. **Brena, la encargada del establo** (ciclo de 100 s):
   - `cepillo` de `gancho_cepillo` a `mano:brena`;
   - cepillar a Avena (25 s);
   - colgar el cepillo;
   - *coger* `cubo` (`establo` → mano);
   - ir a `pozo` y llenar (4 s);
   - llevar el cubo a `abrevadero` y verter: `abrevadero_lleno=true`, Avena pasa a «beber»;
   - *dejar* el cubo junto al abrevadero;
   - echar heno (tarea);
   - volver.
   - Avena **no anda**: está atada y solo tiene clips sin desplazamiento.

Otras reglas:
- Damián, Odila y Nela tienen puestos fijos con su «tarea». No son rutinas.
- **Fuera de cámara o a más de 28 m**, el NPC salta al estado calculado solo si está a más de 18 m de Kael (como `_presencia`). Dentro de la vista avanza a 4 Hz, o en cada fotograma de cerca (niveles de detalle de `mundo_vivo.gd` l.32-37).
- **Al hablar** (un diccionario de pausas por NPC, no un único `hablando`):
  - si está en un umbral, primero cruza;
  - si el paso es atómico (coger o dejar), espera a que acabe;
  - con un objeto en las manos usa `llevar_quieto` y no `hablar`;
  - al acabar, `retraso += pausa`.

## 5. Misión «Antes de que se enfríe» [P]

Patrón del cantero (`oakhaven_propuestas.gd` l.87-221): señales idempotentes, un estado bool por paso y **sin cuenta atrás**. Maela vuelve a meter el pan al horno: el título es tono, no un temporizador.

- **Estados** (bool en `mazmorras["oak_barrio"]`): `enf_carro_visto`, `enf_taller`, `enf_galga`, `enf_medida`, `enf_pasador`, `enf_reparado`, `enf_cesta`, `enf_entrega`, `enf_fin` y `viv_llamado`.
- **empieza**: `cond:enf_empieza` = `activado()` Y `hito:pv_02` Y (`enf_carro_visto` O `enf_taller` O `enf_medida` O `enf_pasador`). Coger la galga suelta NO empieza la misión.
- **fin**: `estado_de:oak_barrio/enf_fin`.
- **Pasos** (`hecho` en cada uno):
  1. Mira qué le pasa al carro del horno (`enf_carro_visto`, por Maela o examinando el carro: corte de desgaste en el pasador). Pone `j_sabe_pasador_roto`.
  2. Pregunta en el taller del carretero: `cond:enf_taller_o_mas`.
  3. Busca la galga del carretero: `cond:enf_galga_o_mas`. Con `saltado_si` solo para las pruebas.
  4. Mide el eje con la galga: pieza `carro_horno` «Medir el eje con la galga», `si: ["estado:enf_galga","!estado:enf_medida"]`. Pone también `enf_carro_visto`.
  5. Lleva la medida a Damián. Diálogo prioritario `si: ["estado:enf_medida","!estado:enf_pasador"]`; lo corta en la trastienda: `bar:pasador`.
  6. Pon el pasador en el carro: pieza «Poner el pasador», `bar:reparado`. Tobías carga y Maela da la cesta para la casa de Odila: `bar:cesta`.
  7. Lleva la cesta a la vivienda, todavía caliente: Odila, `bar:entrega`.
  8. Vuelve con Maela: `bar:fin` pone `enf_fin` **antes** de dar el premio.
- **Fuera de orden:**
  - la galga antes de empezar se guarda y no empieza la misión; su pista sale al empezar;
  - el taller antes que el carro: Damián *ha oído* que se paró el carro, y empieza la misión;
  - medir antes del taller vale si hay galga;
  - el pasador solo con `enf_medida`;
  - la cesta solo con `enf_reparado`;
  - salir a mitad de un diálogo no rompe nada, porque las señales repetidas no hacen nada.
- **Recompensa única [P, decide el usuario]:**
  - `farol_peregrino`, mediante `equipo_extra.conseguir()` comprobando antes `disponible()`;
  - si devuelve "" (ya comprado en la tienda), {"Poción": 2} con el `_dar` propio del módulo, porque el `_dar` de `oakhaven.gd` no da equipables.
  - Riesgos: vale 220 en la tienda (>MAX_VALOR_MISION 100) y su texto habla de «peregrinos» (lore de la Vía).
  - Alternativa sin conflictos: {"Éter": 2}.
  - Hay que actualizar la nota de `hallazgos.gd` l.53.

## 6. Modelo sabe / ha oído / cree [P]

En `oakhaven_barrio.gd`:
```
const MODOS := ["sabe", "oido", "cree"]
const AFIRMACIONES := {
 "pasador_roto": {"verdad": true}, "galga_en_casa": {"verdad": true},
 "culpa_caballo": {"verdad": false}}   # el carro duerme en el establo; Brena cree que Avena le dio una coz
const SABER := [
 {"npc":"maela","af":"pasador_roto","modo":"sabe"},
 {"npc":"tobias","af":"pasador_roto","modo":"oido","de":"maela"},
 {"npc":"brena","af":"culpa_caballo","modo":"cree"},
 {"npc":"damian","af":"galga_en_casa","modo":"sabe"},
 {"npc":"damian","af":"pasador_roto","modo":"oido","de":"rumor","si":"!estado:enf_carro_visto"},
 {"npc":"brena","af":"culpa_caballo","modo":"cree","si":"!estado:j_sabe_no_culpa_caballo"},
 {"npc":"tobias","af":"pasador_roto","modo":"sabe","si":"estado:enf_reparado"}]
```

Reglas:
- Gana la última regla cuyo «si» se cumple.
- «oido» exige «de»; nadie «sabe» algo falso; «cree» puede ser falso.
- Cada entrada de `NPCS[*].dialogos` declara `"dice": {af: modo}`, que tiene que casar con `modo_de(npc, af)`.
- Los `.dtl` terminan en `[signal arg="bar:oido:pasador_roto:tobias"]` y similares. Eso apunta bools DEL JUGADOR: `j_sabe_*`, `j_oido_*`, `j_cree_*`.
- Solo `j_sabe_*` hace avanzar un paso.
- Examinar a Avena o las herraduras pone `j_sabe_no_culpa_caballo` y Brena cambia de frase.
- Hay una opción «- ¿Quién te lo dijo?» (sintaxis de `oak_pip_secreto.dtl`).
- Las pistas del Diario llevan fuente y modo: «Tobías (se lo oyó a Maela): …», «Brena cree que…».
- **Rumores ambientales**: solo de caravanas, caminos, precios y guardia. **Ningún texto nombra la niebla, el Sello, Érebo, el tapiz ni al niño.** Tampoco aldeas.

**Texto:**
- frases al pasar ≤48 letras; globo ≤110; notas ≤15 palabras;
- vetado por subcadena: `olvid-`, `hermano`, `crio`, `recuerd`, `record`, `memoria`, `corazon`, `rocio`, `cripta`… Por ejemplo, «se dejó la galga», nunca «se le olvidó»;
- además niebla, sello, erebo, tapiz y corona.
- Ejemplos [P]: Maela «Al carro se le partió el pasador. El pan no espera.»; Brena «Seguro que fue Avena. Anoche estaba inquieta.»

## 7. Claves de guardado

No hay claves nuevas en `progreso.CLAVES` y FORMATO 3 sigue igual.

- `mazmorras["oak_barrio"]`: **solo bool**. Misión, `viv_llamado`, `j_*`.
- `pos_3d`/`pos_3d_ok`/`pos_3d_lugar = 102` (constante `INDICE` del barrio). Dentro de un interior se guarda **la puerta de fuera** de ese interior.
- En `_ready` se valida: si la posición está prohibida o cae en un ORIGEN de interior, se usa INICIO.
- `inventario`: solo el premio.
- `guardar()` solo actúa con `en_banco()`, y va a `user://banco_pruebas.save`.
- Metas de SESIÓN, que hay que añadir a METAS_SESION:
  - `barrio_v12` (activado);
  - `barrio_interior` (id y posición, solo para volver a aparecer dentro tras la recarga de CAL);
  - `barrio_reloj`.
- Los barks ya dichos y las veces de diálogo son de sesión.
- Partida antigua: sin el diccionario, todo vale false y la misión está oculta.
- **Botón de prueba «Guardar y recargar»** (solo en el banco): `Progreso.guardar` → `leer` → `restaurar` → `cambiar_escena(barrio.tscn)` **directamente**. `restaurar` devuelve MAPA para `zonas3d/` si modo3d está apagado: hay que comprobarlo en el banco.

## 8. Arquitectura técnica

- **Escena** `zonas3d/barrio/barrio.tscn` con `barrio.gd extends "res://prototipos/vista3d.gd"`. Sigue la plantilla de `sunken_3d.gd` para vecinos, piezas, Dialogic y guardado, y la de `muestra_calle.gd` para la luz horneada. **`muestra_calle.gd` y `crear_calle.py` no se tocan.**
- **Datos del trazado** en `zonas3d/barrio/trazado.gd`, estático como `sunken/trazado.gd`. También se escribe `barrio.json`, que leen Blender (recorte y sondas) y Godot. Así se evita la duplicación de cámaras que avisa MUESTRA §9.
- **Sectores horneados** con `fuente/kit_barrio.py`: una COPIA refactorizada del kit de `crear_calle.py`, con `Sector{nombre, semilla, rnd}`, anclas con prefijo y ventanas o entramados con (frente, tangente).
  - El generador es `fuente/crear_barrio.py` con `--solo <sector>`, `--fase blockout|completa` y `--muestras`.
  - Se construye todo en una sesión de Blender y cada sector se hornea con los demás como tapadores, para que no haya costuras.
  - **La escala de luz es COMÚN** (unos 2,23, o el percentil sobre todos).
  - Salidas: `barrio_<s>.glb`, `barrio_<s>_luz_{1024,2048}.png` y `barrio_<s>_sondas.png` (R=sol, G=cielo; no json, porque costaba 6-18 ms en el Redmi).
- **Shaders**: se reutilizan **sin cambios** los de `muestra_calle/` (`calle_estatico`, `vertice`, `hoja`, `brillo`). Así no hay programas nuevos y vale el precalentado actual.
  - Los NPC, el caballo y los objetos de mano llevan un shader nuevo `barrio_npc.gdshader` (sol y cielo por uniform desde `sonda(pos)` a 4 Hz). Ese sí hay que añadirlo al precalentado de `carga.gd`.
  - La sombra de contacto de los NPC y los uniformes globales en `project.godot` quedan para la Fase 2. **No se tocan ahora.**
- **Cámara**: lista de zonas `{rect, modo:'x'|'eje'|'libre', límites}` con pesos smoothstep. Interiores con cámara propia (como CAMARA_POSADA). Sin giro.
- **Choques**: un StaticBody3D por caja (medido como lo mejor), exportados como `choque_*` por sector. El suelo por sector, con `T.altura(x,z)` para las rampas.
- **Interiores**: en la misma escena, como sub-árboles en ORIGEN. `preparar(id)` hace `load_threaded_request` cuando Kael está a menos de 8 m de la puerta. Dentro, el exterior va con `visible=false` y los NPC exteriores pausados; fuera, los interiores con `visible=false` y `PROCESS_MODE_DISABLED`.
- **Niveles de detalle y visibilidad**:
  - visibilidad manual por sector: el actual + el del norte + los laterales en cuadro;
  - vegetación con `visibility_range_end` de 30-35 m;
  - NPC con los niveles de 12, 28 y 34 m;
  - Avena animada solo cerca y si se ve.
- **Cachés estáticas**: todas con `soltar_caches()`, llamado desde `banco.salir()` y desde `_exit_tree`. El cierre 0xC0000005 sigue ABIERTO.

## 9. Presupuesto móvil (Redmi Mali-G57, perfil bajo, 30 FPS)

| Concepto | Límite |
|---|---|
| Sector visible | ≤18 llamadas (objetivo 14), ≤60k triángulos (fijo ≤12k, piezas ≤20k, vegetación ≤28k) |
| A la vez en pantalla | ≤2 sectores + Kael (≈9 llamadas, 18k) + NPC y caballo (≤20 llamadas, ≤25k) → **≤65 llamadas, ≤160k** (el borde conocido son 80 llamadas y 165k) |
| Interior | ≤14 llamadas, ≤35k, luz de 1024 |
| NPC nuevo | ≤6000 triángulos y 22 huesos. Caballo: ≤5000 triángulos, unos 16 huesos, atlas de 512. Cada utensilio ≤300 triángulos, con un atlas y un material opaco (nada transparente: ni agua, ni harina, ni vapor en bajo o medio) |
| Memoria | +25-45 MB sobre la calle (ESTIMACIÓN) → PSS ≤900 MB (Oakhaven 3D: 1004) |
| Entrada | ≤1 s en negro con caché (ESTIMACIÓN: 6 sectores × 72-184 ms). Medir con `diagnostico_tirones.gd` por sector |
| CPU | `us_proceso` del barrio vivo ≤1,5 ms en el PC; en el Redmi, medir |

## 10. Pruebas

**Automáticas, sin ventana:**
- `pruebas/prueba_barrio_trazado.gd` (A):
  - todo lo andable conectado (BFS en rejilla de 0,25 m desde INICIO hasta todas las puertas, los nodos del grafo y las anclas);
  - anclas dentro de lo andable y fuera de los umbrales;
  - examinables a ≥2,5 m entre sí;
  - lado sur ≤1,6 m (desde `barrio.json`);
  - cámara y altura continuas (sin saltos >0,3 m);
  - las anclas del contrato existen.
- `pruebas/prueba_barrio_interiores.gd` (B):
  - entrar y salir de los 3;
  - `guardar_posicion` dentro guarda la puerta de fuera;
  - `restaurar` nunca deja a Kael en un ORIGEN;
  - recarga de CAL vuelve a dentro;
  - la trastienda, cerrada y abierta;
  - doble pulsación y «Volver al banco» en mitad de un fundido;
  - exterior oculto dentro.
- `pruebas/prueba_barrio_datos.gd` (C):
  - apagado no cambia nada (`encargos.todos()` sin la misión visible);
  - textos: los PROHIBIDO ampliados con niebla, sello, erebo, tapiz, corona y SENTIDO, y los límites de 48, 110 y 15;
  - `error_condicion`;
  - SABER coherente;
  - la misión en los órdenes normal, galga primero, taller primero y medir antes del taller;
  - premio una sola vez, también con el Farol ya comprado;
  - `_guardar_y_cargar` en cada paso;
  - partida antigua;
  - sin `pv_02` no empieza.
- `pruebas/prueba_barrio_vivo.gd` (C):
  - ciclos completos;
  - cada objeto siempre en una sola ubicación;
  - hablar en cada paso y reanudar;
  - nadie se para en un umbral;
  - el salto fuera de cámara coincide con lo simulado;
  - `us_proceso`.
- `prueba_banco_pruebas`: subir el número de casos de EXPLORAR (A).

**Con los controles normales, con ventana:**
- `pruebas/fotos_barrio_recorrido.gd` (C, en la integración), copiada de `fotos_cantero_recorrido.gd`:
  - andar con teclas o clics;
  - `_accion(texto)` y `_dialogo()`;
  - la misión completa en orden normal y con la galga primero;
  - «Guardar y recargar» a mitad;
  - una captura por tramo y por interior.
- `pruebas/medir_barrio.gd` (A): llamadas, primitivas y ms por sector e interior, en bajo y medio.
- **Redmi**: APK de prueba copiada por USB a Download (D-065). FPS, PSS y tirones por sector e interior, en perfil bajo.

## 11. Reparto en 3 tareas paralelas y su CONTRATO

**Fase 0 (secuencial, la hace A, corta, se sube a `integracion-experimental` antes de abrir las ramas):**
- `trazado.gd` con TODOS los nombres del contrato (valores provisionales);
- los stubs de `interiores.gd`, `oakhaven_barrio.gd` y `barrio_vivo.gd` con estas firmas y valores neutros;
- `barrio.tscn` y `barrio.gd` con un blockout de cajas sacado del trazado;
- el caso del banco.

Después, ramas `area-barrio-a/b/c`. **Cada archivo tiene UN dueño**; los stubs pasan a B y C.

### Nombres fijos

- **Anclas exteriores** (A, en `T.ANCLAS`, Vector3 local):
  - `inicio`, `arco_caravanas`, `postigo_oak`, `carro_caravana`, `pozo`, `abrevadero`, `establo_caballo`, `gancho_cepillo`;
  - `puerta_horno`, `mostrador_horno`, `carro_horno`, `puesto_plaza`, `pila_patio`, `puerta_taller`, `puerta_vivienda`;
  - nodos del grafo: `n_carav`, `n_establo`, `n_pozo`, `n_com_o`, `n_horno` (-24,5; 0,2; 1,5, fuera del eje de la puerta), `n_com_e`, `n_plaza_o`, `n_plaza`, `n_patio_s`, `n_patio_n`, `n_res_e`, `n_res_c`, `n_res_o`, `n_atajo_n`, `n_atajo_s`.
- **Umbrales** `T.PASOS`: `paso_horno`, `paso_taller`, `paso_vivienda`, `paso_atajo`.
- **Anclas interiores** (B, `int_<id>_<nombre>`):
  - `int_horno_{entrada,salida,boca,artesa,estante,mesa,maela}`;
  - `int_taller_{entrada,salida,clavo,potro,banco_corte,paso_trastienda,damian}`;
  - `int_vivienda_{entrada,salida,repisa,mesa,rincon,odila,nela}`.
- **Pasos internos**: `cortina_horno`, `trastienda`, `alcoba`.
- **Utensilios** (B entrega `zonas3d/barrio/modelos/utensilios.glb`, con nodos de pivote en el punto de agarre): `bandeja`, `cesta_pan`, `caja`, `saco_harina`, `cepillo`, `cubo`, `galga`, `pasador`, `pasador_roto`. Si falta alguno, C usa un BoxMesh.
- **NPC**: `maela`, `tobias`, `brena`, `damian`, `odila`, `nela`; caballo `avena` (examinable, no habla).
- **Prefijo de señal** `bar:`; mazmorra `oak_barrio`; pos_3d_lugar 102.

### API mínima

```gdscript
# A — zonas3d/barrio/trazado.gd (estático)
const SECTORES := {"caravanas": Rect2(...), ...}; const ANCLAS := {...}; const PASOS := {...}
const PUERTAS := {"horno": {"fuera": Vector3, "mira": float, "radio": 1.6, "texto": "Entrar en el horno"}, "taller": {...}, "vivienda": {...}}
const GRAFO := {"n_plaza": ["n_plaza_o", "n_patio_s"], ...}; const CAMARA_ZONAS := [...]
static func andable(x, z) -> bool; static func altura(x, z) -> float; static func sector_de(x, z) -> String
static func ancla(id: String) -> Vector3
# A — barrio.gd (la región que reciben B y C)
var kael; var cam; var perfil; var interior := ""      # "" = fuera
signal interior_cambiado(id: String)
func avisar(texto, efecto := "", seg := 2.8) -> void; func guardar() -> void; func ocupado() -> bool
func sonda(p: Vector3) -> Vector2                        # fuera: sector; dentro: delega en interiores
func iniciar_dialogo(ruta: String) -> bool               # conecta Dialogic, filtra "bar:" → Barrio.aplicar, guarda al acabar y llama vivo.reanudar_todos()
func ancla(id) -> Vector3                                # "int_*" → interiores.ancla; si no, T.ancla
# B — zonas3d/barrio/interiores.gd (extends Node3D)
const IDS := ["horno", "taller", "vivienda"]; const ORIGEN := {...}
static func interior_de(p: Vector3) -> String
func construir(region) -> void; func preparar(id) -> void; func mostrar(id) -> void
func entrada(id) -> Vector3; func mira_entrada(id) -> float; func salida(id) -> Vector3
func andable(p: Vector3) -> bool; func altura(p) -> float; func abrir_paso(nombre, abierto: bool) -> void
func ancla(nombre) -> Vector3; func camara(id, k: Vector3) -> Array; func sonda(p) -> Vector2
static func soltar_caches() -> void
# C — ciudades/oakhaven_barrio.gd (estático)
const NOMBRE := "oak_barrio"; const NOMBRE_LUGAR := "Oakhaven (barrio de prueba)"; const ACTIVO_POR_DEFECTO := false
static func activado() -> bool; static func cumple(c) -> bool
static func puerta(id) -> String            # "" = se puede pasar; si no, el aviso (incluye la guardia de pv_02/prólogo)
static func paso_interno(nombre) -> bool
const NPCS := {...}; const PIEZAS := {id: {"ancla", "radio", "boton", "si", "senal", "texto", "texto_sin"}}
const MISIONES := [...]; const AFIRMACIONES := {...}; const SABER := [...]
static func accion(pid) -> Dictionary       # {texto, efecto, dialogo, guardar}
static func dialogo_de(npc, veces) -> String; static func frase(npc, veces) -> String
static func aplicar(senal) -> String; static func programa(npc) -> String; static func modo_de(npc, af) -> String
static func registrar_dialogic() -> void
# C — zonas3d/barrio/barrio_vivo.gd (extends Node3D)
signal vio(hecho: String)
func montar(region) -> void; func piezas() -> Array   # [[npc, pos, radio, "Hablar con Maela"]] de la zona actual
func hablar(id) -> void; func reanudar_todos() -> void; func ocupa(p: Vector3) -> bool
func al_interior(id) -> void; static func soltar_caches() -> void
```

`barrio._accion` reparte así: `entrar_<id>` y `salir_<id>` → A + B (fundido); un id de NPC → `vivo.hablar`; cualquier otro id → `Barrio.accion(pid)`. Las piezas se reúnen de `T.PUERTAS`, `interiores` (salir), `vivo.piezas()` y `Barrio.PIEZAS` filtradas por zona (prefijo del ancla).

### (A) Exterior + kit/Blender + región

- **Archivos:**
  - `zonas3d/barrio/{barrio.gd,barrio.tscn,trazado.gd,sectores.gd}`;
  - `zonas3d/barrio/fuente/{kit_barrio.py,crear_barrio.py}`;
  - `zonas3d/barrio/modelos/barrio_*`, `barrio.json`;
  - `pruebas/{prueba_barrio_trazado.gd,medir_barrio.gd}`.
- **Únicos cambios fuera de su carpeta:**
  - `banco_pruebas.gd`: EXPLORAR["barrio"]; METAS_SESION con `barrio_v12`, `barrio_interior` y `barrio_reloj`; `soltar_caches` de las tres clases en `salir()`;
  - el número de casos en `prueba_banco_pruebas`;
  - el precalentado en `carga.gd` (en la integración).
- **Orden de trabajo:**
  1. blockout con la cámara por zonas;
  2. hornear `comercial` + `plaza` y medir en el Redmi;
  3. el resto de sectores.
- **No toca:** `muestra_calle/*`, `crear_calle.py`, `project.godot`, Oakhaven.

### (B) Interiores

- **Archivos:**
  - `zonas3d/barrio/interiores.gd`, `zonas3d/barrio/interiores/*.json` (anclas, bloqueos, cámaras);
  - `zonas3d/barrio/fuente/crear_interiores.py`: importa `kit_barrio.py` de A; hasta tenerlo, blockout en Godot;
  - `zonas3d/barrio/modelos/int_*` y `utensilios.glb` (con `fuente/crear_utensilios_barrio.py`);
  - `pruebas/prueba_barrio_interiores.gd`.
- **Encargo:** la luz de horno y hogar por ANCLAS a luces POINT (`preparar_cycles`); la de las ventanas, horneando con el exterior en la escena cuando A lo tenga.
- **No toca** `barrio.gd`: lo pide a A por el contrato.

### (C) Rutinas + misión + conocimiento

- **Archivos:**
  - `ciudades/oakhaven_barrio.gd`;
  - `zonas3d/barrio/{barrio_vivo.gd,utensilios.gd,npc_barrio.gd}` (`npc_barrio.gd` es una subclase de `npc_chibi` con los bucles nuevos; `npc_chibi.gd` no se toca);
  - `dialogos/oakhaven/barrio/*.dtl`, `dialogos/personajes/oakhaven/barrio/*.dch`;
  - modelos: `fuente/crear_npc_chibi.py`, **solo añadiendo** los oficios `panadera`, `porteador` y `encargada_establo` (sin herramienta horneada; clips `caminar_llevar`, `llevar_quieto`, `coger`, `dejar`, `hornear`, `amasar`, `cepillar`, `verter`) y las personas de Damián, Odila y Nela. Se regenera solo con `SOLO`;
  - `fuente/crear_caballo.py`: un prototipo que se enseña al usuario, no el definitivo. Hunyuan3D no se usa;
  - `pruebas/{prueba_barrio_datos.gd,prueba_barrio_vivo.gd,fotos_barrio_recorrido.gd}`.
- **Cambios fuera de su carpeta:** una línea en `encargos.gd` FUENTES y la nota de `hallazgos.gd` l.53.
- **Reserva:** si falta un modelo, una cápsula (patrón de Sunken).

**Integración** (el orquestador): `lista_pruebas.txt`, el precalentado de `carga.gd`, `fotos_barrio_recorrido` de punta a punta y la medida en el Redmi.

## 12. Riesgos principales

1. La luz global de Kael (`_luz_kael`) haría parpadear a los NPC con StandardMaterial: hace falta `barrio_npc.gdshader`, sin probar todavía en Compatibility ni en el Redmi.
2. Costuras de luz entre sectores: escala común y misma sesión de Blender.
3. Un lado sur alto taparía a Kael, y las transparencias fallan en bajo y medio.
4. Las palabras vetadas por subcadena.
5. La recompensa (precio y lore del Farol) está sin decidir.
6. El nombre, el arrabal extramuros y la hora dorada frente a la azul piden decisión del usuario.
7. Las cachés estáticas y el cierre 0xC0000005, que sigue abierto.
8. Las cifras de memoria y de carga son ESTIMACIONES hasta medirlas en el Redmi.
