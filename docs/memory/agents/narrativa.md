# Informe del especialista de narrativa

Cada entrega añade una sección con fecha y hora; las anteriores no se borran (ver `LEEME.md`).

## 2026-11-09, 00:25 — Fase 0 de T-089, T-090 y T-094, y preparación de T-086 (solo diseño)

**Encargo:** diseñar, sin tocar el juego, las ciudades (T-089), los sitios nuevos que explorar (T-090), los compañeros de
viaje (T-094) y la tabla de texto del prólogo y de Pastos Verdes para T-086. Decisiones vigentes: D-071, D-072, D-033.
Copia `D:\Aethelgard_narrativa`, rama `area-narrativa`, partiendo de `dddbddb`.

### 1. Archivos y commits
- Nuevo: `docs/diseno/ciudades_y_lugares.md` (el diseño completo).
- Nuevo: este informe, `docs/memory/agents/narrativa.md`.
- No se ha tocado ningún `.dtl`, `.dch`, script ni escena. Los commits se indican en la respuesta al coordinador.

### 2. Pruebas
- No se ha ejecutado Godot: en esta fase no tocaba.
- **Medido con scripts** (PowerShell, 2026-11-09, sobre `dddbddb`):
  - la longitud visible de las 44 frases del prólogo y de la misión de Pastos Verdes, y la de las frases propuestas;
  - el color de los píxeles de la captura del mapamundi del 08/11
    (`D:\REBELUM_diagnostico\mapamundi\2026-11-08\antes\2_mapa_entero_1a1.png`) en cada marcador nuevo: los cuatro caen en
    tierra y a 140 px o más de cualquier otro lugar. **Pendiente de comprobar en el juego.**

### 3. Evidencias
- Tabla de antes y después de las 44 frases, con la intención de cada una para animaciones:
  `docs/diseno/ciudades_y_lugares.md` §5.2. Cambian 6.
- Ciudades (Oakhaven, Sunken City y Arboleda Mítica), con trazado, posada, NPC, misiones, secretos, notas y dirección
  visual: §2.
- Ocho sitios nuevos, primero los de canon, con nivel, conexión en el mapa y restricciones de D-033: §3.
- Compañeros (Nyx, Brea y Nerea) y acompañantes ligeros (Pip y Lucero): §4.

### 4. Límites y propuestas pendientes de decisión
- Todo es propuesta [P] salvo lo marcado [C]. Las decisiones para el usuario están en §7 del documento (10, con
  recomendación; ninguna bloquea los pasos 1 a 4 del orden).
- **Riesgos técnicos encontrados en el código** (§1.3 del documento):
  - añadir lugares a `LUGARES` desplazaría el índice 10 de Pastos Verdes en el modo 3D (`mapa.gd:110`);
  - el generador del mapa colorea los biomas con todos los lugares (`mapa.gd:173-178`): crecer `LUGARES` sin crecer
    `ZONA_LUGAR` se sale del arreglo, y con él cambia el mapa;
  - un detalle de lore nuevo en un lugar de un acto vuelve a ocultar la página ya ganada (`progreso.gd:178-187`): se
    propone una lista `NOTAS` aparte, guardada en `lore_visto`;
  - el id de los cofres depende de la posición (`zona.gd:1761`): ids escritos en los sitios hechos a mano.
- Las posiciones de los marcadores se midieron en una captura, no en el juego.

### 5. Siguiente paso y cambios en archivos de otros
- **Siguiente paso:** cuando animaciones termine con los `.dtl`, aplicar la tabla de §5.2 (6 frases) y pasar
  `prueba_prologo`, `prueba_dialogo`, `prueba_dialogo_interfaz` y `prueba_ruta_alpha`.
- **Cambios que hacen falta en archivos de otros** (al aplicar la tabla):
  - `aethelgard/pruebas/prueba_prologo.gd:130`: de 9 a 11 frases (10 si solo se parte el primer globo);
  - opcional, `aethelgard/progreso.gd:45`: el texto del detalle `pastos_estela` (§5.3).
- **Para implementar las ciudades y los sitios:** el orden y los responsables están en §6 del documento.

## 2026-11-09, 08:20 — Fase 1 de T-089: Oakhaven en archivos nuevos, listo para enganchar

