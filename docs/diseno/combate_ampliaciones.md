# Ampliaciones de combate: magias, equipo y enemigos (fase 0, diseño)

> **Estado:** propuesta de diseño del especialista de combate. **Nada está implementado** y no se ha ejecutado Godot.
> **Base:** rama `area-combate` @ `dddbddb` (igual que `integracion-experimental`). Los ganchos de sonido se han mirado
> en `area-sonido` @ `1359386` (sin integrar todavía).
> **Fecha:** 2026-11-09, 00:20 (encargo del coordinador del 08/11 por la noche).
> **Tareas:** [T-091] magias nuevas, [T-092] accesorios y armas especiales, [T-093] enemigos nuevos.
> **Decisiones:** D-071 y D-072. Respeta D-048 (lo protegido), D-037 (Garon sin magia), D-060 (ningún enemigo aturde
> ni duerme), D-062 (nivelación automática, solo propuesta) y D-033 (nada sobre Érebo y los corazones antes del
> acto III; ningún detalle de Final Fantasy X).

**Leyenda**
- **[código]** observado en el código de `dddbddb` (archivo:línea). Nada se ha comprobado ejecutando.
- **[biblia C] / [biblia P]**: canon o propuesta de `docs/biblia/rebelum_biblia_narrativa_v2.md`.
- **[usuario]**: nombre o idea del usuario (propuestas de `MEMORIA_CHAT.md`, §6).
- **[decidir]**: conviene que lo vea el usuario (lista en §7).
- Las cifras son **valores iniciales**: se ajustan con las pruebas de §6.

**Índice:** 0. En una página · 1. Lo que hay hoy · 2. Principios · 3. Magias · 4. Equipo · 5. Enemigos ·
6. Orden, pruebas y riesgos · 7. Decisiones · 8. Peticiones a otros archivos · 9. Límites

---

## 0. En una página

- **Magias:** tres familias nuevas de tres niveles (nueve hechizos) que llenan los huecos tácticos de hoy: nadie
  revive, no hay barreras ni regeneración y nadie toca el ritmo del ATB.
  - **Alba** (Kael): ritmo del ATB. *Compás del Alba*, *Peso del Ocaso* y *Hora Dorada*.
  - **Escarcha** (Kael): defensa. *Coraza de Escarcha*, *Muralla de Escarcha* e *Invierno Guardián*.
  - **Lumbre** (Lya): resistencia. *Lumbre de Retorno*, *Segundo Aliento* y *Última Brasa*.
  - Cinco de los nueve nombres son del usuario. **Ninguna hace daño:** no pasan por el camino de las 12 protegidas.
    Garon no aprende ninguna.
- **Menú de magia:** una pestaña con icono por familia nueva, detrás de «I · II · III». Las pestañas de siempre no
  cambian. Hace falta porque Lya ya llena las cuatro filas que caben (§1, punto 8).
- **Equipo:** el sistema ya existe (7 ranuras, 6 armas). Se añade al final:
  - una octava ranura, **Accesorio**, con 8 accesorios de efecto especial;
  - **6 armas especiales**, dos por héroe, cada una con un efecto propio, como Frostfang.
  - Todos los efectos son aditivos y documentados: **sin ese equipo, el combate da lo mismo que hoy**.
- **Enemigos:** 10 nuevos en siete regiones, cada uno con un patrón que se anuncia y una debilidad que se ve.
  - Ocho se pueden hacer ya (★) reutilizando el goblin 3D, el guardián, el Hollín y el limo con tintes y auras, o
    dibujados por código.
  - Encuentros por región, solo con el grupo de tres. Pastos Verdes no cambia.
- **Orden:** C0 red de seguridad → M1 Alba I → M2 Lumbre I-II → C1 accesorios → E1 enemigos con lo que hay → M3
  Escarcha → C2 armas especiales → M4 niveles III → E2 enemigos por código → E3 arte nuevo.
  - Propuestas aparte, con aprobación: **P1 «Guardia a tiempo»** (ventana de reacción) y **P2 familia «Eclipse»**
    (ofensiva y de sinergia).

---

## 1. Lo que hay hoy (observado en el código, `dddbddb`)

1. **ATB.** `_process` llena `atb += vel × delta` a todos menos en «fin» (`combate.gd:1169-1173`). Al llegar a 100
   entran en `cola`. Solo actúa uno cada vez y solo desde «esperando» (`:1178-1192`): mientras un héroe elige, los
   demás siguen cargando y esperan su turno.
2. **Magia.** Datos en `MAGIAS` (`:65-71`) y `NIVELES_MAGIA` (`:85-99`).
   - El comportamiento se decide por el nombre: `_golpe_visual` (`:2912`), `_lanzar` (`:3397`), `_magia_grupal`
     (`:3290-3303`) y `_desc_magia` (`:1765`).
   - En `_magia_grupal`, una familia que no sea Fuego ni Rayo acaba en `_maremoto`. Cura va por su rama
     (`"cura": true`, `:1782`).
3. **Daño a los héroes.** `_animar_golpe` (`:2458`) aplica, por este orden:
   - crítico del 12 % (`:2459`);
   - defensa / 2 en los golpes físicos (`:2462`);
   - Defender, ×0,5 (`:2464`).
   - El impacto llama a `_quitar_pv` (`:2471`). El golpe devastador de los jefes resta los PV de los demás
     directamente (`:1283-1287`).
4. **Estados.** Solo los enemigos los tienen: quemadura, congelado, furia y cargando (`:1206-1213`). Se ven en
   `lbl_estado`, a 18 px (`:605`, `:3807`). Los héroes solo tienen «defendiendo», y Garon, «embuir».
5. **Nadie revive en combate.** Cura y los objetos solo eligen aliados en pie (`:1807`, `:1931`). Sin embargo, los tres
   modelos 3D ya tienen `revivir()` sin usar (`maga_3d.gd:314`, `kael_3d.gd:350`, `garon_3d.gd:644`).
6. **Enemigos.**
   - Hay 5 (`:199-210`). La personalidad «apoyo», que cura aliados («chamanes», `:1199`, `:1235`), no la usa ninguno.
   - No hay debilidades ni botín.
   - Los encuentros al azar no dependen de la zona: en todo el mundo salen los mismos 5 grupos (`:225-229`,
     `:380-384`); solo cambia el fondo.
7. **Equipo: ya existe.**
   - 7 ranuras (`inventario.gd:7`), 6 armas (`:14-46`) y 16 protecciones que suman atributos (`:50-67`).
   - **Frostfang ya es un arma especial:** congela con cada golpe (`combate.gd:1335-1352`).
   - Se equipa en el menú Grupo con ◀ ▶ en cada ranura (`menus.gd:195-234`), con teclado, mando y táctil (D-063).
8. **Límite del menú de combate** (`menu_combate.gd:27-42`, `:358-378`, `:228`).
   - Columna derecha: el submenú empieza en y = 160, con filas de 64 px y pestañas de 96 px.
   - Con tres héroes, el bloque del grupo empieza en y = 562. Con pestañas caben **4 filas y su descripción**, que
     acaba hacia y = 552.
   - Lya ya tiene 4 familias: **una quinta en las pestañas I · II · III se montaría sobre el grupo**. Este límite
     decide el menú de §3.6.
9. **Sonido** (rama `area-sonido`).
   - Las 12 magias no suenan: es una decisión aparte.
   - Los golpes suenan en el impacto con `Sonido.golpe()`. Los efectos se piden con `Sonido.efecto(nombre)`, y su
     catálogo está en `sonido.gd`.

**Lo que no cambia:**
- las 12 magias (ID, nombre, aprendizaje, coste, daño, fórmulas, objetivos, animaciones y comportamiento);
- Esgrima, Embuir, Érebo, la Armonía y las reglas base del ATB (D-048);
- Garon sin magia (D-037) y ningún enemigo que aturda o duerma (D-060);
- la progresión: quien se une conserva sus datos (D-060, D-062);
- las revelaciones del acto III (D-033).

---

## 2. Principios tomados de otros RPG (solo principios, D-072)

| Principio | Cómo se usa aquí |
|---|---|
| Ritmo táctico con respuesta del jugador | Alba adelanta y retrasa turnos. Los enemigos anuncian su golpe y se les puede contestar. Propuesta P1, «Guardia a tiempo» |
| Sinergias entre personajes | Compás del Alba para que Lya actúe antes y revive. Escarcha sobre Garon en guardia. Fauces de Gorthor sostienen al tanque |
| Riesgo y recompensa | Hora Dorada, muy cara. El autómata, al que conviene dejar calentarse. El hollín de brasa, que hay que rematar con agua. Armas con menos ataque y un efecto |
| Familias por niveles, estados de apoyo y debilidades | Como las cuatro de siempre: el I a uno, el II y el III a todos. Debilidades solo en los enemigos nuevos |
| Secretos que premian explorar | Tomos del nivel III y armas especiales en lugares del canon |
| Legibilidad | Cada estado tiene icono, texto y color, nunca solo color. Cada patrón se anuncia un turno antes |

No se copian nombres, interfaces, escenas ni argumentos, y no hay ningún detalle de Final Fantasy X.

---

## 3. Magias nuevas

### 3.1 Reglas comunes

- **Ruta propia.** Cada familia nueva lleva `"tipo"` en `MAGIAS`. `_elegir_hechizo` desvía, con una línea al
  principio, las que lo tienen. Las 12 de siempre siguen exactamente su camino.
- **Ninguna hace daño:** no pasan por `_animar_golpe`, `_golpe_visual`, `_lanzar` ni `_magia_grupal`.
- **Son acciones normales:** gastan PM, acaban el turno y cargan la Armonía +0,15, como cualquier acción (la regla de
  la Armonía no cambia).
