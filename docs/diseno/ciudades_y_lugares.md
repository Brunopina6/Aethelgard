# Ciudades, lugares y compañeros de viaje — diseño (fase 0)

> **Propuesta de diseño. No toca el juego:** ni diálogos (`.dtl`), ni código, ni escenas. Sirve para que gráficos y el
> coordinador implementen [T-089] (ciudades), [T-090] (sitios nuevos) y [T-094] (compañeros), y prepara [T-086] (texto
> del prólogo y de Pastos Verdes). Decisiones vigentes: D-071, D-072, D-033, D-032 y D-048.
> **Fecha:** 2026-11-09 · **Copia:** `D:\Aethelgard_narrativa`, rama `area-narrativa` @ `dddbddb` · **Autor:** especialista
> de narrativa.

**Leyenda** (la de la biblia v2)
- **[C]** canon: está en el juego o es canon en la biblia v2. Siempre con su fuente.
- **[P]** propuesta de este documento. **[P v2]** / **[P v3]**: propuesta que ya estaba en la biblia v2 o v3 (no es canon).
- **[D]** decisión pendiente del usuario (resumen en §7).

**Cómo se ha comprobado** (2026-11-09, `dddbddb`)
- **Observado en el código y en los documentos:** las rutas llevan línea (`archivo:línea`).
- **Posiciones del mapamundi:** medidas sobre la captura del 08/11
  `D:\REBELUM_diagnostico\mapamundi\2026-11-08\antes\2_mapa_entero_1a1.png` (2400 × 1350, el tamaño de `MAPA_TAM`),
  leyendo el color de los píxeles alrededor de cada punto. **Pendiente de comprobar en el juego.**
- **Nada se ha ejecutado:** en esta fase no se abre Godot.

---

## 0. En una página

- **Tres ciudades con identidad propia** (§2):
  - **Oakhaven, «la ciudadela de los faroles»:** hora azul, un roble milenario que se ve desde toda la ciudad, una taberna
    cálida y un crematorio frío. Posada: la Taberna del Cuervo Oxidado [C], con Olvido [P v2].
  - **Sunken City, «la ciudad en las costillas»:** tarde dorada dentro del esqueleto de un buque de guerra varado en una
    laguna. Posada: el Ancla Seca [P].
  - **Arboleda Mítica, «el jardín que no olvida»:** la imagen pintada se queda; se añaden hospedería, dos vecinos, el
    libro de firmas de los peregrinos y cinco secretos.
- **Ocho sitios nuevos** (§3). Primero, los de canon: el crematorio y su cripta, el Templo del Cristal del Cielo, la costa
  del Océano de Bruma y el Abismo Quebrado. Después, las propuestas: Gruta del Velo, Escalera del Cielo, Aldea Rocío y el
  Collado de Ámbar. Hay **cuatro grutas**: la Cripta de las Urnas, la Gruta de la Marea, la Gruta del Velo y la Gruta de
  los Centinelas, más el Casco del buque dentro de Sunken City.
- **Compañeros de viaje** (§4), todos [P]: **Nyx** (ya está en los datos del juego), la **capitana Brea** y **Nerea**, la
  cartógrafa. Versión ligera, sin tocar el canon: **Pip como guía de pago** y **Lucero**, el perro que esperaba en Aldea
  Rocío.
- **Texto del prólogo y de Pastos Verdes** (§5): 44 frases revisadas. Cambian 6: dos globos partidos en el prólogo, una
  repetición, la voz de Garon y los dos recordatorios de Tilo.
- **Orden propuesto** (§6) y **decisiones para el usuario** (§7).

---

## 1. Reglas que respeta este diseño

### 1.1 Canon y revelaciones
- La **biblia v2** es la referencia; la **v3** son propuestas sin canon (se citan como [P v3]).
- **D-033:** nada antes del acto III sobre Érebo y los corazones o recuerdos. En este documento ningún sitio, NPC, nota
  ni misión trata de Érebo. Solo sale en §4, como el compañero que ya es (la invocación de Lya), en bromas de convivencia
  que no dicen qué hace ni qué guarda. Tampoco se explica qué es la niebla (la «Gran Verdad A» de la v2 es del acto III):
  en Aldea Rocío, la Cala de los Mástiles y la Arboleda solo hay **pistas sin explicación**.
- **D-032:** Kael y Lya, amistad profunda y nunca romance; Kael, Lya, Garon y Érebo, una familia de aventureros; tono
  luminoso, con humor y emoción.
- **D-048:** las 12 magias, Esgrima, Embuir, Érebo, la Armonía y el ATB no cambian. Los enemigos, el equipo y las magias
  nuevas son de [T-093], [T-092] y [T-091]: aquí solo se sugieren ganchos con sentido en el mundo.
- **D-072:** un compañero nuevo en el grupo lo decide el usuario. Mientras, solo acompañantes que no tocan el canon.
- **Regla de oro** [P v3 §1.4, dirección aprobada]: nadie conoce un secreto antes de descubrirlo. Por eso algunas frases
  de NPC llevan una **condición** (un hito o una misión).
- **Final Fantasy X:** ninguna referencia.

### 1.2 Principios tomados de otros juegos de rol (solo principios)
| Principio | De dónde viene (solo la idea) | Cómo se aplica aquí |
|---|---|---|
| Una ciudad, una silueta y una hora del día | Las capitales memorables de los JRPG clásicos; la ternura de cuento de FFIX | Oakhaven: un roble y la hora azul. Sunken City: costillas de barco y tarde dorada. Arboleda: un templo de cristal y mañana eterna |
| El descanso es una escena | La convivencia del grupo en los JRPG | Cada posada tiene una conversación corta del grupo (tipo «campamento» de la v3 §7.1) |
| Secretos que se ven desde lejos y cuyo acceso no es evidente | v2 §7.1, regla 3; el cofre del nido de la Garganta [C: `garganta.gd:10-11`] | Cofres que brillan en lo alto de una muralla, en el ojo de un mascarón o en un islote |
| Riesgo y recompensa voluntarios | Expedition 33: tensión y recompensa claras | Zonas más duras y opcionales con premio a la vista (el Centinela Mayor, el cofre raro del Casco) |
| El escenario cuenta la historia | Canon del proyecto: «Una frase al examinar, 15 palabras o menos» [C: `progreso.gd:22`] | Notas de lore de 15 palabras o menos |
| Contraste cálido y frío | FFVII (máquina y naturaleza); Expedition 33 (la luz como puesta en escena) | La taberna cálida frente al crematorio frío; una ciudad viva dentro de una máquina de guerra |
| Humor y ternura en lo pequeño | FFIX | Bastián cuenta faroles; el gato que manda más que la capitana |
| Misiones pequeñas con pago emocional | v2 §7.4 | Recordar el nombre de una aldea hace que vuelva al mapa |

No se copia ningún nombre, diseño, escena, encuadre ni argumento.

### 1.3 Reglas técnicas (para el coordinador y gráficos)
Observado en el código (`dddbddb`). Son condiciones para implementar sin romper partidas ni el mapa.

1. **Índices de lugar.** `LUGARES` (`mapa.gd:39-61`) tiene los índices 0 a 9. Pastos Verdes es el 10 solo con la
   exploración 3D, porque se añade al final (`mapa.gd:110`). Si se añaden lugares a `LUGARES`, en 3D Pastos dejaría de ser
   el 10 y se romperían `modo3d.PASTOS_VERDES := 10`, `DETALLES[10]` y las partidas guardadas allí.
   - **Propuesta:** pasar Pastos a `LUGARES` como índice 10 con `"solo_3d": true` (no se dibuja ni se entra en 2D) y
     añadir los nuevos desde el 11. Hay que actualizar `pruebas/prueba_zona3d.gd:152`, que comprueba que Pastos es el único
     lugar extra.
   - Los sitios interiores (Cripta, Casco, Gruta de los Centinelas, Templo) llevan su índice con `"oculto": true`: no se
     dibujan en el mapa y se entra desde su ciudad o su zona.
2. **El terreno del mapa usa todos los lugares** para colorear los biomas (`mapa.gd:173-178`: el lugar más cercano decide
   la zona, con `ZONA_LUGAR`). Si `LUGARES` crece:
   - `ZONA_LUGAR` (`mapa.gd:37`) tiene que crecer a la vez, o el generador se sale del arreglo;
   - los colores de bioma y la zona de los encuentros del mapa cambiarían alrededor de cada lugar nuevo.
   - **Propuesta:** que ese bucle use solo los 10 lugares originales. Así el mapa no cambia. `RUTAS` e `ISLAS` no se tocan:
     todos los marcadores nuevos caen en tierra que ya existe (§3.0).
3. **Distancia entre marcadores:** el botón «Entrar» sale a 70 px (`mapa.gd:14`). Los marcadores nuevos están a 140 px o
   más de cualquier otro, para que dos botones no se pisen.
4. **Detalles de lore y páginas del Diario.** La página de un acto se calcula en vivo con todos los detalles de sus lugares
   (`progreso.gd:178-187`). Un detalle nuevo en Oakhaven (lugar 0, acto I) o en Sunken City (lugar 5, acto II) **volvería
   a ocultar** una página ya ganada en las partidas antiguas.
   - **Propuesta:** las notas nuevas de las ciudades van en una lista aparte, `NOTAS`, que no cuenta para las páginas. Se
     guardan en la clave que ya existe, `lore_visto`, con el prefijo `nota_`, y el Diario las enseña en una sección
     «Notas». No hace falta ninguna clave nueva.
   - Los detalles de canon que se cambian de sitio (`oak_sello`, `oak_tapiz`, `sunken_contratos`) **conservan su id**.
5. **Cofres con id fijo.** Hoy el id sale del índice y la posición (`zona.gd:1761`); si una zona se rehace, sus cofres
   cambian de id y se pueden volver a abrir. Las ciudades no tienen cofres todavía. **Propuesta:** en los sitios hechos a
   mano, ids escritos (`oak_cofre_raices`…), como ya hace el cofre 3D de Pastos (`ID_COFRE`).
6. **Estado sin claves nuevas.** Todo lo de este documento cabe en claves que ya existen: `hitos`, `decisiones`,
   `mazmorras` (`progreso.gd:197`, para palancas, faroles y pasadizos), `cofres_abiertos`, `combates_ganados`,
   `lore_visto` e `inventario`.
7. **Nivel por zona.** El nivel va por estilo de zona (`progreso.gd:12`). Los estilos nuevos («cripta», «costa»,
   «niebla», «mina», «templo_cielo») necesitan su entrada en `NIVEL_ZONA` (§3.0).
8. **Ciudades hechas a mano.** Como `garganta.gd`, que hereda de `zona.gd` con un trazado fijo: `ciudad_oakhaven.gd`,
   `ciudad_sunken.gd` y una aldea para el Collado. Se conservan la entrada por abajo, la salida al mapa, TIENDA y POSADA
   (`zona.gd:2105-2110`), los NPC con Dialogic, los detalles y el guardado.
9. **Rendimiento en el Mali-G57** (`docs/guia_visual.md`): faroles con emisión y halos pintados, sin luces reales en los
   perfiles bajo y medio (en 2D, sin luces 2D en el móvil, D-H05); humo y niebla con pocas imágenes grandes, nunca muchas
   capas transparentes. Medir antes y después cada ciudad ([T-089]).
10. **Arte de NPC.** Solo hay cuatro imágenes de NPC (`personajes/npc/`: aldeana, caballero, maga y pícaro), repetidas en
    las dos ciudades y la isla. Cada NPC nuevo necesita la suya. Mientras tanto, una de las cuatro con otro tinte, nunca la
    misma figura con dos nombres en la misma escena.

---

## 2. Ciudades

### 2.0 Lo que hay hoy (observado en el código)
| Ciudad | Cómo se hace | Qué tiene | Qué le falta |
|---|---|---|---|
| Oakhaven (lugar 0) | `zona.gd` generada; solo cambia la semilla (`:345`) | Plaza, calle norte-sur hasta un altar y otra este-oeste (`:362-369`), hasta 34 casas al azar (`:427-438`), farolas (`:475-485`), 4 NPC (`:2181-2198`), TIENDA y POSADA a 30 monedas (`:2308`), dos detalles de lore (`progreso.gd:25-28`) | Taberna, crematorio y Árbol Milenario [C: `mapa.gd:41`]; cofres; secretos; misiones |
| Sunken City (lugar 5) | La misma ciudad generada | Lo mismo, con los **mismos 4 NPC**, y un detalle de lore (`progreso.gd:39-40`) | El barco [C: `mapa.gd:51`], la Compañía del Águila y la Astraea; identidad propia |
| Arboleda Mítica | `isla.gd`: imagen pintada (Meshy) con máscaras de paso y profundidad (`:2-14`) | 4 NPC con frases, sin Dialogic (`:26-43`); el portal de vuelta | Posada, tienda, cofres, detalles, secretos |