**Encargo:** diálogos de los vecinos de Oakhaven, datos de la ciudad en un módulo nuevo, una prueba nueva y la lista
exacta de enganches, **solo con archivos nuevos**. Decisiones adoptadas por el coordinador (D-073): lugares desde el
11, mapa con los 10 de siempre, notas en una lista aparte (`NOTAS`, en `lore_visto`) y cofres con id escrito. Lo que
espera al usuario va en **versión neutra**, y la propuesta, aparte. Copia `D:\Aethelgard_narrativa`, rama
`area-narrativa`, desde `3c6f795` (integración `4c6fafc`, con la tanda 2 de sonido).

### 1. Archivos y commits
| Commit | Qué |
|---|---|
| `936488a` | 27 diálogos en `aethelgard/dialogos/oakhaven/`, 4 personajes en `aethelgard/dialogos/personajes/oakhaven/` y el retrato provisional con tinte (`dialogos/oakhaven/retrato_tenido.gd` y `.tscn`) |
| `c56bbb1` | La propuesta, aparte: `aethelgard/dialogos/oakhaven/propuesta/` (con `.gdignore`): 2 personajes, 9 diálogos y `oakhaven_propuesta.gd` |
| `e3ed9a7` | `aethelgard/ciudades/oakhaven.gd`: los datos de la ciudad |
| `b1d2af4` | `aethelgard/pruebas/prueba_ciudad_datos.gd` y su línea en `pruebas/lista_pruebas.txt` (al final del bloque automático, tras `prueba_partida`) |

- No se ha tocado ningún archivo que ya existiera, salvo esa línea de la lista. Ni `project.godot` (ver §5).
- El asunto de `936488a` empieza con un carácter invisible (BOM: el mensaje lo escribió `Set-Content` de PowerShell 5.1).
  No lo reescribo, porque la norma prohíbe reescribir el historial; el texto del commit es correcto.

**Qué hay en Oakhaven** (`ciudades/oakhaven.gd`, versión neutra)
- **Trazado** de 80 × 56 casillas (`LUGARES`, rectángulos): Puerta del Sur, Calle Mayor, Plaza del Tapiz, Calle del
  Cuervo y del Mercado, Barrio del Cuervo (taberna, patio, callejón, grieta y Patio de las Velas), Botica, cuerpo de
  guardia con su patio, Colina del Crematorio, Raíces del Árbol, Torre de la Campana y ronda de la muralla este.
  - **Canon:** la Taberna del Cuervo Oxidado es la posada (30 monedas, como hoy); el crematorio tiene la **puerta
    sellada**; el Árbol Milenario sustituye al altar (`ARBOL`, `TEXTO_ARBOL`).
  - Los detalles `oak_sello` y `oak_tapiz` cambian de sitio (a la puerta del crematorio y al pórtico del Concejo) y
    **conservan su id** (`SITIOS_DETALLE`).
- **8 vecinos** con su casilla (`NPCS`): los 4 de siempre con sus diálogos de siempre más los nuevos, y 4 nuevos.
  `dialogo_de(id, veces)` elige: primero lo de una misión en curso; si no, se turnan los que se cumplen.
- **4 misiones** (`MISIONES`), con pasos, recompensa y estado:
  | Misión | Quién | Pasos | Recompensa |
  |---|---|---|---|
  | Tres favores para el Cuervo | posadera | barril del patio, flores de Rosa, el cucharón que tiene Pip, volver | una noche gratis y 2 Pociones |
  | Los faroles de la ronda | Bastián | subir a la torre y encender 3 faroles | el cofre de la ronda y la vista (sin pago extra) |
  | Un secreto por una moneda | Pip | pagar 1 moneda | la grieta del callejón → Patio de las Velas |
  | Lavanda para el Árbol (solo 3D) | Rosa | coger lavanda en Pastos Verdes y llevársela | 2 Pociones; Doña Encina da las gracias |
- **4 cofres** con id escrito y premio fijo (`COFRES`), entre 80 y 125 a precio de tienda (un cofre normal da hasta
  120): `oak_cofre_velas` (1 Éter y 1 Incienso), `oak_cofre_raices` (100 monedas y 1 Poción), `oak_cofre_ronda`
  (2 Éter) y `oak_cofre_requisados` (60 monedas y 1 Poción; cuando Kael ya ha salido, Aldric mira hacia otro lado).
  El equipo del diseño (Colgante de luna, Cinta de cuero) ya está en el inventario inicial: no premiaba nada.
