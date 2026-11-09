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

## 2026-11-09, 12:45 — Fase 2 de T-089: Oakhaven enganchada al juego

**Encargo:** que Oakhaven se vea y se juegue. Desde el mapa, el lugar 0 abre una ciudad hecha a mano,
`ciudad_oakhaven.tscn`, que hereda de `zona.gd` como la Garganta y usa los datos de la fase 1. Archivos asignados:
`zona.gd` (métodos que se puedan sobrescribir), `ciudad_oakhaven.gd` y `.tscn`, la entrada del lugar 0 en `mapa.gd`,
`progreso.gd` (`CIUDADES`, `notas_de()` y `ver_nota()`), la sección «Notas» de `diario.gd` y el ramito de lavanda de
`zonas3d/pastos_verdes_3d.gd`. El arte lo hace gráficos aparte: aquí, el provisional.
Copia `D:\Aethelgard_narrativa`, rama `area-narrativa`, desde `ab250c9`. Un límite de uso cortó la sesión a media
tarea; se retomó desde los cambios sin confirmar, que se revisaron antes de seguir.

### 1. Archivos y commits
| Commit | Qué |
|---|---|
| `2be0bf1` | Los `.uid` de los archivos de la fase 1, que generó la importación pedida |
| `acc8e74` | `zona.gd`: los métodos que una ciudad puede sobrescribir, sin cambiar lo que hacen las demás zonas |
| `c69fba1` | `progreso.gd` (`CIUDADES`, `notas_de()`, `ver_nota()`) y `diario.gd` (sección «Notas») |
| `59140ea` | `ciudad_oakhaven.gd`, `.tscn` y `.uid`; la entrada en `mapa.gd`; textos nuevos en `ciudades/oakhaven.gd` |
| `32f6325` | `zonas3d/pastos_verdes_3d.gd`: solo el ramito de lavanda |
| `557f5fe` | `prueba_oakhaven` y `prueba_oakhaven_fotos` (con sus `.uid` y su línea en la lista); `prueba_foco`, `prueba_escenas` y `prueba_ciudad_datos`, al día |
| `ee438b7` | `ciudad_oakhaven.gd`, preparada para el arte de gráficos tal como lo está montando (casas, farolas, estados y ambiente) |
| `d62fae3` | `prueba_oakhaven` prueba también el camino del arte, con `pruebas/oakhaven_arte_falso.gd` |
| `77aabdc` | `prueba_foco_fotos` espera la ciudad nueva |
| (este) | Este informe |

**`zona.gd`** (observado en el código; las pruebas de las otras zonas siguen pasando):
- `_poner_altar()` y `_adornar_altar()`, el altar y su orbe;
- `_npcs()`: cada vecino puede traer `casilla` (en vez de `lugar`, respecto a la plaza), `tinte`, `escala` y `corto`
  (para «Hablar con»); sin ellos, lo de siempre;
- `_dialogo_npc()`, qué diálogo toca; al abrirse uno, el vecino pasa de turno (sus frases de respaldo, igual que
  antes);
- `_pagar_posada()` y `_tras_posada()`;
- `_brillo_brazalete()`, el brillo, aparte;
- el muro 3: muro invisible (choca, no se dibuja, no crece hierba), que solo pone una ciudad.
- Las líneas de sonido no cambian.

**`ciudad_oakhaven.gd`: qué se juega ya** (comprobado ejecutando, ver §2)
- **Entrar desde el mapa:** «Entrar: Oakhaven» abre la ciudad. Kael aparece en la Puerta del Sur. Suena el ambiente
  de ciudad (ver §5, `musica.gd`). Al salir por la puerta se vuelve al mapa.
- **El trazado** de `ciudades/oakhaven.gd`:
  - calles, plaza y patios empedrados; la colina, las raíces y el jardín de urnas, con hierba;
  - la muralla, con la Puerta del Sur abierta (la del este, doble: la ronda va por encima);
  - edificios de tejado (taberna, botica, Concejo, cuerpo de guardia) y de piedra (torre, crematorio);
  - el resto, casas con jardines entre ellas. Los jardines no se pisan y tienen setos junto a las calles, para que
    se note;
  - unas 21 farolas en las calles, la plaza, la puerta, el soportal y el crematorio (en la Oakhaven generada había
    unas 20), más los 3 faroles de la ronda.