Las dos ciudades del suelo son hoy la misma ciudad y no tienen nada que descubrir. Lo que sigue les da un trazado fijo, una
identidad y contenido, sin quitarles ninguna función.

### 2.1 Oakhaven — «La ciudadela de los faroles»

**Canon que se respeta** [C]
- «Ciudadela de Oakhaven: el crematorio, la Taberna del Cuervo Oxidado y el Árbol Milenario.» (`mapa.gd:41`)
- Sello del crematorio: «Un sello rúnico roto con un anillo partido. Alguien raspó los nombres.» (`progreso.gd:25-26`)
- Tapiz de los reyes: «Un tapiz viejo de la familia real. Han recortado a un niño de la tela.» (`progreso.gd:27-28`)
- La guardia no deja salir a nadie de noche (`npc_aldric.dtl:2`). Primer objetivo: «escapa de Oakhaven» (`mapa.gd:593`).
- La niebla se tragó otra aldea al norte de Oakhaven (`prologo.dtl:4`).

**Tema** [P]: una capital bonita, ordenada y segura que vive en paz porque olvida. Se cuenta con contraste: la taberna
cálida y ruidosa al oeste, el crematorio pálido y silencioso al este, y en lo alto un roble tan viejo que lo recuerda todo.
Desde que llegó la niebla, la ciudad enciende el doble de faroles.

**Composición** (80 × 56 casillas, norte arriba). Se conservan la entrada y la salida por el sur, la plaza en el centro y
la calle hacia el norte (`zona.gd:362-369`); el altar del final de esa calle pasa a ser el Árbol Milenario.

```
 N ↑   x: 0        10        20        30        40        50        60        70      79
 y: 0  ┌──────────────────────────────────────────────────────────────────────────────┐
       │                            ░░ raíces ░░                         ▲ chimenea    │
       │                        ░░  ♣ ÁRBOL MILENARIO ░░   urnas ·· ┌────────────┐     │
       │                            (cofre tras el tronco)          │ CREMATORIO │     │
       │                              ║                             └─────┬──────┘     │
       │                    ┌──────────────────────┐       puerta con el sello         │
       │     ┌────────────┐ │ CASA DEL CONCEJO     │              ╱                    │
       │     │ TABERNA DEL│ │ (tapiz de los reyes) │             ╱                     │
       │     │ CUERVO     │ └──────────────────────┘            ╱                      │
 y:26  │═════╧════════════╧═════════ PLAZA (fuente) ═══ mercado ═══════════════════╗  │
       │  patio·trampilla   callejón (grieta)  ║ flores de Rosa  (TIENDA)          ║ronda
       │                   ┌────────┐          ║                                   ║(3 faroles)
       │                   │ BOTICA │          ║ Calle Mayor                       ▲ Torre
       │                   └────────┘          ║                                   │ de la
       │                                       ║          ┌──────────┐             │ Campana
       │                                       ║          │ GUARDIA  │             │
 y:55  └──────────────────────────────── PUERTA DEL SUR ───────────────────────────┘
                                          (salida al mapa)
```

| Zona | Casillas (x, y) | Qué hay | Función |
|---|---|---|---|
| Puerta del Sur | (36-44, 50-55); cuerpo de guardia (44-49, 48-53) | Dos torres, rastrillo, Aldric | Entrada y salida al mapa (se conserva) |
| Calle Mayor | x = 40, de y = 50 a 31 | Calle de 2 casillas con un farol cada 5; la Botica de Selene (33-38, 35-40) | Recorrido principal; Bastián |
| Plaza del Tapiz | centro (40, 26), radio 5 | Fuente, tablón de anuncios, puesto de flores; la Casa del Concejo al norte (35-45, 17-21) | Corazón de la ciudad; tapiz de los reyes [C] |
| Mercado | (48-60, 27-32) | Puestos con toldos | TIENDA (se conserva) |
| Barrio del Cuervo | (6-30, 18-35) | Taberna del Cuervo Oxidado (11-21, 19-25); patio con barriles y trampilla (10-15, 27-31); callejón con una grieta (22-26, 30-35) | Posada; Pip; pasadizo a la cripta |
| Colina del Crematorio | (56-74, 4-18) | Crematorio (62-72, 7-15), chimenea (70, 8), jardín de urnas (57-62, 9-14), puerta con el sello (66, 16) | Lugar de canon; la cripta, debajo |
| Raíces del Árbol | (30-50, 2-13) | Tronco en (40, 7); raíces que cruzan la calle como escalones | Hito del norte (sustituye al altar) |
| Torre de la Campana y ronda | Torre (72-75, 40-44); ronda por la muralla este, de y = 44 a 30 | Tres faroles apagados; un cofre al final de la ronda | Misión de Bastián; vista |

**Lugares de canon dentro**
| Lugar [C] | Dónde | Cómo se usa |
|---|---|---|
| Taberna del Cuervo Oxidado | Barrio del Cuervo | Es la posada. Letrero de hierro con un cuervo oxidado que chirría con el viento |
| Crematorio | Colina del Crematorio | Visitable por fuera; el **Sello del crematorio** (`oak_sello`) pasa de la plaza a su puerta, con el mismo id. Debajo, la Cripta de las Urnas (§3.1) |
| Árbol Milenario | Norte, al final de la calle | Un roble enorme [P: la especie]; la copa se ve desde toda la ciudad |
| Tapiz de los reyes | Pórtico de la Casa del Concejo | El detalle `oak_tapiz` pasa de la plaza al pórtico, con el mismo id |
| Guardia nocturna | Puerta del Sur | Aldric y el cuerpo de guardia |

**Posada: Taberna del Cuervo Oxidado** [C nombre; P lo demás]
- **Posadera:** Olvido [P v2 §4.7]. Crió a Kael [P v2]; aguda, cariñosa y con memoria de prestamista.
- **Ambiente:** chimenea, guiso, mesas largas, canciones desafinadas; en la pared, un mapa donde el nombre de la aldea del
  norte se ha vuelto borroso [P v2 §6.2].
- **Precio:** 30 monedas, como hoy (`zona.gd:2308`). Una noche gratis al terminar «La deuda de Olvido».
- **Escena al descansar** [P, tipo «campamento», una por descanso]:
  > **Olvido:** Tres cenas, Kael. Con esta, cuatro.
  > **Kael:** Apúntalas a nombre de Garon. Es de fiar.
  > **Garon:** No.
  > **Lya:** Yo pago la mía. Y la de Garon.
  > **Olvido:** Por fin alguien con modales en esta mesa.

**NPC** (8: los cuatro de canon y cuatro nuevos). Las frases [C] se conservan tal cual (`dialogos/npc_*.dtl`).
| NPC | Dónde | Personalidad | Frases | Condición |
|---|---|---|---|---|
| **Caballero Aldric** [C] | Puerta del Sur (40, 49) | Veterano cansado; cumple las normas y sabe cuándo mirar hacia otro lado | [C] Las tres de `npc_aldric.dtl`. [P] «Anoche no vi salir a nadie. Que conste en el libro de guardia.» · [P] «Desde que llegó la niebla, encendemos el doble de faroles. Por si acaso.» | La primera [P], tras `pv_02` (Kael ya salió) |
| **Maga Selene** [C] | Puerta de la Botica (36, 41) | Sabia y prudente; tiene miedo de algo que no cuenta | [C] Las tres de `npc_selene.dtl`. [P] «Hay libros que se cierran por algo. No me preguntes cuáles.» · [P] «¿Lya se fue contigo? Bien. Cuídala… aunque ella crea que es al revés.» | La segunda [P], tras `pv_03` |
| **Pip el Pícaro** [C] | Callejón del Barrio del Cuervo (24, 31) | Ladronzuelo simpático; vende rumores | [C] Las tres de `npc_pip.dtl`. [P] Si paga: «¿Me la das? ¿Sin regatear? Qué raro eres.» · «Detrás del Cuervo hay una trampilla. Sale aire frío… y huele a ceniza.» · Después: «Yo no te he dicho nada. Yo nunca digo nada. Por eso me pagan.» | Pagar 1 moneda: `decisiones.pip_oak = "pagado"` |
| **Aldeana Rosa** [C] | Puesto de flores de la plaza (44, 29) | Alegre y charlatana | [C] Las tres de `npc_rosa.dtl`. [P] «Antes la lavanda crecía hasta en los tejados. Ahora solo en los Pastos.» · [P] «¡Huele a mañana! La pondré a los pies del Árbol.» | La segunda [P], al entregar la lavanda |
| **Olvido** [P v2] | Taberna (16, 25) | Tabernera aguda y maternal; no perdona una deuda | «Me llamo Olvido y no se me olvida nada: ni una cara ni una deuda.» [P v2] · «Kael, cariño: tres cenas. Las tengo apuntadas con buena letra.» · «Cama, sopa y silencio: treinta monedas. El silencio no lo garantizo.» · «Lo apunté yo en el libro. Mi letra no la borra ni la niebla.» | La última, tras «El nombre borroso» |
| **Hermano Albar** [P] | Puerta del crematorio (65, 17) | Cortés, de voz baja, inquietantemente sereno | «Bienvenido al crematorio. Aquí todo acaba en paz.» · «Recordar duele, muchacho. Nosotros ayudamos a soltar.» · «La puerta de abajo no es para visitas. Ni para preguntas.» | — |
| **Bastián** [P v2 §7.3] | Calle Mayor (41, 44); corre de farol en farol | Niño muy serio con los números; se enfada si un farol se apaga | «¡Ciento doce faroles! Bueno, ciento nueve: tres están apagados.» · «Si un farol se apaga, la niebla se acerca. Lo dice mi abuela.» · «Los tres de la muralla. ¿Me ayudas a encenderlos?» | La última abre su misión |
| **Doña Encina** [P] | Raíces del Árbol (37, 10) | Anciana guarda del roble; lenta, seca y con humor | «Este roble ya era viejo cuando Oakhaven era una aldea. Respétalo.» · «Cuenta sus anillos y sabrás su historia. Yo me perdí por el dos mil.» · «Hay un anillo negro, muy al fondo. Como si un año entero hubiera ardido.» | — |

**Pequeñas misiones**
| Misión | Quién | Qué se hace | Pago emocional | Recompensa | Estado guardado |
|---|---|---|---|---|---|
| **La deuda de Olvido** [P v2 n.º 6] | Olvido | Tres favores por las cenas que debe Kael: sacar un barril del patio (así se ve la trampilla), llevar flores de Rosa a las mesas y devolver la cuchara que Pip «encontró» | Olvido tacha la deuda… y apunta otra: «Una cena: hoy» | Una noche gratis. El libro de cuentas de Olvido queda presentado [P v2: clave del acto III] | `hitos.oak_deuda` |
| **Los faroles de la ronda** [P] | Bastián | Subir a la Torre de la Campana y encender los tres faroles de la muralla este | La muralla se ilumina y Bastián grita: «¡Ciento doce!» | El cofre de la ronda y la vista de la torre | `mazmorras.oakhaven.farol_1` a `farol_3` |
| **El nombre borroso** [P] | El mapa de la taberna | Nadie recuerda cómo se llamaba la aldea del norte. En el libro de cuentas hay un pedido: «pan para Aldea Rocío». Lo escrito a mano resiste [P v2 §3.6, regla 2] | El nombre vuelve al mapa de la taberna… y **Aldea Rocío aparece en el mapamundi** (§3.7) | Un lugar nuevo | `hitos.rocio_nombre` (exige `hitos.oak_deuda`) |
| **Un secreto por una moneda** [C la frase; P el pago] | Pip | Pagarle una moneda | El secreto es verdad | El pasadizo a la cripta; Pip se ofrece como guía (§4.4) | `decisiones.pip_oak` |
| **Lavanda para el Árbol** [P] | Rosa | Traer lavanda de Pastos Verdes (tras `pv_02`) | Doña Encina: «Hacía años que nadie le traía flores.» | 3 Pociones, o un accesorio de [T-092] | `hitos.oak_lavanda` |