- **6 secretos** (`SECRETOS`, con id: velas, raíces, ronda, requisados y las dos vistas), **7 piezas** (`PIEZAS`:
  barril, torre, bajada, 3 faroles y grieta) y **6 notas** (`NOTAS`: bando, letrero del cuervo, anillos, libro de
  guardia, velas y requisados), de 15 palabras o menos.
- **Estado:** solo claves que ya existen: `hitos` (`oak_favores`, `oak_faroles`, `oak_lavanda`), `decisiones`
  (`pip_oak`), `mazmorras["oakhaven"]` (pasos, faroles, vistas, noche gratis), `cofres_abiertos` y `lore_visto`.
  Ninguna clave nueva en la partida.
- **Efectos una sola vez:** `aplicar_senal(arg)` (las señales `[signal arg="oak:…"]` de los diálogos y de las piezas;
  devuelve el aviso), `abrir_cofre(id)`, `ver_nota(id)`, `usar_noche_gratis()`, `escena_posada()`,
  `estado_mision(id)`, `pasos_mision(id)` y `lavanda_disponible()`.
- **`registrar_dialogic()`:** da a conocer los 4 personajes nuevos a Dialogic en tiempo de juego, **por su ruta** y sin
  escribir nada (en el editor no hace nada). Los diálogos se abren por su ruta, así que no hace falta registrarlos.

### 2. Pruebas
- **Importación aislada** (lo pedido, antes de empezar): `D:\REBELUM_diagnostico\importaciones\narrativa_20261109_073909\importacion.log`.
  Salida 0 y `git status` limpio después.
- **`prueba_ciudad_datos`** (comprobado ejecutando, aislado, 2026-11-09, `b1d2af4`): **SUPERADA, FALLOS: 0**.
  - 38 recorridos con Dialogic: los 27 diálogos neutros y los 9 de la propuesta, más la segunda opción de Pip en cada
    versión. En cada uno: de 2 a 4 frases por vecino (de 3 a 5 en la posada), cada frase con su `.dch`, un solo vecino
    por diálogo, en la posada solo hablan los presentes, las señales esperadas y el tinte del retrato provisional.
  - Antes de nada, unos controles: los comprobadores de texto, casillas y condiciones detectan casos malos a propósito.
  - Registro con la lista de recorridos: `D:\REBELUM_diagnostico\pruebas\2026-11-09_081615\prueba_ciudad_datos.log`.
- **Hallazgo al probar:** la primera pasada acabó en 0 fallos, pero Godot se cayó al cerrar (0xC0000005). La causa: un
  personaje de Dialogic guardado **como objeto** en los metadatos de `Engine` (`register_runtime_resource`). Por su
  ruta, no se cae. Por eso `registrar_dialogic()` usa rutas, y **ningún enganche debe guardar recursos en `Engine`**.
- **Batería completa** (comprobado ejecutando, aislado, 2026-11-09, sobre `b1d2af4`): **SUPERADAS 40 · FALLIDAS 0 ·
  MANUALES 23** (las de ventana y las manuales no se lanzan). `prueba_ciudad_datos`, SUPERADA en 5,4 s. La partida
  real y su carpeta, sin cambios. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-09_081830\resumen.md`.
  - El resumen marca «proyecto: cambiado» porque escribí este informe mientras corría: `git status` solo mostraba
    `docs/memory/agents/narrativa.md`. Las pruebas no tocaron ningún archivo.

### 3. Evidencias
**Neutro frente a propuesta** (D-073; la propuesta, en `dialogos/oakhaven/propuesta/`, fuera del juego)
| Depende de | Versión neutra (en el juego) | Propuesta (aparte) |
|---|---|---|
| n.º 1, Olvido | «Posadera» del Cuervo, sin nombre ni pasado con Kael: precio, la niebla, «Tres favores para el Cuervo» y las tres escenas de posada | Olvido (`olvido.dch`): «Me llamo Olvido y no se me olvida nada», «Kael, cariño: tres cenas», «La deuda de Olvido» y sus escenas de posada |
| n.º 1 y la v2 (acto III) | Nota del libro de guardia: «Noche tranquila. Niebla al norte. Dos faroles cambiados.» | `nota_oak_pagina`: falta una página de hace diecisiete años |
| n.º 2, la Cripta | Albar, «custodio del crematorio»: «Esa puerta no se abre. Ni para visitas, ni para preguntas.» | Hermano Albar: «Recordar duele. Nosotros ayudamos a soltar.» y «La puerta de abajo…»; la trampilla del Cuervo; `nota_oak_urna` |
| n.º 2 y n.º 5, Pip guía | El secreto de Pip es la grieta del callejón, que lleva al Patio de las Velas | La trampilla que huele a ceniza y Pip como guía de pago |
| n.º 3, Aldea Rocío | Nada del nombre borroso ni del mapa | «El nombre borroso» (`oak_olvido_nombre`), `nota_oak_mapa` y la señal `oak:rocio_nombre` |
| Madre Ceniza (v3) | El favor es un **cucharón**, no una cucharilla de plata | — |

- `oakhaven_propuesta.gd` dice qué cambia (`SUSTITUYE_NPC`, `SUSTITUYE_DIALOGO`), qué se añade y de qué decisión
  depende cada parte (`DEPENDE_DE`). Adoptarla: mover los archivos fuera de la carpeta y quitarles la primera línea,
  el comentario `# PROPUESTA…` (Dialogic lo imprimiría en la consola cada vez).
