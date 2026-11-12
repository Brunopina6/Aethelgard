# Narrativa, V12: la misión de incorporación de Naira, jugable (PROTOTIPO APAGADO)

## 12/11/2026, 03:20-04:40 · rama LOCAL `claude/v12-fase2-naira-mision` (`D:\Aethelgard_v12_naira_mision`, desde `claude/rebelum-v12` @ `3e032c3`)

Encargo: «La única noche que cabe en un día» (`docs/v12/NAIRA.md` §4) jugable de principio a fin, **detrás del
interruptor `naira_v12` (APAGADO)**. Naira sigue siendo una **propuesta, no canon**. Sin push ni merge.

### Commits

| Commit | Qué |
|---|---|
| `2ec5636` | Diálogos: `dialogos/personajes/naira.dch` y las 9 timelines `dialogos/mar_cristal/nr_*.dtl` (+ `.uid`); `project.godot`: solo las 10 entradas nuevas de Dialogic |
| `3688abb` | Lógica: `zonas3d/mar_cristal/naira_mision.gd` y `observatorio.gd` (nuevos) y enganches en `mar_cristal_3d.gd`, `trazado.gd`, `clima.gd`, `mision.gd`, `buscador.gd` y `progreso.gd` |
| `520ea4e` | `pruebas/prueba_naira_mision.gd` (+ `.uid`) y una línea en `lista_pruebas.txt` |
| `f2a7a7d` | Si se carga la partida entre la medición y el combate, vuelve la escena de la totalidad (no la del reintento) |
| `8986f1d` + el último | este informe (el primero salió vacío por un error de mi `sed`; el segundo lo rellena) |

## 1. Cómo se activa

- Interruptor de desarrollo de la tanda de combate: `grupo.gd` `naira_v12()` → `Engine.set_meta("naira_v12", true)` o
  el argumento `-- naira_v12` (`NAIRA_POR_DEFECTO = false`). **Sin él, la región no crea el módulo de la misión**: ni
  observatorio, ni explanada, ni plomadas en el buscador, ni piezas, ni diálogos, ni objetos, ni hitos.
- Requisito en el juego: `mc_fin` («La caravana perdida» terminada). Antes, Naira está en su puerta pero no habla
  («Hoy no. Estoy midiendo.»).

## 2. La misión, paso a paso (comprobado ejecutando, aislado, `520ea4e`)

| # | Hito | Dónde y qué pasa | Sistema |
|---|---|---|---|
| 1 | `nr_rumor` | Campamento: al acercarse, aviso «Oren e Ismena discuten junto al fuego…». Hablar con Oren o con Ismena → `nr_campamento_rumor` | timeline nueva; las acciones «oren»/«cartografa» las toma la misión tras `mc_fin` |
| 2 | `nr_observatorio` | El **Viejo Observatorio de Calid**, al nordeste (torre en (70, 9), puerta en (70, 13,9)), más allá de la arena que tiembla, en una explanada. «Hablar con la astrónoma» → `nr_torre_puerta`: los echa, Garon dice «No», ella acepta el buscador y se presenta | `observatorio.gd`; `trazado.gd` `llanos_extra` |
| 3 | `nr_plomada_1/2/3` → `nr_plomadas` | Con el buscador (únicos «naira» de `buscador.gd`, pitido raro): junto a la torre (76,2; 11), en la boca del cañón del oeste (19,5; 33,5) y **en la arena de Bramavidrio** (71; 43). Antes, una vez `nr_plomadas_espera`; luego un aviso con las que faltan | `buscador.gd` REGIONES, `hallazgo` |
| 4 | `nr_medicion` | «Darle las plomadas» → `nr_medicion`. Las plomadas pasan al trípode (cuatro), la luz baja 9 s, la cámara se acerca y mira al cielo (estrellas, esfera armilar encendida y el sol tapado con su corona). Nadie se mueve en el momento ni hay encuentros | `clima.gd` `eclipse`; `observatorio.gd` cielo; `mar_cristal_3d.gd` `_colocar_camara` |
| 5 | (combate) | Totalidad → `nr_eclipse_antes`: Grimfangs (cazan de noche); **Garon guarda la puerta** → combate fijo `nr_eclipse` con **Kael, Lya y Naira y Garon en la reserva**, sin huida | `combate.gd` sin tocar: `GRUPOS[0]` (dos Grimfang), `encuentro()` de la región |
| 5b | — | **Perdido**: se vuelve con el grupo curado (lo de siempre), el grupo de antes, la totalidad sigue; hablar con Naira → `nr_eclipse_reintento` → otra vez | `naira_mision.gd` `al_entrar` |
| 6 | `nr_eclipse` (+ `nr_eclipse_perfecto`) | **Ganado**: `nr_eclipse_despues` (el brazalete no se apagó; «No me cuides») y la luz vuelve en 6 s. Si Naira preparó su Eclipse y nadie la golpeó mientras preparaba: **Lente ahumada** | Medidor externo (abajo) |
| 7 | `nr_catalogo` | «Mirar el Almanaque» en el atril → `nr_catalogo`: 41 estrellas sin nombre; «…me llamo Naira. Apúntalo.» | timeline |
| 8 | `nr_union` | «Hablar con Naira» → `nr_union` → `poner_hito("nr_union")` y `Grupo.unir("Naira")`: entra **en la reserva** (el grupo va lleno) y aparece la **Formación**; aviso «cámbialo en Grupo › Formación»; +1 Almanaque de las Estrellas sin Nombre; Naira deja la puerta | `grupo.gd` (API de la tanda de combate) |