**Secretos**
| # | Tipo | Dónde | Cómo se descubre | Premio | Id |
|---|---|---|---|---|---|
| O1 | Pasadizo | Trampilla del patio del Cuervo (12, 29) → alcantarillas → Cripta de las Urnas (§3.1) | Pip la vende; o aparece al sacar el barril; una rejilla del callejón echa aire frío que huele a ceniza | La cripta; sale al jardín de urnas (atajo de un solo sentido) | `mazmorras.oakhaven.trampilla` |
| O2 | Rincón escondido | Grieta del callejón (24, 33) → el **Patio de las Velas**: un altar pequeño con el anillo partido y velas recién encendidas | El brazalete brilla cerca [P: ampliar a los secretos no vistos la mecánica de `zona.gd:990`]; de lejos solo se ve luz en una grieta | Cofre: 2 Éter y 1 Incienso de Ceniza; nota «Velas» | `oak_cofre_velas` |
| O3 | Cofre escondido | Entre las raíces, al norte del tronco (43, 4): la copa lo tapa | Un destello entre las hojas; se llega rodeando por una raíz estrecha del oeste | 150 monedas y 2 Pociones | `oak_cofre_raices` |
| O4 | Cofre a la vista, de acceso no evidente | Final de la ronda (77, 31); brilla desde el mercado | Subir a la Torre de la Campana | Colgante de luna [C: `inventario.gd:66`] | `oak_cofre_ronda` |
| O5 | Cofre | Patio del cuerpo de guardia (47, 52): «objetos requisados» | Tras `pv_02`, Aldric mira hacia otro lado | Cinta de cuero y 60 monedas; nota «Requisados» | `oak_cofre_requisados` |
| O6 | Vista | Torre de la Campana (73, 42) | Al subir | Antes de `pv_07`: el brillo morado del Portal al sureste y la niebla al norte. Después: además, la silueta lejana de la ciudad flotante. Una viñeta pintada de 4-6 s que se salta tocando | — |
| O7 | Vista | Raíces del Árbol (40, 11) | La primera vez que se llega | La ciudad entera en la hora azul; los faroles se encienden en ola, de la plaza hacia fuera | — |

**Notas de lore** (lista `NOTAS`, §1.3 punto 4; 15 palabras o menos)
| Id | Dónde | Texto |
|---|---|---|
| `nota_oak_bando` | Tablón de la plaza | «Bando: por prudencia, no se nombran en voz alta las aldeas perdidas.» |
| `nota_oak_mapa` | Mapa de la taberna | «El nombre de la aldea del norte se ha vuelto borroso. ¿Cómo se llamaba?» |
| `nota_oak_anillos` | Raíz cortada del Árbol | «Miles de anillos en la madera. Uno, muy hondo, es negro como el carbón.» |
| `nota_oak_guardia` [P v2 §5.7, semilla] | Libro del cuerpo de guardia | «Falta una página de hace diecisiete años. Nadie sabe quién la arrancó.» |
| `nota_oak_velas` | Patio de las Velas | «Un anillo partido y velas recién encendidas. Alguien sigue viniendo.» |
| `nota_oak_requisados` | Cofre de los requisados | «Requisado: una cinta, tres dados y una carta sin abrir. Sin nombre.» |

**Dirección visual** (para el especialista de gráficos)
- **Hora fija: la hora azul**, justo después de ponerse el sol. Encaja con el prólogo, que es de noche, y con la luz que ya
  tiene la ciudad en el código (ambiente azul violáceo y farolas, `zona.gd:53-56`). No hay ciclo de día y noche.
- **Paleta:**
  - sombras azul pizarra `#3A4A72` que bajan a índigo `#1D1B4D` (el índigo de la marca);
  - piedra gris cálida `#8C847A` / `#A39A8C`, nunca blanca;
  - tejados de teja rojiza `#A0583A` en el Barrio del Cuervo y de pizarra `#4A5468` en la colina;
  - madera marrón rojiza `#6B3F2A`;
  - luz de farol oro cálido `#F2C86B` (el oro de la marca); ventanas de la taberna `#FFB45A`;
  - roble verde profundo `#3F5E3A` con brillos `#6E8F4E`; luciérnagas `#E9F59A`;
  - crematorio de piedra hueso `#D9D4C7` y humo frío `#C9D3E0`: el único lugar frío de la ciudad.
- **Materiales:** empedrado (ya existe), casas de entramado de madera, hierro oxidado (el cuervo del letrero), musgo en las
  caras norte, corteza con raíces que levantan el empedrado.
- **Luz:** faroles con emisión y halo pintado (aditivo, `luz_tex` y `mat_aditivo` ya existen); luces reales solo en el
  perfil alto. La taberna y el mercado, cálidos; el crematorio, iluminado solo por su humo pálido.
- **Ambiente:** humo blanco lento en la chimenea del crematorio; luciérnagas en las raíces; polillas alrededor de los
  faroles; para sonido: campana lejana, bullicio de taberna, el chirrido del cuervo de hierro.
- **Legibilidad en el móvil:** tres hitos en tres puntos: el roble (norte), la chimenea con humo (este) y el resplandor de
  la taberna (oeste). La Calle Mayor, de 2 casillas.
- **Referencias de principio:** la capital de cuento con un hito vertical (ternura de FFIX); la luz como puesta en escena
  (Expedition 33). No se copian arquitectura, encuadres ni paletas concretas.
- **Evitar:** luces reales en bajo y medio; humo hecho con muchas capas transparentes; casas al azar que tapen la plaza.

**Funciones que se conservan:** entrada y salida por el sur, TIENDA, POSADA, los cuatro NPC de canon con sus timelines, los
dos detalles (con su id), el guardado y la ausencia de encuentros (`NIVEL_ZONA["ciudad"] = 0`).

### 2.2 Sunken City — «La ciudad en las costillas»

**Canon que se respeta** [C]
- «Ciudad construida dentro del esqueleto de un barco de guerra antiguo.» (`mapa.gd:51`)
- Contratos del Águila: «Contratos de la Compañía del Águila, firmados con el sello de la corona.» (`progreso.gd:39-40`)
- «El viaje rápido se desbloquea con el barco volador Astraea.» (`mapa.gd:591`); los lugares en islas, «solo con el
  Astraea» (`mapa.gd:36`).
- Es del acto II («Las Reliquias»: Calid, Sunken City, Ciclópea y Templo, `progreso.gd:51`).

**Ya propuesto en la v2** [P v2]: base de la Compañía del Águila; la capitana Brea; el mascarón es un águila dorada; casas
colgadas de las costillas; el Casco del buque como mazmorra; aquí se consigue la Astraea.

**Tema** [P]: la guerra que nadie recuerda, a la vista de todos. Una ciudad entera vive dentro de una máquina de guerra y
nadie se pregunta por ella: mercenarios, deudas, sal, óxido y risas. El nombre «hundida» se explica en el escenario: el
casco quedó varado y medio hundido en el fango de una laguna salada, junto a la costa.
- **Apodo** [P][D]: los vecinos la llaman «el Costillar». No cambia el nombre del mapa; ayuda mientras sigue pendiente la
  revisión de nombres de la v2 (§1.4, n.º 15).

**Composición** (80 × 56 casillas). El barco va de sur (popa, la entrada) a norte (proa, el hito).
```
 N ↑                         ▲ MASCARÓN DEL ÁGUILA (el ojo esconde un cofre)
                           ╭─┴─╮ bauprés
          laguna     ╭────╮│   │╭────╮      laguna
                     │cos-││ Q ││tilla│   ┌──────────────────────────┐
   MUELLE  ┌─────────┤    ││ U ││    ├───┤ DIQUE DE LA ASTRAEA      │
   barcas  │ casas   ╰────╯│ I │╰────╯   │ (una lona enorme)        │
           │ colgadas      │ L │         └──────────────────────────┘
   ┌───────┴──────┐  ══════╧ L ╧══ CUBIERTA MAYOR ══════  fragua de Inés
   │ EL ANCLA SECA│   palo mayor · escotilla → CASCO · mercado (TIENDA)
   └──────────────┘        │ A │
   compuertas              │   │   ┌──────────────────┐
                           │   │   │ ARCHIVO DEL ÁGUILA│
                           ╰─┬─╯   └──────────────────┘
                       POPA ROTA (entrada; el nombre del barco, raspado)
```

| Zona | Casillas (x, y) | Qué hay | Función |
|---|---|---|---|
| Popa Rota | (34-46, 48-55) | Espejo de popa partido; el nombre del barco, raspado (solo quedan los clavos de las letras) | Entrada y salida al mapa |
| Archivo del Águila | (48-56, 42-48) | El antiguo camarote del capitán | El detalle `sunken_contratos` [C] pasa aquí, con su id; Ulla |
| La Quilla | x = 40, de y = 48 a 9 | Pasarela de madera sobre la quilla; cada 6 casillas una costilla la cruza por encima como un arco (y = 44, 38, 32, 20 y 14) | Calle principal |
| Cubierta Mayor | centro (40, 26) | Tocón del palo mayor con la bandera del Águila; mercado; escotilla al Casco (43, 27) | Plaza; TIENDA |
| Babor | (4-30, 14-40) | Casas en plataformas entre costillas; Muelle de la Laguna (4-12, 20-38); posada (14-21, 29-35); compuertas (8, 40) | Posada; misión de la marea |
| Estribor | (50-76, 10-36) | Dique de la Astraea bajo una lona (60-74, 12-24); fragua de Inés (52-56, 30-34) | Astraea (acto II); fragua |
| Proa | (34-46, 2-9) | Mascarón del águila dorada (40, 4) en lugar del altar; el bauprés hacia el norte | Hito; vigía; cofre secreto |
| Laguna | Bordes oeste y este | Agua turquesa poco profunda | Marco; muelle |

**Lugares de canon dentro:** el barco de guerra [C] es la ciudad entera; los contratos [C], en el Archivo; la Astraea [C
nombre], bajo la lona del dique: se ve desde el primer día y no se puede usar hasta su hito del acto II [P v2].

**Posada: El Ancla Seca** [P]
- **Posadera:** Doña Coral, antigua cocinera de a bordo; alegre, habla en términos de barco y canta mientras friega.
- **Ambiente:** se duerme en hamacas dentro de una costilla; un ancla clavada en el suelo junto a la puerta; el gato
  Almirante ocupa siempre la mejor hamaca.
- **Precio:** 40 monedas [P][D] (puerto caro; si se prefiere, 30 como en todas).
- **Escena al descansar:**
  > **Doña Coral:** ¡Hamacas para tres! El Almirante duerme en la buena.
  > **Kael:** ¿Quién es el Almirante?
  > **Doña Coral:** El gato. Manda más que la capitana.
  > **Garon:** Yo duermo en el suelo.
  > **Lya:** Garon, la hamaca no muerde.
  > **Garon:** La hamaca, no. El gato, ya veremos.