- La prueba comprueba que la versión neutra no nombra nada de lo pendiente (Olvido, Rocío, cripta, trampilla, Cónclave,
  «crió», «hermano», «diecisiete», alcantarillas) y que nada revela lo de D-033.

**Intención de cada diálogo** (para animaciones; los vecinos usan hoy retratos fijos, sin gestos)
| Diálogo | Quién | Intención |
|---|---|---|
| `oak_aldric_salida` | Aldric | Guiño cómplice: no vio nada; el patio de los requisados, «por ahí no miro» |
| `oak_selene_lya` | Selene | Cariño contenido por Lya; al final, seria y evasiva con los libros |
| `oak_pip_secreto` / `_sin_monedas` / `_despues` | Pip | Pillo vendiendo; burla sin monedas; misterio exagerado después |
| `oak_pip_cucharon` | Pip | «Me lo encontré»: inocencia fingida |
| `oak_rosa_flores` / `_lavanda` / `_lavanda_entrega` | Rosa | Alegre y charlatana; nostalgia por la lavanda; alegría al olerla |
| `oak_posadera` / `_niebla` | Posadera | Ruda y cálida; luego, preocupada mirando al norte |
| `oak_posadera_favores` / `_pendientes` / `_fin` | Posadera | Agobiada; impaciente con humor; agradecida («Hasta brilla. Qué miedo.») |
| `oak_albar` / `_puerta` | Albar | Sereno, voz baja, inquietante; firme ante la puerta |
| `oak_bastian` / `_ronda` / `_ronda_pendiente` / `_ronda_fin` / `_contento` | Bastián | Niño muy serio con los números; ruego; prisa; júbilo; calma |
| `oak_encina` / `_anillo` / `_gracias` | Doña Encina | Seca y con humor; misterio («un año entero hubiera ardido»); ternura |
| `oak_posada_solo` / `_lya` / `_grupo` | Posadera y el grupo | Humor de convivencia; Garon telegráfico; Kael y Lya, amistad (D-032: «Debatimos. A gritos.») |

### 4. Límites y propuestas pendientes
- **Solo datos y diálogos:** nada de esto se ve todavía en el juego. Las longitudes están medidas por caracteres (como
  mucho 73 en la versión neutra); falta verlas en el Redmi.
- **Retratos provisionales:** la posadera usa la ilustración de Rosa, y Bastián la de Pip, con otro tinte
  (`retrato_tenido.tscn`; el tinte va en el `.dch`). Albar y Doña Encina, sin retrato: ninguna de las cuatro
  ilustraciones sirve para un custodio ni para una anciana.
- **Sin la exploración 3D** no hay Pastos Verdes ni hito `pv_02`. Por eso «Kael ya ha salido» vale siempre en 2D (el
  juego empieza fuera de la ciudad) y «Lavanda para el Árbol» solo existe en 3D.