Recompensas (modestas, «los astrónomos no cobramos»): el Almanaque (objeto) y, solo con la medición perfecta, la Lente
ahumada (objeto). Sin monedas. El Astrolabio de Bronce llega con sus datos (`inventario.preparar_recluta`).

**Naira de invitada en el combate.** Antes de `nr_union` no es del grupo: al pedir el combate, `invitar_naira()` le da
sus datos (`grupo.gd` `_crear_recluta`, nivel 1 con su plantilla, como `unir`) y una formación de un combate
(`Grupo._poner([Kael, Lya, Naira], [Kael, Lya, Garon, Naira])`). La formación de antes se guarda en la partida
(`mazmorras["naira_mision"]`) y **se repara al entrar en la región, siempre** (también con el interruptor apagado), así
que ni el guardado que hace el combate al terminar ni un cierre a medias dejan a Naira en el grupo antes de su hito.
Comprobado al perder y al ganar.

**La medición perfecta sin tocar `combate.gd`:** un observador (`naira_mision.gd`, clase `Medidor`, vivo en
`Engine` «nr_medidor») lee cada fotograma a Naira en `heroes` de la escena del combate: cuenta los golpes que le quitan
vida mientras tiene `conjuro` (su preparación, `magia_negra.gd`) y si preparó su Eclipse. Se desengancha solo al
volver. Una barrera que para el golpe no cuenta (no quita vida).

## 3. El observatorio y el eclipse

- **Lugar** (dentro del primer sector, como pedía la opción barata de NAIRA.md §4.1): torre de arenisca de 7 m (2 bajo
  la arena), franjas de sillares, cornisa de bronce verdeado, almenas rotas, puerta en arco con marco de bronce,
  saeteras, dunas que la entierran por el norte; arriba, **esfera armilar de tres aros que gira** (se enciende un poco
  en el eclipse) y un anteojo; delante, trípode con las plomadas, atril con el Almanaque y Naira (modelo provisional,
  sin cambiarlo). Choques: torre y atril (`StaticBody3D`) y `_prohibido`. Sin luces nuevas; unas 30 mallas pequeñas,
  una malla de puntos (180/260/340 estrellas según perfil) y dos planos del cielo. **Sin medir en el Redmi.**
- **Explanada:** `trazado.gd` `llanos_extra` (vacío por defecto: `altura()` es la de siempre). Solo con la misión.
- **Eclipse** (`clima.gd`, `eclipse` 0-1): se mezcla encima de la luz del perfil y de la tormenta (ambiente, cielo,
  niebla, energía y color del sol); con 0 no se toca nada. **Comprobado en alto y en bajo** (`LUZ_SIN_SOMBRAS`): tras
  el eclipse, cielo, ambiente y sol vuelven **exactos** (`is_equal_approx`). Sin tormentas sistémicas mientras dura.
- **El momento:** cámara a 20° y 12 m que además mira 14° hacia arriba (`mar_cristal_3d.gd` `_colocar_camara`; la
  inclinación baja de verdad metía la cámara en las dunas: captura descartada del primer intento).

## 4. Diálogos (Dialogic) con intención y gesto

