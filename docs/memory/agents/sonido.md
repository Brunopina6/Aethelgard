# Informe del especialista de sonido

## 2026-11-08, 23:45 · T-083, tanda 1: primera tanda de efectos desde la biblioteca del usuario

Rama `area-sonido`, desde `1c17763` (igual que `integracion-experimental`), en `D:\Aethelgard_sonido`.
**No he podido escuchar nada**: las pruebas dicen qué suena, cuántas veces, por qué bus y a qué nivel sale por el
altavoz, no cómo suena. La escucha la tiene que hacer el usuario (muestras más abajo).

### 1. Qué se ha hecho

- **Selección y licencias** (de unos 7 100 WAV de Sonniss y 500 de la colección CC0, se usan 61 originales):
  - colección CC0 «500 GAME SOUND EFFECTS»: páginas de cada fuente usada comprobadas en el navegador integrado el
    08/11 (s03, s13, s14, s29, s32, s35, s40 y s58: todas «CC0»);
  - paquetes GDC de Sonniss 2016-2024: el PDF de licencia de cada carpeta y `sonniss.com/gameaudiogdc` (uso en juegos
    sin atribución; no venderlos tal cual; no entrenar IA). El de 2015 no trae PDF: no se usa.
  - Tabla por efecto (fuente, recurso, evento, licencia y evidencia): `docs/audio/inventario_sonidos.md`; una fila por
    derivado con la huella SHA-256 del original: `docs/audio/efectos_procedencia.csv`; fila nueva en `docs/recursos.md`.
- **Derivados** (`aethelgard/audio/efectos/`, 100 archivos): hechos con `pruebas/prueba_efectos_preparar.gd` (tramo,
  capas, mono, filtro de media banda al bajar de 96/192 kHz, 48 kHz, fundidos, normalización); WAV de 16 bits en el
  repositorio (17,1 MB), QOA al importar. Los originales no se tocan (el modo `comprobar` vuelve a mirar sus huellas).
- **API central** (`sonido.gd`): catálogo `EFECTOS` (55 efectos), `Sonido.efecto()`, `Sonido.golpe()`, `cortar()`;
  10/4/4 voces en Efectos/Interfaz/Ambiente; prioridades 0-4 (mientras suena una 4, los golpes, pasos e interfaz van
  8 dB más bajos); variantes sin repetir la anterior y tono y volumen con una variación leve; espera mínima por efecto
  (un evento no suena dos veces); retraso que se anula al cambiar de escena; corte con fundido al cambiar de escena
  (salvo `cruza` y la interfaz); pausa del árbol (Efectos se para, Interfaz no) y de la app (todo); silencio (volumen 0
  o bus callado: ni suena ni ocupa voz); pasos 3D por los pies del esqueleto de Kael y 2D por los fotogramas del
  muñeco; emisor 3D fijo (cascada) y a lo largo de un segmento (río); oyente en Kael mirando como la cámara; detalles
  de la naturaleza según el contexto de `Musica` (ráfagas, pájaro, hojas, gotas).
- **Enganches** (llamadas cortas, sin cambiar la lógica): `combate.gd`, `menu_combate.gd`, `menus.gd`, `tienda.gd`,
  `zona.gd`, `garganta.gd`, `isla.gd`, `mapa.gd` y `zonas3d/pastos_verdes_3d.gd` (la lista de eventos, en el
  inventario). `inventario.gd` y `carga.gd` no hacían falta (la carga ya sonaba). El cofre de Pastos Verdes suena
  ahora con la biblioteca; el sonido hecho por código se queda para comparar y para `prueba_cofre3d`.
- **Magias:** ninguna suena (lo comprueba la prueba). Candidatos para una decisión aparte, en el inventario.
- **Habilidades nuevas y momentos de la misión:** Embuir y Esgrima suenan como golpes y un brillo (sin cambiar su
  presentación ni sus tiempos); Lya y Garon al unirse (PV-03, PV-05), la mecha de Tilo (PV-14), la estela y la página
  del Diario.

### 2. Archivos y commits (rama `area-sonido`)

| Commit | Qué |
|---|---|
| `606f111` | `audio/efectos/` (100 WAV + 100 `.import`), `pruebas/prueba_efectos_preparar.gd` (+ `.uid`), `docs/audio/efectos_procedencia.csv`. **Ojo:** al mensaje le falta la línea en blanco tras el título (sale entero como título); no lo he corregido para no reescribir la historia |
| `a0e162a` | `sonido.gd`: la API de efectos |
| `bb27a97` | Enganches: `combate.gd`, `menu_combate.gd`, `menus.gd`, `tienda.gd`, `zona.gd`, `garganta.gd`, `isla.gd`, `mapa.gd`, `zonas3d/pastos_verdes_3d.gd` |
| `285a293` | `pruebas/prueba_efectos.gd`, `pruebas/prueba_efectos_senal.gd` (+ sus `.uid`), `pruebas/lista_pruebas.txt` (tres líneas tras las de la música) |
| `e2689bf` | `docs/audio/inventario_sonidos.md`, `docs/recursos.md` |
| (este) | `docs/memory/agents/sonido.md` |

Sin confirmar, como pidió el coordinador: `dialogos/retrato_vivo.gd.uid`, `escena_dialogo.gd.uid`,
`pruebas/prueba_prologo.gd.uid` y `pruebas/prueba_prologo_fotos.gd.uid` (los generó Godot al importar; son de
animaciones).

### 3. Pruebas (todas con datos aislados)

- El ejecutor de siempre no arranca con el editor del usuario abierto (`D:\Aethelgard`): sale con 255 («Hay un Godot
  abierto»). He usado una copia en mi carpeta temporal con un único cambio: solo impide empezar un Godot sobre **esta**
  copia (`Aethelgard_sonido`); los de otras copias se apuntan en el resumen, como siempre. El aislamiento, la sonda,
  las huellas de la carpeta real y `git status`, iguales.
- `prueba_efectos` (nueva, sin ventana, muda), por partes el 08/11 a las 23:29 y 23:31 (`1c17763` + cambios, ya en
  `285a293`): **0 fallos**. Catálogo (55 efectos, 100 archivos: QOA, mono, 48 kHz; ni saturan ni son mudos); un golpe
  pedido dos veces en el mismo instante suena una; 6 de 6 variantes, ninguna seguida, tono 0,949-1,057; diez efectos
  importantes llenan las 10 voces, un golpe no quita ninguno y la victoria sí, y el golpe que llega durante la
  victoria va 8 dB más bajo; cortar, retrasar, cambio de escena (lo programado no suena; Efectos se apaga; el portal y
  la interfaz siguen), pausa del árbol y de la app, silencio; combate de verdad: un ataque físico suena una vez, una
  magia (Fuego) no suena, defensa, escudo, poción, Embuir, victoria y monedas, huida y derrota una vez cada uno;
  Pastos Verdes 3D: oyente en Kael, el río se pone frente a quien escucha, 8 pasos de piedra en 2,6 s por el camino y 5
  de hierba en 1,2 s (corriendo), ninguno parado, el cofre una vez (tapa y premio), la emboscada una vez y en el combate
  ya no están ni el río ni la cascada; zona 2D: 13-15 pasos en 4 s, todos de su suelo, cofre, posada sin dinero y
  emboscada; Garganta: puerta, ascensor sin fuerza, palanca y puente, guardado; menús y tienda.