- **Pendientes del usuario** que cambian Oakhaven: n.º 1 (Olvido), 2 (la Cripta), 3 (Aldea Rocío) y 5 (Pip guía). La
  propuesta ya está escrita y probada.

### 5. Enganches que harán falta (cuando el coordinador pase esos archivos)
**`mapa.gd`** (de gráficos), línea 666: entrar en el lugar 0 abre la ciudad nueva:
`Recursos.cambiar_escena("res://garganta.tscn" if i == INDICE_GARGANTA else ("res://ciudad_oakhaven.tscn" if i == 0 else "res://zona.tscn"))`.
Sunken City (lugar 5) sigue con `zona.tscn` hasta su fase.

**`zona.gd`** (lo integra el coordinador): unos métodos que la ciudad pueda sobrescribir, sin cambiar nada para las
demás zonas. Después, **`ciudad_oakhaven.gd` + `.tscn` nuevos**, que heredan de `zona.gd` como `garganta.gd`:
1. **Trazado** (`_leer_lugar`, `_generar_disposicion`, l. 336 y 350): `es_ciudad = true`, `plaza = Oak.PLAZA`,
   `meta = Oak.ARBOL`, `salida_x = Oak.SALIDA_X`; muros = 2 en los `LUGARES` con `pisable: false`; suelo de camino en
   los pisables; borde de 1 casilla con la Puerta del Sur abierta; las farolas por las calles como hoy. La ronda va en
   alto: solo se llega por la pieza `oak_torre` (`lleva_a`).
2. **Vecinos** (`_poner_npcs`, l. 2207): leer de `_npcs()` (por defecto, `NPCS`). Si un vecino trae `"casilla"`, usarla
   en lugar de `plaza + "lugar"`; aplicar `"tinte"` a `s.modulate` y `"escala"` a la escala (Bastián, 0,8). En
   `_comprobar_cerca` (l. 2264): `"Hablar con " + d.get("corto", d["nombre"].get_slice(" ", 0))`.
3. **Qué dice cada uno** (`_accion`, l. 2287): `_empezar_dialogo(_dialogo_npc(npc_cerca))`, que por defecto devuelve
   `npc_cerca[1].get("dialogo", "")` y en Oakhaven `Oak.dialogo_de(npc_cerca[1]["id"], npc_cerca[2])` (y suma 1 a
   `npc_cerca[2]`). Antes del primer diálogo, `Oak.registrar_dialogic()` (en `_ready`).
4. **Señales:** en `_ready`, `Dialogic.signal_event.connect(_al_senal)`, y en `_exit_tree`, `disconnect` (lo vigila
   `prueba_dialogo_interfaz`). `_al_senal(arg)`: `var t = Oak.aplicar_senal(arg)`; si no es "", `_mostrar_aviso(t)`
   y `_poner_oro()`.
5. **Posada** (`_posada`, l. 2340): `if not Oak.usar_noche_gratis(): (cobrar como hoy)`; tras el fundido,
   `_empezar_dialogo(Oak.escena_posada())`. El precio sigue siendo `PRECIO_POSADA` (30), que la posadera dice.
6. **Cofres hechos a mano** (`_crear_objetos`, l. 939, y `_abrir_cofre`, l. 1773): poner un cofre en cada
   `Oak.COFRES[i]["casilla"]` con su `id` escrito (no `_id_cofre(pos)`), si no está en `cofres_abiertos`. Al abrirlo:
   `var r = Oak.abrir_cofre(id)`; con `"bloqueado"`, solo el aviso y no se abre; si no, aviso `r["texto"]` (y la nota,
   si la trae, ya queda en el Diario). Sin cofres al azar en la ciudad.
7. **Detalles de canon** (`_poner_detalles`, l. 970): en Oakhaven, la casilla sale de `Oak.SITIOS_DETALLE[d["id"]]`.
8. **Notas y piezas:** se examinan como los detalles (mismo radio), pero las notas llaman a `Oak.ver_nota(id)` (nunca
   completan un acto) y las piezas enseñan `texto` si `Oak.cumple(p["si"])` (y entonces `Oak.aplicar_senal(p["senal"])`
   y, si hay `lleva_a`, mueven a Kael) o `texto_sin` si no. Botón: `p["accion"]`.
9. **Vistas** (`oak_vista_torre` al usar la torre; `oak_vista_raices` la primera vez que Kael pisa las raíces, con la
   señal `oak:vista_raices`): viñetas de 4-6 s que se saltan tocando (arte pendiente; mientras, un aviso).