Formato del Mar de Cristal: Kael `left` y Lya `right` con `vivo_pv`; **Naira `center` con `vivo_pv`** (retrato
provisional `personajes/naira/naira_retrato_provisional.png`, nombre en verdín `#5FB49C`); Garon, Oren e Ismena sin
`join`. **Gestos de Naira:** su retrato aún no tiene poses, así que van como `pose+movimiento` (`naira_seria+firme`):
hoy se ve el movimiento (`retrato_vivo.gd`), y la pose saldrá sola cuando su `.dch` tenga la ilustración de esa
etiqueta (las de NAIRA.md §2.5). Etiquetas por acordar con el coordinador. Todas las intervenciones ≤ 70 caracteres
(comprobado por la prueba). «—» = sin gesto (sin retrato, o sigue el anterior).

**Antes y después respecto a la propuesta (NAIRA.md §4.3):**

| Timeline | Propuesta | En el juego | Por qué |
|---|---|---|---|
| `nr_campamento_rumor` | 6 frases | 9: + Kael pregunta dónde, Ismena da la dirección («al nordeste. Pasado el arenal del gusano»), Garon «Con la noche salen los que cazan de noche», Kael cierra | Dar el rumbo en el propio diálogo y sembrar el combate |
| `nr_torre_puerta` | «Habéis pisado mi medición» … «Faltan tres. El eclipse es hoy. Iros» / Garon: «No.» | «Estáis pisando…»; «Esa es la única que me ha dejado el viento. Faltan tres.» + el buscador («palo que pita»), las tres pistas de sitio y **las presentaciones**: «Naira. No hace falta que lo recordéis.» | El nombre sale en el combate (HUD), así que se presenta antes; su «no hace falta que lo recordéis» prepara el «Apúntalo» del catálogo |
| `nr_plomadas_espera` | (esquema) | 3 frases: prisa, el pitido raro, «Si el suelo tiembla… Cavad y salid» | Pista sin repetir la torre |
| `nr_medicion` | (esquema) | 9 frases: el «aire pesa» cerca de la niebla y «No sé qué pesa. Por eso lo mido» (NAIRA.md §1.2), «Allí, donde no estorbéis», la luz se va | Medir sin explicar (nada de la Gran Verdad) |
| `nr_eclipse_antes` | «Cuatro minutos…» … «Necesito tres turnos» | + «Un eclipse es la única noche que cabe en un día»; los Grimfangs (cazan de noche); «Necesito prepararlo. Un rato.» | Los Hollines de la propuesta no son un enemigo del combate (es Grimfang) y tocan la niebla; y la preparación real es de un turno suyo, no tres (límite abajo) |
| `nr_eclipse_reintento` | — | 2 frases nuevas: «Me han roto la cuenta, no el cielo.» | El reintento tras perder |
| `nr_eclipse_despues` | 5 frases | 6: + «Mirad. Ya vuelve.» (da paso a la luz) | El momento de la luz |
| `nr_catalogo` | 8 frases | las mismas | — |
| `nr_union` | Garon: «Yo duermo en el suelo.» | «Duermo en el suelo.» (eco exacto de `oak_posada_grupo`); Kael con `ligero+risa` | Continuidad con Oakhaven |

**Intenciones y gestos (tabla completa):**

`nr_campamento_rumor` (Kael, Lya, Garon, Oren, Ismena)

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Oren | La de la torre del norte… La saludé y me tiró una piedra. | chiste para no admitir el susto | — |
| 2 | Ismena | Le gritaste «¡eh, tú!» desde abajo. Yo también te la tiro. | la riña cariñosa de siempre | — |
| 3 | Oren | Y me dijo: «Me estás tapando el cielo». ¡A mediodía! | sigue el chiste | — |
| 4 | Kael | ¿Una torre? Por ahí solo hay dunas y arena que tiembla. | curiosidad | sorpresa |
| 5 | Ismena | Medio enterrada, al nordeste. Pasado el arenal del gusano. | orienta: es cartógrafa | — |
| 6 | Ismena | Dice que hoy habrá noche a mediodía. Yo no pregunto. | dato seco | — |
| 7 | Lya | Habla de un eclipse. La luna tapará el sol un rato. | lo sabe y lo dice exacto | decidida |
| 8 | Garon | Con la noche salen los que cazan de noche. | parte militar; siembra el combate | — |
| 9 | Kael | Pues vamos a ver una noche de día. Y a esquivar piedras. | ganas, con broma | ligero |