- **Los ocho vecinos**, en su casilla y con su muñeco provisional (tinte y escala). Su diálogo, por
  `Oak.dialogo_de()`: lo de una misión en curso va primero; si no, se turnan.
- **Las señales de Dialogic** (`oak:…`):
  - misiones, pagos y recompensas, una sola vez;
  - sus avisos salen al cerrar el diálogo, de uno en uno, con un efecto que ya existía (`pagina`, `tesoro`,
    `ui_confirmar`, `monedas`);
  - la partida se guarda al acabar el diálogo.
- **La posada:**
  - con la noche gratis de «Tres favores para el Cuervo», no cobra y el botón dice «POSADA (gratis)»;
  - al despertar, la escena de los que están en el grupo; con la noche gratis, después, «Esta noche invita la
    posadera.».
- **Cuatro cofres** con id escrito y premio fijo. Los escondidos brillan mientras están cerrados: el de la ronda y el
  de las raíces, entre las hojas. El de los requisados sigue cerrado (aviso de Aldric) hasta que Kael ha salido
  (en 3D, PV-02); deja su nota en el Diario.
- **Las piezas:**
  - el barril (favor de la posadera);
  - la torre: con un fundido, sube a la ronda; la primera vez, la vista;
  - los tres faroles: «Encender» con la misión de Bastián; «Examinar» sin ella; encendidos dan luz y ya no se usan;
  - la escalera para bajar;
  - la grieta, que se pasa de lado en los dos sentidos.
  - Lo de la ronda solo se usa estando en la ronda: desde el suelo, al pie de la torre, quedaba a menos de 90 px.
- **El Patio de las Velas, a oscuras** hasta pasar la grieta. Desde el callejón solo se ve la luz de la grieta, y el
  brazalete brilla cerca de ella mientras no se haya pasado.
- **Las cinco notas** con casilla se examinan, dan su aviso y quedan en el Diario («Nueva nota en el Diario: «…»»).
  No completan ningún acto. La sexta sale del cofre de los requisados.
- **Los detalles de canon,** en su sitio nuevo: el sello, a la puerta del crematorio; el tapiz, en el pórtico. Siguen
  siendo detalles: brazalete, Diario y página del acto I.
- **El Árbol Milenario** en lugar del altar, provisional: el arce grande, único en la ciudad.
  - «Examinar» a su pie da `TEXTO_ARBOL`.
  - Su copa se vuelve translúcida si Kael pasa por detrás.
  - En las raíces, la cámara sube para que se vea entera.
- **Las dos vistas:** desde la torre (con texto distinto tras PV-07) y desde las raíces, la primera vez. De momento
  son avisos; las viñetas están pedidas.
- **Tras cada cambio de la partida** (cofre, nota, pieza, señal o posada) se guarda.
- **La música:** `musica.gd` elige por la escena y aún no conoce esta. Mientras, la ciudad pide su contexto,
  «ciudad». Cuando `musica.gd` la conozca, ese código no hará nada (ver §5).

**El arte** (contrato con gráficos, completo en la cabecera de `ciudad_oakhaven.gd`):
- si existe `ciudades/oakhaven_piezas.gd` con `crear_pieza(id, rect_casillas, tam_casilla)`, se le pide un dibujo
  para:
  - cada lugar de `LUGARES`, cada pieza, cada nota con casilla y cada detalle;
  - cada casa del relleno (`casa_<ancho>x<alto>`) y cada farola de las calles (`farol`).
- El nodo va a `mundo_y`. Si viene en (0, 0), se pone en la esquina de arriba a la izquierda de su huella; si no, se
  respeta su posición.
- Bajo el dibujo de un edificio o una casa, sus casillas pasan a muro invisible.
- Hablar, examinar y usar se miden desde las casillas de los datos, no desde el dibujo.
- Un `Node2D` vacío evita la provisional de una pieza que ya dibuja su lugar (el letrero en la taberna, los faroles en
  la ronda…).