- `prueba_efectos_senal` (nueva, con ventana y el driver real): **0 fallos**, 62 grabaciones (pasada
  `D:\REBELUM_diagnostico\pruebas\2026-11-08_233711`).
- **Batería completa** (automáticas, 08/11 a las 23:41, con `e2689bf`): **38 superadas, 0 fallidas, 21 manuales, 0 no
  seguras**; `partida.save` real y carpeta real de datos, sin cambios; `git status`, sin cambios. Resumen:
  `D:\REBELUM_diagnostico\pruebas\2026-11-08_234146\resumen.md`. `prueba_efectos` entra en ella y pasa entera (todas
  las partes de una vez). Durante la pasada había 24 Godot de otras copias (animaciones y gráficos) y el editor.
- `prueba_efectos_preparar -- <biblioteca> comprobar`: **58 de 58 originales intactos** (las tres fuentes que solo
  son capa —el golpe sordo, la botella s35 y el orco— llevan en el CSV los 12 primeros caracteres de su huella).

### 4. Evidencias

- **Muestras para escuchar**, con su índice (evento, archivo del juego, fuente, licencia, pico, RMS y duración):
  `D:\REBELUM_diagnostico\sonido_muestras\2026-11-08\indice.md` y sus 62 WAV (cada efecto solo; el río y la cascada a
  1, 2 y 4 veces su distancia; y tres mezclas: pasos seguidos en la hierba, un combate con victoria y un cofre).
- **Niveles a la salida** (bus Master, todo al 100 %; ambientes de antes: −29 a −39 dBFS de RMS, música de combate
  −20): pasos, pico −15 a −17 dBFS y RMS −32 a −39; golpe −5,9 / −27,7; crítico −6 / −19,6; golpe defendido −8,3 /
  −23,3; emboscada, jefe y fase 2 −5 / −17 a −19; victoria −6 / −20,9; derrota −6 / −19; interfaz −15 a −20 de pico
  (como el «tic» de siempre); detalles de la naturaleza −37 a −42 de RMS; río −28,7 a 4 m, −36,4 a 8 m; cascada −31,1
  a 8 m (el mirador está a unos 9-10 m), −40,6 a 16 m.
- Ajustes hechos tras la primera medida: golpe −6 → −5 dB, crítico −3 → −5, pasos de piedra, arena y madera +1 a +2,
  grava −1, ascensor +3, gotas −2, río −6 → −3, cascada −4 → +3 con 8 m de referencia (antes casi no se oía en el
  mirador), y la atenuación de la prioridad 4 ya no baja las monedas ni el nivel (llegan durante la victoria).

### 5. Límites

- **Escucha:** nadie ha oído los efectos. Lo más dudoso, por elegirlo sin oírlo: la victoria (s29, una de tres), los
  golpes (hacha en carne: ¿demasiado crudo para un limo?), el cofre (crujido de Kenney), el tesoro («collect item» de
  un paquete de juegos casuales) y la cascada (grabación con salpicones: su RMS varía unos 15 dB).
- **Pasos 2D:** los fotogramas 1 y 6 de «correr» son una estimación mirando `personajes/kael_mapa/correr_derecha.png`.
- **Pasos 3D:** salen de los pies del esqueleto (comprobado sin ventana); que caigan justo con el pie en pantalla
  hay que mirarlo con ventana.
- **Rendimiento:** no medido (no tocaba). El oyente, el río que se mueve, los pasos por esqueleto y los detalles son
  poca cosa, pero conviene medirlo en el Redmi.
- Sin APK ni móvil (no tocaba).

### 6. Siguiente paso y cambios en archivos de otros

- **Escucha del usuario** con el índice de muestras: elegir victoria (hay dos alternativas), golpes, cofre y tesoro.
- Para **animaciones** (`kael_3d.gd`, `muneco.gd`): confirmar los fotogramas de la pisada del muñeco 2D (ahora 1 y 6)
  o, mejor, que emitan una señal `pisada` en el momento exacto; Lya y Garon (`maga_3d.gd`, `garon_3d.gd`,
  `zonas3d/grupo_3d.gd`) pueden llevar sus pasos con una línea: `Sonido.pasos_3d(nodo, superficie)`.
- Para **combate** (T-087): el segundo tajo del doble ataque de hacha solo tiembla (un sonido por golpe que resuelve
  daño); decidir si cada tajo visible suena, más bajo.
- **Decisión aparte:** sonido para las 12 magias (candidatos en el inventario).
- **Siguiente tanda de sonido:** voces de los enemigos (furia), agua en las zonas 2D cerca de los ríos, pasos de Lya,
  Garon y los enemigos, la puerta de la Garganta al abrirse.

## 2026-11-09, 07:45 · T-083, tanda 2: voces de los enemigos, río 2D, Garganta, interfaz y propuesta de magias

Rama `area-sonido`, desde `713fe8d` (tanda 1 y animaciones ya integradas), en `D:\Aethelgard_sonido`. Antes de
empezar, importado lo nuevo de animaciones con datos aislados
(`D:\REBELUM_diagnostico\importaciones\sonido_20261109_001811`). La tanda se paró una vez (límite de uso del
coordinador) y se retomó donde estaba. **No he podido escuchar nada**: las pruebas dicen qué suena, cuántas veces, por
qué bus y a qué nivel sale, no cómo suena.

### 1. Qué se ha hecho

- **Voces de los enemigos** (observado en el código y comprobado ejecutando, 09/11): cinco familias con sus derivados
  en `audio/efectos/voces/` (limo, goblin, Gorthor, piedra y ámbar). `Sonido.voz(enemigo, evento)`: **ataque** cuando
  el enemigo llega y se lanza (`_anim_ataque_3d`, `_anim_fisico_imagen`, `_anim_fisico_sprite`, `_anim_fisico`);
  **herido** o **caída** cuando un golpe físico ya le ha restado los PV (`Sonido.recibe` en el impacto de
  `_animar_golpe`, de Juicio y de cada vuelta del Giro); Gorthor, además, **de rodillas** (`_decidir`), **«Acabar»**
  (`_acabar`) y su **mordisco** (Devorar, en el impacto). Una voz por enemigo (la nueva corta la suya), **dos a la vez
  como mucho** (grupo «voz»), la «espera» de cada voz deja una por familia cuando el Giro golpea a varios; con furia,
  el ataque +2 dB y un poco más grave. Prioridades: ataque y herido 2 (bajan durante la victoria), caída 3. Los héroes
  no tienen voz. **Las magias no piden voces** (ni la quemadura ni Érebo): va en la propuesta.