`nr_torre_puerta` (Kael, Lya, Naira, Garon)

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | Alto. Estáis pisando mi medición. | echarlos con autoridad | naira_seria+firme |
| 2 | Kael | ¿Tu qué? | descolocado | sorpresa |
| 3 | Naira | Una plomada de bronce. Bajo tu bota izquierda. | precisión como arma | naira_seria |
| 4 | Kael | ¿Y la derecha? | broma para recuperar terreno | ligero |
| 5 | Naira | La derecha solo pisa arena. Enhorabuena. | le gana la broma sin sonreír | naira_ironica+duda |
| 6 | Lya | Perdona. Podemos ayudarte a colocarla. | arreglar el daño | preocupada |
| 7 | Naira | Esa es la única que me ha dejado el viento. Faltan tres. | el problema, en un dato | naira_mira |
| 8 | Naira | Y el eclipse es hoy. Iros: tardo menos sola. | rechaza la ayuda que necesita | — |
| 9 | Garon | No. | se quedan | — |
| 10 | Naira | ¿«No»? ¿Ese es todo vuestro argumento? | le discute la certeza | naira_incomoda+duda |
| 11 | Garon | Tenemos un palo que pita. | humor seco sin querer | — |
| 12 | Kael | Un buscador. Encuentra metal enterrado. Y a veces, lo que buscas. | presume del juguete | ligero |
| 13 | Naira | …Interesante. Bronce. Del tamaño de un puño. | le interesa (y le da miedo perder el eclipse) | naira_interesante+inquieta |
| 14 | Naira | Una, junto a la torre. Otra, en la boca del cañón del oeste. | pista exacta | — |
| 15 | Naira | La tercera, en la arena que tiembla. Allí no voy yo. | admite un miedo con humor | — |
| 16 | Kael | Allí vamos nosotros. Soy Kael. Ella es Lya; el grande, Garon. | decide y presenta | decidido |
| 17 | Naira | Naira. No hace falta que lo recordéis. Daos prisa. | su herida, dicha como trámite | naira_seria |

`nr_plomadas_espera` (Naira)

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | El sol aún no ha empezado a menguar. Pero lo hará. | prisa | naira_mira |
| 2 | Naira | El bronce suena distinto que la chatarra. Fiaos del pitido raro. | pista práctica | — |
| 3 | Naira | Si el suelo tiembla, no discutáis con él. Cavad y salid. | aviso con ironía | naira_seria+firme |

`nr_medicion` (Kael, Lya, Naira)

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Kael | Tres plomadas. Una huele a gusano, pero ahí la tienes. | orgullo con broma | ligero |
| 2 | Naira | Las tres, y a tiempo. Lo apunto: «Ayuda inesperada. Eficaz». | agradece a su manera | naira_apunta+firme |
| 3 | Lya | ¿Para qué sirven? | curiosidad de estudiosa | duda |
| 4 | Naira | Caen, y mido cuánto tardan. Cerca de la niebla, el aire pesa. | su descubrimiento, sin explicarlo | naira_mira |
| 5 | Lya | ¿Pesa? | inquietud | — |
| 6 | Naira | No sé qué pesa. Por eso lo mido. | honradez de científica | naira_seria |
| 7 | Naira | Podéis quedaros. Allí, donde no estorbéis. | primera concesión | naira_ironica |
| 8 | Kael | Eh… ¿es cosa mía, o se está yendo la luz? | asombro | sorpresa |
| 9 | Naira | Primer contacto. No miréis al sol: gafas solo tengo yo. | emoción contenida y cuidado sin decirlo | naira_interesante+inquieta |

`nr_eclipse_antes` (Kael, Lya, Naira, Garon)

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | Totalidad. Cuatro minutos. Si alguien habla, que sea después. | concentración | naira_mira |
| 2 | Lya | Se ven las estrellas… a mediodía. | asombro | duda |
| 3 | Naira | Un eclipse es la única noche que cabe en un día. | su frase: lo que ama | — |
| 4 | Garon | Algo baja por la duna. Hachas. Grimfangs. | parte militar | — |
| 5 | Kael | ¿Ahora? ¿No podían esperar cuatro minutos? | broma nerviosa | sorpresa |
| 6 | Garon | Cazan de noche. Para ellos, ya es de noche. | explica el peligro | — |
| 7 | Garon | La puerta es mía. Vosotros, con ella. | se queda fuera: presenta la reserva | — |
| 8 | Naira | Necesito prepararlo. Un rato. Que nadie me toque. | el reto del combate | naira_interesante+inquieta |
| 9 | Lya | ¿Nadie? | la pregunta cálida | duda |
| 10 | Naira | Ellos, sobre todo. Vosotros, poco. | primera concesión de cercanía | naira_ironica |
| 11 | Kael | Hecho. Tú mira al cielo; nosotros miramos lo demás. | protegerla | decidido |