10. **Brillo del brazalete** (l. 992): que también brille cerca de la grieta (`oak_secreto_velas`) mientras no se haya
    pasado (`estado:grieta`).
11. **El cartel del altar** pasa a `Oak.TEXTO_ARBOL`; la hora azul y la iluminación, con gráficos (diseño §2.1).

**`progreso.gd`** (lo integra el coordinador): las notas, en una lista aparte que lee de las ciudades:
```gdscript
const CIUDADES := {0: "res://ciudades/oakhaven.gd"}   # notas del Diario: no cuentan para los actos
static func notas_de(lugar: int) -> Array:
	return load(CIUDADES[lugar]).NOTAS if CIUDADES.has(lugar) else []
static func ver_nota(id: String) -> bool:              # igual que Oak.ver_nota: lore_visto[id] = true
```
Ninguna clave nueva en `CLAVES`. `NIVEL_ZONA` no cambia (Oakhaven es «ciudad», 0).

**`diario.gd`**: en `_pintar()`, tras los actos (l. 146), una sección «Notas» con las vistas: para cada lugar de
`Progreso.CIUDADES`, las notas con `Progreso.visto(id)`, como «nombre · lugar» y el texto debajo (mismo estilo que
los detalles). Las que faltan no se enseñan: no hay página que completar.

**`zonas3d/pastos_verdes_3d.gd`** (lavanda): un ramito que examinar cerca del puesto de Tilo, solo si
`Oak.lavanda_disponible()`; al examinarlo, `_mostrar_aviso(Oak.aplicar_senal(Oak.LAVANDA["senal"]))`.

**`project.godot`**: no hace falta. El editor (o `--import`) apuntará solo los 4 personajes y los 27 diálogos en
`dialogic/directories`; ese cambio se puede confirmar o no (con `registrar_dialogic()` y las rutas funciona igual).
La carpeta de la propuesta no se apunta (`.gdignore`).

**Pruebas que repasar al enganchar:** `prueba_foco` (6: vecinos con diálogo en Oakhaven), `prueba_escenas`,
`prueba_musica` (mapa → Oakhaven), `prueba_guardado_protegido` (lugar 0), `prueba_dialogo_interfaz` (conexiones) y
`prueba_ciudad_datos`.

**Arte que hay que pedir**
1. **Retratos de Dialogic**, como los de `dialogos/retratos/` (figura entera, fondo transparente): la posadera (si se
   aprueba, Olvido), Bastián, Doña Encina y Albar.
2. **Muñecos del mundo 2D**, como los de `personajes/npc/`: los mismos cuatro. Mientras, `NPCS` reutiliza los de siempre
   con tinte (aldeana, pícaro y dos veces la maga), y eso se nota.
3. **La ciudad** (gráficos, T-089, diseño §2.1): taberna con el letrero del cuervo de hierro; crematorio de piedra hueso
   con chimenea y humo blanco y la puerta con el sello; Árbol Milenario (tronco, copa visible desde toda la ciudad y
   raíces que levantan el empedrado); Casa del Concejo con pórtico y tapiz; Botica; cuerpo de guardia con patio; Torre
   de la Campana; muralla este con la ronda y 3 faroles (apagado y encendido); mercado con toldos; tablón de anuncios;
   puesto de flores; barriles; grieta con luz; Patio de las Velas (altar pequeño con el anillo partido y velas);
   jardín de urnas.
4. **Dos viñetas pintadas:** desde la torre (antes y después de PV-07) y desde las raíces (la hora azul y los faroles
   que se encienden en ola).
5. **3D (Pastos Verdes):** un ramito de lavanda que examinar.
6. **Para sonido:** campana lejana, bullicio de taberna, el chirrido del cuervo de hierro y un farol que prende.

### 6. Siguiente paso
- Con `zona.gd`, `mapa.gd`, `progreso.gd` y `diario.gd` en la mano: `ciudad_oakhaven.gd` y los enganches de §5, y la
  prueba de la ciudad jugada (entrar, hablar con los ocho, una misión entera, un cofre, una nota, la posada y salir).
- Cuando animaciones suelte los `.dtl`: el texto de T-086 (sesión anterior, §5).