- **Aprendizaje por familia.** Umbrales propios en `grupo.gd`; las cuatro de siempre siguen con 1, 5 y 10.
  - Libro del nivel II en la tienda.
  - El nivel III se aprende por nivel o antes con un **tomo escondido** en un lugar del canon.
  - **Ninguna se aprende en el nivel 1:** las pruebas que empiezan en nivel 1 ven el menú como hoy.
- **Partidas antiguas.** El nivel de magia se calcula, no se guarda: un Kael de nivel 7 tendrá Compás del Alba y Coraza
  de Escarcha nada más cargar. [decidir] si se prefiere que solo se aprendan con tomos.
- **Sonido:** una vez por lanzamiento, en el momento en que se aplica el efecto, por el bus Efectos con
  `Sonido.efecto(...)`. Los nombres están en cada tabla; el catálogo lo pone el especialista de sonido (§8).
- **Efectos visuales:**
  - el círculo de carga de siempre (`_carga_magia`, con el color de la familia) y `lanzar_magia()` / `fin_magia()` de
    Kael y Lya;
  - lo demás, con las piezas 2D de `combate.gd` (`_onda`, `_particulas`, `_brillo`, `_luz`, `_fogonazo`);
  - tres escenas nuevas en `vfx/` que **reutilizan** el círculo, la espiral, `cura.gdshader` y `healing_vfx.gd` con
    otro tinte y otros tiempos. Mismo sombreador: no hay compilaciones nuevas.

### 3.2 Familia Alba (Kael): el ritmo del ATB

- **Lore:** [biblia P] El Sol «recuerda cada día que ha amanecido». La magia del Alba le toma prestadas la prisa del
  amanecer y la pesadez del ocaso.
- **Nombres:** I y II son del usuario.
- **Color:** rosa del alba, `F2B5A0`. **Icono:** medio sol con rayos sobre una línea de horizonte.
- **Aprendizaje (Kael):** I en el nivel 3; II en el 9 o con libro (tienda, 350); III en el 16 o con el **Tomo del
  Alba** (Mar de Arena de Calid, escondido junto a la «Máquina enterrada» [biblia C]).
- **Regla:** cada hechizo cambia la barra **una vez**; el bucle del ATB no se toca. Una aceleración duradera
  obligaría a tocarlo [decidir].

| Nivel | Nombre | PM | Objetivo | Efecto |
|---|---|---|---|---|
| I | **Compás del Alba** | 6 | Un aliado en pie que no sea Kael ni esté esperando ya su turno | +50 de ATB, sin pasar de 99,9: entra en la cola por el camino normal |
| II | **Peso del Ocaso** | 15 | Todos los enemigos | −40 de ATB (los jefes, −20). Quien esperaba su turno lo pierde y vuelve a cargar |
| III | **Hora Dorada** | 30 | Los aliados en pie, menos Kael | Barra a 99,9: actúan en cuanto Kael acabe (los que ya esperaban, antes) |

- **Cómo se verá:**
  - **I:** una chispa rosa sale del sable hacia el aliado (`_proyectil` con el color del Alba). A sus pies, un anillo
    que gira deprisa como la aguja de un reloj (`vfx/AlbaVFX.tscn`). Su barra ATB del menú da un destello.
  - **II:** la pantalla se tiñe de violeta un momento (`_fogonazo`, 1,2 s). Sobre cada enemigo, un anillo oscuro que
    se cierra y lo aplasta un poco (escala vertical 0,92) y el texto «Retraso».
  - **III:** luz dorada desde arriba, un disco de sol que sube detrás del grupo y las barras de los aliados llenas y
    brillando.
- **Sonido:**
  - `arte_alba`: campanilla que sube y un tic de reloj suave (0,6 s);
  - `arte_ocaso`: tono grave que cae y un golpe sordo (1 s);
  - `arte_hora_dorada`: acorde cálido que crece, con campanas (1,5 s).
- **Juego:** dar el turno antes a Lya para revivir o curar; retrasar a un jefe que «⚠ Carga» para tener tiempo de
  proteger al grupo (es la idea del usuario de contestar al golpe anunciado de Gorthor).

### 3.3 Familia Escarcha (Kael): la defensa

- **Lore:** [biblia P, §3.6] «El hielo conserva»: congelar es «fijar». La escarcha de Kael fija y protege. Su abrigo
  lleva dibujos de hielo [biblia C, retrato] y Frostfang congela [C].
- **Color:** blanco escarcha, `BFE6FF`: más claro que el color de Kael (`8FD3FF`). **Icono:** cristal hexagonal.
- **Aprendizaje (Kael):** I en el nivel 6; II en el 12 o con libro (400); III en el 20 o con el **Tomo de la
  Escarcha** (Cumbres de Ciclópea, siguiendo la mirada de la «Estatua sin brazo» [biblia C]).

| Nivel | Nombre | PM | Objetivo | Efecto |
|---|---|---|---|---|
| I | **Coraza de Escarcha** | 7 | Un aliado en pie (también Kael) | Barrera del 30 % de sus PV máximos |
| II | **Muralla de Escarcha** | 18 | Los aliados en pie | Barrera del 20 % |
| III | **Invierno Guardián** | 32 | Los aliados en pie | Barrera del 30 %; quien la rompa queda **Congelado**, el estado que ya pone Frostfang |

- **Cómo se verá:**
  - **I:** esquirlas de hielo salen del sable hacia el aliado. Se forma una coraza hexagonal translúcida, de alfa
    0,35 con borde (dibujada en 2D), que brilla despacio mientras dura. Al absorber, «❄ −N» en blanco azulado; al
    romperse, estalla en esquirlas.
  - **II:** cristales de hielo brotan del suelo delante del grupo (0,4 s) y cada aliado recibe su coraza.
  - **III:** un copo grande en el suelo bajo el grupo y nieve que cae. Al romperse una coraza, una ráfaga de escarcha
    alcanza al atacante y lo congela con el `_congelar` de siempre.
  - Escena `vfx/EscarchaVFX.tscn`: el círculo con tinte de hielo.
- **Sonido:** `arte_escarcha` (cristalización que cruje, 0,8 s), `barrera_absorbe` (tintineo corto: como mucho 2 a
  la vez, cada 0,05 s) y `barrera_rota` (cristal que estalla).
- **Juego:** Coraza sobre Garon en guardia es casi un muro; Muralla antes del golpe devastador de un jefe; Invierno
  Guardián castiga a quien ataca.

### 3.4 Familia Lumbre (Lya): la resistencia

- **Lore:** [biblia P, §3.6] «Lo que se recuerda, brilla»: la magia toma prestada esa luz. Si Cura le recuerda al
  cuerpo su forma, la Lumbre le recuerda al caído que sigue aquí.
- **Nombres:** los tres son del usuario.
- **Color:** luz de farol, `FFE3A3`. **Icono:** llama dentro de un farol.
- **Aprendizaje (Lya):** I en el nivel 4; II en el 10 o con libro (450); III en el 18 o con el **Tomo de la
  Lumbre** (Valle de los Ecos, junto al agua más quieta).

| Nivel | Nombre | PM | Objetivo | Efecto |
|---|---|---|---|---|
| I | **Lumbre de Retorno** | 14 | Un aliado caído | Vuelve con el 25 % de sus PV y la barra ATB vacía |
| II | **Segundo Aliento** | 16 | Los aliados en pie | **Aliento** 3 turnos: al empezar cada uno de sus turnos recupera el 8 % de sus PV |
| III | **Última Brasa** | 34 | Los aliados en pie | **Brasa**: si cae en este combate, se levanta una vez con el 30 % |

- **Cómo se verá:**
  - **I:** una luz cálida baja como un farol sobre el caído; las brasas suben, el héroe se levanta (`revivir()` en
    3D) y sale el pilar de luz con tinte de farol (`vfx/LumbreVFX.tscn`).
  - **II:** un soplo verde dorado gira alrededor de cada aliado (partículas en órbita, como la espiral del Agua).
    Mientras dura, alguna mota sube de vez en cuando.
  - **III:** una brasa pequeña queda a los pies de cada aliado. Si cae, sube una columna de brasas y «¡Última Brasa!»
    en vez de la animación de muerte.
- **Sonido:** `arte_lumbre` (subida cálida con una campana suave), `renacer` (soplo que se levanta), `aliento` (muy
  suave, prioridad baja; como mucho uno a la vez) y `brasa` (chisporroteo y campana).
- **Juego:** el grupo deja de depender de huir o de perder cuando cae alguien; Lya pasa a ser la primera a proteger
  (los enemigos «agresivos» ya van a por quien cura).

### 3.5 Estados nuevos de los héroes

| Estado | De dónde sale | Reglas | Se ve |
|---|---|---|---|
| **Barrera** (`barrera`: PV que absorbe; `barrera_escarcha` en el III) | Escarcha I-III; accesorio «Lágrima de ámbar» | Absorbe cualquier daño, también el golpe devastador y la magia de los enemigos nuevos. Defender y la defensa reducen antes y la barrera absorbe lo que queda. **No se suma:** se queda la mayor. Dura hasta romperse o acabar el combate | Coraza translúcida; icono de cristal junto al nombre; «❄ −N» |
| **Aliento** (`aliento`: turnos; `regen`: fracción) | Lumbre II; «Rama del Árbol Milenario» | Cura al empezar el turno del héroe, antes de abrir su menú. Volver a lanzarlo lo renueva a 3 turnos: no suma | Motas verdes; icono de hoja; «+N» |
| **Brasa** (`brasa`: sí o no) | Lumbre III; accesorio «Brasa en frasco» | Al llegar a 0 PV, en ese mismo instante vuelve al 30 %. Se gasta. Si todo el grupo cae a la vez y alguien tiene Brasa, el combate no se pierde | Brasa a los pies; icono de llama |

- **Al acabar el combate** desaparecen. **No se guardan;** los PV que queden, sí, como hoy.
- **Los ausentes** no reciben nada: no están en `heroes`.
- **Iconos de estado en el grupo:** en el bloque de abajo del menú, entre el nombre y los PV (x ≈ 935-995), de 18 px,
  dibujados por código como los de las magias. No dependen de que la fuente tenga el carácter.