`nr_eclipse_reintento` (Naira): 1 «Seguimos en la umbra. Me han roto la cuenta, no el cielo.» — terquedad, no rendirse —
`naira_seria+firme` · 2 «Otra vez. Y esta vez, que no me toquen.» — el reto, otra vez, con miedo —
`naira_interesante+inquieta`.

`nr_eclipse_despues` (Kael, Lya, Naira)

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | Tu brazalete no se ha apagado. Todo lo demás, sí. | el dato que lo cambia todo para ella | naira_mira |
| 2 | Kael | Es su único truco. No se lo digas a nadie. | quitar peso | brazalete |
| 3 | Naira | La única anomalía de hoy que no ha querido matarme. Lo apunto. | lo apunta | naira_apunta+firme |
| 4 | Lya | ¿Estás herida? | la cuida | preocupada |
| 5 | Naira | No me cuides. Me desconcentra. | incomodidad ante el cuidado | naira_incomoda+duda |
| 6 | Naira | Mirad. Ya vuelve. | vuelve al cielo (y a la luz) | naira_mira |

`nr_catalogo` (Kael, Lya, Naira, Garon)

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | Cuarenta y una estrellas sin nombre. Cada una era un pueblo. | enseña lo que más le importa | naira_mira |
| 2 | Lya | ¿Y sus nombres? | dolor por lo perdido | preocupada |
| 3 | Naira | Se borraron del papel. Las estrellas no se dejan. | orgullo terco | naira_seria+firme |
| 4 | Kael | «Si lees esto y no me conoces, me llamo Naira. Apúntalo.» | lee la primera página en voz alta | sorpresa |
| 5 | Naira | Es método. No drama. | corta la emoción | naira_incomoda+duda |
| 6 | Garon | ¿Para qué? | pregunta directa | — |
| 7 | Naira | Por si la niebla me encuentra antes que nadie. | lo de verdad, de lado | naira_seria |
| 8 | Kael | Ya te hemos encontrado nosotros. | deja la broma: pocas palabras | decidido |

`nr_union` (Kael, Lya, Naira, Garon)

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | No os acompaño a vosotros. Acompaño a ese brazalete. | salvar la distancia | naira_seria |
| 2 | Kael | Venimos en el mismo paquete. Brazalete incluido. | acepta el juego | ligero |
| 3 | Naira | Ya me lo temía. | ironía | naira_ironica |
| 4 | Garon | Cuatro. En combate, tres. | la regla (la Formación), en parte militar | — |
| 5 | Kael | Por turnos. Como la cama grande de la posada. | eco de `oak_posada_grupo` | ligero+risa |
| 6 | Garon | Duermo en el suelo. | su frase de siempre | — |
| 7 | Naira | Por fin alguien sensato. | su primera casi sonrisa, para Garon | naira_sonrisa+ligero |

Avisos (región, `naira_mision.gd` TEXTOS): el rumor, «Hoy no. Estoy midiendo.», las plomadas (encontrada, todas, las
que faltan: «Naira: «Faltan la del cañón del oeste y la de la arena que tiembla.»»), «La luz empieza a bajar…»,
«¡Grimfangs! Garon guarda la puerta: lucháis Kael, Lya y Naira.», la derrota, «La luz vuelve…», la Lente, el atril,
la unión y, después, Oren («yo no dije que estuviera loca. Lo dijo Ismena.») e Ismena («Si te tira una piedra,
esquívala.»).

**Lo reservado (comprobado por la prueba con una lista de palabras y a mano):** nada de Érebo (ni nombrado), ni de qué
es la niebla («No sé qué pesa»), ni del anillo (el brazalete solo «no se apaga», canon de `zona.gd`), ni de Lya, Garon,
Morgath, el Lente del Sol o la máquina de Calid; ninguna estrella con nombre de dios. Nada de Final Fantasy X.
**Continuidad:** acto II, tras `mc_fin`: Kael, Lya y Garon presentes (Garon desde PV-05), Oren de vuelta en el
campamento (`mc_superviviente`).