**NPC** (7, todos [P]; Brea viene de la v2)
| NPC | Dónde | Personalidad | Frases | Condición |
|---|---|---|---|---|
| **Capitana Brea** [P v2] | Cubierta Mayor (38, 24) | Ruidosa, generosa, endeudada y apostadora; llama «grumete» a todo el mundo | «¿Nuevos? Aquí se paga en monedas o en historias. Las tuyas parecen baratas.» · «Este barco no se hundió, grumete. Se cansó de navegar.» · «Le debo dinero a media ciudad. A la otra media, todavía no.» · «Lo que hay bajo esa lona vuela. Pero aún no es asunto tuyo.» | La última, antes del hito de la Astraea |
| **Contramaestre Ulla** [P] | Archivo del Águila (52, 45) | Archivera estricta; vive para el orden | «Los contratos del Águila se cumplen. Todos. Siempre.» · «Los viejos llevan el sello de la corona. Todos.» · «No toques ese cajón. No porque sea secreto: porque está ordenado.» | — |
| **Doña Coral** [P] | El Ancla Seca (18, 33) | Posadera; ver arriba | «¡Al Ancla Seca! Hamaca, guiso y canciones desafinadas: cuarenta monedas.» · «El Almirante es el gato. Manda más que la capitana.» · «Si oyes crujir las costillas de noche, es el barco. Ronca.» | — |
| **Tomé, el grumete** [P] | Muelle (8, 30) | Niño que vive dentro de un barco y nunca ha visto el mar abierto | «Vivo dentro de un barco y nunca he visto el mar de verdad.» · «Dicen que el Océano de Bruma no tiene horizonte. ¿Cómo se llega allí?» | — |
| **Ojo de Gaviota** [P] | Sobre el mascarón (41, 5) | Vigía viejo; ve lejos y habla poco | «Desde el águila se ve todo. Hasta lo que no debería verse.» · «Al oeste, en la bruma, asoman mástiles. Barcos que nadie echa de menos.» | La segunda lleva a la Cala (§3.3) |
| **Inés Remache** [P] | Fragua (54, 32) | Herrera orgullosa del hierro antiguo | «El hierro de este barco es mejor que el de hoy. Lo hicieron para una guerra.» · «Tráeme remaches del casco y te forjo algo que corte de verdad.» | La segunda abre su misión |
| **Mamá Nácar** [P] | Muelle (10, 22) | Buceadora de perlas; cuenta leyendas del mar | «En la gruta de la cala hay perlas grises. Brillan sin luz.» · «Mi abuela decía que el mar se tragó una guerra entera. Y aún no la ha digerido.» | — |

**Pequeñas misiones**
| Misión | Quién | Qué se hace | Pago emocional | Recompensa | Estado guardado |
|---|---|---|---|---|---|
| **La marea baja** [P] | Ulla y Brea | Abrir las compuertas del muelle (palanca, como la de `garganta.gd`) para vaciar la cubierta de abajo | La ciudad oye crujir el casco por primera vez en años | Acceso al Casco del buque | `mazmorras.sunken.compuertas` |
| **Remaches para Inés** [P] | Inés | Traer remaches del Casco | Inés: «Este hierro aún recuerda para qué lo hicieron.» | Un arma especial de [T-092] | `hitos.sunk_remaches` |
| **Perlas de bruma** [P] | Mamá Nácar | Traer tres perlas grises de la Gruta de la Marea (§3.3) | Mamá Nácar recuerda una canción de su abuela | Un accesorio de [T-092] | `hitos.sunk_perlas` |
| **El gato Almirante** [P] | Doña Coral | Seguir al gato por las jarcias hasta la cofa | Coral: «Ese gato ha subido más que la capitana.» | La vista de la cofa y su cofre | `hitos.sunk_gato`; cofre `sunk_cofre_cofa` |
| **La apuesta de Brea** [P] | Brea | Brea apuesta a que nadie encuentra el cofre del ojo del águila | Brea paga… con un pagaré | Un pagaré de 200 monedas que Brea paga al final del acto II | `decisiones.brea_apuesta` |

**Secretos**
| # | Tipo | Dónde | Cómo se descubre | Premio | Id |
|---|---|---|---|---|---|
| S1 | Cofre a la vista, de acceso no evidente | Dentro del ojo del águila (40, 3) | Brilla desde la Cubierta Mayor; se llega por el bauprés, una tabla estrecha | Escudo rúnico [C: `inventario.gd:64`] | `sunk_cofre_ojo` |
| S2 | Vista y cofre | La cofa, en lo alto de la costilla mayor (30, 20) | Siguiendo al gato | La vista del Océano de Bruma (ver abajo) y un cofre: 2 Éter | `sunk_cofre_cofa` |
| S3 | Pasadizo | Compuertas del muelle (8, 40) | Misión «La marea baja» | El Casco del buque | `mazmorras.sunken.compuertas` |
| S4 | Lugar cerrado, a la vista | La lona del dique (60-74, 12-24) | Siempre se ve; Brea no deja pasar | La Astraea, en el acto II [P v2] | — |
| S5 | Vista | La cofa | Al subir | Hacia el oeste, el mar de niebla sin horizonte y, muy lejos, las puntas de unos mástiles (gancho a la Cala de los Mástiles, §3.3) | — |

**El Casco del buque** [P v2 §7.2]: la mazmorra de la ciudad
- **Concepto:** las cubiertas inundadas bajo la ciudad. Pasillos con agua por las rodillas, coyes podridos, cañones que
  nadie disparó en siglos y, al fondo, una sala de máquinas muerta, con tubos quemados y ceniza fina por todas partes.
- **Qué hacer:** combates fijos con cangrejos de casco ([T-093]: duros por fuera, débiles al Rayo); un minijefe, el
  Autómata de la sala de máquinas ([T-093]: carga dos turnos y descarga; débil al Rayo); remaches para Inés; un cofre raro
  tras una puerta estanca que se abre bajando el agua otra vez (segunda palanca).
- **Nota:** `nota_sunk_bitacora`: «Diario de a bordo: “La máquina tiene hambre. Hoy quemamos cartas.”» Es una pista del
  acto II [P v2 §2.4: el combustible son recuerdos], sin explicación.
- **Nivel** 13-16. **Conexión:** índice nuevo oculto, desde la escotilla de la Cubierta Mayor. **D-033:** nada de Érebo.
- **Para no pisar el canon de Calid:** la sala de máquinas no tiene un hueco con forma de brazalete; eso es de Calid
  [C: `progreso.gd:37-38`].

**Notas de lore** (lista `NOTAS`)
| Id | Dónde | Texto |
|---|---|---|
| `nota_sunk_popa` | Espejo de popa | «Alguien raspó el nombre del barco. Solo quedan los clavos de las letras.» |
| `nota_sunk_bandera` | Palo mayor | «La bandera del Águila, remendada mil veces. El águila siempre, intacta.» |
| `nota_sunk_bitacora` | Casco (sala de máquinas) | «Diario de a bordo: “La máquina tiene hambre. Hoy quemamos cartas.”» |

**Dirección visual**
- **Hora fija: tarde dorada**, con sol bajo y luz de mar.
- **Paleta:**
  - costillas de madera blanqueada `#CDB79A` y hueso cálido `#E3D5BC`;
  - hierro oxidado `#8A4B2A` y cobre con verdín `#4E9C8A`;
  - toldos de lona crema `#EFE6D2` con remiendos ocre `#C98B3A`;
  - bandera del Águila en rojo carmesí `#9E2B2B` [P: el color de Garon en los menús, `menu_combate.gd:21`; enlaza con la
    propuesta de la v3 de que Garon sirvió en la Compañía];
  - laguna turquesa `#3BB3B0` con fondo `#1F6F78` y espuma `#F2F7F2`;
  - el águila del mascarón, en el oro de la marca `#F2C86B`; sombras verde azulado profundo `#24484F`.
- **Materiales:** madera curtida, cabos embreados, remaches oxidados, percebes, lona, redes.
- **Luz:** sol fuerte y cálido; reflejos de la laguna en las costillas con una textura animada barata, no con reflejos
  reales. Faroles de barco con emisión.
- **Ambiente:** gaviotas, velas que se hinchan, crujidos de madera, agua que lame el casco (para sonido).
- **Legibilidad en el móvil:** las costillas son arcos grandes que se leen desde 20 m; la Quilla, recta y clara; el
  mascarón, siempre al norte.
- **Referencias de principio:** la escala de una ciudad dentro de un objeto gigante, que asombra; la vida cotidiana
  domesticando una máquina de guerra (FFVII: máquina y naturaleza). Sin copiar.
- **Evitar:** redes con transparencia superpuesta (mejor recorte alfa); agua con refracción en bajo y medio.

**Funciones que se conservan:** las mismas que en Oakhaven; el detalle `sunken_contratos` conserva su id.

### 2.3 Arboleda Mítica — «El jardín que no olvida»

**Canon que se respeta** [C: `isla.gd`]
- Ciudad flotante: «Aquí la niebla no llega.» (`:116`)
- Ilia: «El templo de arriba guarda el Cristal del Cielo. Nadie entra sin permiso.» (`:28`)
- Orun: «Si el agua se para, la isla cae.» · «Late cuando alguien con un brazalete pasa cerca…» · «Antes subían peregrinos
  con un anillo partido grabado. Ya no sube nadie.» (`:32-34`)
- Lumi: «¡Yo nunca he bajado!» · «Mi abuela dice que abajo todo es gris.» (`:36-37`); Vex compra plumas de arpía (`:40`).

**Tema** [P]: un refugio luminoso de ritmo lento. Aquí se viene a respirar. La belleza es la de un sitio que todavía
recuerda: firmas de peregrinos, faroles cuidados, una puerta con un anillo que no está partido.

**Composición:** la imagen pintada **no se toca**. Todo lo nuevo se pone en zonas andables de `isla/isla_paso.png` (en
píxeles de la isla, 3072 × 3348; **comprobar cada punto en la máscara**):
| Punto | Dónde (≈) | Qué es |
|---|---|---|
| Ermita de las Firmas | La capillita del arco azul, al oeste de la gran escalera (975, 1150) | Libro de firmas de los peregrinos |
| Hospedería del Peregrino | Una casa del lado este de la plaza (2000, 2150) | La posada |
| Orilla | Borde sureste | Vista hacia abajo |
| Fin de la vieja escalera | Borde oeste (160, 1760) | El extremo de arriba de la Escalera del Cielo (§3.6) |
| Puerta del templo | Arriba de la gran escalera (1330, 900) | Cerrada hasta el acto III |
| Islote suelto | Arriba a la izquierda (470, 630); no es andable | Cofre visible e inaccesible |

**Posada: Hospedería del Peregrino** [P]
- **Hospedera:** Yedra, que lleva años esperando huéspedes y lo tiene todo preparado.
- **Ambiente:** camas con colchas de lino, ventanas abiertas a las nubes, olor a pan de higo.
- **Precio:** 20 monedas [P][D] (la hospitalidad de los peregrinos).
- **Escena al descansar:**
  > **Yedra:** Hacía años que no subía nadie a dormir.
  > **Kael:** ¿Y eso?
  > **Yedra:** No había por dónde subir. Ahora hay un portal. Y vosotros.
  > **Lya:** Se duerme bien aquí. Demasiado bien.
  > **Garon:** Yo hago la primera guardia.
  > **Yedra:** ¿Guardia? Aquí arriba no pasa nada. Ese es el problema.

**NPC** (6: los cuatro de canon, que pasan a Dialogic con sus frases, y dos nuevos)
| NPC | Dónde | Personalidad | Frases | Condición |
|---|---|---|---|---|
| **Guardiana Ilia** [C] | Pie de la escalera (1364, 1600) | Seria y leal | [C] Sus tres frases | — |
| **Jardinero Orun** [C] | Plaza oeste (1000, 1920) | Paciente; habla de agua y raíces | [C] Sus tres frases. [P] «El canal de las cascadas está atascado de hojas. ¿Me echas una mano?» | La [P] abre «El agua de Orun» |
| **Niña Lumi** [C] | Plaza este (1700, 1980) | Curiosa y alegre | [C] Sus tres frases. [P] «¿Me traes una flor de abajo? Una de verdad, de las que huelen.» | La [P] abre «Una flor para Lumi» |
| **Mercader Vex** [C] | Plaza oeste (700, 2048) | Comerciante sin clientes | [C] Sus tres frases | Plumas: misión de la v2 |
| **Yedra** [P] | Hospedería (2000, 2150) | Hospedera feliz de tener por fin a quién cuidar | «Hace años que no subía nadie a dormir. Te he guardado la mejor cama.» · «Firma en el libro de la ermita, como los peregrinos. Aquí arriba, lo escrito se queda.» · «Veinte monedas. Los peregrinos pagaban con una historia. Tú pareces de pagar.» | — |
| **Abuela Nívea** [P] | Junto a Lumi (1760, 2010) | La abuela que Lumi cita [C: «Mi abuela dice…»]; subió de niña con los peregrinos y nunca bajó | «Subí de niña con los peregrinos. Bajar no me ha hecho falta.» · «Subí con un niño muy serio que encendía todos los faroles.» · «Lumi repite todo lo que digo. Hasta lo que no debería.» | La segunda es una pista de Tilo [P] |