### 3.6 Menú de magia: una pestaña por familia nueva

- Las pestañas **«I · II · III» siguen igual**, con las cuatro familias de siempre.
- Detrás va **una pestaña con icono por cada familia nueva** que conozca el héroe, de 64 px:
  - Kael: Alba y Escarcha;
  - Lya: Lumbre.
- **Geometría:** I, II y III están en x = 808, 908 y 1008 (96 px); las de familia, en 1108 y 1176 (64 px) y acaban en
  1240, el borde del menú. Por eso **cada héroe conoce como mucho dos familias nuevas**.
- **Contenido:** cada pestaña de familia lista los niveles que sabe (3 filas como mucho; nunca se sale). A la derecha,
  el nivel y el coste: «I · 6 PM».
- **Si hoy no hay pestañas** (las clásicas solo en el nivel I): al conocer una familia salen «I · ☀», porque ya son dos.
- **Con teclado y mando,** L1 / R1 (Q / E) recorren todas las pestañas (`menu_combate.gd:633-638` ya admite cualquier
  número), ↑ ↓ eligen, Intro / A lanzan y Esc / B vuelven. **Con el dedo,** se toca el icono.
- **`magia_nivel_menu`** guarda 1-3 para los niveles y 4-5 para las familias, en orden.
- **Filas apagadas** con su motivo en la descripción: «Necesita a otro aliado en pie» (Compás con Kael solo), «Nadie
  ha caído» (Lumbre de Retorno), «Ya esperan su turno» (Compás y Hora Dorada).
- **Descripciones** (dos líneas como mucho):
  - Compás: «Un aliado gana media barra: actuará antes.»
  - Ocaso: «Los enemigos pierden casi media barra. Los jefes, la mitad.»
  - Hora Dorada: «Llena la barra de los aliados: actúan en cuanto acabes.»
  - Coraza: «Una coraza de hielo absorbe golpes (30 % de sus PV).»
  - Muralla: «Hielo para todo el grupo: absorbe el 20 % de los PV de cada uno.»
  - Invierno: «Corazas de hielo para todos; quien las rompa, se congela.»
  - Retorno: «Devuelve al combate a un aliado caído con un cuarto de su vida.»
  - Aliento: «Tres turnos: cada aliado recupera vida al empezar su turno.»
  - Brasa: «Si un aliado cae, se levanta una vez con algo de vida.»

### 3.7 Implementación sin tocar las existentes

**Datos** (`combate.gd`): entradas nuevas **al final** de `MAGIAS` y `NIVELES_MAGIA`. Las doce no se tocan.

```gdscript
# MAGIAS (al final)
"Alba": {"coste": 6, "dano": 0, "color": Color("F2B5A0"), "tipo": "ritmo"},
"Escarcha": {"coste": 7, "dano": 0, "color": Color("BFE6FF"), "tipo": "barrera"},
"Lumbre": {"coste": 14, "dano": 0, "color": Color("FFE3A3"), "tipo": "lumbre"},
# NIVELES_MAGIA (al final). "todos": a todo el grupo (o a todos los enemigos en Peso del Ocaso)
"Alba": [{"nombre": "Compás del Alba", "coste": 6, "dano": 0, "todos": false, "atb": 50.0},
	{"nombre": "Peso del Ocaso", "coste": 15, "dano": 0, "todos": true, "atb_enemigos": -40.0},
	{"nombre": "Hora Dorada", "coste": 30, "dano": 0, "todos": true, "atb_lleno": true}],
"Escarcha": [{"nombre": "Coraza de Escarcha", "coste": 7, "dano": 0, "todos": false, "barrera": 0.30},
	{"nombre": "Muralla de Escarcha", "coste": 18, "dano": 0, "todos": true, "barrera": 0.20},
	{"nombre": "Invierno Guardián", "coste": 32, "dano": 0, "todos": true, "barrera": 0.30, "congela": true}],
"Lumbre": [{"nombre": "Lumbre de Retorno", "coste": 14, "dano": 0, "todos": false, "revive": 0.25},
	{"nombre": "Segundo Aliento", "coste": 16, "dano": 0, "todos": true, "aliento": 3, "regen": 0.08},
	{"nombre": "Última Brasa", "coste": 34, "dano": 0, "todos": true, "brasa": 0.30}],
```

**Desvío** (una línea al principio de `_elegir_hechizo`, `:1780`):

```gdscript
if MAGIAS[magia].has("tipo"):          # familias nuevas: ruta propia (las 12 de siempre siguen igual)
	_elegir_arte(magia, nivel, sola)
	return
```

**Funciones nuevas** (no cambian nada de lo existente):
- `_objetivos_arte(magia, d)` decide los objetivos:
  - Compás: aliados en pie, menos el actor y los que ya esperan turno;
  - Ocaso: enemigos en pie;
  - Lumbre I: héroes con 0 PV;
  - los demás: aliados en pie.
  - El menú apaga la fila si la lista sale vacía.
- `_elegir_arte`: pide el objetivo con `_pedir_objetivo` o lo aplica a todos; con `sola` (pruebas: `-- magia=Alba:1`),
  al primero de la lista.
- `_lanzar_arte(objs)`: oculta el menú, gasta los PM, anima, aplica el efecto según el tipo, suena **una vez** y
  llama a `_terminar_turno()`.
- `_sumar_atb(f, v)`: **cuidado con la cola.** Si se pone el ATB a 100 a mano, `_process` ya no lo mete en la cola y
  el héroe se quedaría sin turno. Por eso:

```gdscript
func _sumar_atb(f: Dictionary, v: float) -> void:
	if v > 0.0:
		if f in cola or f["atb"] >= ATB_MAX:     # ya espera su turno: nada (si no, tendría dos)
			return
		f["atb"] = minf(ATB_MAX - 0.1, f["atb"] + v)   # _process lo mete en la cola al llegar a 100
	else:
		cola.erase(f)                            # pierde el turno que esperaba
		f["atb"] = maxf(0.0, minf(f["atb"], ATB_MAX) + v)
```

- `_revivir(f, frac)`:
  - pone los PV;
  - pone `atb = 0` y saca al héroe de la cola: si murió con la barra llena, se quedaría sin volver a la cola;
  - llama a `revivir()` en 3D; en 2D deshace el giro de 25° y el desplazamiento de `_restablecer_color` (`:3640-3644`);
  - termina con `_restablecer_color(f)`.
- `_tic_estados_heroe(f)`, sin `await`: en `_siguiente_turno`, rama del héroe (`:1184`), antes de `_mostrar_menu()`.
  Cura el Aliento y la regeneración del equipo.

**Ganchos en código existente** (sin la barrera ni la Brasa, el resultado es idéntico):
- `_quitar_pv` (`:2059`):
  - en un héroe con barrera, absorbe antes de restar; con Brasa, lo levanta en vez de dejarlo a 0;
  - **devuelve el daño real** (quien no lo use, no cambia);
  - en el III, el atacante que rompe la barrera queda Congelado. Para saber quién es, `_animar_golpe` apunta
    `objetivo["golpeado_por"] = origen` antes del impacto.
- El impacto de `_animar_golpe` (`:2470-2477`) usa ese daño real para el número que flota. Sin barrera, es el mismo.
- El golpe devastador de los jefes (`:1285-1287`) pasa a usar `_quitar_pv`; en los héroes hace lo mismo que hoy.
- `_menu_magia` (`:1737`): separa los hechizos con `"tipo"` en las pestañas de familia.
- `_desc_magia` (`:1765`): ramas nuevas en su `match`.
- `_repartir_exp` (`:3774`): el aviso «aprende…» usa el umbral de la familia.

**Otros archivos:**
- `menu_combate.gd`:
  - la pestaña acepta `"icono"` y un ancho propio;
  - `_dibujar_icono` gana Alba, Escarcha y Lumbre;
  - `COLOR_ELEMENTO` gana sus colores;
  - iconos de estado en el bloque del grupo.
- `grupo.gd`:
  - `HEROES["Kael"]["magias"]` y `HEROES["Lya"]["magias"]` añaden sus familias **al final**;
  - `NIVEL_MAGIA_FAMILIA := {"Alba": [3, 9, 16], "Escarcha": [6, 12, 20], "Lumbre": [4, 10, 18]}`;
  - `umbral_magia(magia, i)`, que para las de siempre devuelve `NIVEL_MAGIA[i]`;
  - `nivel_magia` usa ese umbral.
- `menus.gd`: «Habilidades» (`:338`) usa `Grupo.umbral_magia(m, i)`: mismo texto para las de siempre.
- `tienda.gd`: libros al final de `LIBROS`: `["Alba", 2, 350]`, `["Escarcha", 2, 400]` y `["Lumbre", 2, 450]`.
- `diario.gd`: fichas nuevas («Barrera», «Aliento», «Brasa», «Ritmo»).
- `carga.gd` y `_precalentar_efectos` (`:3057`): las tres escenas nuevas de `vfx/`.

### 3.8 Propuestas aparte (no entran sin aprobación)

**P1 · «Guardia a tiempo»: una ventana de reacción del jugador.**
- **Qué es.** Cuando un enemigo va a dar un golpe físico a un héroe, un anillo dorado se cierra sobre ese héroe:
  - si el jugador toca la pantalla, pulsa Intro o A en los **últimos 0,4 s** antes del impacto (más 0,08 s de
    margen), el golpe le quita un 40 % menos y sale «¡A tiempo!»;
  - si pulsa antes de que aparezca el anillo, no sirve, para que no se pueda pulsar sin mirar.