## 5. Compatibilidad

- **Interruptor apagado** (comprobado, parte A de la prueba): `naira` de la región es `null`, sin nodo `Observatorio`,
  `llanos_extra` vacío, el buscador da los **22** hallazgos de siempre, ninguna pieza `nr_*`, Oren dice lo de siempre
  y la partida volcada no trae `nr_`, «Naira» ni `naira_mision`. Lo único que cambia sin interruptor es el registro de
  Dialogic en `project.godot` (dos listas de nombres; nada lo lanza).
- Partidas: los hitos `nr_*` son claves nuevas del diccionario `hitos` (las partidas de antes no los traen = false);
  la formación de un combate va en `mazmorras["naira_mision"]` y desaparece al volver. Sin claves nuevas en `CLAVES`.
- Las pruebas de la región y del grupo pasan sin cambios (abajo).

## 6. Pruebas (todo aislado con `ejecutar_pruebas.ps1`, 12/11/2026)

- `prueba_naira_mision` (nueva; auto `3d mardecristal sin_prologo`; con ventana `fotos=<carpeta> perfil=bajo|medio|alto`):
  A sin interruptor; B la misión entera (rumor; **llegar andando** de las ruinas a la torre; encuentro; las tres
  plomadas con el buscador, una en la arena que tiembla; **guardar y cargar a mitad** con dos plomadas; medición;
  oscurecer, totalidad, cielo y cámara; **combate perdido** (grupo de antes, totalidad, reintento) y **ganado** sin golpes
  (medición perfecta y Lente); la luz vuelve **exacta**; Almanaque; unión a la reserva con Formación; recarga final) y
  C los textos. Orden de los hitos comprobado: `nr_rumor, nr_observatorio, nr_plomada_1, nr_plomada_2, nr_plomada_3,
  nr_plomadas, nr_medicion, nr_eclipse, nr_eclipse_perfecto, nr_catalogo, nr_union`.
  - auto, tras el último cambio (`f2a7a7d`), junto con `prueba_mar_cristal`, `prueba_buscador`, `prueba_grupo_reserva`,
    `prueba_naira_combate`, `prueba_guardado`, `prueba_integridad` y `prueba_bramavidrio_combate`:
    `D:\REBELUM_diagnostico\pruebas\2026-11-12_041219\resumen.md` → **SUPERADAS 8 · FALLIDAS 0**; partida y carpeta
    reales y proyecto sin cambios.
  - con ventana, alto: `D:\REBELUM_diagnostico\pruebas\2026-11-12_035247\resumen.md` (FALLOS: 0) · bajo:
    `D:\REBELUM_diagnostico\pruebas\2026-11-12_035436\resumen.md` (FALLOS: 0)
- **Batería completa** (`520ea4e`): `D:\REBELUM_diagnostico\pruebas\2026-11-12_035626\resumen.md` → **SUPERADAS 129 ·
  FALLIDAS 0 · MANUALES 57 · NO SEGURAS 0**; partida y carpeta reales sin cambios («proyecto cambiado»: el arreglo de
  `f2a7a7d`, hecho durante la pasada y repetido después en la tanda corta). `prueba_naira_mision` 15,5 s. Antes de esta
  tanda: 127 · 1 · 57 · 0 (la fallida ya estaba arreglada en `73a4cef`) + 1 auto nueva. Incluye `prueba_mar_cristal`,
  `prueba_buscador` (22 hallazgos sin interruptor), `prueba_bramavidrio_*`, `prueba_grupo_reserva`,
  `prueba_naira_combate`, guardado e integridad.
- Pendiente de verificar: nadie lo ha jugado a mano ni en el Redmi.

## 7. Capturas