- **El segundo tajo del doble ataque** (Grimfang y Gorthor): **decidido que suena, 6 dB más bajo** (el golpe, o el
  escudo si el héroe se defiende). Un tajo que se ve y no se oye parece un fallo; más bajo no parece un segundo daño.
- **Congelar** (Frostfang o Embuir de hielo): un crujido de hielo, solo la primera vez.
- **Río de las zonas 2D**: `Sonido.agua_zona(zona)` desde `zona.gd`. Un emisor 2D (izquierda/derecha) en el punto del
  río más cercano; todo el volumen a 1,5 casillas de la orilla o menos, la mitad cada vez que se dobla la distancia,
  callado (y sin sonar) hacia las 9 casillas; fundido de 0,8 s; al salir de la zona se funde el doble de rápido. Solo
  el río (la mancha de agua que llega a un lado de la zona): las charcas no suenan a corriente (`mascara_rio`); el
  hielo, el abismo, la lava y el veneno, nada. Medido: RMS −33,1 dBFS en la orilla, −38,7 a 3 casillas, −45,3 a 6; el
  ambiente de la pradera va a −29: no lo tapa.
- **La Garganta 2D**: la puerta sellada **suena al abrirse**, a lo lejos (`puerta_abre`, la parte «open» de la misma
  puerta que suena «cerrada», con paso bajo), 1,3 s tras la palanca. Revisados todos sus eventos: guardar, puerta
  cerrada, palanca, puente, puerta que se abre, ascensor sin fuerza y con fuerza, cofre raro del nido, combates del
  nido y de Gorthor (emboscada y voces), gotas y pasos. No he tocado la Garganta 3D.
- **Interfaz y mundo**: el Diario pasa la hoja al cambiar de pestaña (solo si cambia) y se cierra con un libro (CC0
  s14, Kenney); el brazalete de Kael brilla y se oye muy bajo junto a un detalle sin ver (una vez por detalle); examinar
  el altar suena como los detalles. Ningún «tic» duplicado: donde ya había uno, no se ha añadido otro.
- **Pasos de varios cuerpos**: `Sonido.pasos_3d(cuerpo, superficie, db)` ya admite a Kael, Lya y Garon a la vez (uno
  por cuerpo; pedirlo dos veces para el mismo no duplica) y un volumen para los compañeros (propuesto −3 dB).
- **Generador aleatorio** (aviso del coordinador): `sonido.gd` usa solo su `_rng` (variantes, tono, volumen, detalles,
  punto de inicio de los bucles) y un `rng` local con semilla fija para la muestra de los ajustes. Comprobado con grep
  el 09/11 (`sonido.gd` y `musica.gd`: ninguna llamada a `randf()`, `randi()`, `randf_range()`, `randi_range()`,
  `shuffle()`, `pick_random()` ni `seed()` globales) y con una prueba: `randi()` sale igual con y sin sonidos.
- **Magias, solo propuesta (D-048)**: tabla con un candidato por magia y nivel (archivo, tramo, licencia y la línea
  donde se engancharía) en `docs/audio/inventario_sonidos.md`, y 12 muestras fuera del proyecto. Nada integrado: las
  magias siguen sin pedir ningún sonido (lo comprueba la prueba).
- **Licencias**: CC0 comprobadas en la página de OpenGameArt de cada fuente el 09/11 con el navegador integrado (s06,
  s09, s10, s24, s33, s34, s51, s52, s53, s56 y s57: todas «CC0»); los paquetes de Sonniss son de años ya comprobados.
  OpenGameArt rechaza las descargas automáticas (403), así que se miró en el navegador.

### 2. Archivos y commits (rama `area-sonido`)

| Commit | Qué |
|---|---|
| `97a4cf7` | 37 derivados nuevos (`audio/efectos/voces/` 33, `combate/congelar`, `mundo/puerta_abre`, `mundo/brazalete`, `interfaz/libro_hoja`, `interfaz/libro_cerrar`, con su `.import`), `pruebas/prueba_efectos_preparar.gd` (recetas, «solo=», «tono», «magias=», no reescribe un `.import` que ya existe) y `docs/audio/efectos_procedencia.csv` (37 filas) |
| `35b89da` | `sonido.gd`: catálogo, `voz()`, `recibe()`, límite de grupo, `golpe(db)`, `agua_zona()`/`Agua2D`/`mascara_rio()`, `pasos_3d` de varios cuerpos |
| `8909a4c` | Enganches: `combate.gd` (18 líneas añadidas, ninguna cambiada), `zona.gd` (3), `garganta.gd` (1), `diario.gd` (3) |
| `f212bac` | `pruebas/prueba_efectos.gd` (partes «voces», «agua», «interfaz», «azar» y la Garganta ampliada), `pruebas/prueba_efectos_senal.gd` («efectos=», mezclas y río 2D), `pruebas/lista_pruebas.txt` (sus notas) |
| `11fc961` | `docs/audio/inventario_sonidos.md` (tanda 2 y propuesta de magias), `docs/recursos.md` (fila de efectos) |
| (este) | `docs/memory/agents/sonido.md` |

Sin confirmar, porque no es mío: `aethelgard/pruebas/prueba_boton_prologo.gd.uid` (lo generó Godot al importar; el
`.gd` lo añadió el coordinador en `713fe8d`).

### 3. Pruebas (todas con datos aislados)

- `prueba_efectos` (muda), con el ejecutor del repositorio el 09/11: **SUPERADA** (11,3 s). Partes nuevas: el limo
  (se lanza: voz 1 y golpe 1; recibe: herido 1; con Agua no pide nada; cae: caída 1), Grimfang (voz 1 y **dos tajos
  que suenan, separados 0,62 s** como la animación; herido 1; congelar dos veces seguidas: 1), el Gólem de ámbar (su
  voz, no la de la piedra), Gorthor (mordisco y voz; el golpe que lo deja de rodillas: herido; de rodillas: caída;
  «Acabar»: muerte y crítico), la API (un héroe no tiene voz; la voz nueva corta la anterior del mismo; tres enemigos
  a la vez: suenan 2; furia más fuerte; pasos de tres cuerpos sin duplicar), el río 2D (−5,0 / −11,9 / −18,6 dB a
  0,3 / 3 / 6 casillas y callado a 11; al llegar a la orilla no salta de golpe; al salir deja de sonar; sin río o con
  lava no hay emisor), el Diario (hoja 1 aunque se pulse dos veces la misma pestaña, cerrar 1, ningún «tic»), el
  brazalete (1 por detalle), el altar, la Garganta (la puerta se abre una vez, el ascensor viaja, no hay río en el
  abismo, el cofre raro y la emboscada del nido) y el generador global intacto.