- **Encaje con el ATB, sin tocar lo protegido.** Los enemigos actúan desde «esperando», sin ningún menú abierto
  (`:1178-1192`), así que la pulsación no choca con los menús. El ATB no se pausa ni se toca. No da Armonía ni toca
  magias, Érebo ni fórmulas base: es un multiplicador nuevo que solo existe si se acierta. **Sin pulsar, todo da lo
  mismo que hoy** (las pruebas automáticas no pulsan).
- **Saber el impacto con antelación.**
  - Ya se sabe en el goblin 3D: 0,78 s (doble tajo) y 1,55 s (golpe fuerte) desde que empieza el ataque
    (`goblin_3d.gd`, `GOLPES_ATACAR` y `GOLPE_FUERTE`).
  - En los enemigos de imagen, tras 0,6 + 0,25 + 0,1 s (`_anim_fisico_imagen`, `:1003-1030`).
  - Para el resto, una señal «antes del golpe» en cada animación.
- **Móvil:** la latencia del toque obliga a una ventana generosa. Hay que probarla en el Redmi antes de fijarla.
- **Opción en Ajustes:** «Reacción en combate: sí / no», en `ajustes.cfg`, aparte de la partida.
- **Encaja con los principios de D-072** («ritmo táctico con respuesta del jugador»), pero cambia la sensación del
  combate: [decidir].

**P2 · Familia «Eclipse», ofensiva y de sinergia (para más adelante).**
- **Parte de ideas del usuario:**
  - «Marca del Eclipse»: premia coordinar al grupo;
  - «Caída del Firmamento»: pulsos escalonados, con contrajuego;
  - «Cénit Quebrado»: gran descarga de área, con preparación visible;
  - «Quiebrasello»: abre una defensa.
- **Esbozo:**
  - **I, Marca del Eclipse:** el siguiente golpe de **otro** héroe al marcado le hace +60 % y gasta la marca.
  - **II, Caída del Firmamento:** tres pulsos sobre todos: ahora, tras la siguiente acción de un aliado y tras la
    otra.
  - **III, Cénit Quebrado:** se carga un turno, a la vista de todos. Si al lanzador le golpean mientras carga, pierde
    la mitad.
- **Por qué después:** multiplica el daño de otros, también el de las magias protegidas, y depende de la decisión
  sobre las debilidades (§5.1).
- **«Quiebrasello»** se deja sin usar: el Sello es la pieza central de la historia y un hechizo corriente con ese
  nombre le quitaría peso [decidir].

**P3 · Bestiario (pequeño).** Una clave nueva, `bestiario`, al final de `CLAVES` (`progreso.gd:60`), con las
debilidades ya descubiertas, y una pestaña en el Diario. Así una debilidad que se descubre no hay que recordarla.

---

## 4. Equipo: accesorios y armas especiales

### 4.1 Lo que ya existe y cómo se amplía

- **Ranuras.** `RANURAS` gana **«accesorio» al final** (`inventario.gd:7`); `NOMBRES_RANURA`, «Accesorio».
  - Anillo y Amuleto siguen siendo de atributos; el Accesorio es solo para efectos especiales, sin atributos.
  - [decidir] el nombre: «Accesorio», que es lo que pidió el usuario, o «Reliquia», más de este mundo.
- **Accesorios:** diccionario nuevo `ACCESORIOS` con `"ranura": "accesorio"`, `"para": "todos"`, `"efectos"`,
  `"efecto"` (texto corto del menú) y `"texto"` (lore).
- **Armas especiales:** van en `ARMAS`, con `"solo": "<héroe>"`, `"efectos"`, `"efecto"` y un aspecto (§4.4).
- **«solo».** `puede_llevar` lo respeta. Hoy Kael puede quitarle a Garon sus Hojas Infernales, porque las dos son
  «espada» (`inventario.gd:128-133`). Con «solo», las especiales de Garon no.
- **Los efectos no cambian las estadísticas.** `grupo.estadisticas()` solo lee `ataque`, `magia` y `bonus`. La
  excepción es «ataque_recuerdo» (§4.4).
- **Sin un objeto nuevo equipado, todo da lo mismo que hoy.** El equipo inicial (`INICIAL`) no cambia.

### 4.2 Catálogo de efectos (cada uno con su único gancho)

Se suman con `Inventario.efectos_de(heroe)`: los números se suman y los «sí o no» se combinan con «o». `combate.gd`
lo guarda en `h["efectos"]` en `_ready`. **Ningún gancho tira un dado de más si el efecto vale 0:** la misma semilla
da el mismo combate (prueba de huella, §6).

| Clave | Valor | Qué hace | Dónde se aplica |
|---|---|---|---|
| `atb_inicio` | 0-60 | ATB inicial del portador | `_ready`, tras crear a los héroes (sin pasar de 99,9) |
| `critico` | +probabilidad | Crítico en sus golpes físicos | `_animar_golpe` (`:2459`): la misma tirada, otro umbral |
| `esquiva` | probabilidad | Esquiva golpes físicos («¡Esquiva!», 0 de daño) | `_animar_golpe`; solo tira si es mayor que 0 |
| `oro_pct` | % | Más monedas al ganar (una sola vez, aunque lo lleven varios) | `_repartir_exp` |
| `pm_turno` | PM | Recupera PM al terminar cada turno suyo | `_terminar_turno` |
| `regen` | fracción | Recupera PV al empezar cada turno suyo | `_tic_estados_heroe` |
| `barrera_inicio` | fracción | Empieza con Barrera | `_ready` (necesita M3) |
| `brasa` | sí | Empieza con Brasa | `_ready` (necesita M4) |
| `robo_vida` | fracción | Se cura parte del daño físico que hace | Impacto de `_animar_golpe` |
| `ataque_recuerdo` | tope | +1 de ataque por cada detalle de lore visto (`lore_visto`), hasta el tope | `grupo.estadisticas()`; se ve en el menú |
| `contra_defendiendo` | ×ataque | Si le golpean mientras defiende, devuelve el golpe | `_turno_enemigo`, tras el golpe |
| `cubrir` | umbral de PV | Recibe él el golpe dirigido a un aliado por debajo del umbral | `_turno_enemigo`, al elegir objetivo |
| `aliento_inicio` | turnos | Aliento al aliado con menos PV al empezar | `_ready` (necesita M2) |
| `apoyo_turnos` | +turnos | El Aliento que lanza dura más | `_lanzar_arte` (Lumbre II) |

### 4.3 Los 8 accesorios

| id | Nombre | Efecto | Texto del menú | Lore | Dónde | Incr. |
|---|---|---|---|---|---|---|
| `farol_peregrino` | Farol de peregrino | `atb_inicio` 35 | «Empieza con un tercio de barra.» | «Latón abollado y cristal ahumado. Los peregrinos lo llevaban encendido a pleno día.» | Tienda de Oakhaven, 220 | C1 |
| `diente_grimfang` | Diente de Grimfang | `critico` 0,08 | «+8 % de golpe crítico.» | «Los Grimfang se pasan sus dientes de padre a hijo. Este se perdió en una pelea.» | Botín del Grimfang embestidor (5 %, una vez) y cofre del campamento del Gran Bosque Verde | C1 |
| `moneda_aguila` | Moneda del Águila | `oro_pct` 25 | «+25 % de monedas al ganar.» | «Plata con un águila acuñada. La Compañía cobraba en estas.» | Tienda de Sunken City, 450 | C1 |
| `gota_cascada` | Gota de la cascada alta | `pm_turno` 2 | «+2 PM al acabar cada turno.» | «Agua de las cascadas que sostienen la isla, quieta dentro de un cristal.» | Arboleda Mítica, en la orilla (secreto) | C1 |
| `cinta_lumi` | Cinta de Lumi | `regen` 0,05 | «Recupera un 5 % de PV cada turno.» | «Lumi la tejió para alguien de abajo. Huele a las flores de la isla.» | Regalo de Lumi en la Arboleda Mítica | C1 |
| `pluma_arpia` | Pluma de arpía | `esquiva` 0,12 | «12 % de esquivar golpes.» | «Blanca, ligera y fría. Vex pagaría bien por ella.» | Botín de la Arpía de las cumbres; mientras no exista, cofre de las ruinas de Ciclópea | C1 |
| `lagrima_ambar` | Lágrima de ámbar | `barrera_inicio` 0,15 | «Empieza con una coraza (15 % de PV).» | «Ámbar tibio del gólem del nido. Dentro hay un insecto que nadie ha visto vivo.» | Primera victoria en el nido de la Garganta (Gólem de ámbar) | M3 |
| `brasa_frasco` | Brasa en frasco | `brasa` | «Si cae, se levanta una vez.» | «Una brasa que no se apaga, en un frasco tapado con cera.» | Cofre del Abismo de Ceniza; mientras no se llegue, el Valle de los Ecos | M4 |

- **Lore:** Lumi, Vex, la Arboleda y la Compañía del Águila son canon [biblia C]. Los faroles de los peregrinos son
  [biblia P].
- **D-033:** ningún accesorio toca a Érebo, la Armonía ni los corazones.
- **Botín:** solo lo dan enemigos nuevos. Así los combates de Grimfang, slime y guardián no tiran un dado de más.

### 4.4 Las 6 armas especiales (dos por héroe)

**Aspecto:** se reutilizan las mallas que ya existen, con otro tinte y otro color de brillo. Para eso,
`material_arma.gd` necesita dos parámetros nuevos con valor por defecto: `tinte` (blanco) y `color_brillo` (blanco).
Con ellos, las armas de hoy se ven igual (§8). Un modelo propio para cada una puede llegar después.

