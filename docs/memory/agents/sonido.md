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