**Pequeñas misiones**
| Misión | Quién | Qué se hace | Pago emocional | Recompensa | Estado guardado |
|---|---|---|---|---|---|
| **Una flor para Lumi** [P v2 n.º 1] | Lumi | Traerle una flor de abajo (lavanda de los Pastos o una flor de Rosa) | Lumi: «Entonces abajo no es gris.» | Un dibujo de Lumi (nota en el Diario) | `hitos.isla_flor_lumi` |
| **Plumas para Vex** [P v2 n.º 7] | Vex | Traer plumas de arpía (enemigo de [T-093]) | Vex por fin vende algo | Botas aladas [C: `inventario.gd:58`] | `hitos.isla_plumas` |
| **El libro de firmas** [P] | Yedra | Buscar en el libro de la ermita una firma torcida: «Tilo, 9 años. Subí solo.» y contárselo a Tilo | Tilo [P]: «¿Aún está? Pues firmé torcido. Tenía prisa por ver el cielo.» | Una línea nueva de Tilo y una nota | `hitos.isla_firma_tilo` |
| **El agua de Orun** [P] | Orun | Limpiar de hojas el canal que alimenta las cascadas | La cascada del oeste suena más fuerte | Aparece un puente de raíces (una imagen encima del fondo) hasta el islote suelto y su cofre | `mazmorras.isla.canal` |

**Secretos**
| # | Tipo | Dónde | Cómo se descubre | Premio | Id |
|---|---|---|---|---|---|
| A1 | Vista | La orilla | Al asomarse, como dice Lumi | Las nubes pasan por debajo. Tras `pv_14`, entre las nubes se ven dos puntitos de luz: los faroles del puente de Tilo | — |
| A2 | Cofre y nota | Fin de la vieja escalera (160, 1760) | El brazalete brilla al acercarse | Cofre (Amuleto de vida [C: `inventario.gd:61`]) y nota «Escalera» | `isla_cofre_escalera` |
| A3 | Cofre a la vista, inaccesible al principio | Islote suelto (470, 630) | Se ve desde la ermita; puente de raíces tras «El agua de Orun» | 300 monedas y 2 Éter | `isla_cofre_islote` |
| A4 | Puerta cerrada | Templo (1330, 900) | Al acercarse: Ilia y la nota «Puerta» | Nada todavía: el acto III (§3.2) | — |
| A5 | Libro | Ermita de las Firmas (975, 1150) | Examinar | Las firmas (nota) y la misión de Tilo | — |

**Notas de lore** (lista `NOTAS`; la isla no tiene índice de lugar: se propone uno oculto para ella)
| Id | Dónde | Texto |
|---|---|---|
| `nota_isla_firmas` | Ermita | «Cientos de firmas de peregrinos. Una, torcida: “Tilo, 9 años. Subí solo.”» |
| `nota_isla_puerta` | Puerta del templo | «En la puerta del templo hay un anillo grabado. Este no está partido.» |
| `nota_isla_escalera` | Fin de la vieja escalera | «Aquí acababa la escalera de los peregrinos. Abajo, solo nubes.» |

**Dirección visual:** se respeta la imagen pintada (verdes lima `#A8D63A` y `#5FA82E`, piedra crema `#E8DDBF` con oro
`#E0A93A`, cristal y agua cian `#5FE0F0`, cielo `#8ED6FF`). Lo que se añada usa esa misma paleta y ese tamaño. La hora es
una **mañana eterna**. Ambiente: nubes que pasan por debajo, motas de luz (ya existen), el cristal de la plaza que late
despacio (un brillo aditivo); para sonido: viento, campanillas y cascadas lejanas. Referencia de principio: el refugio de
cuento después del peligro (FFIX). **Evitar:** objetos 3D nuevos que no estén en la máscara de profundidad (`isla_tapa`):
Kael no pasaría por detrás.

### 2.4 Las posadas, de un vistazo
| Ciudad | Posada | Quién la lleva | Ambiente | Precio | Canon |
|---|---|---|---|---|---|
| Oakhaven | Taberna del Cuervo Oxidado | Olvido | Chimenea, guiso, deudas apuntadas | 30 (como hoy) | Nombre [C]; Olvido [P v2] |
| Sunken City | El Ancla Seca | Doña Coral | Hamacas en una costilla; el gato Almirante | 40 [D] | [P] |
| Arboleda Mítica | Hospedería del Peregrino | Yedra | Colchas de lino y ventanas a las nubes | 20 [D] | [P] |
| Collado de Ámbar (§3.8) | La Lámpara de Ámbar | Telmo | Lámparas de ámbar, sopa de setas, figuritas talladas | 35 [D] | [P] |
| Pastos Verdes | El puesto de Tilo (descanso al aire libre) | Tilo | Hoguera junto al farol oeste | Gratis | [P v3 PV-13] |

Precios distintos [D]: hoy la posada es una constante, `PRECIO_POSADA` (`zona.gd:2308`). Para que varíe, cada ciudad pasa su
precio, con 30 por defecto. Si se prefiere no tocarlo, 30 en todas.

---

## 3. Sitios nuevos que explorar

### 3.0 Resumen
Orden: primero los de canon [C], después las propuestas [P]. El orden de implementación va en §6.
| # | Sitio | Canon | Tipo | Nivel | Conexión en el mapa | Zona (nivel en `NIVEL_ZONA`) |
|---|---|---|---|---|---|---|
| 3.1 | Crematorio y Cripta de las Urnas | Crematorio [C]; cripta [P v2] | Gruta urbana | 3-5 | Oculto: trampilla del Cuervo (Oakhaven) | «cripta»: 4 |
| 3.2 | Templo del Cristal del Cielo | [C] | Templo (acto III) | 22-26 | Oculto: terraza de la Arboleda | «templo_cielo»: 24 |
| 3.3 | Cala de los Mástiles y Gruta de la Marea | Océano de Bruma [C]; contenido [P] | Costa y gruta | 10-13 | Marcador nuevo en (1160, 790) | «costa»: 11 |
| 3.4 | Acantilados del Abismo Quebrado | Abismo Quebrado [C]; contenido [P] | Entrada de la mazmorra final | 30-34 | Dentro de la zona del Abismo (índice 8) | — (la del Abismo) |
| 3.5 | Gruta del Velo | [P v2, P v3] | Gruta santuario | 2-3 | Dentro de Pastos Verdes (índice 10) | — (la de Pastos) |
| 3.6 | Escalera del Cielo | [P v2] | Ruinas | 3-5 | Marcador nuevo en (520, 500) | «escalera»: 4 |
| 3.7 | Aldea Rocío | Aldea tragada [C]; nombre y contenido [P v2] | Aldea en la niebla | 4-6, sin encuentros | Marcador nuevo en (500, 175), al recordar su nombre | «niebla»: sin encuentros |
| 3.8 | Collado de Ámbar y Gruta de los Centinelas | [P]; enemigos [C] | Aldea con posada y gruta | 9-13 | Marcador nuevo en (1160, 480) | aldea: «ciudad» 0; gruta: «mina» 11 |

**Comprobación de los marcadores nuevos** (sobre la captura del 08/11; pendiente en el juego y de coordinar con [T-085],
el mapamundi de gráficos):
| Marcador | Terreno en la captura | Lugar más cercano | Ruta más cercana |
|---|---|---|---|
| Aldea Rocío (500, 175) | Tierra (llanura), 49 de 49 muestras | Oakhaven, 156 px (al norte, como dice el prólogo) | Oakhaven → Bosque, 156 px |
| Escalera del Cielo (520, 500) | Tierra (llanura) | Pastos, 142 px; Portal, 161 px; Oakhaven, 170 px | Oakhaven → Bosque, 117 px |
| Collado de Ámbar (1160, 480) | Tierra (montaña) | Ninguno a menos de 170 px | Garganta → Ciclópea, 37 px |
| Cala de los Mástiles (1160, 790) | Tierra (montaña), con costa al este | Ninguno a menos de 170 px | Garganta → Valle, 141 px |

En la isla del Abismo no cabe otro marcador a 140 px o más (las posiciones probadas quedan a 106-120 px del Abismo); por
eso 3.4 va dentro de su zona. Las posiciones al norte y al este del Portal caen en el mar.

### 3.1 Crematorio de Oakhaven y Cripta de las Urnas
- **Canon:** el crematorio [C: `mapa.gd:41`]; el sello roto con los nombres raspados [C: `progreso.gd:25-26`]; el Incienso
  de Ceniza, «un rato sin encuentros» [C: `diario.gd:21`]. La cripta es [P v2 §7.2]; que el Cónclave raspe nombres
  allí, [P v2 §3.5].
- **Concepto:** bajo el crematorio, alcantarillas antiguas que llevan a una cripta de urnas sin nombre, en filas que no
  acaban. Al fondo, una puerta con el anillo partido que no cede. Se abre en el acto III [P].
- **Identidad visual:** piedra color ceniza `#6A6460`, urnas color hueso `#BFB6A8`, velas ámbar `#FFB45A`, motas de
  ceniza que suben con las corrientes de aire. El único color fuerte: cintas y flores que alguien dejó.
- **Qué hacer:**
  - **Alcantarillas:** slimes [C enemigo]; por las rejillas entra la luz de la ciudad y se ven pasar por arriba los pies
    de Bastián (humor);
  - **Osario:** polillas de ceniza ([T-093]: vuelan y esquivan; débiles al Agua);
  - **Combate fijo:** el Guardia de las Urnas (el modelo del Gólem de ámbar teñido de gris [C: `combate.gd:209`]);
  - **Secretos:** la urna de la cinta azul (nota); un nicho con 3 Incienso de Ceniza (pista sin explicación del secreto
    n.º 1 de la v2: el incienso se hace con esa ceniza); un cofre raro tras una urna caída
    (`oak_cripta_cofre_raro`);
  - **Vista:** un balcón sobre la Sala del Horno: el fuego que nunca se apaga y el humo blanco que sube por la chimenea;
  - **Atajo:** se sale al jardín de urnas, junto a la puerta del crematorio.
- **Nota:** `nota_oak_urna`: «Entre urnas sin nombre, una lleva una cinta azul atada con prisa.»
- **Nivel:** 3-5. Se abre tras el capítulo 1 (`pv_14`; sin 3D, tras salir de Oakhaven la primera vez).
- **Conexión:** índice nuevo oculto; se entra por la trampilla del Cuervo (secreto O1).
- **D-033:** sin Érebo. Que alguien raspa nombres solo se ve (urnas raspadas; una cucharilla de plata sobre una mesa [P v3],
  si se aprueba a Madre Ceniza); no se explica qué se quema.

### 3.2 Templo del Cristal del Cielo (Arboleda Mítica)
- **Canon:** «El templo de arriba guarda el Cristal del Cielo. Nadie entra sin permiso.» [C: `isla.gd:28`]; «Si el agua se
  para, la isla cae.» [C: `isla.gd:32`]. Cerrado hasta el acto III [P v2 §6.3; D].
- **Ahora (actos I y II):** la puerta azul de la imagen sigue cerrada. Al acercarse habla Ilia; nota del anillo entero
  (`nota_isla_puerta`); el brazalete brilla. La puerta «no cede», como la de la Garganta [C: `garganta.gd:230`].
- **En el acto III** [P]: un interior de tres alturas:
  - la Sala de las Fuentes: canales de agua que alimentan las cascadas; un puzle de compuertas;
  - la Galería de los Peregrinos: manos y faroles grabados en las paredes de cristal;
  - la Cámara del Cristal: desde arriba, el mundo entero.
  - Lo que le pasa al Cristal (la v3 propone que el Cónclave se lo lleve) es **decisión de historia** [D]: aquí solo se
    diseña el espacio.
- **Identidad visual:** cristal celeste `#8ED6FF`, agua, piedra marfil `#FFF6E3` con oro; la luz nace del suelo. Reflejos
  pintados, sin refracción en los perfiles bajo y medio.
- **Nivel:** 22-26. **Conexión:** índice nuevo oculto, desde la terraza del templo.
- **D-033:** el Cristal no se relaciona con Érebo en ningún momento.

### 3.3 Cala de los Mástiles y Gruta de la Marea (Océano de Bruma)
- **Canon:** el rótulo «OCÉANO DE BRUMA» [C: `mapa.gd:69`]; un barco de guerra antiguo en Sunken City [C]. El contenido es
  [P].