| id | Nombre | Quién | Ataque / magia | Efecto | Malla y aspecto | Lore | Dónde | Incr. |
|---|---|---|---|---|---|---|---|---|
| `hoja_sin_nombre` | Hoja sin Nombre | Solo Kael | Ataque 8 | `ataque_recuerdo` 12: +1 por detalle de lore visto, hasta +12 | `espada2.obj` en dorado pálido, con un brillo que crece con los recuerdos | «Alguien raspó el nombre de la hoja. Brilla más cuanto más recuerda quien la empuña.» | Gran Bosque Verde, junto a la «Armadura del árbol» [biblia C], al examinarla | C2 |
| `guardiana_ambar` | Guardiana de Ámbar | Solo Kael | Ataque 12 | `contra_defendiendo` 0,6 | `diamante_azul.obj` en ámbar | «Ámbar de los centinelas del camino. Lo que golpea a quien la sostiene en guardia, vuelve.» | Cumbres de Ciclópea, cerca de la «Estatua sin brazo» | C2 |
| `baculo_peregrino` | Báculo del Peregrino | Solo Lya | Ataque 2, magia +10 | `apoyo_turnos` 1 | `vara.obj` en madera clara | «Madera de la Vía, pulida por miles de manos que se apoyaron en él para no detenerse.» | Garganta del Diablo, junto al «Pilar del peregrino» [biblia C] | C2 (efecto con M2) |
| `rama_milenaria` | Rama del Árbol Milenario | Solo Lya | Ataque 2, magia +12 | `aliento_inicio` 2 | `vara.obj` en verde, con brillo de savia | «No se seca aunque pasen los inviernos.» | Oakhaven, al pie del Árbol Milenario [biblia C]; lugar de T-089/T-090 | C2 (con M2) |
| `fauces_gorthor` | Fauces de Gorthor | Solo Garon (dos) | Ataque 30 | `robo_vida` 0,15 | `hoja_infernal.obj` en hueso, con brillo rojo | «Forjadas con los colmillos del jefe de los Grimfang. Muerden.» | Al vencer a Gorthor, se le perdone o no [decidir] | C2 |
| `gemelas_muralla` | Gemelas de la Muralla | Solo Garon (dos) | Ataque 28 | `cubrir` 0,30 | `espada2.obj` en bronce | «Dos espadas cortas de la Guardia de la Muralla, melladas de no retroceder.» | Oakhaven, Taberna del Cuervo Oxidado (secreto; T-089) | C2 |

- **Comparación con lo que hay:** Frostfang (0), Colmillo Nocturno (6), Averno (14), Diamante Azul (20) y Hojas
  Infernales (34).
- **Las especiales cambian ataque por efecto:** las de Garon quitan algo menos que sus Hojas y aportan algo propio. La
  Hoja sin Nombre llega a 20 si el jugador explora.
- **«Guardia de la Muralla»** es [biblia P] (el pasado de Garon): aquí solo da sabor; no se cuenta nada de su
  historia.

### 4.5 Dónde se consigue cada cosa y cómo

- **Tiendas.** `EQUIPO` de `tienda.gd` es la misma lista para Oakhaven y Sunken City. Se propone
  `EQUIPO_POR_LUGAR := {0: [...], 5: [...]}`, que se suma a la lista común según el índice del lugar.
- **Cofres y secretos.** Un archivo nuevo, `recompensas.gd` (datos estáticos; lo llevaría combate), con cada
  recompensa especial (tomos, armas y accesorios) y `Recompensas.dar(id) -> String`, que devuelve el aviso.
  - **Dónde se pone cada cofre** lo decide el código del mundo: `zona.gd`, `garganta.gd`, `isla.gd`, `zonas3d/`, con
    T-089 y T-090. Ese código solo llama a `dar(id)`.
  - **Nada nuevo en la partida:** las armas y los accesorios se ven en `equipables`, los tomos en `libros` y los cofres
    en `cofres_abiertos`.
- **Jefes y combates fijos.** En `_fin_combate`, según `combate_fijo`:
  - «garganta_gorthor» da las Fauces de Gorthor;
  - «garganta_nido» da la Lágrima de ámbar.
  - Se gana una sola vez, porque ya se apunta en `combates_ganados`.
- **Botín de enemigos.** `"botin": [[id, prob]]` en los enemigos nuevos. Se tira en `_repartir_exp`, solo si se gana y
  si no se tiene ya.

### 4.6 Menú para equipar (teclado, mando y táctil)

- **Grupo.** La ranura nueva sale sola como **octava fila**, porque `menus.gd` recorre `Inv.RANURAS`. Sus ◀ ▶ llevan
  las claves `ranura:accesorio:-1` y `ranura:accesorio:1`, así que el foco con teclado y mando y su vuelta tras
  repintar ya funcionan (D-063); con el dedo, igual. «Sin accesorio» es una opción, como en las ranuras que no son
  arma.
- **Efecto.** Bajo la fila, la línea de resumen (`Inv.resumen`) añade el texto corto del efecto.
- **Mejora propuesta:** una línea de «detalle» al pie de la columna con el lore del objeto elegido cuando el foco está
  en sus ◀ ▶.
- **Espacio:** con 8 filas, la columna pasa un poco de los 520 px del marco; el `ScrollContainer` sigue al foco
  (`follow_focus`) y con el dedo se arrastra.
- **Tienda y Objetos.** Las filas nuevas usan el mismo `resumen`. Los textos de efecto tienen **32 caracteres como
  mucho**, porque la columna de la tienda mide 300 px y no parte las líneas.
- **Tolerancia a ids desconocidos.** Hoy un id que no existe rompe `menus.gd:283` y `inventario.gd:162` (`o["ranura"]`
  sobre `{}`). Se cambia a `.get("ranura", "")`: con los ids conocidos, mismo resultado.

### 4.7 Guardado compatible

- **No hace falta ninguna clave nueva:** la ranura vive dentro de `inventario.equipo[héroe]`; si falta, no se lleva
  nada.
- **Los ids nuevos** solo entran en `equipables` al conseguirlos. Una partida antigua carga igual y empieza sin nada
  nuevo equipado.
- **Lo que no se soporta:** abrir una partida nueva con una versión anterior. Sus menús de equipo fallarían con un id
  que no conocen.
  - En Android no pasa: no se puede instalar una versión anterior sin desinstalar, y desinstalar borra los datos.
  - En el PC, las pruebas usan datos aislados y la partida estable es otro archivo (`partida.save`).
  - [decidir] si basta con documentarlo.

---

## 5. Enemigos nuevos

### 5.1 Mecánicas comunes (todas opcionales: sin el campo, el enemigo hace lo de hoy)

- **Variantes sin modelos nuevos.** `ENEMIGOS` admite `tinte` y `escala`, que mandan sobre los de `MODELOS`.
  - Así un enemigo nuevo reutiliza «grimfang», «guardian», «hollin» o «slime» **sin entradas nuevas en `MODELOS` ni en
    `ANIM`**. Cada clave de `MODELOS` necesita la suya en `ANIM`: `_process` la lee en cada fotograma (`:1152`), y si
    falta, falla.
  - `_crear_rig_sprite` aún no aplica el tinte (el 3D y la imagen sí, `:907`, `:977`): hay que añadirlo.
  - Un 3D con otra escala puede necesitar `pies_como` para no flotar ni hundirse, como Gorthor (`:169`, `:695-699`).
- **Auras.** `"aura": "humo" | "esporas" | "escarcha" | "vapor" | "brasas"` crea un emisor continuo pequeño: como
  mucho 12 partículas, ×0,4 en el móvil (`CALIDAD_MOVIL`).
- **Afinidades legibles.** `"debil": {"Fuego": 1.5}`, `"resiste": {"Agua": 0.5}` y `"absorbe": ["Agua"]`.
  - Se aplican a la magia (por familia), al elemento de Embuir y a «Físico».
  - Al acertar sale «¡Débil!» en dorado, «Resiste» en gris o el número de curación en verde, y la debilidad queda en su
    etiqueta durante el combate («Débil: Fuego»).
  - **Esto toca, con una línea en cada sitio, el camino de daño de las magias protegidas:** al principio de
    `_animar_golpe` y en `impacto_en` de `_magia_grupal`. El daño de cada magia no cambia: cambia cuánto le hace a un
    enemigo nuevo. **Ningún enemigo de hoy tiene afinidades:** con ellos, el mismo número. [decidir]
- **Rasgos.** `"rasgo"`: un patrón propio que se anuncia un turno antes. Se procesa al principio de `_turno_enemigo`,
  solo si existe.
- **Etiqueta de estado.** Pasa de 18 px a 24 px: en el Redmi, 18 px son unos 10 dp.
- **Ataques mágicos de enemigos.** Van por una función propia, `_ataque_elemental`, con `_proyectil` y los efectos de
  `_efecto_fuego`, `_efecto_agua` y `_efecto_rayo`, que solo dibujan.
  - No usan `_golpe_visual`: su rama «Fuego» encendería una quemadura en el héroe que nadie apagaría (los héroes no la
    procesan).
  - La defensa física no los reduce; Defender y la barrera, sí.
- **Encuentros por región, solo con el grupo de tres.**
  - Lo decide `AL_AZAR_POR_REGION`; con uno o dos héroes y en las regiones sin tabla (`llanura`, Pastos Verdes),
    todo sigue como hoy.
  - Tira el dado **una vez**, como hoy.
  - Como mucho **dos enemigos 3D por grupo**: cada uno es una ventana 3D más en el Mali-G57.
- **Nivel de región.** `_region()` devuelve la zona de siempre, salvo el Templo Sumergido: usa el estilo «llanura»
  (`mapa.gd:37`) y se reconoce por el lugar 7.
  - Con ella se llaman `zona_limpia` y `mult_exp`; en todas las demás zonas, igual que hoy.
  - `progreso.gd` gana `NIVEL_ZONA["templo"] = 18`. Sin ese cambio, en el Templo los enemigos huirían casi siempre,
    porque se trata como una zona de nivel 2.
- **Escala por región.** Un enemigo con `"nivel"` por debajo del de la región se multiplica (PV, ataque, experiencia y
  monedas) por `1 + 0,12 × (región − nivel)`.
  - Así el Hollín errante sirve también en la nieve o el yermo.
  - Los enemigos de hoy no tienen `"nivel"`: no se escalan.