- **Estados:** `poner_estado("farol_1"…"farol_3", encendido)` y `poner_estado(<id del cofre>, cerrado)`. Si un dibujo
  pinta el destello de un cofre (`tiene_estado`), la ciudad no pone el suyo. A un farol con `encender(si)` se le
  llama.
- Si el módulo trae `AMBIENTE`, es la luz ambiente de la ciudad.
- **Comprobado con un módulo falso** (`prueba_oakhaven`, apartado 11), porque el de verdad aún no está publicado.
- Visto sin tocarlo (solo lectura, 12:25): el borrador de gráficos en `D:\Aethelgard_graficos`, sin confirmar, ya usa
  esta forma: `Pieza` con `poner_estado` y `tiene_estado`, `AMBIENTE` y piezas `casa_4x4` y `farol`. Ver §5.

**`progreso.gd` y `diario.gd`:**
- `CIUDADES = {0: "res://ciudades/oakhaven.gd"}`;
- `notas_de(lugar)` lee `NOTAS` del módulo;
- `ver_nota(id)` apunta en `lore_visto` solo las notas de una ciudad y nunca completa un acto. `Oak.ver_nota()` pasa
  por ella.
- Ni claves nuevas ni cambios en guardar, cargar o sus protecciones.
- En el Diario, la sección «Notas» va bajo los actos, con las leídas («nombre · lugar» y el texto). No aparece hasta
  leer la primera.

**`pastos_verdes_3d.gd`:** el ramito sale junto al camino, antes del puente, si Rosa lo pidió y no se ha cogido.
- «Coger la lavanda» aplica la señal una vez, avisa, lo quita y guarda.
- Provisional (espigas moradas y un destello) y sin choque.
- Nada más de la región cambia.

**Textos nuevos que ve el jugador** (todos en `ciudades/oakhaven.gd`, revisados por `prueba_ciudad_datos`: D-033,
D-073 y largo de aviso)
| Dónde | Texto |
|---|---|
| Vista desde la torre (antes de PV-07) | «Al sureste, un brillo morado. Al norte, la niebla.» |
| Vista desde la torre (tras PV-07) | «Al sureste, un brillo morado. Al norte, la niebla. Y arriba, la ciudad flotante.» |
| Vista desde las raíces | «Desde las raíces se ve la ciudad entera. Los faroles se encienden en ola.» |
| Al despertar con la noche gratis | «Esta noche invita la posadera.» |
| Nota nueva | «Nueva nota en el Diario: «‹nombre›»» (como la página nueva de los detalles) |
| Botones | «Subir el barril», «Subir», «Bajar», «Encender», «Pasar», «Examinar» (de los datos) y «Coger la lavanda» (3D) |

### 2. Pruebas
- **Importación aislada** (lo pedido, antes de empezar): `D:\REBELUM_diagnostico\importaciones\narrativa_20261109_082934\importacion.log`,
  salida 0.
  - Creó los `.uid` de los archivos de la fase 1 (confirmados, `2be0bf1`).
  - Añadió en `project.godot` los 4 personajes y los 27 diálogos de Oakhaven (`dialogic/directories`). Ese archivo no
    es mío: lo dejé como estaba (ver §5). Con `registrar_dialogic()`, el juego funciona igual con ellos o sin ellos;
    las pruebas se pasaron sin ellos, como está confirmado.
  - Dos importaciones más (`narrativa_20261109_121920` y `_123130`) dieron los `.uid` de los guiones nuevos.
- **`prueba_oakhaven`** (comprobado ejecutando, aislado, 2026-11-09): **SUPERADA, FALLOS: 0**, en 6-14 s.
  - Recorre los once apartados de su cabecera: entrar, trazado, los ocho vecinos, Pip y los favores, la posada, la
    torre y los faroles, la grieta, los cofres, la nota y el Diario, salir y volver, guardar y cargar, la lavanda con
    Pastos Verdes 3D y el camino del arte con el módulo falso.
  - Usa su propia partida (`user://prueba_oakhaven.save`).