- **Concepto:** una cala donde el Océano de Bruma, un mar cubierto de niebla, lame la orilla. Asoman mástiles y cuadernas
  de buques antiguos, como un bosque muerto. En el acantilado, un faro apagado. Debajo, la Gruta de la Marea: algas que
  brillan, pozas y una barca con el águila de la Compañía.
- **Identidad visual:** hora fija de atardecer lavanda; bruma gris lavanda `#A9A3C2`, madera mojada casi negra `#3F3A36`,
  roca pizarra `#4C4A50`, algas cian que brillan `#6FF2D8` (emisión), el haz del faro en oro `#F2C86B`.
- **Qué hacer:**
  - **El faro** [P]: encenderlo con el farero Quirós. La bruma retrocede un poco y deja ver un banco de arena hasta un
    pecio con un cofre (`cala_cofre_pecio`);
  - **Gruta de la Marea:** pozas con perlas grises (misión «Perlas de bruma» de Sunken City); cangrejos de casco y
    medusas de bruma ([T-093]: las medusas flotan y son débiles al Fuego); un cofre en la barca del Águila;
  - **Vista:** desde el faro, la línea de mástiles hasta perderse en la bruma;
  - **Nota:** `nota_cala_botella`: «Una botella con un mensaje. El agua se ha comido todos los nombres.»
- **NPC:** el farero Quirós [P], ermitaño: «El faro se apagó solo, una noche. Desde entonces no viene nadie.» · «La bruma
  no avanza donde hay luz. Por eso subo cada tarde.» (es una creencia suya, de la regla 3 de la v2 [P]).
- **Nivel:** 10-13. **Conexión:** marcador nuevo en (1160, 790) (§3.0). Zona «costa», nueva.
- **D-033:** del mar de niebla solo se dice cómo es («no tiene horizonte»), nunca qué es.

### 3.4 Acantilados del Abismo Quebrado
- **Canon:** el rótulo «EL ABISMO QUEBRADO» [C: `mapa.gd:70`]; «La fortaleza final de Morgath. Solo se llega con el
  Astraea.» [C: `mapa.gd:57`].
- **Concepto** [P]: los acantilados de basalto roto alrededor de la fortaleza. El desembarco de la Astraea, puentes de
  cadenas y dunas de ceniza con letras quemadas [P v2 §7.6, n.º 13].
- **Nivel:** 30-34 (acto IV). **Conexión:** primera parte de la zona del Abismo (índice 8), no un marcador nuevo (§3.0).
- **Identidad visual:** basalto `#2A2628`, ceniza `#58524F` con brasas `#FF7A3D`, cadenas de hierro; ráfagas de ceniza
  como pocas imágenes grandes.
- **D-033:** es del acto IV. Lo que pase allí sigue las decisiones de la historia principal [D].
- Va el último en el orden (§6).

### 3.5 Gruta del Velo (Pastos Verdes)
- **Estado:** [P v2 §8.8; P v3 PV-09 y PV-10]. El corte alfa (D-035) aún no la tiene.
- **Concepto:** tras la cascada de Pastos Verdes, una gruta pequeña. Miles de huellas de manos alrededor de un anillo de
  piedra partido, un farol viejo apagado y la tercera estela.
- **Identidad visual:** roca húmeda verde azulada; la luz del día entra filtrada por la cortina de agua (ondas de luz
  animadas, baratas); las huellas, más claras por el uso; el anillo, con un brillo dorado tenue.
- **Qué hacer:**
  - bajar por la escalera escondida tras unos arbustos junto al mirador [P v2]; Tilo la enseña;
  - examinar las manos (detalle `pastos_manos` [P v2]) y poner la mano: el momento musical lo decide Audio;
  - **Secreto** [P]: el farol viejo se enciende con la **mecha de Tilo**, que ya existe en el juego (hito `mecha_tilo`,
    D-052), y descubre un nicho con un cofre (`pastos3d_cofre_velo`). Es un motivo para volver tras el capítulo;
  - **Vista:** desde dentro, el puente visto a través del agua.
- **Nivel:** 2-3, sin combates: es un santuario.
- **Conexión:** dentro de Pastos Verdes (índice 10); no hace falta índice nuevo. La bajada al barranco es hoy zona
  prohibida (`sendero_puente.gd:256-268`): recorrido y colisiones con `aet-fisica-recorrido`.
- **D-033:** es uno de los sitios afectados. Cabe que la sombra de Lya llegue a la roca un instante antes que ella, sin
  que nadie lo comente [P v3 PV-10]. Nada más.

### 3.6 Escalera del Cielo
- **Estado:** [P v2 §3.1 y §7.2]: «Ruinas de una escalera que sube y termina en el aire: por ahí subían los peregrinos a la
  Arboleda.»
- **Concepto:** una escalera monumental de piedra blanca que sube en espiral por una colina y se corta en el aire. A lo
  largo, faroles de peregrino apagados y losas con nombres, algunos raspados.
- **Identidad visual:** piedra blanca envejecida `#D8D2C4`, musgo `#7FA65A`, lavanda entre las juntas `#B9A6F5`; el corte
  final, con varillas de hierro torcidas. Desde arriba, la panza de la ciudad flotante y sus cascadas deshaciéndose en
  bruma.
- **Qué hacer:**
  - encender los faroles de la escalera; los Grimfang los apagan (patrullas con combates fijos de Grimfang [C]), igual que
    en PV-06 intentan apagar el ojo del centinela;
  - un cofre en un rellano roto, al que se llega cruzando por una columna caída (`escalera_cofre_rellano`);
  - **Vista** en lo alto, hacia arriba: la ciudad flotante (tras `pv_07`, para no adelantar la primera vista);
  - **Nota:** `nota_escalera_losas`: «Losas con nombres de peregrinos. Faltan las de los últimos escalones.»
  - Bastián puede acompañar este tramo (§4.4).
- **Nivel:** 3-5. **Conexión:** marcador nuevo en (520, 500), al suroeste del Portal y al oeste de Pastos (§3.0). Se abre
  tras `pv_07` (sin 3D, tras subir a la Arboleda). El extremo de arriba está en la Arboleda (secreto A2).
- **D-033:** no hay niebla ni Érebo en este sitio.

### 3.7 Aldea Rocío
- **Canon:** «otra aldea al norte de Oakhaven» [C: `prologo.dtl:4`]. El nombre y el contenido son [P v2 §3.1 y §7.2].
- **Concepto:** la aldea que la niebla se tragó la víspera del prólogo. Dentro, todo sigue como lo dejaron: mesas puestas,
  ropa tendida, una mecedora que aún se mece, pan en el horno. Ni una persona. En la puerta de una casa, un perro espera.
- **Cómo se juega:**
  - Lya y Garon se quedan en la linde, junto a dos postes con faroles; Kael entra solo, porque a él la niebla no le toca
    [C: `prologo.dtl:7`].
  - Dentro todo está gris; el farol de Kael devuelve el color en un círculo a su alrededor. Es una desaturación con
    máscara radial: barata, pero hay que medirla.
  - Sin combates: el peligro es perderse. Si el farol se apaga, Kael aparece de vuelta en la linde.
  - El grupo de la partida no cambia (`grupo_activo` no se toca): en 2D solo se ve a Kael, y en esta zona no hay
    combates.
- **Qué hacer:**
  - «Cartas a nadie» [P v2 n.º 5]: un buzón con cartas que la gente sigue escribiendo. Nota `nota_rocio_carta`: «Una
    carta sin firma: “No te olvides de encender los faroles.”»;
  - un cofre en la panadería (`rocio_cofre_horno`);
  - el perro: Lucero (§4.4);
  - **Vista:** desde el campanario, la aldea gris y, más allá, el borde de la niebla con los dos faroles de la linde.
- **En la linde** [P, muestra]:
  > **Garon:** Hasta aquí. La niebla no es para nosotros.
  > **Lya:** Kael… si no vuelves pronto, entro a buscarte.
  > **Kael:** No puedes. Lo dijiste tú: solo yo.
  > **Lya:** Por eso. No tardes.
- **Al salir con el perro** [P, muestra]:
  > **Lya:** ¿Y ese perro?
  > **Kael:** Esperaba en una puerta. Le he preguntado a quién, pero no lo sabe.
  > **Kael:** Se llama Lucero. Bueno, ahora se llama Lucero.
  > **Garon:** No pienso darle de comer.
- **Nivel:** 4-6, sin encuentros. **Conexión:** marcador nuevo en (500, 175). Aparece en el mapa al completar «El nombre
  borroso» (`hitos.rocio_nombre`). Zona «niebla», nueva.
- **D-033 y la Gran Verdad:** no se explica qué es la niebla ni dónde está la gente. Sin siluetas: se guardan para la
  bruma del puente [P v3 PV-11]. Nada de Érebo.

### 3.8 Collado de Ámbar y Gruta de los Centinelas
- **Estado:** [P] nuevo. Canon relacionado: el Guardián de piedra y el Gólem de ámbar [C: `combate.gd:203`, `:209`]; el
  centinela de Pastos es un gólem de ámbar con el ojo encendido [C visual].
- **Concepto:** una aldea minera en el paso entre la Garganta y Ciclópea. Sacan ámbar. Hace poco abrieron una galería y
  dieron con un taller antiguo lleno de centinelas a medio tallar; algunos despertaron y atacan. Además, es un sitio para
  descansar entre el final del acto I (la Garganta, nivel 7) y Ciclópea (nivel 15).
- **Identidad visual:** piedra gris azulada `#6F7480`, nieve en las cumbres `#EEF3FA`, casas de madera oscura `#4A3426`
  con lámparas de ámbar que brillan como la miel `#F5C04A` (emisión). En la gruta, vetas de ámbar luminoso `#E89A2C` y
  estatuas en fila.
- **La aldea** (4 NPC):
  | NPC | Frases |
  |---|---|
  | **Telmo**, posadero de La Lámpara de Ámbar; un gigante callado que talla animalitos de ámbar | «Treinta y cinco monedas, cama caliente y sopa de setas. La sopa no se discute.» · «¿Te gusta? Es un zorro. O un gato. Aún no lo ha decidido.» |
  | **Capataza Berta**, jefa de la mina; práctica y sin miedo | «Abrimos una galería y apareció un taller. Con estatuas. Que se mueven.» · «Si las limpias de ahí abajo, te pago. Si no vuelves, no.» |
  | **Pirita**, hija de mineros; colecciona piedras | «Esta piedra tiene un bicho dentro. Dormido. Desde hace siglos.» |
  | **Dámaso**, guardia de la mina; muy prudente | «Yo guardo la entrada. Desde fuera. Bien lejos.» |
- **La gruta:**
  - combates con el Guardián de piedra y el Gólem de ámbar [C];
  - un centinela dormido se aparta cuando pasa Kael: pista, sin explicación, de que obedecen a la llave [P v2, secreto
    n.º 2]. Garon: «…Se ha apartado. ¿Por ti?» · Kael: «Será mi encanto.»;
  - un cofre en el banco del tallista (`collado_cofre_taller`);
  - **Nota:** `nota_collado_orden` [P v3 §3.9, semilla]: «En cada pedestal, la misma orden grabada: “Guía al que vuelva.”»;
  - **Riesgo y recompensa:** en la sala más honda, opcional, el Centinela Mayor ([T-093]), con el premio a la vista;
  - **Vista** desde el collado: los puentes de la Garganta muy abajo y el pico de Ciclópea, al que mira la estatua sin
    brazo [C: `progreso.gd:35-36`].
- **Nivel:** 9-13. **Conexión:** marcador nuevo en (1160, 480), en la ruta Garganta → Ciclópea. La aldea, de tipo «ciudad»
  con trazado propio (TIENDA de la tallista con accesorios de ámbar de [T-092]); la gruta, índice oculto.
- **D-033:** nada de Érebo.

### 3.9 Aplazados (y por qué)
| Sitio | Estado | Por qué no ahora |
|---|---|---|
| Arcos de la Sombra (Pastos, noroeste) | [P v2] | Afectado por D-033: es la semilla de que la sombra de Lya encaja en un altar. Mejor al acercarse el acto III |
| Vía del Peregrino | [P v2] | Mejor como misión que une sitios («Los faroles del camino», v2 n.º 2): Pastos, la Escalera, el Collado |
| Fábrica de Calid, Pico de la Escarcha | [P v2] | Mejoras de zonas que ya existen (Calid y Ciclópea), no lugares nuevos |
| El Confino | [P v2] | Acto III; es el corazón de la Gran Verdad |
| La Isla Borrada | [P v3 §10.2.5] | Contenido opcional del final; pendiente de decisión |