### 5.2 Resumen (★ = se puede hacer ya con lo que hay)

| id | Nombre | Región (nivel) | Base visual | ★ | PV | Atq. | Vel. | Exp. | Oro | Patrón | Débil / resiste |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `hollin_errante` | Hollín errante | Bosque (4); Garganta y montaña (7) | Tiras del Hollín, tinte de hollín y humo | ★ | 120 | 14 | 12 | 24 | 14 | Bruto; «⚠ Hacha del Vacío» cada 3 turnos | Rayo ×1,5 / Fuego ×0,5 |
| `chaman_grimfang` | Chamán Grimfang | Bosque (4) | Goblin 3D, verde musgo, 0,55, esporas | ★ | 90 | 10 | 15 | 22 | 16 | «Apoyo» (ya existe): cura al más herido | Fuego ×1,5 |
| `embestidor_grimfang` | Grimfang embestidor | Montaña (7) | Goblin 3D, rojizo, 0,7, polvo | ★ | 170 | 19 | 11 | 40 | 26 | «⚠ Embestida», que se interrumpe | Rayo ×1,25 (e interrumpe) |
| `centinela_escarcha` | Centinela de escarcha | Nieve (15) | Guardián, azul hielo, escarcha | ★ | 380 | 32 | 8 | 90 | 60 | «Guardia ❄»: el fuego la rompe | Fuego ×1,5 / Agua ×0,5 |
| `arpia_cumbres` | Arpía de las cumbres | Nieve y montaña (14) | **Arte nuevo** | — | 210 | 26 | 30 | 70 | 40 | «En vuelo» | Rayo ×1,5 |
| `limo_arena` | Limo de arena | Desierto (10) | Limo, color arena (falta el tinte en el sprite) | ★ | 160 | 22 | 14 | 50 | 30 | «Enterrado» un turno sí y otro no | Agua ×1,5 (lo vuelve barro) |
| `automata_calid` | Autómata de Calid | Desierto (10) | Provisional: guardián en cobre y vapor | ★ (provisional) | 280 | 24 | 9 | 70 | 55 | «Calor ●●●», descarga y «Enfriándose» | Agua ×1,5 (enfría) / Fuego ×0,5 |
| `fuego_fatuo` | Fuego fatuo | Yermo, Valle de los Ecos (18) | Dibujado por código | ★ (código) | 150 | 30 (magia) | 24 | 80 | 30 | Cambia de elemento cada turno | Absorbe el suyo; ×2 el que lo vence; físico ×0,5 |
| `medusa_templo` | Medusa del templo | Templo Sumergido (18) | Dibujada por código | ★ (código) | 320 | 26 | 12 | 110 | 70 | «Pulso en 3 · 2 · 1»: quita PM | Rayo ×1,75 / absorbe Agua |
| `hollin_brasa` | Hollín de brasa | Ceniza (34) | Tiras del Hollín, ceniza y brasas | ★ | 1000 | 60 | 14 | 200 | 120 | «⚠ Arderá al caer» | Agua ×1,5 / Fuego ×0,25 |

- **Puntos de partida:** experiencia ≈ 6 × nivel de la región y monedas ≈ 4 × nivel, por enemigo. Se ajustan con
  `prueba_regiones` (§6).
- **Hoy no se llega** al Templo Sumergido ni al Abismo de Ceniza: son islas y la Astraea no existe (`mapa.gd:591`).
  Sus enemigos quedan listos y probados con `-- fondo=`, a la espera de un acceso (T-090).

### 5.3 Fichas

**Hollín errante ★** (Gran Bosque Verde y Garganta)
- **Aspecto:** el orco del hacha de los diálogos («Hollines… con hachas del Vacío» [biblia C]), ensombrecido: gris
  pizarra, bordes que humean y ojos apagados.
- **Base:** `enemigos/hollin_*.png` (guardia, andar, preparar, tajo, herida; `MODELOS["hollin"]`, `:188`), con tinte
  (0,42, 0,40, 0,48) y aura de humo.
- **Patrón:** bruto, golpea a cualquiera. Cada tres turnos, «⚠ Hacha del Vacío» (humo negro que sube); en el siguiente,
  un golpe ×2 a uno.
- **Debilidad:** Rayo ×1,5; resiste el Fuego (×0,5, porque el hollín ya ardió). El aviso pide Defender, Coraza o Peso
  del Ocaso.
- **Sonido:** gruñido grave y respiración con siseo de ceniza.
- **Lore:** [biblia P] lo que queda de alguien a quien borraron a la fuerza.

**Chamán Grimfang ★** (Gran Bosque Verde)
- **Aspecto:** un Grimfang más pequeño, verde musgo, rodeado de esporas.
- **Base:** goblin 3D (`goblin.fbx`, `goblin_3d.gd`), tinte (0,8, 1,0, 0,75) y escala 0,55.
  - En el arte definitivo, un bastón en lugar del hacha: variante con `usa_vara` (petición a animaciones, §8).
  - Si los chamanes acaban siendo Hollines, sirve el «orco chamán» de `para_meshy/` [decidir].
- **Patrón:** personalidad «apoyo», que ya existe (`:1235`): cura un 30 % al aliado más herido por debajo del 50 %; si
  no hay ninguno, ataca. Al curar, un halo verde.
- **Debilidad:** Fuego ×1,5. Lo que se lee: el aura verde dice «a este, primero».
- **Sonido:** voz de goblin que canturrea.

**Grimfang embestidor ★** (montaña; la Garganta, si se aprueba tras su prueba)
- **Aspecto:** un Grimfang más grande, rojizo, con la cabeza gacha y polvo en los pies.
- **Base:** goblin 3D, tinte (1,0, 0,78, 0,68) y escala 0,7; la embestida es su `golpe_fuerte`.
- **Patrón:** «⚠ Embestida» (pisotón, polvo y el cuerpo encendido en rojo). En su siguiente turno embiste ×2,2 al
  héroe con menos defensa.
  - **Se interrumpe** si antes recibe un daño de al menos el 25 % de sus PV o un Rayo: «¡Embestida rota!», se tambalea
    y pierde ese turno. Lo pierde él: ningún héroe queda aturdido (D-060).
  - Idea del usuario: «la embestida de Grimfang, que se puede interrumpir».
- **Debilidad:** Rayo ×1,25, que además interrumpe.
- **Botín:** Diente de Grimfang (5 %, una vez).
- **Sonido:** rugido corto y pisadas pesadas.

**Centinela de escarcha ★** (Cumbres de Ciclópea)
- **Aspecto:** el guardián de piedra bajo una costra de hielo azulado, con el ojo encendido en blanco frío.
- **Base:** `enemigos/guardian.png`, tinte (0,75, 0,90, 1,30) y escarcha que cae.
- **Patrón:**
  - Empieza con «Guardia ❄»: los golpes físicos le hacen la mitad.
  - Un golpe de Fuego (magia o Embuir) la rompe: «¡Guardia rota!». Se vuelve a formar a los tres turnos suyos.
  - Cada dos turnos, «Aliento helado» contra todos (×0,6).
- **Debilidad:** Fuego ×1,5, que además rompe la guardia; resiste el Agua (×0,5). Lo que se lee: hielo pide fuego.
- **Sonido:** roce de piedra y crujido de hielo; al romperse, cristal que estalla.
- **Lore:** [biblia P] los centinelas que tocó la niebla se volvieron hostiles; este se quedó helado mirando el pico.
  La idea del usuario «la guardia agrietada del Guardián».

**Arpía de las cumbres** (Ciclópea y montaña). **Necesita arte.**
- **Aspecto:** mujer pájaro de plumas blancas y grises, con alas grandes y garras.
- **Base:** no existe. Dos caminos:
  - una figura 2D por piezas (cuerpo, cabeza, dos alas y patas) con el sistema articulado de `combate.gd`, en el que
    las alas aprovechan el balanceo que ya tiene `brazo_a`; se dibuja en Blender 5.2 (instalado) o en 2D;
  - un modelo de Meshy, con la cuenta del usuario.
- **Patrón:** rápida (velocidad 30), va a por el héroe con menos PV. «En vuelo»: los golpes físicos le hacen la mitad,
  salvo los que saltan (el ataque de Kael y el Juicio de Garon).
- **Debilidad:** Rayo ×1,5. Lo que se lee: su sombra queda lejos de sus pies.
- **Botín:** Pluma de arpía.
- **Lore:** [biblia C] Vex compra plumas de arpía (`isla.gd:40`).

**Limo de arena ★** (Mar de Arena de Calid)
- **Aspecto:** el limo de siempre, del color de la arena, con granos que se le escurren.
- **Base:** el sprite del limo, con tinte (1,15, 0,95, 0,65).
- **Patrón:**
  - Un turno sí y otro no se entierra: «Enterrado»; solo se ve un montículo y los golpes físicos le hacen un cuarto.
  - Huye si se queda solo y herido, como el de siempre.
- **Debilidad:** Agua ×1,5, que lo vuelve «Barro» dos turnos (no puede enterrarse).
- **Sonido:** arena que se desliza y un borboteo seco.

**Autómata de Calid ★, provisional** (Mar de Arena de Calid)
- **Aspecto:** máquina de guerra enterrada, de bronce verdoso, con tubos en la espalda y un hueco con forma de
  brazalete en el brazo (guiño a la «Máquina enterrada» [biblia C]). Echa vapor.
- **Base provisional:** el guardián en cobre (1,25, 0,85, 0,60) con vapor.
  - **Definitiva: un modelo propio, prioridad 1 de arte.** Con tres enemigos hechos a partir del guardián, se parecen
    demasiado.
- **Patrón:** el «Calor» sube cada turno (●○○ → ●●○ → ●●●). Con ●●●, descarga vapor contra todos (×1,4) y queda
  «Enfriándose» un turno: recibe ×1,5.
