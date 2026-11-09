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

## 2026-11-09, 13:20 — T-086: el texto del prólogo y de Pastos Verdes, aplicado

**Encargo:** aplicar los 6 cambios de la tabla de `docs/diseno/ciudades_y_lugares.md` §5.2, adoptada por el
coordinador en D-073 (incluido partir los dos globos del prólogo), sin mover las etiquetas de retrato y gesto de
animaciones; ajustar las pruebas que cuentan frases; capturas con ventana antes y después; comprobar la continuidad.
Copia `D:\Aethelgard_narrativa`, rama `area-narrativa`, desde `70ef723`.

### 1. Archivos y commits
| Commit | Qué |
|---|---|
| `453c794` | `pruebas/prueba_prologo_fotos.gd`: imprime cuántas líneas ocupa cada frase en la caja (solo informa) |
| `6e3bc57` | Los 6 cambios en `dialogos/prologo.dtl`, `pv_02.dtl`, `pv_07.dtl`, `pv_tilo.dtl` y `pv_tilo_fin.dtl`; `pruebas/prueba_prologo.gd` y `prueba_prologo_video.gd`, al día |
| (este) | Este informe |

- **Las etiquetas de animaciones** no se mueven ni se quitan:
  - al partir un globo, el gesto (`duda`, `preocupada`) se queda en el primero, que es la frase que lo pide;
  - el segundo no lleva gesto propio, así que ninguno se repite seguido;
  - los globos nuevos son de Lya (`lya: …`) y salen con su retrato «vivo». Ella conserva el foco porque sigue
    hablando: Dialogic solo cambia el resaltado al cambiar de interlocutor (observado en
    `addons/dialogic/Modules/Character/subsystem_portraits.gd`, final de `change_speaker`).
- **`prueba_prologo.gd`**, qué cambia y por qué:
  - espera 11 frases (`FRASES`, antes 9), en la pasada entera y en la deprisa: los dos globos partidos suman dos;
  - Lya tiene siete frases. El segundo globo de cada frase partida admite la pose del primero o el reposo
    (`duda|reposo` y `preocupada|reposo`). Sin etiqueta propia, sigue con la pose anterior hasta que
    `retrato_vivo.gd` la devuelve sola al reposo, 3,2 s después de pedirla. A la velocidad de la prueba se ve la cola
    (vio `duda, duda` y `preocupada, preocupada`); a ritmo de lectura ya está en reposo (§3, capturas del vídeo);
  - **nuevo:** cada frase cabe en dos líneas de la caja (`LINEAS_MAX`), contadas con `RichTextLabel.get_line_count()`
    en la caja de verdad. Imprime las poses de Lya y las líneas de cada frase.
- **`prueba_prologo_video.gd`:** espera 11 frases.
- **Repasadas, sin cambios:**
  - `prueba_dialogo_interfaz`: el texto nuevo de `pv_tilo` no tiene «Rosa» ni «flores»;
  - `prueba_ruta_alpha`: solo usa nombres de diálogos, objetivos y grupo;
  - `prueba_anim_pv_fotos` y `prueba_boton_prologo`: no cuentan frases.

### 2. Pruebas
- **Importación aislada,** antes de empezar:
  `D:\REBELUM_diagnostico\importaciones\narrativa_20261109_125053\importacion.log`. Salida 0, sin archivos nuevos.
