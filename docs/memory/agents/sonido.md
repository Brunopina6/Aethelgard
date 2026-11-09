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