---

## 4. Compañeros de viaje

### 4.0 Lo que ya hay y los límites
- **Grupo** [C]: Kael, Lya y Garon (`grupo.gd:31`). Nyx existe en los datos como «Mago negro», fuera del grupo
  (`grupo.gd:26`).
- **El combate coloca a tres** y cada héroe 3D se dibuja en su propia ventana, que cuesta en el móvil (v3 §10.4). Un cuarto
  compañero no debería combatir a la vez: haría falta un banquillo. La base ya existe: `grupo_activo` y `activos()`
  (`grupo.gd:60`).
- **D-072:** el grupo jugable no cambia sin el usuario. Todo lo de §4.1 a §4.3 es **propuesta** [P] para la biblia; lo de
  §4.4 se puede hacer ya, porque no toca el canon.
- **El tamaño del grupo** sigue abierto (v3 §10.4). Estas propuestas sirven para un grupo de 3 activos más reservas.

### 4.1 Nyx, el aprendiz de ceniza
- **Canon:** nombre, clase «Mago negro», cetro, Fuego, Agua y Rayo, y sus atributos están en `grupo.gd:26-27`; tiene color
  propio en los menús, violeta `#8E5BD8` (`menu_combate.gd:21`); no está en el grupo. El hueco del modelo de Lya en el
  combate se llama «nyx3d» (`combate.gd:152`), una confusión de nombres que la v2 ya señaló (§1.4, n.º 12).
- **Quién es** [P v2 §4.5, ampliado]: joven mago del Cónclave de las Cenizas y aprendiz de su archivera. Orgulloso,
  preciso y sarcástico; amable a escondidas. Cree de verdad que olvidar es una forma de piedad.
- **De dónde sale:** aparece como rival en el acto I (en el santuario del Bosque) y en el acto II (en Calid o en Sunken
  City). Se une en el acto III, después de ver la niebla por dentro [P v2].
- **Motivación:** descubrir si lo que le enseñaron es verdad. Su arco va de «olvidar es piedad» a «recordar es valentía».
- **Qué aporta:** el daño mágico. Usa las magias que ya existen sin cambiarlas (D-048); Lya queda libre para curar. Si
  [T-091] crea una familia nueva, la de la ceniza le pega (por ejemplo, magias que debilitan).
- **Cómo encaja:**
  - **Kael:** Nyx le ve como una catástrofe con patas; Kael le llama «Ceniza». Pullas constantes que acaban en respeto.
  - **Lya:** rivales, luz contra ceniza; se corrigen el uno al otro los hechizos. Sin romance (no hace falta).
  - **Garon:** desconfianza total hacia alguien del crematorio; más tarde, el primero en defenderle.
  - **Érebo:** a Nyx le enseñaron que la sombra de Lya es una maldición; le tiene pánico. Érebo le roba la merienda.
- **Riesgos:** que reste peso a la familia de cuatro si llega pronto (por eso, acto III); hace falta un modelo propio y
  renombrar el hueco «nyx3d»; su género no está fijado en los datos (la v2 dice «joven mago») [D].
- **D-033:** se une después de las revelaciones del acto III; antes no puede decir nada de lo que guarda Érebo.

### 4.2 La capitana Brea
- **Canon:** la Compañía del Águila [C: `progreso.gd:39-40`] y la Astraea [C nombre]. Brea es [P v2 §4.7].
- **Quién es:** capitana de la Compañía del Águila en Sunken City; ruidosa, generosa, endeudada y apostadora. Guarda la
  Astraea.
- **De dónde sale:** Sunken City, en el acto II, con el primer vuelo de la Astraea (nivel 12-14).
- **Motivación:** pagar sus deudas y que la Compañía vuelva a valer algo. En el fondo, redimir a un Águila que hizo
  trabajos sucios para la corona [P v2].
- **Qué aporta:**
  - fuera del combate, la Astraea: viaje rápido [C] y una base móvil con conversaciones;
  - en combate (si el usuario la quiere como heroína): ataque físico a distancia y apoyo con luz. Sugerencias para
    [T-091]/[T-092]: «Bengala» (deslumbra y baja la evasión; enlaza con «la luz frena la niebla», regla de la v2) y
    «Ancla» (un golpe lento y muy fuerte).
- **Cómo encaja:**
  - **Kael:** dos bromistas; ella se convierte en la tía que le enseña a apostar (y a perder).
  - **Lya:** Lya desaprueba sus métodos; Brea le enseña a reírse de sí misma.
  - **Garon:** dos veteranos que se miden. Si se aprueba la v3, compartieron la Compañía y un encargo que Garon no recuerda
    [P v3 §3.3]: tensión de verdad.
  - **Érebo:** supersticiosa; pone sal alrededor de su hamaca (humor).
- **Riesgos:** que le quite a Garon el papel de veterano. Para evitarlo: Brea es el caos y Garon el orden.
- **Versión mínima:** Brea solo pilota la Astraea y no combate. Eso ya es un «amigo de viaje» y no toca el grupo.

### 4.3 Nerea, la cartógrafa de nombres
- **Canon:** ninguno. Es [P v2 §4.7]: «Recorre las aldeas tragadas y apunta en sus mapas los nombres que la gente aún
  recuerda.»
- **De dónde sale:** está en la linde de Aldea Rocío cuando Kael sale de la niebla (o en la taberna del Cuervo, si se
  prefiere más pronto).
- **Motivación:** que ninguna aldea desaparezca del todo de los mapas. Olvida todo menos los nombres: por eso lo apunta
  todo. «Lo que no apunto, no existe.»
- **Qué aporta** (sugerencias para [T-091]/[T-093]):
  - **Explorar** («Cartografiar»): una vez por zona, marca en pantalla los cofres y secretos cercanos. Sirve al pilar de
    «muchos secretos».
  - **En combate** («Nombrar»): revela el patrón y la debilidad de un enemigo. Encaja con [T-093], que pide debilidades
    legibles.
  - Da las misiones de «El mapa de los nombres» [P v2 n.º 4].
- **Cómo encaja:**
  - **Kael:** quiere escribir su historia y él no tiene. «Escribe “Kael”. Con eso basta.» (el tema de la identidad,
    canon: «La sangre no te hace nombre; te lo dan los pasos que das», `carga.gd:21`).
  - **Lya:** complicidad de lectoras.
  - **Garon:** le entrevista; él contesta con monosílabos y ella los apunta como si fueran versos.
  - **Érebo:** intenta dibujarlo y nunca se está quieto (solo humor).
- **Riesgos:** su tema (los nombres) toca el final de la historia. Ella apunta; quien actúa es Kael.
- **Versión mínima:** acompañante que no combate (como §4.4) y da misiones.

### 4.4 Versión ligera: acompañantes que no tocan el canon
Siguen a Kael en la exploración durante un tramo, comentan, señalan un secreto y se van. No entran en `grupo.gd` ni en el
combate. En 3D se puede reutilizar el seguimiento de `zonas3d/grupo_3d.gd`; en 2D hace falta una figura que siga a Kael
con retraso (código nuevo y sencillo). Cada uno empieza y acaba con un hito.

| Acompañante | Tramo | Qué hace | Por qué encaja | Canon |
|---|---|---|---|---|
| **Pip, guía de pago** | Alcantarillas de Oakhaven → Cripta (§3.1) | Por una moneda, guía y abre un atajo; en el primer combate huye («¡Os espero fuera! Muy fuera.») y vuelve al final | Paga la frase de canon «Si me das una moneda te cuento un secreto» (`npc_pip.dtl:4`) | Pip [C]; su papel [P] |
| **Lucero, el perro de Aldea Rocío** | Desde Aldea Rocío; se queda a vivir en el Cuervo y se le puede llevar | Olfatea: una vez por zona encuentra un **cofre enterrado** (un tipo nuevo de cofre con id fijo) | El perro que «espera» [P v2 §7.2]; recuerda a alguien que nadie recuerda: el tema del juego en pequeño | [P] |
| **Bastián** | Escalera del Cielo (§3.6) | Enciende faroles con el grupo; no pasa de la primera niebla | El niño que cuenta faroles [P v2 §7.3] | [P] |

Además, sin nadie nuevo: las **escenas de posada** (§2) hacen que el grupo de siempre conviva entre aventura y aventura.

### 4.5 Recomendación
1. **Ya** (sin decisión de historia): Pip como guía y Lucero; las escenas de posada.
2. **Primera decisión:** Brea en su versión mínima (pilota, no combate), cuando llegue el acto II.
3. **Si se quiere un cuarto héroe:** Nyx, porque ya está en los datos y su llegada en el acto III no quita protagonismo a
   la familia. Nerea, mejor como acompañante.

---

## 5. Texto del prólogo y de Pastos Verdes (preparación de [T-086])

### 5.1 Criterios
- Caja de 880 px con letra de 28 px: unas **dos líneas de unos 55 caracteres** por intervención (unos 110).
- **No cambian hechos ni canon.** Las frases del prólogo que la biblia v2 cita como canon (su §1.3) se conservan palabra
  por palabra; solo se parten dos globos.
- **No cambia quién habla** ni el orden: Kael solo en PV-02; Lya desde PV-03; Garon desde PV-05 (D-059).
- **Se conservan** las palabras de las que salen los objetivos en pantalla (D-059): «saludar antes al viejo», «el
  centinela del mirador» y «el bosque está al noreste».
- **Gestos:** las etiquetas `extra_data` del prólogo no cambian. Si se parte un globo, animaciones decide si el segundo
  repite el gesto. En la copia de animaciones hay un gesto «brazalete» antes de la línea 8, sin confirmar (observado en
  sus archivos, sin tocarlos): no le afecta nada de esta tabla.
- **Longitud** = caracteres visibles, sin las etiquetas `[pause=…]`. Medida con un script el 2026-11-09 sobre `dddbddb`.

### 5.2 Tabla de antes y después
«=» significa sin cambios. Las intenciones son para animaciones.