- `prueba_efectos_senal` (con ventana y el driver real), solo la tanda 2 (`efectos=…`), 09/11 a las 07:23: **0
  fallos**, 31 grabaciones (`D:\REBELUM_diagnostico\importaciones\sonido_senal_20261109_072308`).
- `prueba_efectos_preparar -- <biblioteca> comprobar`: **88 de 88 originales intactos**. Las fuentes que solo son
  capa (burbujas s53, los arrastres de Wav Junction, el paso de criatura de Bluezone, «stone_impact_041», el hielo de
  Stuart Duffield y el cristal de BluezoneCorp) llevan en el CSV los 12 primeros caracteres de su huella.
- **Batería completa**: (automáticas, 09/11 a las 07:30, con `11fc961`): **39 superadas, 0 fallidas, 23 manuales, 0 no seguras**; `partida.save` real y carpeta real de datos, sin cambios; `git status`, sin cambios. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-09_073016\resumen.md`. Durante la pasada había 20 Godot de otras copias.

### 4. Evidencias

- **Muestras para escuchar**, con su índice: `D:\REBELUM_diagnostico\sonido_muestras\2026-11-09\indice.md`: cada
  voz y efecto nuevo solo, cuatro combates seguidos (limo, Grimfang con su doble tajo, piedra y ámbar, Gorthor entero),
  la palanca de la Garganta con su puerta, el río 2D a 0, 3 y 6 casillas y el río con la pradera debajo; y en
  `magias\` las 12 muestras de la propuesta con `magias_procedencia.csv`.
- **Niveles a la salida** (Master, todo al 100 %): voces de ataque y herido, RMS −23 a −31 dBFS (picos −9 a −16);
  caídas −24 a −27 (Gorthor, muerte −20,7 y mordisco −21); congelar −26,1; puerta que se abre −32,7; brazalete −34,1
  (pico −20); libro −31,8 y −36,3; el golpe de siempre −27,7 de RMS con pico −5,9. Primera medida y ajustes: goblin
  −3 dB, Gorthor −1 a −2, piedra (ataque) −2, limo +1, río 2D +4 (en la orilla quedaba 8 dB por debajo del ambiente).
- La tabla de cada efecto (fuente, licencia, evento, bus, dB y prioridad) y la propuesta de magias:
  `docs/audio/inventario_sonidos.md`.

### 5. Límites

- **Escucha**: nadie ha oído las voces. Elegidas por nombre, duración, brillo y tono medidos (analizador propio en
  Python, sin instalar nada). Lo más dudoso: si el goblin suena demasiado «orco» o humano, si el ataque del limo (barro)
  suena sucio, si la piedra del guardián (un zumbido «melódico» de roca) parece una voz, y el órgano de Gracia Divina.
- **Panorama 2D**: el río 2D suena a la izquierda o a la derecha según dónde está el agua (AudioStreamPlayer2D), pero
  solo se ha medido de frente; el reparto entre canales no está comprobado.
- **Rendimiento**: no medido (no tocaba). El río 2D busca el agua cada 0,12 s en un cuadro de 21 × 21 vértices y el
  río se calcula una vez al entrar en la zona; las voces son reproductores del grupo de siempre.
- **Pasos de Lya y Garon**: la API está lista y probada sin animación; los engancha animaciones.
- **Línea base**: la pasada completa del principio se cortó con la parada del coordinador (hasta
  `prueba_guardado_protegido`, todas superadas); la comparación es con la de la tanda 1 (38 superadas, 0 fallidas).

### 6. Siguiente paso y cambios en archivos de otros

- **Escucha del usuario** con el índice de hoy: voces de cada familia, el doble tajo, el río 2D (¿se nota lo
  bastante en la orilla?) y la propuesta de magias (aprobar, cambiar o descartar cada una).
- **Animaciones** (`zonas3d/grupo_3d.gd` o donde creen a Lya y Garon en 3D): una línea por compañero,
  `Sonido.pasos_3d(lya, superficie, -3.0)` y `Sonido.pasos_3d(garon, superficie, -3.0)`, con la misma `superficie` que
  Kael en `pastos_verdes_3d.gd`. Para que sigan los pies, el nodo debe tener `skel` (su Skeleton3D); si no, van por
  distancia.
- **Garganta 3D** (otro especialista): ya existen en el catálogo `palanca`, `puente_baja`, `puerta_abre`, `ascensor`,
  `atascado`, `cerrada`, `guardado`, `cofre`, `tesoro`, `gota` y `emboscada`, y `Sonido.fuente_3d` / `fuente_linea` /
  `oyente_3d` para el ambiente 3D; que diga qué le falta.
- **Gráficos** (`mapa.gd`): lo que hay hoy ya suena; lo nuevo del mapamundi (por ejemplo, descubrir un lugar)
  necesitará su línea `Sonido.efecto(...)`: que lo marque y lo preparo.
- **Combate** (diseño): la decisión del segundo tajo está tomada y registrada; si cambia la animación de Grimfang,
  `prueba_efectos` lo dirá (tajos separados 0,62 s).
- **Coordinador**: confirmar o descartar `prueba_boton_prologo.gd.uid`.
- **Siguiente tanda de sonido**: magias si se aprueban, charcas, lava y veneno de las zonas 2D, voces de los héroes
  (si se quieren) y medir el río 2D y las voces en el Redmi.

## 2026-11-09, 13:10 · T-083, tanda 3: la Garganta 3D, los pasos de Lya y Garon, las artes y Oakhaven

Rama `area-sonido`, desde `555fc29` (la integración con la Garganta 3D, la tanda 2 de animaciones, Oakhaven fase 1 y
combate fase 1), en `D:\Aethelgard_sonido`. Importado con datos aislados antes de empezar
(`D:\REBELUM_diagnostico\importaciones\sonido_20261109_084813`) y después de los derivados (`…_121408`). La tanda se
paró una vez (límite de uso del coordinador) justo después de importar: los 44 cambios sin confirmar que había eran solo
de esa importación (43 `.uid` y `project.godot`), no míos. **No he podido escuchar nada**: las pruebas dicen qué suena,
cuántas veces, desde dónde y a qué nivel sale, no cómo suena.

### 1. Qué se ha hecho

- **La Garganta 3D** (`zonas3d/garganta_3d.gd`, solo líneas de enganche: `_sonido_3d`, `suelo_de_pasos`,
  `_punto_gota`, una línea en `_crear_grupo` y dos en `_tirar_palanca`):
  - se escucha desde Kael (`oyente_3d`), mirando como la cámara;
  - pasos según el suelo: **tablas** en los puentes colgantes, el levadizo y las estaciones del ascensor; **roca** en lo
    demás; los de Lya y Garon con el mismo suelo (`grupo.pasos_superficie`);
  - **la cascada grande** (un derivado nuevo: un rugido grave, no el chorro pequeño de Pastos Verdes) a lo largo de su
    caída: suena desde el punto a la altura de quien escucha y se oye en toda la garganta (de lejos, solo el rumor);
  - **el viento del abismo** (un aullido tonal) a lo largo del eje del abismo y, 6 dB más bajo, bajo los puentes
    colgantes (al cruzarlos se está sobre el vacío);
  - **las gotas en la roca**: cada detalle de la mazmorra cae en la pared de roca más cercana (`detalles_3d`); la
    mazmorra (también la 2D) tiene ahora además una gota de cueva con su propia cola;
  - **el eco de la garganta** (`eco`): una reverberación en los buses Efectos y Ambiente mientras la escena es la
    actual; se quita sola al salir. Primero lo puse muy bajo (0,16) y, medido, no se oía (la cola de un paso, 48 dB
    por debajo); ahora 0,45/0,35 con lo directo a 0,92 (ver §3);
  - **los efectos de la 2D, una vez cada uno**: guardar, la puerta sellada, el ascensor sin fuerza y con fuerza, la
    palanca, el cofre raro, examinar y la emboscada (comprobado pulsando dos veces). El puente que baja suena ahora
    **desde el levadizo** y **la puerta que se abre** (faltaba en la 3D; en la 2D ya sonaba) desde la puerta, a 1,3 s.
- **Los pasos de Lya y Garon** (`sonido.gd`, `Pasos3D`): **desde su pie y en el espacio** cuando hay un oyente 3D (Pastos
  Verdes y la Garganta): a un lado o detrás de Kael y más bajos cuanto más lejos (`PASO_3D`: a 2,5 m de su cabeza, a
  su volumen); **un volumen por personaje** (`DB_PASOS`, por el nombre del nodo: Lya −2 dB, Garon 0); sin oyente 3D,
  3 dB más bajos. **Ojo:** en `555fc29` `grupo_3d.gd` los crea con `son.pasos_3d(nodo, pasos_superficie)`, sin el
  `-3.0` que decía el encargo; ahora el volumen lo pone `sonido.gd` y no hace falta tocar `grupo_3d.gd`.
  - **Arreglo:** la espera mínima entre dos pasos era por efecto (0,09 s): si dos personajes pisaban a la vez el mismo
    suelo, uno no sonaba. Medido en la Garganta: se perdía casi la mitad (14 de 26). Ahora es de cada cuerpo (opción
    `clave` de `efecto`) y suenan hasta 3 pasos del mismo suelo a la vez: 9 de 9 de Kael, 9 de 9 de Lya y 8 de 8 de
    Garon. En Pastos Verdes, por el camino suenan ahora 13 pasos en 2,6 s (antes 8: eran solo los de Kael).
- **Las artes, solo en el catálogo** (los engancha combate en `combate.gd`): `arte_alba`, `arte_ocaso`,
  `arte_hora_dorada`, `arte_escarcha`, `arte_lumbre`, `renacer`, `aliento`, `barrera_absorbe`, `barrera_rota`, `brasa` y
  `esquiva`, con los nombres exactos que piden `artes.gd` (`SONIDO_LANZAR`, `SONIDO_ESTADO`) y combate. Cada familia con
  su color: Alba, campanilla y reloj (y su contrario, un tono que cae); Escarcha, hielo y cristal; Lumbre, fuego cálido
  y una campana. Prioridad 3 los lanzamientos, 1 el Aliento y la coraza que absorbe, 2 la esquiva. No son las 12 magias
  de siempre, que siguen sin sonar (lo comprueba la prueba).
- **Oakhaven, solo en el catálogo** (los engancha narrativa): `campana` (lejana), `taberna` (el bullicio, en bucle y por
  cercanía), `cuervo` (el letrero que chirría de vez en cuando, por cercanía) y `farol` (prende). Para la taberna y el
  cuervo, una función nueva: `Sonido.fuente_2d(padre, nombre, pos, quien)`. Cómo pedirlos, con el código, en
  `docs/audio/inventario_sonidos.md` («Cómo pedirlos»). **Añadido del coordinador:** `musica.gd` da a
  `res://ciudad_oakhaven.tscn` el contexto «ciudad» (y `prueba_musica` lo comprueba); la escena aún no está en mi rama.