- **Debilidad:** Agua ×1,5, que además le baja el Calor a cero («¡Vapor!»); resiste el Fuego (×0,5).
  - Riesgo y recompensa: enfriarlo antes, o dejarle llegar a ●●● para pegarle mientras se enfría.

**Fuego fatuo ★, por código** (Valle de los Ecos)
- **Aspecto:** una llama de luz sin cuerpo que flota sobre el agua quieta. Cambia de color (naranja, azul o
  amarillo) y lleva encima el icono de su elemento: no se distingue solo por el color.
- **Base:** figura nueva dibujada por código (`"tipo": "luz"`): núcleo y halo con `_brillo`, llama con `_particulas` y
  balanceo. Ataca con el `_proyectil` de su color, que ya existe.
- **Patrón:** cobarde. Cada turno cambia de elemento: Fuego → Agua → Rayo. Absorbe el suyo (se cura), y el que lo
  vence le hace ×2: Agua al de fuego, Rayo al de agua y Fuego al de rayo. Los golpes físicos, ×0,5.
- **Sonido:** chisporroteo suave y un silbido que sube.
- **Lore:** [biblia C] «Espejos de agua bajo un cielo estrellado».

**Medusa del templo ★, por código** (Templo Sumergido; hoy no se llega)
- **Aspecto:** una campana de luz turquesa con tentáculos que ondulan, como si el combate fuera bajo el agua.
- **Base:** por código (tipo «luz»): la campana es un brillo aplastado y los tentáculos, `Line2D` que ondulan. Su
  ataque físico es un latigazo corto.
- **Patrón:** «Pulso en 3 · 2 · 1»; al llegar a cero, quita 6 PM a cada héroe y vuelve a contar.
- **Debilidad:** Rayo ×1,75; absorbe el Agua.
- **Fondo:** usa el de llanura hasta tener uno de templo (petición a gráficos).
- **Lore:** [biblia P] El Mar recuerda todo lo que se hundió.

**Hollín de brasa ★** (Abismo de Ceniza; hoy no se llega)
- **Aspecto:** el Hollín con grietas de brasa por todo el cuerpo y chispas que suben.
- **Base:** tiras del Hollín, tinte (0,55, 0,45, 0,42) y aura de brasas.
- **Patrón:**
  - «⚠ Arderá al caer»: al morir estalla contra todos (×0,8 de su ataque), salvo si lo mata el Agua o el Hielo
    («Se apaga»).
  - Inmune a la quemadura: si el Fuego lo prende, la llama se apaga al empezar su turno y sale «Inmune». No hace falta
    tocar la rama del Fuego.
- **Debilidad:** Agua ×1,5; resiste el Fuego (×0,25).
- **Lore:** [biblia P] montañas de ceniza con letras quemadas.

### 5.4 Grupos por región (al final de `GRUPOS`, desde el 10; los índices 0-9 no cambian)

`GRUPO_CENTINELA` de Pastos Verdes es el 0 (`zonas3d/pastos_verdes_3d.gd:42`): por eso solo se añaden grupos al final.

| Grupo | Enemigos (posición como en los grupos de hoy) | Región |
|---|---|---|
| 10 | Hollín errante (230, 150) · Grimfang (410, 115) | Bosque |
| 11 | Chamán (250, 40) · Grimfang (60, 130) · Hollín errante (440, 130) | Bosque |
| 12 | Hollín errante (30, 90) · Hollín errante (410, 115) · Slime (215, 135) | Bosque |
| 13 | Embestidor (230, 150) · Grimfang (410, 115) | Montaña |
| 14 | Embestidor (230, 150) · Hollín errante (410, 115) | Montaña |
| 15 | Guardián (150, 120) · Embestidor (420, 125) | Montaña |
| 16 | Autómata (150, 120) · Limo de arena (420, 125) | Desierto |
| 17 | Limo de arena ×3 (250, 40 · 60, 130 · 440, 130) | Desierto |
| 18 | Autómata (150, 120) · Autómata (420, 125) | Desierto |
| 19 | Centinela de escarcha (250, 120) | Nieve |
| 20 | Centinela de escarcha (150, 120) · Hollín errante, escalado (420, 125) | Nieve |
| 21 | Arpía ×2 · Centinela de escarcha (E3) | Nieve |
| 22 | Fuego fatuo ×3 | Yermo |
| 23 | Fuego fatuo (250, 40) · Hollín errante, escalado (60, 130) · Hollín errante, escalado (440, 130) | Yermo |
| 24 | Medusa ×2 | Templo |
| 25 | Medusa (230, 150) · Fuego fatuo (410, 115) | Templo |
| 26 | Hollín de brasa ×2 | Ceniza |
| 27 | Hollín de brasa (250, 40) · Fuego fatuo, escalado ×2 | Ceniza |

```gdscript
const AL_AZAR_POR_REGION := {"bosque": [10, 11, 12, 1, 2], "montana": [13, 14, 15, 4], "desierto": [16, 17, 18],
	"nieve": [19, 20], "yermo": [22, 23], "templo": [24, 25], "ceniza": [26, 27]}   # «garganta»: [decidir]
```

- **Bosque y montaña mezclan grupos de hoy** (1, 2 y 4). Sus enemigos no tienen `"nivel"` y salen como siempre.
- **Garganta:** su tabla queda como hoy hasta revisar las capturas de `prueba_garganta`.

### 5.5 Arte: qué falta y en qué orden

1. **Autómata de Calid**, modelo propio: es el más repetido sobre el guardián.
2. **Arpía de las cumbres**: no hay nada en que basarla.
3. Variante del goblin **con bastón**, para el chamán: no hace falta modelo nuevo, solo código.
4. **Fondo de templo** en `fondo_combate.gd`.
5. Opcional: renders nuevos del Hollín y del guardián con otros materiales, en vez de tintes, para que las variantes
   tengan textura propia. Se puede hacer con el método con el que se sacaron las tiras del Hollín de su modelo 3D.

**Licencias** (D-050, `docs/recursos.md`):
- el goblin, el guardián y los modelos de Meshy siguen pendientes del plan de Meshy: las variantes heredan el aviso
  `NO_DISTRIBUIR`;
- antes de basar enemigos nuevos en ellos, hay que registrar la procedencia de los sprites del limo («Free RPG Sprites»
  de Segel2D, según `combate.gd:176`) y de `enemigos/hollin_*.png`: no están en `recursos.md` ni en
  `licencias_pendientes.txt`;
- lo que se dibuja por código es propio.

---

## 6. Orden de implementación, pruebas de aceptación y riesgos

**En todos los incrementos:**
- la batería completa (`ejecutar_pruebas.ps1`) sin pruebas FALLIDAS ni NO SEGURAS y con la partida real intacta;
- la **huella del combate** igual mientras no se use lo nuevo;
- capturas para lo visual (pruebas con ventana, que revisa una persona);
- nada de medir rendimiento con otro especialista trabajando.