`D:\REBELUM_diagnostico\narrativa\2026-11-12_naira_mision\alto\` y `\bajo\` (13 cada una, sacadas por la prueba):
`01_rumor`, `02_observatorio` (la torre, el trípode, el atril y Naira con la cámara de siempre), `03_primer_encuentro`
(Kael, Naira en el centro y Lya), `04_oscurece`, `05_cielo_eclipse` (el momento: torre, esfera armilar encendida,
estrellas y el sol tapado con su corona), `06_totalidad` (con el diálogo), `07_combate` (Kael, Lya y Naira contra dos
Grimfang), `08_despues`, `09_aclara`, `10_luz_vuelve`, `11_catalogo`, `12_union`, `13_unida` (el aviso de la reserva).

## 8. Límites (honesto)

- **La preparación es la del Eclipse de la tanda de combate: un turno de Naira (0,7 de su barra), no «tres turnos».**
  El texto ya no promete tres. Tampoco hay regla «a por quien prepara», refuerzos en su segundo turno ni fondo de combate
  más oscuro: todo eso es de `combate.gd`, que no se toca (propuesta abajo). Los enemigos son **dos Grimfang**
  (`GRUPOS[0]`), no Hollines.
- **Naira lucha a nivel 1** (`NIVEL_AL_UNIRSE`, D-062 pendiente) en una zona de nivel 10: frágil de verdad. El combate
  lo ganan Kael y Lya; nadie lo ha jugado a mano para medir la dificultad (la prueba fuerza el resultado).
- La medición perfecta la mide un observador desde fuera del combate (lee `heroes`); si `combate.gd` cambia el nombre de
  `conjuro` o `heroes`, deja de ver (la prueba lo detectaría).
- **Sin medir en el Redmi**: el observatorio, la malla de estrellas (puntos con `point_size`), los planos del cielo y el
  modelo provisional de Naira en la puerta. Las formas del observatorio son sencillas (como Tilo o el nido): provisional.
- Con la cámara del momento, Kael queda en el borde de abajo; el HUD del buscador sigue visible si estaba abierto.
- Sin sonido ni música propios del eclipse (el silencio que crece de NAIRA.md: `musica.gd`/`sonido.gd`, no son míos).
- La Lente ahumada y el Almanaque son objetos sin efecto (el efecto de la Lente y la página «Observaciones» del Diario
  son de `equipo_extra.gd` y `diario.gd`).
- Sin la ficha de encargo `enc_naira` (`encargos.gd`, no es mío).

## 9. Propuestas pendientes de decisión (no van al juego)

1. **Canon**: todo lo de Naira (NAIRA.md §7). Si se aprueba, basta con `NAIRA_POR_DEFECTO = true` (o con quitar el
   interruptor) para que la misión salga tras `mc_fin`.
2. **Tres turnos de preparación** para el combate del eclipse (P2): un `combate.gd` con `prep` mayor solo en
   `nr_eclipse`, la regla «a por quien prepara» con aviso y dos Grimfang de refuerzo en el segundo turno de Naira.
3. **Nivel de Naira al unirse** (D-062): para este combate al menos el nivel medio del grupo.
4. **Fondo de combate oscuro** para `nr_eclipse` (la luz de la región ya está a oscuras).
5. **Observatorio como punto de descanso** (NAIRA.md §7.6) y su sala interior (opción completa).
6. La Lente ahumada: «el primer hechizo con preparación de cada combate, un 25 % antes» (NAIRA.md §4.5).

## 10. Para integrar (copiando) y lo que necesito de otros

- **Nuevos:** `aethelgard/zonas3d/mar_cristal/naira_mision.gd`, `observatorio.gd` (+ `.uid`),
  `aethelgard/dialogos/personajes/naira.dch`, `aethelgard/dialogos/mar_cristal/nr_*.dtl` (9, + `.uid`),
  `aethelgard/pruebas/prueba_naira_mision.gd` (+ `.uid`).
- **Cambiados (todos de mi encargo):** `aethelgard/zonas3d/mar_cristal_3d.gd`, `zonas3d/mar_cristal/trazado.gd`,
  `clima.gd`, `mision.gd`, `aethelgard/buscador.gd`, `aethelgard/progreso.gd` (solo `HITOS_NAIRA`),
  `aethelgard/project.godot` (solo las 10 entradas de Dialogic; mejor añadirlas a mano por si otro especialista registra
  las suyas) y `aethelgard/pruebas/lista_pruebas.txt` (una línea al final; mejor a mano).
- **De otros:** `combate.gd` (propuestas 2 y 4), `menu_combate.gd` (`COLOR_HEROE["Naira"] = Color("5FB49C")`, ya
  pedido por combate), `sonido.gd`/`musica.gd` (contexto «eclipse»), `equipo_extra.gd` (la Lente), `diario.gd` (el
  Almanaque), `encargos.gd` (`enc_naira`), arte (poses del retrato de Naira con las etiquetas de §4 y esperas 3D).