- **API nueva** (`sonido.gd`): `efecto(…, {"pos": Vector3})` (efectos en el espacio, 8 voces 3D por escena),
  `{"clave": …}`, `detalles_3d`, `eco`/`quitar_eco`/`eco_activo`, `fuente_2d` y `db` en `fuente_3d`/`fuente_linea`.
- **Licencias**: los 23 derivados nuevos salen de los paquetes GDC de Sonniss 2016-2024 (el PDF de cada paquete está
  en su carpeta: mirado otra vez el 09/11) y la esquiva 1 de la colección CC0 (s32, comprobada el 08/11). Ninguna
  fuente CC0 nueva; nada del paquete de 2015, de TomMusic, de «Helton Yan's Pixel Combat» ni de Suno.

### 2. Archivos y commits (rama `area-sonido`)

| Commit | Qué |
|---|---|
| `04f5731` | 23 derivados (`audio/efectos/ambiente`, `combate`, `mundo`, con su `.import`), `pruebas/prueba_efectos_preparar.gd` (recetas), `docs/audio/efectos_procedencia.csv` (23 filas) |
| `3140f28` | `sonido.gd` (API y catálogo), `musica.gd` (`ciudad_oakhaven.tscn` → «ciudad») |
| `7043816` | `zonas3d/garganta_3d.gd`: líneas de enganche |
| `6bfbb8d` | `pruebas/prueba_efectos.gd`, `pruebas/prueba_efectos_senal.gd`, `pruebas/prueba_musica.gd` (una fila de su tabla, como pidió el coordinador), `pruebas/lista_pruebas.txt` (las notas de las dos de efectos) |
| `7fcfd3c` | `docs/audio/inventario_sonidos.md` (tanda 3), `docs/recursos.md` (fila de efectos) |
| `82778f8` | `sonido.gd`: el reproductor 3D nuevo elige su bus nada más crearse (lo pide `prueba_audio`) |
| (este) | `docs/memory/agents/sonido.md` |

Sin confirmar, porque no son míos: `aethelgard/project.godot` (Dialogic apunta los diálogos de Oakhaven al importar) y
43 `.uid` de archivos de la Garganta 3D, Oakhaven y sus pruebas (los generó Godot al importar).

### 3. Pruebas (todas con datos aislados)