| # | Archivo:línea | Quién | Antes | Después | Long. | Motivo | Intención |
|---|---|---|---|---|---|---|---|
| 1 | `prologo.dtl:4` | Lya | Kael…[pause=0.4] ¿lo has visto? La niebla ha vuelto a tragarse otra aldea al norte de Oakhaven. | = | 84 | Canon; cabe en dos líneas | Inquieta (`inquieta`) |
| 2 | `prologo.dtl:6` | Kael | Lo he visto. Y como siempre, a mí ni me roza.[pause=0.3] Será que hasta la niebla tiene buen gusto. | = | 88 | Canon; la pausa ya da el ritmo del chiste | Ligero (`ligero`) |
| 3 | `prologo.dtl:7` | Lya | No bromees. Nadie es inmune a la niebla.[pause=0.5] Nadie… salvo tú. | = | 57 | Canon | Seria, y al final baja la voz |
| 4 | `prologo.dtl:8` | Kael | Supongo que este brazalete sirve para algo más que para presumir. | = | 65 | Canon | Mira el brazalete |
| 5 | `prologo.dtl:10` | Lya | Ese brazalete…[pause=0.5] He visto ese símbolo en los libros prohibidos del templo. Lo llamaban la «Llave del Confino». | **Globo 1:** Ese brazalete…[pause=0.5] He visto ese símbolo en los libros prohibidos del templo. **Globo 2:** Lo llamaban la «Llave del Confino». | 108 → 72 + 35 | Con 108 caracteres y el corte por palabras, lo normal es que ocupe tres líneas. Partido, el nombre del brazalete llega solo y pesa más. Sin cambiar una palabra | Duda (`duda`) en el 1; seria en el 2 |
| 6 | `prologo.dtl:12` | Kael | ¿La llave de qué? | = | 17 | — | Sorpresa (`sorpresa`) |
| 7 | `prologo.dtl:13` | Lya | No lo sé.[pause=0.3] Pero si los Hollines han empezado a salir del bosque, alguien tiene que averiguarlo. | = | 94 | Canon (y la v3 propone que ese «No lo sé» sea mentira: no se toca) | Aparta la mirada en «No lo sé»; firme al final |
| 8 | `prologo.dtl:15` | Kael | Entonces vamos. El Gran Bosque Verde no está lejos. | = | 51 | — | Decidido (`decidido`) |
| 9 | `prologo.dtl:17` | Lya | Ten cuidado ahí fuera. Los Hollines ya no son solo sombras: ahora llevan hachas del Vacío. | **Globo 1:** Ten cuidado ahí fuera. **Globo 2:** Los Hollines ya no son solo sombras: ahora llevan hachas del Vacío. | 90 → 22 + 67 | Recomendado, no imprescindible. «Ten cuidado ahí fuera» queda solo, y PV-03 lo recuerda («Te dije “ten cuidado”. No “vete solo”»); la amenaza cierra el prólogo | Preocupada (`preocupada`) en los dos |
| 10 | `pv_02.dtl:2` | Kael | Pastos Verdes. Ni rastro de niebla. | = | 35 | — | Alivio, mira alrededor |
| 11 | `pv_02.dtl:3` | Kael | Bien. Por una vez, algo sale bien. | **Y nadie me ha seguido. Por una vez, algo sale bien.** | 34 → 51 | Quita la repetición «Bien… bien» y prepara el chiste de PV-03: Lya sí le ha seguido. Es lo que cree Kael, no un hecho | Satisfecho; tienta a la suerte |
| 12 | `pv_03.dtl:3` | Lya | ¡Kael! ¿De verdad pensabas irte sin mí? | = | 39 | Ya tiene ritmo y voz | Llega corriendo, enfadada a medias |
| 13 | `pv_03.dtl:4` | Kael | Pensaba dejarte dormir. Es distinto. | = | 36 | — | Pillado; se defiende |
| 14 | `pv_03.dtl:5` | Lya | Te dije «ten cuidado». No «vete solo». | = | 38 | — | Reproche con cariño |
| 15 | `pv_03.dtl:6` | Kael | Matices. | = | 8 | — | Sonrisa ladeada |
| 16 | `pv_03.dtl:7` | Lya | El bosque está al noreste. Y yo sé el camino. | = | 45 | De aquí sale el objetivo «hacia el noreste» | Señala; manda ella |
| 17 | `pv_03.dtl:8` | Kael | Yo también. Más o menos. Bastante menos. | = | 40 | — | Se rinde con humor |
| 18 | `pv_05.dtl:3` | Garon | Llegáis tarde. | = | 14 | Frase de presentación de Garon | Brazos cruzados |
| 19 | `pv_05.dtl:4` | Kael | ¿Garon? ¿Has venido andando o te han traído en carro? | = | 53 | — | Sorpresa, luego burla |
| 20 | `pv_05.dtl:5` | Garon | A caballo, antes del alba. Nadie sale de noche. Vosotros salisteis. | = | 67 | Telegráfico: es su voz | Seco |
| 21 | `pv_05.dtl:6` | Garon | Volvéis conmigo a Oakhaven. | = | 27 | — | Orden |
| 22 | `pv_05.dtl:7` | Lya | Están desapareciendo aldeas, Garon. | = | 35 | — | Firme, preocupada |
| 23 | `pv_05.dtl:8` | Garon | Por eso. Fuera de la muralla no os puedo proteger. | = | 50 | — | Protector; deja ver por qué |
| 24 | `pv_05.dtl:9` | Tilo | Aquí nadie va a ninguna parte sin saludar antes al viejo. | = | 57 | De aquí sale el objetivo «Saluda al centinela» | Interrumpe, cascarrabias |
| 25 | `pv_05.dtl:10` | Kael | ¿Qué viejo? | = | 11 | — | Desconcierto |
| 26 | `pv_05.dtl:11` | Tilo | El centinela del mirador. Los peregrinos lo saludaban antes de cruzar. | = | 70 | — | Señala el mirador |
| 27 | `pv_05.dtl:12` | Tilo | Cuarenta años con el ojo apagado… y esta madrugada se le encendió. | = | 66 | — | Asombro contenido |
| 28 | `pv_05.dtl:13` | Tilo | Cuando al viejo se le enciende el ojo, algo viene. | = | 50 | Refrán: es su voz | Grave |
| 29 | `pv_05.dtl:14` | Garon | …Os acompaño. Solo hasta la estatua. | = | 36 | — | Cede a regañadientes |
| 30 | `pv_06.dtl:3` | Garon | Quietos. Dos. | = | 13 | — | Alerta, mano al arma |
| 31 | `pv_06.dtl:4` | Kael | ¿Le están pegando a una estatua? | = | 32 | — | Incredulidad |
| 32 | `pv_06.dtl:5` | Lya | Al ojo. Quieren apagárselo. | = | 27 | — | Entiende; alarma |
| 33 | `pv_07.dtl:3` | Lya | Una ciudad… en el cielo. | = | 24 | — | Asombro |
| 34 | `pv_07.dtl:4` | Kael | Y nosotros aquí, con los pies mojados. | = | 38 | — | Quita hierro |
| 35 | `pv_07.dtl:5` | Lya | Kael, te está mirando. | = | 22 | — | Inquieta |
| 36 | `pv_07.dtl:6` | Kael | Las estatuas no miran. | = | 22 | — | Escéptico, sin mirar |
| 37 | `pv_07.dtl:7` | Garon | Esta, sí. | = | 9 | — | Seco |
| 38 | `pv_07.dtl:8` | Lya | Hay flores frescas a sus pies. Alguien las ha puesto esta mañana. | = | 65 | — | Se agacha; curiosa |
| 39 | `pv_07.dtl:9` | Garon | Y esas huellas de hollín dan vueltas alrededor… sin pisarlas. | **Huellas de hollín. Rodean las flores… sin pisarlas.** | 61 → 51 | La voz telegráfica de Garon y queda claro qué no pisan. El hecho es el mismo | Observa el suelo; desconfía |
| 40 | `pv_14.dtl:1` | Tilo | Tomad. Una mecha de mi farol. Arde más que yo. | = | 46 | — | Entrega la mecha |
| 41 | `pv_14.dtl:2` | Tilo | Lo de las flores… ya lo averiguaré. Tiempo me sobra. | = | 52 | — | Pensativo, con humor |
| 42 | `pv_14.dtl:3` | Tilo | Y si algún día subís allí arriba, saludadme al cielo. | = | 53 | — | Mira hacia arriba |
| 43 | `pv_tilo.dtl:1` | Tilo | El viejo centinela del mirador lleva cuarenta años mirando la cascada. Saludadlo antes de seguir. | **¿Todavía aquí? El viejo os espera en el mirador. Saludadlo antes de cruzar.** | 97 → 75 | No repite «cuarenta años» de PV-05, es más corta y suena a Tilo. Mantiene el hecho: el centinela está en el mirador y se saluda antes de cruzar | Impaciente, con cariño |
| 44 | `pv_tilo_fin.dtl:1` | Tilo | Buen camino, chicos. Y cuidad esa mecha: arde más que yo. | **Buen camino, chicos. Y que no se os apague esa mecha.** | 57 → 53 | «Arde más que yo» ya se dijo en PV-14 | Despedida |

**Resumen:** 44 frases; cambian 6 (n.º 5, 9, 11, 39, 43 y 44). Ninguna cambia un hecho, un hito, una recompensa ni quién
está presente. Por la cuenta de caracteres (94 como mucho), todas caben en dos líneas; falta verlo en el Redmi.

### 5.3 Lo que hay que cambiar fuera de los `.dtl` al aplicarla
- **`pruebas/prueba_prologo.gd:130`** espera 9 frases. Con los dos globos partidos serán 11 (con solo el n.º 5, 10).
- **`pruebas/prueba_dialogo_interfaz.gd:165`** usa `pv_tilo` y falla si su texto contiene «Rosa» o «flores». La frase
  nueva no los contiene.
- **`pruebas/prueba_ruta_alpha.gd`** solo usa los nombres de los timelines: no cambia.
- **Opcional, `progreso.gd:45`** (detalle `pastos_estela`): «El anillo partido y nombres raspados. Uno de los raspados es
  reciente.» → «El anillo partido y nombres raspados. Uno lo rasparon hace poco.» (11 palabras; más claro). No es un
  `.dtl`: lo decide el responsable de ese archivo.
- Los objetivos de la misión (`pastos_verdes_3d.gd:349-363`) están bien y no cambian.

---

## 6. Orden propuesto y dependencias
| Paso | Qué | Tarea | Depende de | Quién |
|---|---|---|---|---|
| 1 | Aplicar la tabla de §5 a los `.dtl` y actualizar `prueba_prologo` | [T-086] | Que animaciones termine con los `.dtl` | Narrativa con animaciones |
| 2 | Oakhaven hecha a mano: trazado, posada con Olvido, 8 NPC, misiones, secretos y notas | [T-089] | §1.3 (índices, `NOTAS`, cofres con id) | Coordinador y gráficos; textos, narrativa |
| 3 | Cripta de las Urnas, con Pip como guía | [T-090], [T-094] | Paso 2; enemigos de [T-093] o los que ya hay | Coordinador, combate |
| 4 | Gruta del Velo en Pastos Verdes, con la mecha de Tilo | [T-090] | Recorrido del barranco; Audio | Coordinador, gráficos, sonido |
| 5 | Aldea Rocío (se abre con «El nombre borroso») y Lucero | [T-090], [T-094] | Paso 2; efecto de desaturación medido | Gráficos, coordinador |
| 6 | Escalera del Cielo y mejoras de la Arboleda (hospedería, NPC, secretos) | [T-089], [T-090] | Índice oculto para la isla | Coordinador, gráficos |
| 7 | Collado de Ámbar y Gruta de los Centinelas | [T-090] | Enemigos que ya existen; Centinela Mayor de [T-093] | Coordinador, combate |
| 8 | Sunken City hecha a mano y el Casco del buque | [T-089] | Paso 2 como plantilla; [T-092] y [T-093] | Coordinador, gráficos, combate |
| 9 | Cala de los Mástiles y Gruta de la Marea | [T-090] | Paso 8 (perlas); estilo «costa» | Gráficos, combate |
| 10 | Templo del Cristal del Cielo y Acantilados del Abismo | — | Actos III y IV: decisiones de historia | Más adelante |
| — | Compañeros que combaten (Nyx, Brea, Nerea) | [T-094] | Decisión del usuario (§7) | — |

En cada paso: mapa con los marcadores nuevos coordinado con [T-085]; rendimiento medido antes y después; pruebas de lugares
y de guardado actualizadas (§1.3).

---

## 7. Decisiones para el usuario
Ninguna bloquea los pasos 1 a 4. Todas tienen una recomendación.

| # | Decisión | Recomendación |
|---|---|---|
| 1 | **Olvido**, la tabernera del Cuervo Oxidado que crió a Kael [P v2], como posadera de Oakhaven | Sí: da a Kael un hogar y humor desde el principio |
| 2 | **La Cripta de las Urnas** bajo el crematorio, donde trabajan quienes raspan nombres [P v2]; en el acto I solo se ve una puerta sellada | Sí |
| 3 | **Aldea Rocío:** el nombre, que Kael entre solo en la niebla y que la aldea aparezca en el mapa al recordar su nombre | Sí |
| 4 | **Compañeros:** Brea como piloto de la Astraea (acto II); Nyx como cuarto héroe (acto III); Nerea como acompañante | Sí a Brea piloto; Nyx, si se quiere un cuarto héroe; Nerea, acompañante |
| 5 | **Acompañantes ligeros:** Pip como guía y Lucero, el perro de Aldea Rocío | Sí (no tocan el canon) |
| 6 | **Precio de las posadas:** 30 / 40 / 20 / 35, o 30 en todas | Distintos: cada ciudad se nota también en el bolsillo |
| 7 | **La abuela de Lumi** como NPC que subió de niña con los peregrinos (y una pista de Tilo niño) | Sí |
| 8 | **Los centinelas se apartan** ante Kael en la Gruta de los Centinelas (pista de que obedecen a la llave) | Sí, sin explicación hasta los actos III-IV |
| 9 | **«El Costillar»** como apodo de Sunken City mientras se revisan los nombres | Sí; el nombre del mapa no cambia |
| 10 | **Prólogo:** partir dos globos (la «Llave del Confino» y «Ten cuidado ahí fuera») | Sí al primero; el segundo, recomendado |

*Registro: 2026-11-09, especialista de narrativa, rama `area-narrativa`. Documento nuevo; no modifica ningún otro archivo.*