- **Antes** (comprobado ejecutando, aislado, 12:54, sobre `70ef723` con la impresión de líneas):
  `D:\REBELUM_diagnostico\narrativa\2026-11-09\texto\2026-11-09_125422\`.
  - Sonda de líneas, SUPERADA.
  - `prueba_prologo_fotos`, con ventana: 9 frases, FALLOS 0.
- **Después** (comprobado ejecutando, aislado, 12:58, sobre lo que luego fue `6e3bc57`; después solo cambiaron
  comentarios): `...\texto\2026-11-09_125821\`.
  - SUPERADAS: `prueba_prologo`, `prueba_dialogo_interfaz`, `prueba_dialogo`, `prueba_ruta_alpha` y
    `prueba_boton_prologo`.
  - Con ventana y sin errores (MANUAL): `prueba_anim_pv_fotos` y `prueba_prologo_video`.
  - `prueba_prologo_fotos` salió FALLIDA en esa pasada **por el orden de mi lista**: `prueba_boton_prologo` deja una
    partida en la carpeta aislada (`partida_exp.save`) y, con partida, el prólogo no sale. En una pasada propia
    (`...\texto\2026-11-09_130120\`), sin errores y con 11 frases.
- **Batería completa** (comprobado ejecutando, aislado, sobre `6e3bc57`, de 13:09 a 13:17):
  **SUPERADAS 49 · FALLIDAS 0 · MANUALES 28 · NO SEGURAS 0**
  (`D:\REBELUM_diagnostico\narrativa\2026-11-09\bateria\2026-11-09_130914\resumen.md`).
  - Ninguna fallida, así que ningún fallo nuevo. Del historial: la última batería completa de la carpeta común
    (`D:\REBELUM_diagnostico\pruebas\2026-11-09_123210`, de otra copia) dio los mismos totales.
  - La partida real, su carpeta y el proyecto, sin cambios. Había otros Godot abiertos, de otras copias.
  - Las MANUALES son las de ventana y las manuales, que la batería no ejecuta. Las de diálogos con ventana se pasaron
    aparte (arriba).
- **Sondas temporales,** que no se confirman; copia en
  `C:\Users\G513\AppData\Local\Temp\claude\1e8b2791f134856b\01fe04af-8fa2-417a-a9ef-c72745be1c17\scratchpad\narrativa\t086\`.
  Estuvieron en `pruebas/` solo mientras corrían.
  - `sonda_narrativa_lineas.gd`: las líneas de cada frase del prólogo y de Pastos Verdes (44 antes y 46 después);
  - `sonda_narrativa_tilo.gd`: la continuidad de §4.

### 3. Evidencias
**Antes y después de cada frase.** Largo: caracteres visibles. Líneas: medidas en la caja con `get_line_count`, sin
ventana y con ventana (dan lo mismo).

| N.º (§5.2) | Archivo | Quién | Antes | Después | Largo | Líneas |
|---|---|---|---|---|---|---|
| 5 | `prologo.dtl:11` → `11-12` | Lya | Ese brazalete…[pause=0.5] He visto ese símbolo en los libros prohibidos del templo. Lo llamaban la «Llave del Confino». | **1:** Ese brazalete…[pause=0.5] He visto ese símbolo en los libros prohibidos del templo. **2:** Lo llamaban la «Llave del Confino». | 108 → 72 + 35 | 2 → 1 + 1 |
| 9 | `prologo.dtl:19` → `20-21` | Lya | Ten cuidado ahí fuera. Los Hollines ya no son solo sombras: ahora llevan hachas del Vacío. | **1:** Ten cuidado ahí fuera. **2:** Los Hollines ya no son solo sombras: ahora llevan hachas del Vacío. | 90 → 22 + 67 | 2 → 1 + 1 |
| 11 | `pv_02.dtl:4` | Kael | Bien. Por una vez, algo sale bien. | Y nadie me ha seguido. Por una vez, algo sale bien. | 34 → 51 | 1 → 1 |
| 39 | `pv_07.dtl:14` | Garon | Y esas huellas de hollín dan vueltas alrededor… sin pisarlas. | Huellas de hollín. Rodean las flores… sin pisarlas. | 61 → 51 | 1 → 1 |
| 43 | `pv_tilo.dtl:1` | Tilo | El viejo centinela del mirador lleva cuarenta años mirando la cascada. Saludadlo antes de seguir. | ¿Todavía aquí? El viejo os espera en el mirador. Saludadlo antes de cruzar. | 97 → 75 | 2 → 1 |
| 44 | `pv_tilo_fin.dtl:1` | Tilo | Buen camino, chicos. Y cuidad esa mecha: arde más que yo. | Buen camino, chicos. Y que no se os apague esa mecha. | 57 → 53 | 1 → 1 |

Las otras 38 frases no cambian. Ninguna, antes ni después, pasa de dos líneas.

**Lo que cabe en la caja** (medido el 2026-11-09):
- el hueco del texto es de 824 × 124 px. Una línea ocupa 51 px y dos, 102: una tercera (153) ya no cabría;
- en una línea caben unos 75 caracteres de este texto (70, 72 y 75 entran en una; 84 ya pasa a dos). Los 110
  caracteres de `prueba_ciudad_datos` (dos de unos 55) dejan margen: valen como objetivo de lectura, no como límite
  físico.

**Corrección a mi diseño.** En §5.2 escribí que el globo 5 (108 caracteres) «lo normal es que ocupe tres líneas».
Medido, ocupa dos (102 de 124 px). Lo que sí se ve en la captura de antes es el corte de línea: «… del templo. Lo /
llamaban la «Llave del Confino»». Parte justo la frase del nombre. Partido el globo, el nombre sale entero y solo.
El cambio se sostiene por eso, y porque el coordinador lo adoptó, pero ya no por espacio.

**Intenciones para animaciones.** No he añadido ni quitado etiquetas; la columna de la derecha es solo propuesta.
| Globo | Quién | Intención | Gesto o retrato que lleva hoy | Propuesta (decide animaciones con el coordinador) |
|---|---|---|---|---|
| Prólogo 5: «Ese brazalete… He visto ese símbolo…» | Lya | Lo reconoce y le cuesta decirlo | `duda` (ladea la cabeza; `lya_duda.png`) | = |
| Prólogo 6: «Lo llamaban la «Llave del Confino».» | Lya | Seria: que el nombre pese | Ninguno: sigue la pose de `duda` hasta volver sola al reposo | `firme` (asentimiento seco; Lya no tiene ilustración para él, solo es el movimiento) |
| Prólogo 10: «Ten cuidado ahí fuera.» | Lya | Preocupada, con cariño | `preocupada` (se encoge; `lya_preocupada.png`) | = |
| Prólogo 11: «Los Hollines ya no son solo sombras…» | Lya | Advierte, grave | Ninguno: sigue la pose de `preocupada` o ya en reposo | `inquieta` (se acerca a Kael) o nada |
| PV-02: «Y nadie me ha seguido. Por una vez, algo sale bien.» | Kael | Satisfecho; tienta a la suerte | `ligero` (mano en la cadera) | = |
| PV-07: «Huellas de hollín. Rodean las flores… sin pisarlas.» | Garon | Mira el suelo; desconfía | Sin retrato (Garon no tiene) | En 3D, mirar al suelo si hay clip |
| `pv_tilo`: «¿Todavía aquí? El viejo os espera…» | Tilo | Impaciente, con cariño | Sin retrato | = |
| `pv_tilo_fin`: «Buen camino, chicos…» | Tilo | Despedida | Sin retrato | = |

- Un globo corto deja ver la transición del que escucha: en la captura rápida de «Ten cuidado ahí fuera.» (22
  caracteres) Kael aún vuelve del paso de `decidido` (dura 2 s). A ritmo de lectura ya está en reposo
  (`despues_frase_10_a.png` del vídeo). No es un fallo.

**Capturas** (con ventana, 1280 × 720, la misma resolución lógica que en el móvil):
- `D:\REBELUM_diagnostico\narrativa\2026-11-09\texto\antes\`: las 9 frases (`antes_frase_NN.png`) y los registros;
- `...\texto\despues\`: las 11 (`despues_frase_NN.png`) y los registros;
- `...\texto\lamina_globos_partidos.png`: los dos globos, antes (uno) y después (dos), a tamaño real;
- `...\texto\lamina_prologo_completo.png`: el prólogo entero, antes y después, alineado por frase;
- a ritmo de lectura, 2,8 s por frase (`prueba_prologo_video`):
  `...\texto\2026-11-09_125821\prueba_prologo_video\` (`despues_frase_NN_a` y `_b`);
- PV-02, PV-03 y PV-05 en 3D con el texto nuevo: `...\texto\2026-11-09_125821\prueba_anim_pv_fotos\`.

### 4. Continuidad
**Lo que pide el encargo cuadra** (Kael solo hasta PV-03, Lya desde PV-03 y Garon desde PV-05):
| Escena | Grupo en ese momento (`prueba_ruta_alpha`) | Quién sale en el diálogo | Texto |
|---|---|---|---|
| PV-02 | Kael solo | Kael | «Y nadie me ha seguido»: es lo que cree Kael, y en PV-03 llega Lya |
| PV-03 | Lya se une al empezar la escena | Kael y Lya | = |
| PV-05 | Kael y Lya; Garon espera junto a Tilo y se une | Kael y Lya con retrato; Garon y Tilo, sin él | = |
| `pv_tilo` | Kael, Lya y Garon | Tilo | «os espera», «Saludadlo»: plural, cuadra |
| PV-06 y PV-07 | Kael, Lya y Garon | Kael y Lya con retrato; Garon sin él | «Rodean las flores»: Lya acaba de verlas |
| PV-14 y `pv_tilo_fin` | Kael, Lya y Garon | Tilo | «Tomad», «chicos», «se os apague»: plural |

- Comprobado ejecutando (aislado, 2026-11-09):
  - `prueba_ruta_alpha` SUPERADA: el grupo es nadie antes de PV-03, `["Lya"]` después y `["Lya", "Garon"]` desde
    PV-05;
  - `prueba_anim_pv_fotos` sin FALLO: quien habla en PV-02, PV-03 y PV-05 está en la escena 3D.
- Los hitos, las recompensas y los objetivos no cambian: `prueba_ruta_alpha` y `prueba_centinela`.
- **Canon** (leído en `D:\Aethelgard\docs\biblia\rebelum_biblia_narrativa_v2.md`, sin tocarlo; en esta copia no está):
  - la biblia cita por separado «Lo llamaban la "Llave del Confino".» y «Los Hollines ya no son solo sombras: ahora
    llevan hachas del Vacío.» (línea 121): ahora cada una es su propio globo, con las mismas palabras;
  - su §8.5 (línea 144) dice que Lya alcanza a Kael al amanecer en Pastos Verdes, sin cambiar el prólogo. «Y nadie me
    ha seguido» es lo que cree Kael justo antes, y cuadra;
  - nada de Érebo, de corazones ni de recuerdos; nada de Final Fantasy X.

**Hallazgo: se puede hablar con Tilo antes de PV-03.** Comprobado ejecutando (aislado, 13:07, sobre `70ef723`; no
depende del texto): `D:\REBELUM_diagnostico\narrativa\2026-11-09\continuidad\2026-11-09_130717\`.
- La sonda busca lo andable con las reglas de la región (`_altura_suelo`: paredes, pendientes, escalones y zonas
  prohibidas) sin entrar en el círculo de PV-03. Después, Kael recorre ese camino de verdad, con un destino tocado.
- Llega junto a Tilo pasando a 4,0 m del punto de PV-03 (el radio es 3,5). El camino va paralelo al sendero, un poco
  al sur.
- Sale «Hablar con Tilo» y, al pulsarlo, empieza **PV-05 sin PV-03**: Lya habla en el diálogo sin estar en el grupo
  ni en la escena 3D, y Garon se une antes que ella. El objetivo sigue en «Sigue el camino.»; si se vuelve por el
  sendero, PV-03 sale después, con Garon ya en el grupo.
- La causa (observada en el código): en `zonas3d/pastos_verdes_3d.gd`, `_comprobar_cerca()` deja hablar con Tilo
  siempre, y en `_accion()` la rama de Tilo no mira `pv_03`. El rombo sí lo exige.
- Propuesta en §6. No he tocado `zonas3d/`.
- **Menor, solo observado en el código:** en `_accion()`, PV-14 tampoco exige `pv_07`. En la práctica PV-07 salta al
  volver del combate junto a la estatua (`prueba_ruta_alpha`, paso 15), así que no lo he visto pasar.

### 5. Límites y propuestas pendientes de decisión
- **El globo 5 cabía en dos líneas** (ver «Corrección», §3). Si el coordinador adoptó partirlo por el espacio, puede
  revisarlo. Mi recomendación es dejarlo partido por el corte «Lo / llamaban» y por el peso del nombre.
- **Gestos de los globos nuevos:** propuestos en la tabla de intenciones (`firme` en el 6 e `inquieta` en el 11). No
  los he puesto: las etiquetas se acuerdan con el coordinador.
- **Sin ver en el Redmi.** Las capturas son del PC a 1280 × 720, la resolución lógica del juego (`canvas_items`), así
  que el corte de línea debería ser el mismo. Falta verlo en el teléfono.
- Sin cambiar del diseño (§5.3), y lo decide el responsable de `progreso.gd`: el texto del detalle `pastos_estela`.

### 6. Siguiente paso y cambios en archivos de otros
- **`zonas3d/pastos_verdes_3d.gd`** (de quien lleve la región), para que PV-05 no salga antes que PV-03. En
  `_accion()`, rama `"tilo"`, antes de `if not P.hito("pv_05"):`:
  ```gdscript
  if not P.hito("pv_03"):
      _escena_mision("pv_03")          # Lya llega antes de hablar con Tilo: nunca PV-05 sin ella
  elif not P.hito("pv_05"):
  ```
  - Con eso, al pulsar «Hablar con Tilo» sin PV-03, Lya llega corriendo como siempre y, al volver a pulsar, sale
    PV-05.
  - Opcional, por la misma razón: `elif not P.hito("pv_07"): _empezar_dialogo("pv_tilo")` antes de la rama de PV-14.
  - Para probarlo, `prueba_ruta_alpha` podría hablar con Tilo antes de PV-03 y comprobar que sale PV-03.
- **`pruebas/lista_pruebas.txt`** (del coordinador), en la nota de `prueba_prologo`: «entero (9 frases, una
  pulsación por frase,» → «entero (11 frases, una pulsación por frase, cada una en dos líneas de la caja como
  mucho,». Es solo la descripción; no cambia cómo se ejecuta.
- **`docs/diseno/ciudades_y_lugares.md`** (mío, fuera de este encargo): corregir en §5.2 el motivo del n.º 5 y en
  §5.1 la medida (unos 75 caracteres por línea). Lo hago cuando se me asigne.
- **Prueba nueva, propuesta:** convertir `sonda_narrativa_lineas.gd` en `prueba_textos_caja`, que recorra todos los
  `.dtl` y falle si una frase pasa de dos líneas. Necesitaría su línea en `lista_pruebas.txt`.
- **Siguiente paso de narrativa:** con la decisión sobre los gestos, si animaciones los pone, repetir
  `prueba_prologo` (espera `duda|reposo` y `preocupada|reposo` en los segundos globos: habría que ajustarla).

## 2026-11-09, 18:10 — Personalidad: el arte de Oakhaven enganchado, la voz de los héroes y sus comentarios al explorar

**Encargo:** (1) enganchar el arte 2D de Oakhaven de gráficos en `ciudad_oakhaven.gd`, con los muñecos de la posadera,
Bastián, Doña Encina y Albar, sin romper vecinos, misiones, posada, cofres ni partidas antiguas; (2) guía de voz de
Kael, Lya y Garon y pulir solo lo que la contradiga; (3) comentarios breves de los héroes al explorar, enganchados donde
haya un punto seguro y el resto documentado, coordinando la intención de cada línea con animaciones. Copia
`D:\Aethelgard_narrativa`, rama `area-narrativa`, desde `01eca69`, con `integracion-experimental` (`eb8bd94`) unida
antes de empezar.

### 1. Archivos y commits
| Commit | Qué |
|---|---|
| `d590693` | Unión `--no-ff` de `integracion-experimental` @ `eb8bd94` (sin conflictos) |
| `85a8fb3` | `ciudad_oakhaven.gd` con el arte de verdad; `pruebas/prueba_oakhaven_ciudad_arte.gd` (nueva); `prueba_oakhaven.gd` al día; una línea en `lista_pruebas.txt` |
| `34aa447` | `docs/narrativa/voces_heroes.md` (nueva) y una línea de Lya en `dialogos/pv_07.dtl` |
| `1723941` | `dialogos/comentarios.gd` (nuevo), su enganche en `ciudad_oakhaven.gd`, `pruebas/prueba_comentarios.gd` (nueva), `prueba_oakhaven_fotos.gd` (captura 19) y una línea en `lista_pruebas.txt` |
| (este) | Este informe |

Sin confirmar y ajeno: `aethelgard/pruebas/prueba_orden_pv03.gd.uid`, que generó la importación (la prueba es de otra
área). Sin push.

**1. El arte en la ciudad** (observado en el código y comprobado ejecutando). La ciudad ya pedía el arte con el contrato
`crear_pieza`, así que con el módulo de gráficos en su sitio ya salían sus edificios; faltaba casi todo lo demás, y había
tres fallos que solo se ven con el arte de verdad:
- **Tejados sobre las calles.** Las casas se repartían al azar (de 3 a 6 × 3 o 4) y en 3/4 una casa tapa unas siete
  casillas al norte: la plaza y varias calles quedaban bajo tejados (`antes\2_plaza.png`, `antes\4_ciudad_entera.png`).
  Además, las de 3 de alto no tienen dibujo y salían con el tejado provisional. Ahora, si el módulo trae `RELLENO`,
  las casas, farolas y tendederos son los suyos (31 casas, 16 farolas y 2 tendederos, con muro invisible debajo) y el
  resto es jardín: setos y flores al azar, y los árboles solo en los huecos de `JARDINES` de gráficos que caen en jardín (25).
- **Dibujos duplicados.** Lo que ya pinta un lugar (el barril, el letrero del cuervo, los tres faroles y la escalera
  de la ronda, la puerta de la torre, la grieta, el tablón, el atril, el altar de las velas, la raíz cortada, el sello y
  el tapiz) salía también en provisional encima, con las farolas de `zona.gd` y su luz 2D en la ronda
  (`antes\11_ronda_encendida.png`). Ahora es un punto vacío (`PINTADO_EN`), y se sigue usando desde su casilla.
- **Faroles de la ronda cruzados.** El dibujo numera sus faroles de norte a sur y la partida, de sur a norte
  (`oak_farol_1` está en y = 38,5): al encender el 1 se encendía en el dibujo el del otro extremo. Ahora se emparejan
  por su sitio (`_farol_del_dibujo`); la prueba lo comprueba con los tres.
- Además: el destello del cofre de las raíces es el del Árbol (`cofre_raices_abierto`) y ya no lleva el provisional
  encima; sin hierba alta; la luz de Kael es un farol de mano (`LUZ_JUGADOR`); y los cuatro vecinos llevan su muñeco
  propio sin tinte (`muneco_de`). Los otros cuatro (Aldric, Selene, Pip y Rosa) no cambian.
- **Sin tocar:** el trazado (se pisa lo mismo: lo comprueban `prueba_oakhaven`, apartado 2, y la prueba nueva), los
  vecinos y sus diálogos, misiones, posada, cofres, notas, guardado y los archivos de gráficos. Con el módulo falso de
  las pruebas (sin `RELLENO`, sin anclas) todo sigue como antes.

**2. Las voces.** Repasadas todas las líneas de los tres héroes (prólogo, PV-02 a PV-07, PV-14 y las tres escenas de la
posada). Casi todas encajan ya con la voz de la biblia v2 (§2.5). Solo cambia una (§3).

**3. Los comentarios.** `dialogos/comentarios.gd` guarda seis momentos, con una frase de cada héroe (21 frases con dos
respuestas) y, para cada una, su intención, su gesto de retrato y su espera 3D de animaciones. Enganchados en Oakhaven:
al llegar, tras abrir un cofre y al quedarse quieto. Los demás quedan listos (§6).

### 2. Pruebas
- **Importación aislada** tras la unión: `D:\REBELUM_diagnostico\importaciones\narrativa_20261109_172749\` (salida 0).
- **Antes de cambiar nada** (aislado, sobre `d590693`): `prueba_oakhaven`, `prueba_oakhaven_arte`,
  `prueba_restaurar_escenas` y `prueba_guardado_protegido`, SUPERADAS
  (`D:\REBELUM_diagnostico\narrativa\2026-11-09\oakhaven_arte\2026-11-09_172830\resumen.md`).
- **Con el arte enganchado** (aislado, sobre lo que fue `85a8fb3`): 12 de 12 SUPERADAS (`prueba_oakhaven`,
  `prueba_oakhaven_ciudad_arte`, `prueba_oakhaven_arte`, `prueba_restaurar_escenas`, `prueba_guardado_protegido`,
  `prueba_ciudad_datos`, `prueba_foco`, `prueba_escenas`, `prueba_musica`, `prueba_precalentado`, `prueba_cofre` y
  `prueba_guardado`): `...\oakhaven_arte\2026-11-09_173928\resumen.md`.
- **Con los comentarios** (aislado, sobre lo que fue `1723941`): 7 de 7 SUPERADAS (`prueba_ruta_alpha`,
  `prueba_dialogo`, `prueba_dialogo_interfaz`, `prueba_prologo`, `prueba_oakhaven`, `prueba_oakhaven_ciudad_arte` y
  `prueba_comentarios`): `D:\REBELUM_diagnostico\narrativa\2026-11-09\comentarios\2026-11-09_174733\resumen.md`.
- **Batería completa** (aislado, sobre `1723941`): **SUPERADAS 57 · FALLIDAS 2 · MANUALES 31 · NO SEGURAS 0** (`D:\REBELUM_diagnostico\narrativa\2026-11-09\bateria_voces\2026-11-09_174927\resumen.md`). Partida real y carpeta real, sin cambios. «Proyecto: cambiado» es este informe, que escribí mientras corría (`git status`: solo `narrativa.md`).
  - **Las dos FALLIDAS no son de este trabajo:** `prueba_mando` y `prueba_teclado`, apartado 4, «Intro / A junto a Tilo no abre el diálogo». Hablan con Tilo antes de PV-03 y, desde `c3f5692` (integración: hablar con Tilo antes de PV-03 empieza PV-03), eso abre la escena de Lya y no el diálogo de Tilo. No toco Pastos Verdes ni esas pruebas. Arreglo propuesto en §6.
- **Pruebas nuevas:**
  - `prueba_oakhaven_ciudad_arte` (auto): módulo, ambiente, hierba y luz; las 31 casas del RELLENO con muro invisible y
    sus 16 farolas; **ninguna luz 2D en el mundo** salvo la de Kael; solo se pisa lo que es calle, plaza o patio; nada
    pintado dos veces y todo en su casilla; muñecos y tintes; los tres faroles de la ronda emparejados por su sitio; el
    destello del cofre de las raíces (se ve cerrado, se apaga al abrirlo); árboles solo en jardín. Imprime el coste:
    **2857 nodos en el mundo, 65 piezas de gráficos y unos 1,3-1,5 s de entrada** en el PC (con la carga de la escena;
    sin medir el antes con el mismo método, y sin medir en el Redmi).
  - `prueba_comentarios` (auto): una frase de cada héroe por momento; cada frase en una o dos líneas de su caja
    (medidas con la fuente de verdad: 13 de una línea y 8 de dos); 70 letras como mucho; gestos y esperas de la
    lista; ninguna palabra vetada (Érebo, corazón, recuerdo, memoria y nombres de Final Fantasy X, por palabra entera);
    solo hablan los del grupo y la respuesta solo si está quien responde; turnos y sin repetir; en Oakhaven, el de
    llegar, el del cofre y el de estar quieto, sin tapar el botón de examinar, y un diálogo lo quita; los hitos no
    cambian.
- **Capturas con ventana** (aislado, 1280 × 720): `prueba_oakhaven_fotos`, antes y después (§3).
- **Ojo, del ejecutor:** en la primera pasada con `-Manual`, `prueba_oakhaven_fotos` paró tras 5 capturas sin error
  (16 s; antes de mis cambios). Lanzada a mano con datos aislados, hace las 19 en 45 s. No lo he investigado más.

### 3. Evidencias
**Capturas** en `D:\REBELUM_diagnostico\oakhaven\2026-11-09_arte\`:
- `antes\` (sobre `d590693`, el arte ya unido pero sin enganchar) y `despues\` (sobre `1723941`): las mismas 18 tomas
  de `prueba_oakhaven_fotos` (entrada, plaza, norte, ciudad entera, diálogo, barrio del Cuervo, callejón, Patio de las
  Velas, colina, ronda apagada y encendida, raíces, detrás del Árbol, mercado, Diario, posada y su escena, lavanda en
  Pastos Verdes 3D) y, solo en `despues\`, `19_comentario.png` (Kael: «¿Para mí? No hacía falta.»).
- Láminas, antes a la izquierda y después a la derecha: `lamina_antes_despues_1.png` (plaza, ciudad entera, barrio
  del Cuervo), `_2.png` (ronda apagada y encendida, raíces) y `_3.png` (diálogo, Patio de las Velas, mercado).
- Lo que se ve (revisado a ojo en el PC): la plaza y las calles despejadas, con el tablón y la fuente de gráficos;
  la fachada de la taberna con el cuervo y la posadera con su vestido vino; la ronda solo con sus faroles; Doña Encina
  con su muñeco junto a las raíces, ya sin una casa delante; jardines con setos, flores y árboles entre las casas.

**Antes y después de cada frase cambiada** (medidas como en T-086):
| Archivo | Quién | Antes | Después | Por qué |
|---|---|---|---|---|
| `pv_07.dtl:8` | Lya | Kael, te está mirando. | Kael… te está mirando. | Su marca: «Kael…» cuando se preocupa (biblia v2 §2.5). Mismo gesto (`preocupada`), mismas letras |

Ninguna otra línea de los tres contradice su voz. Las que podían parecerlo y se quedan:
- Garon, «Por eso. Fuera de la muralla no os puedo proteger.» (`pv_05`): es su frase más larga, y está bien que lo sea:
  es la que le duele (así lo dice la guía).
- Lya, «Buenas noches, Garon. Buenas noches, cama grande.»: es humor, pero tierno y fuera de peligro, como pide su voz.

**Guía de voz:** `docs/narrativa/voces_heroes.md`.

**Intenciones de los comentarios (para animaciones).** Ninguna lleva gesto de retrato en pantalla (en 2D no hay
retrato): la columna «gesto» vale si un día salen con él; «espera», el clip de `animaciones/esperas/<héroe>.res` que le
pega en 3D (los nombres son los de `esperas.py` de animaciones, aún sin confirmar en su rama).
| Momento | Quién | Frase | Intención | Gesto | Espera 3D |
|---|---|---|---|---|---|
| Llegar a Oakhaven | Kael | Oakhaven. Huele a pan y a mecha recién encendida. | Alivio de volver; lo dice como quien no lo dice | `ligero` | `espera_vigilar` |
| | Lya | Mira cuántos faroles. Aquí la niebla lo tiene difícil. | Cálida; se tranquiliza a sí misma | — | `espera_cetro` |
| | Garon | Puerta, muralla, guardia. Todo en su sitio. | Pasa revista sin pararse | `firme` | `espera_hombros` |
| Lugar nuevo | Kael | Sitio nuevo. Que alguien apunte que llegué primero. | Bravuconería de broma; curiosidad | `ligero` | `espera_vigilar` |
| | Lya | Nunca había estado aquí. Quédate cerca, ¿vale? | Curiosa y protectora a la vez | `inquieta` | `espera_pelo` |
| | Garon | Dos salidas. Recordadlas. | Instinto de soldado | `firme` | `espera_hombros` |
| Llegar a la Garganta | Kael | La Garganta del Diablo. Con ese nombre, seguro que es acogedora. | Ironía para quitarse el miedo | `ligero` | `espera_empunadura` |
| | Lya | Se oye el agua desde aquí… Id despacio. | Atenta; pide prudencia sin dramatizar | `preocupada` | `espera_cetro` |
| | Garon | Cornisa estrecha. En fila. Yo, delante. | Órdenes cortas; se pone en el peligro | `firme` | `espera_apoyarse` |
| Cascada de la Garganta | Kael | Vale. Lo admito. Es precioso. | Se le escapa el asombro y lo despacha rápido | `sorpresa` | `espera_vigilar` |
| | Lya | Quédate un momento. Hay cosas que no se ven dos veces. | Contemplativa; le pide que lo guarde | — | `espera_pelo` |
| | Garon | Bonita. Y resbaladiza. Lejos del borde. | Lo admira a su modo y protege | `firme` | `espera_espalda` |
| Cofre | Kael | ¿Para mí? No hacía falta. → Garon: No era para ti. | Broma y contento de verdad → seco, le sigue el juego | `ligero` | `espera_brazalete` → `espera_hombros` |
| | Lya | Lo apunto yo. Tú luego no te acuerdas. | Ordenada, con cariño burlón | `decidida` | `espera_cetro` |
| | Garon | Mira el fondo. Siempre queda algo. | Consejo de veterano | — | `espera_apoyarse` |
| Quietos | Kael | ¿Seguimos? El mundo no se explora solo. → Lya: Kael… respira. | Impaciente → le frena con ternura | `decidido` → `duda` | `espera_impaciencia` → `espera_pelo` |
| | Kael | Este brazalete pesa más cuando no hago nada. | Lo que le pesa, dicho de lado | `brazalete` | `espera_brazalete` |
| | Lya | Esta flor no viene en ningún libro. Me la apunto. | Curiosidad de estudiosa | `duda` | `espera_flor` |
| | Garon | Parar enfría los hombros. Andando. | Ni el descanso le gusta largo | `firme` | `espera_hombros` |

- **Para animaciones:** cuando un héroe 3D haga una espera, puede pedir el comentario del momento «quieto» de ese
  héroe (`Comentarios.MOMENTOS["quieto"]`, filtrando por «quien» y por «espera») para que frase y gesto vayan juntos;
  o al revés, al salir un comentario, lanzar su «espera». Propuesta: la espera empieza y, a 0,6 s, sale la frase.

### 4. Continuidad
- **Quién habla:** `Comentarios.elegir()` solo elige entre `grupo.gd activos()`: Kael solo hasta PV-03, Lya desde
  PV-03 y Garon desde PV-05. Una respuesta solo sale si quien responde está. Comprobado ejecutando
  (`prueba_comentarios`, apartados 2 y 3: en Oakhaven con Kael y Lya, nunca habló Garon).
- **Partida:** los comentarios no escriben nada en la partida; lo dicho se apunta en Engine «comentarios_dichos» (un
  diccionario de textos, no un recurso), que se pierde al cerrar el juego. Los hitos no cambian (comprobado).
- `prueba_ruta_alpha`, `prueba_prologo`, `prueba_dialogo` y `prueba_dialogo_interfaz` SUPERADAS con el cambio de PV-07.
- **Canon:** nada de Érebo ni de lo que guarda; nada de Final Fantasy X; nada del pasado que la biblia v2 solo propone
  (la guía lo marca como propuesta y no se dice en pantalla). «Este brazalete pesa más cuando no hago nada» no añade
  nada al canon: el brazalete ya es un misterio en el prólogo.

### 5. Límites y propuestas pendientes de decisión
- **Sin ver en el Redmi** (pendiente en Redmi): el arte con las 31 casas, la luz y el coste (2857 nodos en el mundo;
  la memoria de vídeo la estimó gráficos en unos 31,6 MB sin comprimir); y si la caja del comentario (26 px) se lee bien
  en el teléfono.
- **Árboles:** salen de `JARDINES` de la maqueta de gráficos (`oakhaven_arte/maqueta_oakhaven.gd`), porque el módulo no
  los trae. Propuesta en §6.
- **Comentarios solo por sesión:** al volver a abrir el juego se pueden repetir. Guardarlos en la partida sería una
  clave nueva: lo decide el coordinador (no hace falta para que funcionen).
- **Sin sonido** al salir un comentario: es a propósito (no compite con los avisos). Si sonido quiere un susurro de
  página, el punto es `Comentarios.mostrar()`.
- **Propuesta de texto** (no aplicada): ninguna más en los diálogos de los tres.

### 6. Siguiente paso y cambios en archivos de otros
- **Gráficos** (`ciudades/oakhaven_piezas.gd`): pasar `JARDINES` de la maqueta al módulo (la ciudad ya lo busca ahí
  primero) y, si quiere, renombrar los faroles de la ronda de sur a norte (la ciudad funciona igual con los dos
  órdenes).
- **Garganta 3D** (`zonas3d/garganta_3d.gd`, de quien lleve la Garganta), con
  `const Comentarios := preload("res://dialogos/comentarios.gd")`:
  - al final de `_ready()`: un temporizador de 2,5 s que llame a `_comentar("llegar:garganta")`;
  - en `_process`, la primera vez que Kael quede a menos de unos 12 m de la línea de la cascada (la de
    `Sonido.fuente_linea(... "cascada_grande" ...)`): `_comentar("cascada_garganta")`;
  - al final de `_abrir_cofre()`: `_comentar("cofre")` con 1,2 s de retraso;
  - `_comentar(m)`: si no está `ocupado()`, `var c := Comentarios.elegir(m)` y, si no está vacío,
    `Comentarios.mostrar(<su CanvasLayer de interfaz>, c)`.
- **Pastos Verdes 3D** (`zonas3d/pastos_verdes_3d.gd`): lo mismo para «cofre» y «quieto» (no para llegar: ya lo dice
  PV-02). Con las esperas de animaciones, «quieto» puede salir del héroe que hace la espera.
- **`zona.gd`** (del coordinador): al entrar por primera vez en un lugar (`_ready`, si el lugar no estaba visitado) y
  en `_abrir_cofre`, las mismas dos llamadas («llegar:lugar_nuevo» y «cofre»).
- **Animaciones:** confirmar los nombres de las esperas (los tomé de su `esperas.py`, sin confirmar en su rama) y la
  propuesta de sincronía de §3.
- **Coordinador, `prueba_mando` y `prueba_teclado`** (apartado 4): antes de hablar con Tilo, `P.poner_hito("pv_03")` y `G.unir("Lya")` (o pasar por el punto de PV-03), o aceptar que salga PV-03; con eso vuelven a abrir `pv_tilo`/PV-05 con Intro / A.
- **Coordinador:** las dos líneas nuevas de `lista_pruebas.txt` (`prueba_oakhaven_ciudad_arte` y
  `prueba_comentarios`).
- **Siguiente paso de narrativa:** cuando se enganchen la Garganta y Pastos Verdes, repasar con capturas que el
  comentario no tape nada en 3D; y, con la decisión del usuario sobre la biblia v3, ampliar los momentos (al ganar un
  combate difícil, al ver la ciudad del cielo de PV-07) con la misma guía.

## 2026-11-09, 18:40 — Comentarios en las zonas 2D y charlas de posada

**Encargo del coordinador:**
1. Enganchar en `zona.gd` el comentario al llegar a un lugar nuevo y el del cofre, con su prueba.
2. «Charlas de posada»: de 4 a 6 conversaciones breves y opcionales entre los héroes. Se desbloquean por hitos que ya
   existen y salen al descansar en la posada de Oakhaven: una por descanso, la más nueva sin ver. Temas: cómo se
   conocieron, una broma recurrente, un miedo de cada uno y la mano de Kael sin revelar nada nuevo.
3. Que lo visto se guarde de forma compatible con las partidas antiguas, con una prueba de partida antigua sin la clave.

**Decisiones del coordinador que se aplican aquí:**
- los comentarios se quedan por sesión;
- no se tocan `pastos_verdes_3d.gd` ni `garganta_3d.gd`.

Copia `D:\Aethelgard_narrativa`, rama `area-narrativa`, desde `8552a6e`. A mitad de la tanda uní la integración
`cb9d51d`, que ya trae mi rama, y al final `a330d77`, como pidió el coordinador.

### 1. Archivos y commits
| Commit | Qué |
|---|---|
| `a884ef3` | `zona.gd`: el comentario al llegar y el del cofre. `ciudad_oakhaven.gd` usa lo de `zona.gd`. `dialogos/comentarios.gd`: los enganches, al día. `prueba_comentarios.gd`: apartado 4, zona 2D |
| `9915507` | Las seis charlas (`dialogos/oakhaven/charlas/*.dtl`). En `ciudades/oakhaven.gd`, la constante `CHARLAS_POSADA` y las funciones que eligen y marcan. `ciudad_oakhaven.gd`, al despertar. `pruebas/prueba_charlas_posada.gd` (nueva). `prueba_oakhaven_fotos.gd`, capturas 20 y 21 |
| `3e9d6ae` | La línea de `prueba_charlas_posada` en `lista_pruebas.txt` |
| `12b7efe` | Unión `--no-ff` de `integracion-experimental` @ `cb9d51d`. Aparté a la carpeta temporal de mi área el `prueba_orden_pv03.gd.uid` suelto, igual que el confirmado; sin conflictos |
| `a4c5829` | Los `.uid` de mis archivos nuevos (los generó la importación) |
| `6958491` | Unión `--no-ff` de `a330d77`: solo trae `prueba_integridad.gd.uid`, igual al que tenía suelto (aparté el mío a la carpeta temporal de mi área) |
| (este) | Este informe |

**Sin confirmar, a la espera del coordinador:**
- `aethelgard/project.godot`: la importación apuntó las seis charlas en `dialogic/directories`. Funciona igual sin
  ello, porque se abren por su ruta.

**Un error mío, ya deshecho.** Una orden de PowerShell con una ruta relativa creó un archivo vacío,
`D:\Aethelgard_alpha\lista_pruebas.txt` (0 bytes, 18:12), en la copia de integración. No se usó y lo borré al momento:
- comprobado que no existe;
- `git status` de esa copia, como antes salvo lo suyo.

No toqué nada más allí. Desde entonces uso solo rutas absolutas en las escrituras.

**1. Comentarios en `zona.gd`** (observado en el código y comprobado ejecutando):
- **Al llegar:** la primera vez en la sesión que se entra en un lugar. Se apunta con «@lugar:N» en Engine
  «comentarios_dichos»; no se guarda en la partida, como decidió el coordinador.
  - En un lugar cualquiera sale «llegar:lugar_nuevo»; en la Garganta 2D, «llegar:garganta»; en Oakhaven,
    «llegar:oakhaven».
  - Para no tocar `garganta.gd`, la Garganta se reconoce por el nombre del lugar.
- **Tras abrir un cofre:** 1,2 s después del premio.
- **Cuándo no sale:** con un diálogo, la tienda, el menú o la salida en marcha, el comentario espera; si empieza un
  diálogo, el que esté en pantalla se quita.
- Una ciudad puede cambiar el momento (`_momento_llegada()`) y lo que la tiene ocupada (`_ocupado_para_comentar()`).
- La lógica que tenía Oakhaven pasa a `zona.gd`. La ciudad conserva solo lo de quedarse quieto. Funciona igual
  (`prueba_comentarios`, apartados 3 y 4).

**2. Charlas de posada:**
- **Cuándo salen.** Al descansar en el Cuervo, en lugar de la escena corta de siempre, sale la charla más nueva sin
  ver de las desbloqueadas. Una charla está desbloqueada si se cumple su hito y todo su grupo está en el grupo
  activo.
- **El orden.** «La más nueva» se mide por el orden de la lista, que sigue la historia; no se guarda cuándo se
  desbloqueó.
- **Sin charlas nuevas,** sale la escena de siempre.
- **Por qué son opcionales.** Solo salen si se descansa (pagando o gratis) y se pueden pasar como cualquier diálogo.
  No cambian hitos, misiones ni nada de la partida, salvo apuntar que se han visto.

| Id | Hito (ya existe) | Grupo | Tema | Frases |
|---|---|---|---|---|
| `charla_conocerse` | `pv_03` | Kael, Lya | Cómo se conocieron | 6 |
| `charla_cama_grande` | `pv_05` | Kael, Lya, Garon | La broma de la cama grande (sigue la de `oak_posada_grupo`) | 6 |
| `charla_miedo_garon` | `pv_06` | Kael, Lya, Garon | El miedo de Garon | 6 |
| `charla_mano` | `pv_07` | Kael, Lya, Garon | La mano del brazalete | 6 |
| `charla_miedo_lya` | `mecha_tilo` | Kael, Lya | El miedo de Lya | 5 |
| `charla_miedo_kael` | `oak_faroles` | Kael, Lya | El miedo de Kael | 5 |

- **Guardado.** Lo visto se guarda como estado de la ciudad: `Progreso.poner_estado("oakhaven", "charla_…")`, dentro
  de «mazmorras». Esa clave ya está en la partida y ya la usa Oakhaven (la noche gratis, los faroles…).
  - Es opcional y vale `false` si falta: una partida antigua sin «mazmorras», o con la ciudad pero sin ninguna
    «charla_…», carga igual y la charla sale sin ver.
  - Así no hace falta una clave nueva en `progreso.gd`, que no es mío, y cumple lo que se pidió: opcional y con
    valor por defecto.
  - Comprobado ejecutando (`prueba_charlas_posada`, apartado 5).
- **«La mano marcada de Kael».** En el canon no hay ninguna marca en su mano: ni en la biblia v2, ni en la v3, ni en el
  código. Lo traté como la mano del brazalete:
  - Garon ve que la esconde cuando brilla. Que brille ya se ve en el juego: brilla cerca de los detalles sin ver.
  - Kael dice que no le duele y no sabe más.
  - No hay marca nueva ni revelación. Si el coordinador quería otra cosa, se cambia la charla.

### 2. Pruebas
- **Importación aislada** tras la unión: `D:\REBELUM_diagnostico\importaciones\narrativa_20261109_181321\` (salida 0).
- **`prueba_comentarios`** (comprobado ejecutando, aislado), con un apartado nuevo, el 4, en el Gran Bosque Verde: al
  llegar sale una frase de «llegar:lugar_nuevo» de alguien del grupo (Lya); tras abrir un cofre, una del cofre
  (Kael); al volver a entrar, ninguna de llegada.
- **`prueba_charlas_posada`** (nueva, auto, comprobado ejecutando y aislado), FALLOS 0:
  - los datos: 6 charlas, con hitos que existen, grupos y diálogos sin huérfanos;
  - el texto: de 5 a 6 frases; solo habla el grupo y hablan todos; 75 letras la más larga; una intención por frase;
    gesto de Kael y Lya de la lista; ninguna palabra vetada; sin comentarios, porque Dialogic los imprime en la
    consola;
  - cada charla, recorrida entera con Dialogic;
  - cuál toca: con PV-03 a PV-07, sale `charla_mano`, `charla_miedo_garon`, `charla_cama_grande` y
    `charla_conocerse`, y después la escena de siempre;
  - con Kael solo, ninguna;
  - las partidas antiguas;
  - en la ciudad: la primera noche sale `charla_conocerse.dtl` y la segunda, `oak_posada_lya.dtl`.
- **Tras los enganches de `zona.gd`,** 9 de 9 superadas
  (`D:\REBELUM_diagnostico\narrativa\2026-11-09\zona_comentarios\2026-11-09_180652\resumen.md`): `prueba_escenas`,
  `prueba_foco`, `prueba_cofre`, `prueba_guardado`, `prueba_guardado_protegido`, `prueba_restaurar_escenas`,
  `prueba_oakhaven`, `prueba_oakhaven_ciudad_arte` y `prueba_comentarios`. Marcó «proyecto cambiado» porque yo editaba
  `oakhaven.gd` mientras corría; la batería completa de abajo es la limpia.
- **Batería completa** (aislada, sobre `a4c5829`): **SUPERADAS 60 · FALLIDAS 0 · MANUALES 32 · NO SEGURAS 0** (`D:\REBELUM_diagnostico\narrativa\2026-11-09\bateria_charlas\2026-11-09_181401\resumen.md`). La partida real, su carpeta y el proyecto, sin cambios. `prueba_mando` y `prueba_teclado` vuelven a pasar (las arregló el coordinador en `9f94601`, que llegó con `cb9d51d`).
- **Tras unir `a330d77`** (`6958491`; solo trae un `.uid` igual al que tenía suelto): `prueba_charlas_posada`, `prueba_comentarios`, `prueba_integridad` y `prueba_oakhaven`, SUPERADAS (`...\tras_a330d77\2026-11-09_182338\resumen.md`).
- **Capturas con ventana** (aislado, 1280 × 720, sobre `6958491`): `D:\REBELUM_diagnostico\oakhaven\2026-11-09_arte\charlas\20_charla_posada.png` y `21_charla_posada_2.png` (las dos primeras frases de «Cómo se conocieron», con los retratos vivos: Lya pensativa y Kael con la mano en la cadera), además de `19_comentario.png`. Las dos primeras veces el guion salió a los 6-7 s sin error y con código 0; a la tercera, todo bien. No he encontrado la causa en el juego: lo apunto por si vuelve a pasar.

### 3. Evidencias: texto, intención y gesto de cada frase
Kael y Lya llevan el gesto (`extra_data`, retrato «vivo») que se pide justo antes de su frase. Garon no tiene retrato:
para él, solo la intención (en 3D, cuando haya clip). Las intenciones también están en `CHARLAS_POSADA`, en su orden.

**Cómo se conocieron** (`charla_conocerse`, Kael y Lya, desde PV-03):
| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Lya | ¿Te acuerdas de la primera vez que hablamos? | Lo saca con una sonrisa, a ver qué recuerda él | `duda` |
| 2 | Kael | Me quitaste una manzana de la mano. Sin presentarte. | Ofendido de broma | `ligero` |
| 3 | Lya | Estaba verde. Te habrías pasado la noche con dolor de tripa. | Se defiende con datos | `decidida` |
| 4 | Kael | Y luego te la comiste tú. | La pilla | `sorpresa` |
| 5 | Lya | …Alguien tenía que comprobarlo. Desde entonces vigilo lo que comes. | Digna, y tierna en la segunda frase | `firme` |
| 6 | Kael | Pues sigue vigilando. Las manzanas de por aquí no son de fiar. | Le da las gracias sin dárselas | `ligero` |

**La broma de la cama grande** (`charla_cama_grande`, los tres, desde PV-05):
| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Kael | Garon, cada noche dices «duermo en el suelo». | Abre el juicio, encantado | `ligero` |
| 2 | Garon | Y duermo en el suelo. | Impasible | — |
| 3 | Lya | Esta mañana estabas en la cama grande. Abrazado a la almohada. | Aporta la prueba, sin piedad y con cariño | `duda` |
| 4 | Garon | Comprobaba el colchón. | Ni un parpadeo | — |
| 5 | Kael | ¿Toda la noche? | No se lo cree | `sorpresa` |
| 6 | Garon | Es un colchón grande. | Cierra el caso | — |

**El miedo de Garon** (`charla_miedo_garon`, los tres, desde PV-06):
| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Lya | Garon… en la estatua te pusiste delante sin pensarlo. | Se lo agradece riñéndole | `preocupada` |
| 2 | Garon | Lo pensé. Rápido. | Corrige, seco | — |
| 3 | Kael | ¿Y nunca te da miedo nada? | Curiosidad de verdad, sin broma | `duda` |
| 4 | Garon | Una cosa. Contar al volver y que falte alguien. | Lo dice una vez y no lo repetirá | — |
| 5 | Lya | Pues cuenta. Estamos los tres. | Le devuelve la calma | `firme` |
| 6 | Garon | …Tres. Bien. A dormir. | Cuenta de verdad; se ablanda medio segundo | — |

**La mano del brazalete** (`charla_mano`, los tres, desde PV-07):
| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Garon | Esa mano. La escondes cuando brilla. | Lo ha visto; lo dice como un parte | — |
| 2 | Kael | Es la mano de comer. Hay que cuidarla. | Esconde la mano también con la broma | `brazalete` |
| 3 | Lya | Kael… ¿te duele? | Preocupada de verdad | `preocupada` |
| 4 | Kael | No. Brilla cuando le da la gana. Como un farol con mal genio. | Le quita hierro | `ligero` |
| 5 | Garon | Si un día duele, lo dices. | Una orden que es cariño | — |
| 6 | Kael | Seréis los primeros. Palabra. | Lo promete, esta vez en serio | `decidido` |

**El miedo de Lya** (`charla_miedo_lya`, Kael y Lya, desde la mecha de Tilo):
| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Kael | Estás muy callada. Eso me da miedo hasta a mí. | Lo nota y entra con una broma | `duda` |
| 2 | Lya | Pensaba en Tilo. Tantos años cuidando de una estatua. | Piensa en voz alta | `duda` |
| 3 | Lya | Me da miedo eso: llegar tarde a alguien. Curar es fácil. Llegar, no. | El miedo, dicho con precisión | `preocupada` |
| 4 | Kael | Entonces voy yo delante y tú llegas conmigo. Problema resuelto. | La cuida con un plan absurdo | `decidido` |
| 5 | Lya | …Tonto. Gracias. | Se ríe sin querer | `decidida` |

**El miedo de Kael** (`charla_miedo_kael`, Kael y Lya, desde «Los faroles de la ronda»):
| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Lya | Bastián dice que encendiste los faroles de la ronda muy despacio. | Lo saca con cuidado | `duda` |
| 2 | Kael | A mí la niebla ni me roza. Ya lo sabes. | Desvía | `ligero` |
| 3 | Kael | Imagina que un día se os lleva a todos y a mí me deja. Vaya suerte, ¿eh? | El miedo, envuelto en chiste | `brazalete` |
| 4 | Lya | Kael… Pues enciende faroles. Muchos. Y no te quedes solo. | No le deja escapar | `preocupada` |
| 5 | Kael | …Prometido. | Lo acepta en serio | `decidido` |

- **Para animaciones:** el gesto de la segunda frase seguida de Lya (charla 5, frase 3) es distinto del de la primera
  (`duda` y luego `preocupada`), así que se ve el cambio. Garon tiene ocho frases: si un día tiene retrato o clip,
  sus intenciones van de la seca a la tierna.

### 4. Continuidad y canon
- **Quién habla.** Solo los del grupo de cada charla, y la charla solo sale si están todos (Kael solo hasta PV-03,
  Lya desde PV-03 y Garon desde PV-05). Comprobado ejecutando: con Kael solo, ninguna; sin Garon, solo las de Kael y
  Lya.
- **Texto que cuadra con lo ya dicho:**
  - la cama grande sigue la escena `oak_posada_grupo` (Garon: «Duermo en el suelo.»);
  - la estatua de PV-06 (Garon delante) y la mecha de Tilo (PV-14), tal como están;
  - «la niebla ni me roza» es el prólogo.
- **Detalle nuevo pequeño, sin contradecir nada:** la manzana de la primera vez (charla 1). No fija ni edad, ni lugar,
  ni familia; es solo cómo lo recuerda cada uno. Si el usuario prefiere no fijar ni eso, se cambia por otra anécdota.
- **Ni Érebo, ni lo que guarda, ni «recuerdos»:** «¿Te acuerdas…?» es de Lya y no habla de su sombra; la prueba lo
  mira. Nada de Final Fantasy X. Lo que la biblia v2 solo propone (el pasado de cada uno, el secreto de Lya, la noche
  de Garon) no aparece.

### 5. Límites y propuestas pendientes
- **«La más nueva»** sigue el orden de la lista, no el momento real del desbloqueo; con estos hitos, casi siempre
  coinciden. Guardar ese momento necesitaría otro estado, y no lo he añadido.
- **Una charla por noche,** y desplaza la escena corta de siempre esa noche. Si el coordinador prefiere las dos (la
  escena y después la charla), es una línea en `escena_al_despertar()`.
- **Pendiente en Redmi:** cómo se leen las charlas en la caja del teléfono (la más larga tiene 75 letras: dos líneas,
  según la medida de T-086).

### 6. Siguiente paso y cambios en archivos de otros
- **Coordinador:** confirmar o no las seis líneas de `project.godot` (`dialogic/directories`).
- **Animaciones:** los gestos de las charlas son los de siempre; si añade gestos nuevos (de Garon, por ejemplo), las
  intenciones de `CHARLAS_POSADA` dicen cuál pide cada frase.
- **Siguiente paso de narrativa:** con las capturas, revisar la charla en la caja; más charlas cuando haya más hitos
  (después de Pastos Verdes), con la misma guía de voz.

## 2026-11-09, 19:05: Oakhaven vivo, la posada como datos para el 3D y dos charlas de la Garganta

**Encargo del coordinador:**
1. Confirmar en mi rama las líneas de `dialogic/directories` que añadió la importación (criterio aprobado: se registran
   los diálogos nuevos).
2. «Vecinos vivos»: frases breves al pasar cerca, de los ocho vecinos y de gente anónima. Cambian con la hora y con el
   estado de las misiones, sin abrir diálogo y con un límite para no saturar. Con prueba.
3. La posada para el Oakhaven 3D (T-103): dormir, comer y rumores que apunten a sitios que ya existen. Los datos, en un
   módulo que usen igual el 2D y el 3D, sin tocar escenas 3D. Con prueba de datos.
4. Si sobra tiempo, 2-3 charlas ligadas a hitos de la Garganta.

El coordinador también aprobó guardar lo visto como estado de la ciudad en «mazmorras».

Copia `D:\Aethelgard_narrativa`, rama `area-narrativa`, desde `d9e2a5e`.

### 1. Archivos y commits
| Commit | Qué |
|---|---|
| `bde0c05` | `project.godot`: las seis charlas en `dialogic/directories` |
| `6aa5a94` | `ciudades/oakhaven_posada.gd` (nuevo) y `pruebas/prueba_oakhaven_posada.gd` (nueva) |
| `986f471` | `ciudades/oakhaven_vida.gd` (nuevo); `ciudad_oakhaven.gd`, que pinta las frases y cobra la posada con el módulo; `pruebas/prueba_oakhaven_vida.gd` (nueva); las dos líneas en `lista_pruebas.txt` |
| `8ff5afe` | Dos charlas de la Garganta: `charla_puentes.dtl` y `charla_gorthor.dtl`. En `ciudades/oakhaven.gd`, la condición `ganado:`, y las charlas pueden desbloquearse con «si». `prueba_charlas_posada`, al día. `project.godot` registra las dos |
| `10332e9` | Los `.uid` de lo nuevo |
| `8fede9b` | Arreglo: la respuesta de un comentario no se pisaba con los vecinos (§3); `prueba_oakhaven_vida` lo comprueba; `prueba_oakhaven_fotos` saca `22_voz_vecino` |
| (este) | Este informe |

Nada sin confirmar en mi copia.

**1. Oakhaven vivo** (`ciudades/oakhaven_vida.gd`):
- **Quién habla:** 43 frases. Son tres o cuatro por vecino (los ocho) y tres o cuatro por cada una de las cuatro voces
  sin nombre: la taberna, un vendedor del mercado, unos niños en la plaza y un guardia.
- **Qué cambia:**
  - con las misiones que ya existen (los faroles, los favores, la lavanda, el secreto de Pip, la torre);
  - con el grupo (Selene le habla a Lya si está);
  - con la «franja».
- **La franja.** El juego no tiene hora del día. Lo resuelvo así: al llegar es «anochecer», la hora azul del arte; tras
  dormir en la posada es «manana», hasta salir de la ciudad. No se guarda nada nuevo.
- **Límite para no saturar:**
  - una frase en pantalla como mucho;
  - 7 s de pausa entre dos frases, de quien sea, y 30 s antes de que la misma persona repita;
  - cada frase, una vez por visita, hasta que se acaban las que tocan y se vuelve a empezar;
  - nunca durante un diálogo, un fundido, un menú, ni a la vez que un comentario de los héroes; si empieza un
    diálogo, la frase se quita.
- **Cómo se ve:** una línea sobre la cabeza de quien habla, en blanco cálido y con contorno, sin luz ni ambiente que la
  oscurezcan. Las voces sin nombre salen entre comillas, en cursiva y en ámbar.
- **Distancia:** 3,2 casillas.
- **Para el 3D:** los mismos datos sirven (`Vida.frase(id, franja, dichos)`), pintados con un Label3D.

**2. La posada como datos** (`ciudades/oakhaven_posada.gd`):
- `servicios()` da el precio de ahora: dormir vale 0 si la posadera invita.
- `dormir()`:
  - cobra el mismo precio que `zona.gd` (30) o gasta la noche gratis;
  - cura al grupo;
  - devuelve el texto y la escena al despertar (la charla que toque o la escena de siempre).
- `comer()`, una **propuesta mía**: 10 monedas por la sopa del día, que recupera los PV y no los PM. La sopa cambia
  con las misiones hechas. Su precio y su efecto los tienen que revisar combate y el coordinador.
- `rumor()`: nueve rumores, contados de uno en uno.
  - Apuntan a sitios que ya existen: Pastos Verdes, el Gran Bosque Verde, la Garganta, Sunken City, el Mar de Arena de
    Calid, las Cumbres de Ciclópea, y tres secretos de la ciudad: el callejón de la grieta, el cofre de la ronda y el de
    las raíces.
  - Se saltan los que ya no tienen gracia: el sitio ya visto o el cofre ya abierto.
  - Lo oído se guarda como estado de la ciudad («rumor_…»).
  - Ninguno revela nada que el juego no diga ya: los textos salen de los del mapa y de los secretos de Oakhaven.
- La ciudad 2D ya cobra con `pagar_noche()` del módulo; la noche gratis sigue saliendo igual.
- Comer y los rumores no tienen todavía interfaz en 2D. Tenerla sería otra opción en el diálogo de la posadera (§5).

**3. Charlas de la Garganta:**
- `charla_puentes`: Garon cruzó los puentes «comprobando las cuerdas», la misma excusa que con el colchón. Sale tras
  ganar `garganta_nido`.
- `charla_gorthor`: Kael se quedó delante de Lya cuando rugió Gorthor. Sale tras ganar `garganta_gorthor`.
- No había hitos de la Garganta, así que se desbloquean con sus combates fijos, que ya guarda `combates_ganados`. Para
  eso, la condición nueva `ganado:` en `ciudades/oakhaven.gd`.

### 2. Pruebas
- **Importaciones aisladas:** `D:\REBELUM_diagnostico\importaciones\narrativa_20261109_183644\` (salida 0).
- **Pruebas nuevas** (comprobado ejecutando, aislado):
  - **`prueba_oakhaven_vida`**, FALLOS 0:
    - los datos: ocho vecinos y cuatro voces; las voces, junto a una calle; cada frase mide menos de 620 px en su
      etiqueta; condiciones y franjas válidas; sin palabras vetadas;
    - qué toca: Aldric y Bastián cambian con los faroles y la posadera saluda por la mañana; Albar no repite hasta
      decir las tres;
    - en la ciudad: junto a la posadera sale su frase sobre la cabeza; después hay pausa y Bastián no habla enseguida;
      un diálogo la quita; la posadera no repite sin su pausa; tras dormir, «¿Ya en pie? El pan acaba de salir.».
  - **`prueba_oakhaven_posada`**, FALLOS 0:
    - los datos: el precio de zona.gd; los lugares, secretos y cofres de los rumores existen;
    - dormir: pagando, con la noche gratis, sin monedas y con la charla al despertar;
    - comer: los PV sí y los PM no; la sopa cambia; sin monedas, no se come;
    - rumores: los nueve en orden y sin repetir; se saltan los ya vistos; partida antigua sin «mazmorras»; lo oído se
      lee al guardar y cargar;
    - la ciudad 2D cobra con el módulo.
- **`prueba_charlas_posada`,** con las ocho charlas: recorridas con Dialogic; tras el nido toca `charla_puentes` y
  tras Gorthor, `charla_gorthor`.
- **Pruebas de Oakhaven antes del commit** (aislado): 10 de 10 superadas
  (`D:\REBELUM_diagnostico\narrativa\2026-11-09\vida_posada\2026-11-09_183355\resumen.md`).
- **Batería completa** (aislado, sobre `10332e9`): **SUPERADAS 62 · FALLIDAS 0 · MANUALES 32 · NO SEGURAS 0** (`D:\REBELUM_diagnostico\narrativa\2026-11-09\bateria_vida\2026-11-09_183721\resumen.md`). La partida real, su carpeta y el proyecto, sin cambios.
- **Tras el arreglo de `8fede9b`** (aislado): `prueba_comentarios`, `prueba_oakhaven_vida`, `prueba_oakhaven`, `prueba_charlas_posada`, `prueba_oakhaven_posada` y `prueba_integridad`, 6 de 6 SUPERADAS (`...\vida_arreglo\2026-11-09_184907\resumen.md`).

### 3. Evidencias
**Frases de los vecinos** (en `ciudades/oakhaven_vida.gd`, con su condición). Algunas:
| Quién | Frase | Cuándo |
|---|---|---|
| Aldric | Tres faroles apagados en la muralla. Mal asunto. / Faroles encendidos, puerta cerrada. Así sí. | Antes y después de «Los faroles de la ronda» |
| Bastián | ¡Ciento nueve! …Sí. Ciento nueve. / ¡Ciento doce! Los he contado dos veces. | Ídem |
| Pip | Una moneda, un secreto. Oferta del día. / Lo del callejón, ni una palabra. | Antes y después de pagarle |
| Rosa | Ojalá alguien pasara por los Pastos… / El Árbol huele a lavanda. ¡Gracias otra vez! | Lavanda pedida / entregada |
| Posadera | Ese cucharón no vuelve solo, ¿eh? / ¿Ya en pie? El pan acaba de salir. | Con los favores / por la mañana |
| Selene | Lya, cuida de ese. Corre demasiado. | Con Lya en el grupo |
| Desde la taberna | «¡Eso no es cantar, es ladrar!» | Anochecer |
| Un vendedor | «¡Manzanas de los Pastos! ¡Maduras, no verdes!» | Siempre (guiño a la charla de cómo se conocieron) |

**Charlas de la Garganta,** con su intención y su gesto:
| Charla | # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|---|
| Puentes | 1 | Kael | Garon, en los puentes de la Garganta ibas muy despacio. | Le pilla, encantado | `ligero` |
| | 2 | Garon | Comprobaba las cuerdas. | La misma excusa de siempre, sin pestañear | — |
| | 3 | Lya | ¿Todas? | Le sigue el juego | `duda` |
| | 4 | Garon | Todas. | Seco, sin ceder | — |
| | 5 | Kael | Primero el colchón, ahora las cuerdas. ¿Qué será lo siguiente? | Une las dos excusas y se ríe | `sorpresa` |
| | 6 | Garon | Tu boca. A ver si aguanta callada una noche. | Le devuelve el golpe: es su forma de reírse | — |
| Gorthor | 1 | Lya | Kael… cuando Gorthor rugió, no te moviste. | Aún con el susto | `preocupada` |
| | 2 | Kael | Me quedé helado. Pero con estilo. | Lo convierte en chiste | `ligero` |
| | 3 | Garon | Te quedaste delante de ella. Eso no es quedarse helado. | Le deja sin escapatoria; lo dice con respeto | — |
| | 4 | Kael | …Bueno. Me pareció un buen sitio. | Lo admite a medias | `duda` |
| | 5 | Lya | Gracias. Y no lo vuelvas a hacer. | Le da las gracias y le riñe a la vez | `firme` |
| | 6 | Kael | Lo segundo no lo prometo. | Tierno y terco | `decidido` |

**Capturas con ventana** (aislado, 1280 × 720, `D:\REBELUM_diagnostico\oakhaven\2026-11-09_arte\vida\`): `22_voz_vecino.png` (desde la taberna, por la mañana: «¿Quién se ha comido mi pan?», sobre la puerta y junto a la posadera), `19_comentario.png` y la charla en `20_` y `21_`.

**Hallazgo y arreglo (`8fede9b`).** En la primera captura salían a la vez la voz de la taberna y la respuesta de Garon a un comentario de los héroes. La causa (observada en el código): Godot nombra «@PanelContainer@…» a la segunda caja que entra con el mismo nombre, y la ciudad buscaba «comentario». Ahora las cajas entran con nombre legible («comentario2»), y `prueba_oakhaven_vida` comprueba que ningún vecino habla mientras hay un comentario o su respuesta.

### 4. Continuidad y canon
- **Las frases de los vecinos y los rumores** solo nombran lo que ya existe: misiones, lugares del mapa, secretos de la
  ciudad y textos ya dichos (los 112 faroles, el anillo negro del roble, el barco de Sunken City, los puentes y
  «algo grande» que espera en la Garganta).
- **Nada de lo que espera decisión del usuario** (D-073): la prueba lo veta palabra por palabra. Por eso «los críos»
  pasó a «los niños», porque contiene «crio».
- **Nada de Érebo** ni de Final Fantasy X.
- **Las charlas de la Garganta:** solo hablan los tres y solo salen con los tres en el grupo. Kael defiende a Lya y no
  se revela nada.

### 5. Límites y propuestas pendientes
- **«Comer»** (10 monedas, solo PV) es una propuesta. Que lo decidan combate y el coordinador antes de que el 3D lo
  enseñe.
- **Comer y los rumores no se ven aún en el 2D.** Propuesta: una pregunta en el diálogo de la posadera («¿Algo más?
  Sopa / Rumores / Nada»), en un `.dtl` nuevo que llame al módulo con señales.
- **La franja** sale de la visita, no de un reloj. Si un día hay hora del día, basta con pasar otra franja a
  `Vida.frase`.
- **Pendiente en Redmi:** cómo se leen las frases sobre las cabezas (24 px).

### 6. Siguiente paso y cambios en archivos de otros
- **Gráficos, para el Oakhaven 3D (T-103):**
  - la posada: `Posada.servicios()`, `dormir()`, `comer()` y `rumor()`;
  - los vecinos: `Vida.VECINOS` y `Vida.VOCES` (con su casilla, en las mismas coordenadas de casilla, 1 casilla = 1 m
    en sus `.blend`), con `Vida.frase()` y las mismas pausas (`RADIO`, `PAUSA`, `PAUSA_QUIEN`);
  - la escena al despertar: `dormir()["escena"]`.
- **Coordinador y combate:** decidir lo de comer.
- **Siguiente paso de narrativa:** la pregunta de la posadera en 2D, si se aprueba; y más frases de vecinos cuando
  haya misiones nuevas.