- `prueba_efectos` (muda), 09/11, `6bfbb8d`: **0 fallos** (28 s). Partes nuevas:
  - «espacio»: con «pos» suena desde ese punto con su distancia (el puente, 14 m de referencia y sin perder agudos);
    sin escucha 3D, normal; doce efectos en el espacio ocupan las 8 voces 3D y lo menos importante no quita nada; los
    reproductores 3D se van con la escena;
  - «artes»: los 10 nombres que pide `artes.gd` y la esquiva existen; cada una suena una vez, por Efectos y con su
    prioridad; el Aliento, uno a la vez; la coraza que absorbe, dos a la vez como mucho y no dos en 0,05 s;
  - «oakhaven»: la taberna −2 / −10 dB a 1 / 5 casillas y callada a 13, con fundido (−14 dB a los 0,2 s); el cuervo, 3
    veces en 30 s cerca y 0 en 25 s lejos, sin bucle; la campana, una vez; la ola de cinco faroles, cinco y tres a la
    vez como mucho;
  - «garganta3d» (la escena de verdad, con Lya y Garon): oyente en Kael; la cascada y los dos vientos en bucle por
    Ambiente; la cascada a la altura de quien escucha (a 15 m en la arena) y el viento frente a él; el eco solo en
    Efectos y Ambiente; por la cornisa y un puente, 4 pasos de roca y 5 de tablas de Kael y 17 de los compañeros desde
    su pie (9/9, 9/9 y 8/8 pisadas que suenan); 4 gotas, todas en la pared de roca; guardar, la puerta, el ascensor sin
    fuerza, la palanca (con el puente desde el levadizo y la puerta desde la puerta), el ascensor, el cofre (tapa y
    premio) y examinar, una vez cada uno aunque se pulse dos veces; la emboscada, una; en el combate ya no hay eco
    (los efectos de los buses, como antes) ni cascada.
- `prueba_musica`, 09/11: **SUPERADA** (con `ciudad_oakhaven.tscn` → «ciudad»).
- `prueba_efectos_preparar -- <biblioteca> comprobar`: **108 de 108 originales intactos**.
- `prueba_efectos_senal` (con ventana, el driver real y **sin** `--fixed-fps`, para que lo que anda en la Garganta vaya
  a tiempo real), `efectos=…` y `mezclas=3`, 09/11 a las 12:41: **0 fallos, 37 grabaciones**
  (`D:\REBELUM_diagnostico\importaciones\sonido_senal_20261109_123744`).
- **A/B del eco** (un guion temporal en mi carpeta, `scratchpad\sonido\eco_ab.gd`, mismos sonidos con variante fija, en
  silencio; la versión final de las muestras está en `prueba_efectos_senal`): con 0,16 la cola de un paso quedaba 36 dB
  por debajo del golpe entre 0,1 y 0,4 s y 48 dB entre 0,4 y 1 s; con la elegida, 26 y 36 dB; una gota, 16 y 25 dB; la
  palanca sube de −7,0 a −4,7 dBFS de pico y la emboscada de −5,0 a −3,5 (sin saturar); el bucle del viento no cambia de
  nivel (−28,3 → −28,6 dBFS).
- **Batería completa** (automáticas, 09/11 a las 12:57, con `82778f8`): **47 superadas, 0 fallidas, 27 manuales, 0 no
  seguras**; `partida.save` real, carpeta real de datos y proyecto, sin cambios. Resumen:
  `D:\REBELUM_diagnostico\pruebas\2026-11-09_125726\resumen.md`. Entran `prueba_efectos`, `prueba_musica`,
  `prueba_audio`, `prueba_garganta3d` (el recorrido entero de la Garganta 3D con el sonido nuevo), `prueba_anim_pies`
  (un nodo de pasos por personaje), `prueba_combate_huella` (la huella del combate no cambia), `prueba_artes` y
  `prueba_artes_combate`. Durante la pasada había 49 Godot de otras copias.
  - La primera pasada completa (12:44, `7fcfd3c`) dio 46 y 1 fallida: `prueba_audio` mira en el código que cada
    `AudioStreamPlayer*.new()` ponga su bus en las líneas siguientes y el reproductor 3D nuevo lo ponía más abajo;
    arreglado en `82778f8` (sin cambio de comportamiento).
  - Al repetir solo esas, `prueba_audio` falló una vez por tiempo: la primera pulsación de los ajustes tardó 118 ms con
    seis Godot de otras copias trabajando (sola, 36 ms; esa parte no la he tocado). Es sensible a la carga del PC.

### 4. Evidencias

- **Muestras para escuchar**, con su índice y una guía de qué escuchar y decidir:
  `D:\REBELUM_diagnostico\sonido_muestras\2026-11-09_tanda3\indice.md` y sus 37 WAV (cada efecto nuevo solo, las artes
  seguidas, Oakhaven, el eco con y sin, y la Garganta 3D de verdad en cinco sitios, los pasos con y sin eco, la palanca
  y las gotas).
- **Niveles a la salida** (Master, todo al 100 %, 09/11):
  - artes: lanzamientos, RMS −24 a −26 dBFS (picos −10 a −13; Embuir y la unión al grupo, −26 y −25,5; el golpe, −27,7);
    Aliento −36,9; la coraza que absorbe −33 (pico −12); la que se rompe −23,6; la Brasa −23,7; la esquiva −23,9 (0,1 s);
  - Oakhaven: la campana sola −32 (con la ciudad, −27,7); el farol −30,7 (pico −7,8); el cuervo −34,7; la taberna con
    la ciudad debajo, −28,3 / −32,0 / −36,5 a 1 / 4 / 8 casillas (la ciudad sola, unos −33: junto a la puerta se oye
    unos 5 dB por encima; con −6 dB apenas asomaba, por eso está a −2);
  - la Garganta 3D (la mazmorra de fondo, la cascada, el viento, las gotas y el eco): entrada −33,5, puentes −27,9,
    arena −26,9, grieta −24,6 y nido −28,8 dBFS de RMS; los tres andando por la cornisa y un puente, −25,5; la palanca,
    −25,8 (pico −4,6); cinco gotas, −31,5.
- La tabla de cada efecto (fuente, licencia, evento, bus, dB y prioridad) y cómo pedir los de Oakhaven:
  `docs/audio/inventario_sonidos.md`.

### 5. Límites

- **Escucha**: nadie lo ha oído. Lo más dudoso, por elegirlo sin oírlo: el eco (¿se nota o sobra?), la cascada grande y
  el aullido del viento (¿demasiado «tonal»?), la taberna (es un restaurante alemán grabado, con paso bajo: de cerca
  podría entenderse que no es medieval), el cuervo (dos crujidos de metal y una puerta) y la campana (campanas de pueblo
  de verdad, con su ambiente debajo).
- **Rendimiento**: sin medir (no tocaba). Lo nuevo en la Garganta: dos reverberaciones de bus, tres emisores en bucle
  que se recolocan cada fotograma, hasta 8 reproductores 3D y los pasos de tres cuerpos. Conviene medirlo en el Redmi.
- **Panorama**: que los pasos de Lya y Garon y las fuentes 2D suenen a un lado o a otro lo hace Godot; está medido el
  nivel, no el reparto entre canales.
- **En el juego con ventana**: solo en pruebas (la escena de verdad, pero guiada); no he jugado la Garganta.
- **Oakhaven**: su escena (`ciudad_oakhaven.tscn`) no está en mi rama; la API se ha probado con una ciudad de mentira.
- **Las artes**: suenan cuando `combate.gd` las pida; no las he oído dentro de un combate (combate no estaba
  enganchado en mi rama).