- **Repaso pedido** (comprobado ejecutando, aislado, 2026-11-09 a las 12:16): **13 de 13 SUPERADAS**
  (`D:\REBELUM_diagnostico\pruebas\2026-11-09_121605\resumen.md`).
  - `prueba_ciudad_datos`, `prueba_oakhaven`, `prueba_foco`, `prueba_escenas`, `prueba_musica`,
    `prueba_guardado_protegido`, `prueba_dialogo_interfaz`, `prueba_mapamundi` y `prueba_efectos`;
  - además, `prueba_partida`, `prueba_guardado`, `prueba_cofre` y `prueba_dialogo`.
  - `prueba_foco` (6, la ciudad) y `prueba_escenas` ahora entran en `ciudad_oakhaven.tscn`. `prueba_musica` sigue usando
    `zona.tscn` con el lugar 0, que no cambia.
- **Batería completa** (comprobado ejecutando, aislado, 2026-11-09, sobre `557f5fe`): **SUPERADAS 43 · FALLIDAS 0 ·
  MANUALES 26 · NO SEGURAS 0** (`D:\REBELUM_diagnostico\pruebas\2026-11-09_122212\resumen.md`).
  - La partida real, su carpeta y el proyecto, sin cambios. Había otros Godot abiertos, de otras copias.
  - En la fase 1 fueron 40 y 23. Las nuevas son `prueba_oakhaven` y `prueba_oakhaven_fotos`, más las que otras áreas
    añadieron entre medias.
- **Tras los cambios del arte** (`ee438b7` y `d62fae3`), sobre `d62fae3`:
  - las seis de la ciudad, **SUPERADAS** (`prueba_oakhaven`, `prueba_ciudad_datos`, `prueba_foco`, `prueba_escenas`,
    `prueba_musica` y `prueba_precalentado`; `2026-11-09_123215`);
  - `prueba_foco_fotos`, con ventana: 8 capturas, la de la ciudad ya en la nueva (`2026-11-09_123621`).