| Incr. | Qué | Archivos | Pruebas de aceptación |
|---|---|---|---|
| **C0** | **Red de seguridad.** Argumento de prueba `-- semilla=N`, que cambia `randomize()` por `seed(N)` solo en pruebas, y huella del combate | `combate.gd` (2 líneas), `pruebas/prueba_combate_huella.gd` y `pruebas/referencias/huella_combate.txt` (nuevos), `lista_pruebas.txt`, `pruebas/LEEME.md` | Dos pasadas seguidas dan la misma huella (registro, PV y PM tras cada acción, exp y oro) en los grupos 0-9, con `auto`, `magia=Fuego:1`, `esgrima=Giro`, `embuir=Fuego` e `invocar` (determinismo comprobado). La referencia se saca en `dddbddb`. `prueba_equilibrio` con semilla da los mismos números |
| **M1** | Infraestructura de familias y **Compás del Alba** | `combate.gd`, `menu_combate.gd`, `grupo.gd`, `menus.gd` (Habilidades), `tienda.gd` (libro), `vfx/AlbaVFX.tscn`; catálogo de `sonido.gd` (§8) | `prueba_menu_magia` (Lya sigue con 4 filas en I; Kael con `nivel=3` ve «I · ☀»). `prueba_mando` y `prueba_teclado` (L1 / R1 llegan a la pestaña de familia; Esc / B vuelve). **`prueba_artes`** (nueva): +50 sin pasar de 99,9; no se lanza sobre uno mismo; apagada con Kael solo; el aliado entra **una sola vez** en la cola; PM gastados; Armonía +0,15. Huella igual; `prueba_equilibrio`, `prueba_ia`, `prueba_grupos_combate` y `prueba_incorporacion`, iguales |
| **M2** | **Lumbre de Retorno** y **Segundo Aliento**, estado Aliento e iconos de estado | `combate.gd`, `menu_combate.gd`, `grupo.gd`, `tienda.gd`, `vfx/LumbreVFX.tscn`, `diario.gd` (fichas) | `prueba_artes`: revive con el 25 % y la barra a 0, vuelve a actuar, el 3D se levanta y el 2D recupera la pose; apagada sin caídos; el Aliento cura en sus turnos y dura 3; no se guarda; en `prueba_grupos_combate`, los ausentes no reciben nada. `prueba_artes_fotos` (ventana): las capturas. Huella igual |
| **C1** | Ranura **Accesorio**, `efectos_de` y 6 accesorios (todos menos Lágrima y Brasa); `recompensas.gd`; tienda por lugar | `inventario.gd`, `combate.gd` (ganchos), `grupo.gd`, `menus.gd` (tolerancia y detalle), `tienda.gd`, `recompensas.gd` (nuevo) | **`prueba_equipo`** (nueva): equipar y quitar; `solo`; suma de efectos; ida y vuelta del guardado; partida antigua sin la ranura; id desconocido sin error. `prueba_foco` (nuevo paso: ◀ ▶ de la ranura nueva con teclado y foco que vuelve) y `prueba_mando` (lo mismo con mando). `prueba_partida` y `prueba_guardado`. **Sin accesorios, huella y `prueba_equilibrio` iguales** |
| **E1** | Mecánicas comunes (afinidades, rasgos, auras, escala, región y botín) y los enemigos ★ con modelos que ya existen: hollín errante, chamán, embestidor, centinela, limo de arena, autómata provisional y hollín de brasa | `combate.gd`, `progreso.gd` (`NIVEL_ZONA["templo"]`) | **`prueba_regiones`** (nueva): por región, a su nivel (`nivel=N`), los grupos se ganan solo atacando en un tiempo razonable (ni menos de 15 s ni más de 180 s), con tabla de resultados. Cada rasgo se dispara y se interrumpe cuando debe; afinidades y etiquetas. En `llanura` todo sale como hoy (`prueba_ia`, `prueba_grupos_combate`, `prueba_incorporacion`, `prueba_centinela`). **`prueba_regiones_fotos`** (ventana). **Medida** (`medir_combate`, nueva y manual): grupos 11 y 13, con dos enemigos 3D, frente al grupo 0 |
| **M3** | **Coraza** y **Muralla de Escarcha**, estado Barrera, `_quitar_pv` con el daño real; accesorio Lágrima de ámbar | `combate.gd`, `menu_combate.gd`, `grupo.gd`, `tienda.gd`, `vfx/EscarchaVFX.tscn`, `inventario.gd` | `prueba_artes`: absorbe golpes, golpe devastador y magia enemiga; no se suma; el número que flota es el real; se rompe y suena una vez. Huella igual (sin barrera, el daño real es el de siempre). `prueba_gorthor` (ventana): el golpe devastador con y sin barrera |
| **C2** | Las 6 armas especiales y sus efectos; Fauces y Lágrima en los combates fijos | `inventario.gd`, `combate.gd`, `grupo.gd` (`ataque_recuerdo`); `material_arma.gd` (§8) | `prueba_equipo`: cada efecto; `solo`; la Hoja sin Nombre sube con `lore_visto`; réplica y cobertura solo cuando toca. `prueba_gorthor`: la recompensa sale una vez. Capturas de cada arma en las tres manos. Huella igual sin ellas |
| **M4** | Niveles III (Hora Dorada, Invierno Guardián y Última Brasa), estado Brasa, accesorio Brasa en frasco y tomos | `combate.gd`, `recompensas.gd`, `grupo.gd` | `prueba_artes`: Hora Dorada sin turnos dobles; quien rompe el Invierno queda Congelado; la Brasa evita la derrota de todo el grupo y se gasta una vez; los tomos enseñan una sola vez |
| **E2** | Tipo de figura «luz»: fuego fatuo y medusa; `_ataque_elemental` | `combate.gd` | `prueba_regiones`: ciclo de colores, absorción, pulso de PM, sin quemaduras en los héroes. `prueba_regiones_fotos`. Medida en el móvil (perfil bajo) |
| **E3** | Arte nuevo: arpía, autómata definitivo y bastón del chamán | Según el arte (con el usuario o con Blender) | Capturas, procedencia en `docs/recursos.md` y medida |
| **P1, P2 y P3** | Solo si el usuario los aprueba | — | P1: pulsar a tiempo quita un 40 % menos, pulsar antes no; huella igual sin pulsar |

**Por qué este orden:**
- **C0** primero: sin una huella fija, no se puede afirmar «sin equipo y sin usar lo nuevo, igual que hoy».
- **M1 y M2** dan lo que más pidió el usuario («crea más magias») y montan el menú y los estados.
- **C1** es independiente.
- **E1** reutiliza lo que hay.
- **M3** y **C2** dependen de la barrera y del Aliento.
- **M4** y **E2** cierran.
- **E3** depende del arte.

**Riesgos para las partidas antiguas:**
- **Las magias aparecen por nivel al cargar.** Es lo pensado; si no se quiere, solo por tomos [decidir].
- **La ranura nueva empieza vacía.** Los ids nuevos solo entran al conseguirlos.
- **Recompensas y botín** usan lo que ya se guarda (`equipables`, `libros`, `cofres_abiertos`, `combates_ganados`).
  La única clave nueva sería `bestiario` (P3), al final de `CLAVES`.
- **No se soporta** abrir una partida nueva con una versión anterior (§4.7).
- **Los combates fijos** (centinela de Pastos Verdes, nido y Gorthor) conservan sus índices.

**Riesgos para el rendimiento en el móvil:**
- **Enemigos 3D:** como mucho dos por grupo. Hoy ya hay grupos con dos Grimfang y los tres héroes 3D: cinco ventanas
  3D. Medir los grupos 11 y 13.
- **Efectos de las magias:** las escenas nuevas usan los sombreadores de siempre, así que no hay compilaciones nuevas;
  el precalentado gana tres ventanas ocultas al empezar el combate. Medir el primer fotograma de «¡Combate!». Con el
  tope de dos efectos 3D en el móvil, el resto se dibuja en 2D, como hoy.
- **Partículas continuas:** auras, Aliento y Brasa, con 12 como mucho cada una y ×0,4 en el móvil. Sin luces 2D en el
  móvil (ya es así).
- **Perfil alto:** no se rebaja nada.
- **Medidas:** en el PC, antes y después con la misma prueba; en el Redmi, la del usuario.

**Pruebas que pueden cambiar de salida y hay que revisar a mano:**
- `prueba_menu_magia`, `prueba_mando`, `prueba_teclado` y `prueba_foco`: el menú;
- `prueba_garganta` y `prueba_gorthor`: las recompensas;
- `prueba_audio` y `prueba_efectos`: los sonidos nuevos;
- `prueba_partida` y `prueba_guardado`.

---

## 7. Decisiones para revisar con el usuario

1. **Menú:** las familias nuevas van en **pestañas con icono** detrás de «I · II · III», no mezcladas por nivel. Es
   por espacio: Lya no cabe con cinco.
2. **Debilidades:** multiplican el daño de cualquier magia (también de las 12) **solo contra los enemigos nuevos**; los
   datos de las magias no cambian.
3. **Aprendizaje:** por nivel (aparecen al cargar partidas antiguas) más tomos que lo adelantan, o solo por tomos.
4. **Alba:** cambia la barra una vez; una aceleración duradera tocaría el bucle del ATB.
5. **P1 «Guardia a tiempo»:** ¿se aprueba? ¿Activada por defecto? El tamaño de la ventana, después de probarla en el
   Redmi.
6. **Nombre de la ranura:** «Accesorio» o «Reliquia».
7. **Fauces de Gorthor:** las mismas se le perdone o no, o una recompensa distinta para cada decisión.
8. **Aspectos provisionales** (tintes del guardián y del Hollín) para tener ya las mecánicas, o esperar a tener el arte
   (Meshy con la cuenta del usuario).
9. **Chamanes:** goblins Grimfang o Hollines (en ese caso, el «orco chamán» de `para_meshy/`).
10. **«Quiebrasello»** fuera, por el peso del Sello en la historia.
11. **Volver a una versión anterior** con una partida nueva no se soporta: ¿basta con documentarlo?
12. **Templo Sumergido y Abismo de Ceniza:** sus enemigos esperan a que haya forma de llegar (T-090).

---

## 8. Peticiones a archivos de otros (al implementar; ahora no se toca nada)

- **`sonido.gd`** (sonido):
  - entradas del catálogo: `arte_alba`, `arte_ocaso`, `arte_hora_dorada`, `arte_escarcha`, `barrera_absorbe`,
    `barrera_rota`, `arte_lumbre`, `renacer`, `aliento` y `brasa`, más las voces de los enemigos nuevos (§5.3);
  - bus Efectos; prioridad 3 para los lanzamientos y 1 para los tics (`aliento`, `barrera_absorbe`), con espera
    mínima;
  - y la regla de **no usar el generador aleatorio global** de Godot durante el combate: si lo usara, la huella
    cambiaría sin que cambie el combate. Hoy usa su propio `_rng`: bien.
- **`material_arma.gd`** (gráficos): uniformes opcionales `tinte` y `color_brillo`, con blanco por defecto (las armas
  de hoy, iguales).
- **`goblin_3d.gd`** (animaciones):
  - variante con bastón para el chamán (`usa_vara = true` y sin hacha);
  - para P1, una señal «antes del golpe».
- **`zona.gd`, `garganta.gd`, `isla.gd` y `zonas3d/`** (coordinador, T-089 y T-090): los cofres y secretos de §4.5,
  llamando a `Recompensas.dar(id)`.
- **`fondo_combate.gd`** (gráficos): fondo «templo».
- **`diario.gd`**: fichas nuevas y, con P3, el bestiario.
- **`carga.gd`**: precargar `AlbaVFX`, `LumbreVFX` y `EscarchaVFX`.
- **`docs/recursos.md`**: la procedencia del limo y de las tiras del Hollín (§5.5).

---

## 9. Límites de este documento

- Todo está **observado en el código** de `dddbddb` (y de `area-sonido` @ `1359386` para el sonido). **Nada está
  comprobado ejecutando:** en esta fase no se lanza Godot.
- **Las cifras** (PM, porcentajes, PV, ataques, umbrales, precios) son de partida: las fijan `prueba_artes`,
  `prueba_regiones` y `prueba_equilibrio`. Los combates ganados con ataques automáticos no prueban la estrategia de un
  jugador.
- **La geometría del menú** sale de las constantes de `menu_combate.gd`; no se ha visto en pantalla.
- **El determinismo** de C0 con `--fixed-fps 30` es una hipótesis razonable (todo avanza por fotogramas), pendiente de
  comprobar con dos pasadas.
- **Los lugares de los secretos** dependen de T-089 y T-090: algunos aún no existen (la orilla de la Arboleda, el Árbol
  Milenario, la Taberna).
- **Sin medir:** ni el rendimiento en el Redmi ni la latencia del toque de P1.
- **Licencias** de los recursos reutilizados: sin verificar (§5.5).