### 6. Siguiente paso y cambios en archivos de otros

- **Escucha del usuario** con el índice de hoy (la guía está al final): el eco, la cascada y el viento, los pasos de
  los compañeros, las artes y Oakhaven.
- **Narrativa** (`ciudad_oakhaven.gd`): las cuatro líneas de «Cómo pedirlos» del inventario (dos `fuente_2d` en
  `_ready` y `efecto("campana")`/`efecto("farol")` en sus sucesos). El contexto de la música ya está en `musica.gd`.
- **Combate** (`combate.gd`): los once nombres existen. `aliento` suena en `_tic_estados_heroe`; `barrera_absorbe` y
  `barrera_rota` cuando entre M3; `brasa` cuando la Brasa levante a alguien (M4); `esquiva` con la pluma (C1).
- **Garganta 3D** (su especialista): si cambia el trazado (puentes, levadizo, ascensor), `suelo_de_pasos` sigue a las
  constantes de `trazado.gd`; si los muros se mueven, `_punto_gota` usa `muro_oeste`/`muro_este`.
- **Coordinador**: decidir el eco al escucharlo (y si se pone también en la Garganta 2D: sería `Sonido.eco(self,
  "garganta")` en `garganta.gd`); medir la Garganta 3D en el Redmi; confirmar o descartar los `.uid` y
  `project.godot` de la importación.

## 2026-11-09, 18:00 · T-097 (sonido) y T-083, tanda 4: las seis bestias del bestiario y los héroes quietos

Rama `area-sonido`. Antes de empezar, integrado `integracion-experimental` (`eb8bd94`) con `merge --no-ff` (`acf08b1`,
como pidió el coordinador) e importado con datos aislados (`D:\REBELUM_diagnostico\importaciones\sonido_20261109_172218`;
solo apareció `prueba_orden_pv03.gd.uid`, que no es mío y no confirmo). La tanda se paró una vez por un límite de uso del
coordinador y se retomó donde estaba. **No he podido escuchar nada**: las pruebas dicen qué suena, cuántas veces, por
qué bus y a qué nivel sale, no cómo suena. **No se ha usado el Redmi** (norma nueva del usuario): lo que lo necesita
está marcado «pendiente en Redmi».

### 1. Qué se ha hecho

- **Las seis bestias, solo en el catálogo** (no he tocado `combate.gd`, `enemigos/**`, los `.dtl`,
  `ciudad_oakhaven.gd`, `zonas3d/**` ni `mapa*`): 51 derivados en `audio/efectos/bestias/` y 44 efectos en
  `sonido.gd`, con nombres por bestia y evento: `<bestia>_aviso_<ataque>` (la preparación, al empezar el ataque; acaba
  antes del impacto de la ficha), `<bestia>_<ataque>` (el impacto, en el instante del golpe, junto al `Sonido.golpe()`
  de siempre, que dice si el héroe se defiende), `<bestia>_herido` y `<bestia>_caida` (su voz, sola con
  `Sonido.recibe()` por `FAMILIAS`) y `<bestia>_entrada`. Zarzalín tiene además `zarzalin_pezuna` (cada señal
  `pezuna(n)` de `zarzalin_3d.gd`) y `zarzalin_derrumbe` (al empezar su clip `derrota`; el cuerpo toca la tierra a
  0,60 s, fotograma 19). La tabla con cada nombre, para quién, en qué instante, original, bus, dB, prioridad y nivel
  medido, y el código para pedirlos: `docs/audio/inventario_sonidos.md` (tanda 4).
- **Tiempos**: los de las fichas y los de los GLB del bestiario (leídos con un guion propio en Python, sin instalar
  nada): la postura de aviso de cada ataque se sostiene hasta poco antes del impacto (p. ej. el Cencerrante 0,3-0,6 s,
  impacto 0,73; el Posadero 0,5-0,77, impacto 0,97). Los de Zarzalín, de `zarzalin_3d.gd` (animaciones): aviso a
  0,267 s, pezuñas a 0,467 y 0,733, embestida 0,167 s desde la carga.
- **Prioridades y volúmenes**: avisos prioridad 3 (el jugador tiene que oírlos), impactos 2, voces como la tanda 2
  (herido 2, caída 3, grupo «voz»); el Posadero (jefe opcional) 2-3 dB más y prioridad 3 en todo. Sin voz de «ataque»:
  el aviso hace ese papel. `Sonido.BESTIAS` lista los efectos de cada bestia.
- **Licencias**: todo de los paquetes GDC de Sonniss 2016-2024 (PDF en la carpeta de cada paquete; releídos el 09/11
  los de 2020 y 2024: uso y modificación en juegos sin atribución, no venderlos tal cual, no entrenar IA). Ninguna
  fuente CC0 nueva; nada de 2015, TomMusic, «Helton Yan's Pixel Combat» ni Suno. Fila de `docs/recursos.md` al día.
- **Héroes quietos** (lo que pidió el coordinador si quedaba margen): `Pasos3D` (el nodo de pasos que ya tiene cada
  personaje 3D) cuenta el tiempo parado; a los 7-14 s suena un gesto muy discreto del personaje y, mientras siga
  parado, otro cada 22-40 s: Kael se recoloca el cuero y suelta el aire; Lya sorbe por la nariz y se ajusta la tela;
  Garon mueve el equipo y respira hondo. Uno a la vez entre los tres, por Efectos, prioridad 0, los compañeros desde su
  sitio. No hace falta tocar ninguna escena (va donde ya hay `pasos_3d`: Pastos Verdes y la Garganta 3D).

### 2. Archivos y commits (rama `area-sonido`)

| Commit | Qué |
|---|---|
| `acf08b1` | Merge de `integracion-experimental` (`eb8bd94`) |
| `2f419df` | 51 derivados `audio/efectos/bestias/` (+ `.import`), `pruebas/prueba_efectos_preparar.gd` (recetas), `docs/audio/efectos_procedencia.csv` |
| `ae93921` | `sonido.gd`: catálogo de las bestias, `FAMILIAS`, `BESTIAS` |
| `d5d4ee7` | `pruebas/prueba_efectos.gd` (parte «bestias»), `pruebas/prueba_efectos_senal.gd` («mezclas=4»), `pruebas/lista_pruebas.txt` |
| `78ae103` | `docs/audio/inventario_sonidos.md`, `docs/recursos.md` |
| `5a1d108` | 6 derivados `audio/efectos/heroes/`, recetas y CSV |
| `404a315` | `sonido.gd`: gestos de los héroes quietos (`QUIETO`, `Pasos3D`, `grupo_sonando`) |
| `ff786ae` | `pruebas/prueba_efectos.gd` (parte «quietos»), `pruebas/prueba_efectos_senal.gd` |
| `b9507f8` | `docs/audio/inventario_sonidos.md`, `docs/recursos.md` (héroes quietos) |
| (este) | `docs/memory/agents/sonido.md` |