- **Capturas con ventana** en `D:\REBELUM_diagnostico\oakhaven\2026-11-09\`:
  - `antes\`: cinco, de `zona.tscn` con el lugar 0, sobre `ab250c9`;
  - `despues\`: dieciocho, entrando desde el mapa, sobre `d62fae3`;
  - `comparacion_antes_despues.png`: las cinco tomas comunes, lado a lado.

### 3. Evidencias
- **Capturas:** las rutas de §2. La lámina compara entrada, plaza, norte (el altar frente al Árbol), la ciudad entera
  y un diálogo.
  - En `despues\` están, además: el Cuervo, el callejón con el patio a oscuras, el patio al pasar la grieta, el
    crematorio, la ronda apagada y encendida, el Árbol y su copa translúcida, el mercado, el Diario con «Notas», la
    posada gratis, su escena y el ramito en Pastos Verdes 3D.
- **Cómo se ve** (revisado a ojo, en el PC):
  - una ciudad densa de calles empedradas entre casas, en vez del prado con casas sueltas de antes;
  - los lugares de canon se reconocen: la taberna con su cuervo de hierro, el crematorio de piedra con la puerta
    sellada y el Árbol al norte.
  - Es arte provisional: tejados y piedra de `zona.gd`, objetos dibujados por código y la ilustración de un arce.

### 4. Límites y pendientes de decisión
- **Partidas guardadas dentro de la Oakhaven de antes** (`escena_guardada = zona.tscn` y lugar 0): al cargarlas se abre
  la zona generada de siempre, hasta salir al mapa y volver a entrar. Lo resolvería una línea al cargar, en
  `progreso.gd` (`restaurar()`) o en `carga.gd`. No los toco: son la carga de la partida. Ver §5.
- **`musica.gd`** no es mío. Mientras no tenga su línea, la ciudad pide la música con `Musica.pedir("ciudad")`.
- **Sin medir en el Redmi:**
  - unas 25 luces de llama (21 farolas, 3 faroles y las velas) y la del Árbol; en la Oakhaven generada, unas 20;
  - el coste de las casas y los jardines.
  - Con el arte de gráficos, las farolas serán las suyas, sin luces 2D según su cabecera.
- **Muñecos y retratos provisionales,** como en la fase 1. Bastián no va «de farol en farol»: está quieto.
- **Vistas:** de momento, avisos. Las viñetas pintadas están pedidas.
- **Sin cambios** en lo que espera al usuario (n.º 1, Olvido; 2, la Cripta; 3, Aldea Rocío; 5, Pip guía): sigue la
  versión neutra.

### 5. Siguiente paso y cambios en archivos de otros
- **`musica.gd`** (pedido, de sonido o del coordinador): en `contexto_de()`, junto a los demás casos,
  `"res://ciudad_oakhaven.tscn": return "ciudad"`. Con eso, lo de la ciudad no hace nada.
  - Después, conviene que `prueba_musica` pase también por `ciudad_oakhaven.tscn`.
- **Partidas antiguas en Oakhaven** (propuesta, del coordinador): en `progreso.gd` `restaurar()`, si
  `escena == "res://zona.tscn"` y el lugar guardado es el 0, volver a `"res://ciudad_oakhaven.tscn"` con
  `pos_zona_ok = false`, para entrar por la puerta: las posiciones de antes no valen en el trazado nuevo.
  - La ciudad ya se protege de una posición que no sea calle: pone a Kael en la puerta.
- **`project.godot`** (del coordinador): confirmar o no lo que añade la importación en `dialogic/directories` (4
  personajes y 27 diálogos). Con o sin ello funciona igual.
- **Para gráficos** (`oakhaven_piezas.gd`):
  - **Ids que pide la ciudad:** los de `LUGARES`, `PIEZAS`, `NOTAS` (con casilla) y los detalles `oak_sello` y
    `oak_tapiz`; `casa_<ancho>x<alto>` para cada casa del relleno (de 3 a 6 de ancho y de 3 a 4 de alto); `farol` para
    cada farola de calle.
  - Para lo que ya pinte un lugar (letrero, faroles de la ronda, sello), un `Node2D` vacío.
  - **Tamaños,** en casillas de 64 px (de `LUGARES`):
    - Edificios: taberna 10 × 6 (fachada al sur, a la Calle del Cuervo), crematorio 10 × 8 (puerta sellada al sur, en
      (67, 15,5)), Concejo 9 × 5 (pórtico de 9 × 2 al sur), botica 5 × 5, cuerpo de guardia 5 × 4, torre 4 × 4 (puerta
      al sur, en (73,5, 42)).
    - Árbol: tronco 4 × 4 con el pie en (40, 9). La copa provisional mide unas 5,3 × 8,8 casillas. En las raíces, la
      cámara sube hasta el borde de la ciudad para enseñarla.
  - **Piezas y notas,** por su casilla: barril (12, 29); tres faroles en la ronda (76,5; 38,5, 34,5 y 31,5), con
    `encender(si)` o los estados `farol_N` de la ronda; escalera (76,5, 41,5); grieta (23, 35), una casilla del muro
    del callejón; tablón (36, 29); letrero del cuervo (13, 25,5); raíz cortada (45, 10); atril con el libro
    (42,5, 46,5); altar de las velas (25,5, 38). Detalles: sello (67, 16) y tapiz (47, 22).
  - **Viñetas:** `oak_vista_torre` y `oak_vista_raices`. Hoy son avisos. Propuesta: que `crear_pieza` las devuelva con
    su id y la ciudad las enseñe 4-6 s, saltables con un toque.
  - **En 3D:** el ramito de lavanda.
- **Para sonido** (lo de la fase 1, sigue pendiente): campana lejana, bullicio de taberna, el chirrido del cuervo de
  hierro y un farol que prende. Hoy suenan efectos que ya existían.
- **Siguiente paso de narrativa:** cuando gráficos publique su módulo, repasar las capturas con el arte de verdad y
  pasar `prueba_oakhaven`. Cuando el usuario decida n.º 1, 2, 3 y 5, adoptar la propuesta
  (`dialogos/oakhaven/propuesta/`, fase 1).