Sin confirmar, porque no es mío: `aethelgard/pruebas/prueba_orden_pv03.gd.uid` (lo generó Godot al importar).

### 3. Pruebas (todas con datos aislados)

- `prueba_efectos`, partes «catalogo», «bestias», «quietos» y «voces» (09/11, sin ventana): **0 fallos**. Catálogo:
  143 efectos, 220 archivos (QOA, mono, 48 kHz; ni saturan ni son mudos). Bestias: los 44 efectos cargan y suenan una
  vez aunque se pidan dos, por Efectos; los avisos acaban antes de su impacto (la prueba cazó el del martillo del
  Custodio, que duraba 1,00 s: recortado a 0,82); herido y caída por familia, sin «_ataque»; el Posadero entra con dos
  voces sonando y una voz de otra bestia no quita la suya. Quietos: 3/2/2 gestos en 45 s, nunca dos a la vez; andando,
  ninguno (sin ventana el driver es mudo y nada acaba solo: la prueba da cada gesto por acabado a los 2 s).
- `prueba_efectos_senal` (con ventana, el driver real, con el ejecutor y `-Lista` propia): **0 fallos**, 57
  grabaciones (`D:\REBELUM_diagnostico\pruebas\2026-11-09_173632\`) y 3 de los gestos (`…\2026-11-09_174602\`). La
  primera pasada (17:33) se cortó sola tras 49 grabaciones, sin error en los registros (había 8 Godot de otras copias,
  algunos con ventana); la segunda, igual pero con los niveles ya ajustados, terminó entera. Lanzarla a mano con `&`
  (sin el ejecutor) también se cortó: uso siempre el ejecutor.
- `prueba_efectos_preparar -- <biblioteca> comprobar`: **146 de 146 originales intactos**.
- **Batería completa** (automáticas, 09/11 a las 17:47, con `b9507f8`): **55 superadas, 2 fallidas, 31 manuales, 0 no
  seguras**; `partida.save` real y carpeta real de datos, sin cambios. Resumen:
  `D:\REBELUM_diagnostico\pruebas\2026-11-09_174741\resumen.md`. Pasan `prueba_efectos` (entera, con «bestias» y
  «quietos»), `prueba_audio`, `prueba_musica`, `prueba_garganta3d`, `prueba_anim_pies` y `prueba_combate_huella`.
  - **Las dos fallidas no son de sonido**: `prueba_mando` y `prueba_teclado` fallan en el mismo punto, «Intro / A junto
    a Tilo no abre el diálogo». Llegan con el merge: `c3f5692` (en `eb8bd94`) cambió lo que pasa al hablar con Tilo
    antes de PV-03, y nada de esta tanda toca diálogos ni Pastos Verdes (los gestos de quieto solo suenan). Pendiente de
    confirmar en `integracion-experimental` por quien lleve narrativa o el coordinador.
  - «Proyecto: cambiado»: era este informe, que escribí mientras corría la pasada (sin confirmar entonces).
  - Había 86 Godot de otras copias durante la pasada.

### 4. Evidencias

- **Muestras para escuchar**, con su índice y una guía de qué escuchar:
  `D:\REBELUM_diagnostico\sonido_muestras\2026-11-09_bestiario\indice.md` (cada efecto solo y una mezcla por ataque con
  los tiempos de su ficha: aviso, impacto con el golpe de siempre y la voz al recibir el contragolpe o al caer; el
  Posadero con su presentación y la victoria) y `…\heroes_quietos\indice.md` (los tres gestos).
- **Niveles a la salida** (Master, todo al 100 %, 09/11, tras un ajuste): avisos −26,4 a −28,4 dBFS de RMS; impactos
  −24,4 a −25,9 (Posadero −22,3 y −22,9); herido −27,4 a −28,3 (Posadero −24,8); caídas −25,0 a −25,7 (Posadero
  −22,2); entradas −25,9 a −28,6; pezuña −29,8; derrumbe −28,9. El golpe de siempre sale a −27,7 y las voces de la
  tanda 2 de −23 a −31. Mezclas: picos de −2,5 a −6,2 dBFS (ninguna satura). Gestos de quieto: −34,7 a −36,9 (los
  pasos, −32 a −39). Primer ajuste: pezuña −2 dB, alarma, campanada, herido del Cencerrante, corte, herido, caída y
  entrada de Velaria, aviso del martillo y caída del Custodio, mordida −1 y trama −2 de la Hilandera, los avisos del
  Posadero −1,5 (tenían picos de −1,4 dBFS).

### 5. Límites

- **Escucha**: nadie lo ha oído. Lo más dudoso, por elegirlo sin oírlo: si el resoplido (caballo) y los gruñidos y
  chillidos (cerdo) suenan a jabalí y no a granja; el cencerro de percusión (una «cowbell» moderna, más grave) en la
  campanada baja; Velaria (un paraguas que se abre y una vela de barco); la trama de eco (una caracola más grave con un
  golpe subsónico); las llaves del Posadero (unas llaves de coche); los gestos de los héroes (una respiración y un
  sorbido pueden sobrar en un diálogo).
- **Pendiente en Redmi**: lo grave (la trama de eco, el portazo y la viga del Posadero, el martillo del Custodio) casi
  no sale por un altavoz de móvil; hay que oírlo allí. Rendimiento: los gestos añaden una cuenta por personaje y
  fotograma (nada medido; no tocaba).
- **Enganche**: los efectos de las bestias no suenan en el juego hasta que combate los pida; los he comprobado por el
  catálogo y en mezclas grabadas, no en un combate de verdad. Los avisos de las cinco bestias que aún no tienen escena
  suponen que suenan al empezar el clip del ataque.
- **Gestos**: no los he oído en una escena de verdad con ventana; suenan también en diálogos y cinemáticas si los
  personajes están quietos (muy bajos).

### 6. Siguiente paso y cambios en archivos de otros

- **Combate** (`combate.gd`, Zarzalín): las líneas de «Cómo pedirlos» del inventario (tanda 4): conectar `aviso`,
  `pezuna`, `impacto` de `zarzalin_3d.gd` a sus efectos, `zarzalin_aviso_colmillo` al llamar a `atacar`, `derrumbe` al
  llamar a `morir()`, `entrada` a `entrada()`, y la `clave` «zarzalin» en `ENEMIGOS` para que `Sonido.recibe()` dé su
  voz. Las demás bestias, igual cuando tengan escena.
- **Animaciones**: si las otras cinco bestias emiten una señal `aviso` (la postura sostenida) como Zarzalín, el aviso
  puede ir ahí en vez de al empezar el clip; los sonidos ya acaban antes del impacto en los dos casos.
- **Usuario**: escuchar el índice de muestras (guía al final del índice).
- **Coordinador**: confirmar o descartar `prueba_orden_pv03.gd.uid`.
