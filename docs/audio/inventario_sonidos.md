# Inventario de sonidos de AETHELGARD / REBELUM

**Actualizado el 2026-11-09 a mediodía** (T-030, D-064, D-067 y **T-083**: primera tanda de efectos el 08/11;
**segunda tanda** el 09/11 por la mañana: voces de los enemigos, agua de las zonas 2D, la Garganta, el Diario, el
brazalete y la propuesta de sonido de las magias; **tercera tanda** el 09/11 a mediodía: la Garganta 3D, los pasos de
Lya y Garon, las artes nuevas y Oakhaven; **cuarta tanda** el 09/11 por la tarde: las seis bestias del bestiario, solo en el catálogo; rama `area-sonido`). Criterio: de cada sonido, el original, el recurso que
usa el juego, el evento, la licencia y la evidencia. Tres comprobaciones **por separado**:

- **Asignación:** el código pide el sonido correcto, una vez y por su bus (`prueba_musica`, `prueba_audio`,
  `prueba_efectos`; sin ventana, mudas).
- **Señal:** sale sonido de verdad por el bus Master con el driver de audio real (`prueba_musica_senal`,
  `prueba_efectos_senal`, con ventana: graban y miden el nivel). Los WAV grabados quedan para escucharlos.
- **Escucha:** una persona lo oye en el PC o en el Redmi. **Pendiente en todo** hasta que la haga el usuario.

## Ambientes (bus Ambiente)

Bucles de 32 s como mucho, hechos con `aethelgard/pruebas/herramientas/preparar_ambientes.gd`: el final se funde 2 s con el principio,
sonoridad media pareja (RMS ≈ 0,06) sin pasar de un pico de 0,9, guardados en WAV y comprimidos en QOA al importar.

| Recurso | Original (biblioteca del autor, colección CC0) | Fuente y licencia | Dónde suena | Señal (08/11) | Escucha |
|---|---|---|---|---|---|
| `audio/ambiente/pradera.wav` (28,7 s) | `15_nature_weather/birds_48kHz_16bit_30.69s_02_s39.wav` + viento bajo (`wind_…_60s_01_s20`, ×0,28) | isaiah658, «Ambient Bird Sounds» y Luke.RUSTLTD, «wind1» (OpenGameArt): **CC0**, comprobado en sus páginas | Pastos Verdes 3D y zonas de llanura (−6 dB), ciudades (−10 dB) | RMS −29,1 dBFS | Pendiente |
| `audio/ambiente/bosque.wav` (28,0 s) | `16_ambiences/forest_48kHz_16bit_30s_01_s29.wav` | Pixel-boy (Sparklin Labs), «Superpowers assets sound effects»: **CC0**, comprobado | Zonas de bosque (−6 dB) | RMS −30,9 dBFS | Pendiente. **Ojo:** el original venía muy bajo (×35 de ganancia): escuchar si se oye siseo |
| `audio/ambiente/viento.wav` (32,0 s) | `15_nature_weather/wind_48kHz_16bit_60s_02_s20.wav` | Luke.RUSTLTD, «wind1»: **CC0**, comprobado | Mapa del mundo (−14 dB), isla flotante, montaña, nieve y otras zonas (−10 dB) | RMS −38,7 dBFS (en el mapa) | Pendiente |
| `audio/ambiente/mazmorra.wav` (32,0 s) | `16_ambiences/dungeon_loop_48kHz_16bit_94.31s_01_s08.wav` | JaggedStone, «Loopable Dungeon Ambience»: **CC0**, comprobado | La Garganta (−6 dB) | RMS −34,7 dBFS | Pendiente |
| `audio/ambiente/desierto.wav` (32,0 s) | `16_ambiences/desert_48kHz_16bit_35.81s_01_s29.wav` | Pixel-boy, «Superpowers assets sound effects»: **CC0**, comprobado | Zonas de desierto (−8 dB) | RMS −34,1 dBFS | Pendiente |

La comprobación de licencias se hizo en el navegador el 2026-11-08: las cuatro páginas de OpenGameArt dicen
«License(s): CC0». El nombre del autor es el de `LICENSES.txt` de la colección.

## Música (bus Musica)

| Recurso | Origen | Licencia | Dónde suena | Asignación | Señal | Escucha |
|---|---|---|---|---|---|---|
| `musica_combate_normal.mp3` | Sin registrar | **Pendiente** (`licencias_pendientes.txt`) | Combate (`combate.gd`), con sus fundidos y la fase 2 de los jefes | Bus Musica (`prueba_audio`) | RMS −20,2 dBFS | Pendiente |
| Campanas de la cinemática del mirador | Hechas por código (`pastos_verdes_3d.gd`, `campana()`) | Propia | Cinemática del mirador (PV-07) | Bus Musica | Sin medir | Pendiente |
| Canciones de Pastos Verdes (Suno) | ZIP del autor | **No libres**: fuera del proyecto, de las APK y de GitHub | — | — | — | — |

Contextos sin pista con permiso (la carga, el mapa, las zonas): la capa de música queda en **silencio controlado**
(`musica.gd`). La carga da −120 dBFS: silencio de verdad.

## Efectos del juego (T-083, primera tanda): buses Efectos, Interfaz y Ambiente

### Cómo están hechos

- **Biblioteca** (`D:\qtorrent\sound effect`, solo lectura; no se importa entera): de 61 originales salen
  **100 derivados** en `aethelgard/audio/efectos/` (pasos, combate, mundo, interfaz y ambiente), con
  `aethelgard/pruebas/prueba_efectos_preparar.gd`: tramo elegido (a veces con una segunda capa), mono, media banda y
  diezmado al bajar de 96/192 kHz (para que lo de arriba no se cuele como ruido), 48 kHz, fundidos de entrada y salida
  y normalización (pico, o RMS con pico máximo). Se guardan en WAV de 16 bits y se importan en **QOA** (bucle solo
  en el río y la cascada). En el repositorio pesan 17,1 MB (WAV); en la APK, comprimidos.
- **Originales intactos:** su SHA-256 está en [`efectos_procedencia.csv`](efectos_procedencia.csv) (una fila por
  derivado: fuente, tramo, capas, huella, duración, pico y RMS). `prueba_efectos_preparar.gd -- <biblioteca>
  comprobar` vuelve a calcular las huellas.
- **API** (`sonido.gd`): `Sonido.efecto(nombre)` desde el evento real; catálogo `EFECTOS` con variantes, volumen,
  variación de tono, prioridad, máximo a la vez y espera mínima; 10 voces en Efectos, 4 en Interfaz y 4 en
  Ambiente; mientras suena una prioridad 4 (victoria, derrota, jefe, emboscada), los golpes, pasos e interfaz de su
  bus (prioridades 0-2) van 8 dB más bajos (las monedas y el nivel, no); cambio de
  escena, pausa y silencio como dice la cabecera de `sonido.gd`.

### Licencias y evidencia

- **Colección CC0 «500 GAME SOUND EFFECTS»** (`LICENSES.txt`: «All included WAV files are CC0»; cada archivo lleva su
  fuente `sNN`). Páginas comprobadas en el navegador el **2026-11-08**, todas «CC0»: s03 Fantozzi «Footsteps
  (Grass/Sand & Stone)», s13 Kenney «Interface Sounds» (kenney.nl, «Creative Commons CC0»), s14 Kenney «RPG Audio»
  (kenney.nl), s29 Pixel-boy «Superpowers assets sound effects» (OpenGameArt y el README del repositorio de Sparklin
  Labs), s32 Vehicle «Fantasy Sound Effects (Tinysized SFX)», s35 artisticdude «RPG Sound Pack», s40 qubodup «20
  Rustles of dry leaves» y s58 syncopika «Bird chirping sounds».
- **Paquetes GDC de Sonniss** (2016, 2017, 2018, 2019, 2020, 2023 y 2024): `Licensing.pdf` / `License.pdf` de cada
  carpeta (leídos el 08/11): uso en un número ilimitado de proyectos personales y comerciales **sin atribución**,
  sincronización con juegos, editarlos como parte de la producción; **no** se pueden vender tal cual ni atribuirse su
  autoría; el de 2024 prohíbe además entrenar IA con ellos. La página pública
  `sonniss.com/gameaudiogdc` (vista el 08/11) dice lo mismo: «royalty free and commercially usable», «No attribution
  is required», licencia solo para producciones (juegos, cine…) y sin entrenar IA. En el proyecto solo hay derivados.

### Efectos integrados

Volumen: el del catálogo (`sonido.gd`), sobre el derivado normalizado. Prioridad: 0 pasos y detalles · 1 interfaz y
movimientos · 2 golpes y objetos · 3 eventos · 4 victoria, derrota, jefe y emboscada.

| Efecto | Evento real (dónde) | Archivos del juego | Original (biblioteca) | Licencia | Bus · dB · prioridad |
|---|---|---|---|---|---|
| `paso_hierba` | Pie de Kael en la hierba: esqueleto en Pastos Verdes 3D (`pastos_verdes_3d.gd`), fotogramas 1 y 6 de «correr» del muñeco 2D (`zona.gd`, llanuras y ciudades) | `pasos/hierba_1…6` | Tovusound «169_Foley_Footsteps_Grass_Sneaker_Walk_Fast_Run_Jog_Close» (seis pasos sueltos) | Sonniss GDC 2017 | Efectos · −15 · 0 |
| `paso_piedra` | Losas del camino y puente de Pastos Verdes, calles de piedra (`zona.gd`), ciudad flotante (`isla.gd`), Garganta | `pasos/piedra_1…6` | Tovusound «015_Foley_Footsteps_Asphalt_Boot_Walk_Fast_Run_Jog_Close» | Sonniss GDC 2017 | Efectos · −14 · 0 |
| `paso_hojas` | Suelo del bosque (zonas 2D de bosque) | `pasos/hojas_1…5` | Sounds Visual «FX3280 Walking Faster Leaves Foley Foosteps» | Sonniss GDC 2018 | Efectos · −15 · 0 |
| `paso_nieve` | Zonas de nieve | `pasos/nieve_1…5` | Studio 23 «S23_SFX_Footsteps_Snow_Singles_Sequence» | Sonniss GDC 2019 | Efectos · −15 · 0 |
| `paso_grava` | Caminos de tierra, montaña, yermo y la Garganta (grava) | `pasos/grava_1…5` | Studio 23 «S23_SFX_Footsteps_Gravel_Loafers_Loops_Walk_Normal» | Sonniss GDC 2019 | Efectos · −16 · 0 |
| `paso_arena` | Desierto y ceniza | `pasos/arena_1…4` | `02_footsteps/sand_…_s03` (Fantozzi) | CC0 (s03) | Efectos · −14 · 0 |
| `paso_madera` | Puentes de tablas de las zonas 2D | `pasos/madera_1…4` | RYK-Sounds «wooden floor 1 loop» | Sonniss GDC 2023 | Efectos · −13 · 0 |
| `golpe` | Golpe físico resuelto, una vez, en el impacto (`combate.gd`, `_animar_golpe`): ataques de héroes y enemigos, Embuir, cada vuelta del Giro | `combate/golpe_1…4` | Justsoundeffects «WEAPAxe_Long Two-Handed Axe Flesh Hit» (cuatro golpes) | Sonniss GDC 2024 | Efectos · −5 · 2 |
| `golpe_critico` | Crítico; Juicio (Esgrima); la onda del golpe cargado del jefe; «Acabar» | `combate/critico_1…2` | David Dumais «SWSH_Sword Slash Impact V2 Assorted 18» y el hacha de arriba, cada uno con Shapeforms «IMPACT_LOW_THUD_10» debajo | Sonniss GDC 2023, 2024 y 2020 | Efectos · −5 · 3 |
| `golpe_defendido` | Golpe a un héroe que se defiende | `combate/defendido_1…3` | Justsoundeffects «WEAPArmr_Metal Shield Block Hits» | Sonniss GDC 2024 | Efectos · −7 · 2 |
| `defensa` | Orden DEFENDER | `combate/defensa` | Double Trouble «LeatherArmor_Rustle_03» + David Dumais «Metal Sword Sheath 04» | Sonniss GDC 2017 y 2023 | Efectos · −8 · 2 |
| `salto` | Kael 3D salta con el sable (`_anim_salto_3d`) | `combate/salto_1…3` | David Dumais «MeleeSwingsPack … HighSwings15 / NormalSwings39» y «SWSH_Swing 3 Large 03» | Sonniss GDC 2020 y 2023 | Efectos · −9 · 1 |
| `huida` | El grupo huye; un enemigo huye (−4 dB) | `combate/huida` | SoundBits «Whoosh_Cloth_Leather_Fight_174» | Sonniss GDC 2016 | Efectos · −8 · 2 |
| `emboscada` | Empieza un encuentro: mapa, zonas, Pastos Verdes, Garganta (cruza al combate) | `combate/emboscada` | Bluezone «BC0226-whoosh-impact-012» | Sonniss GDC 2017 | Efectos · −4 · 4 |
| `jefe` | Presentación de un jefe | `combate/jefe` | Federico Soler «Dramatic E» | Sonniss GDC 2019 | Efectos · −4 · 4 |
| `fase2` | Segunda fase del jefe | `combate/fase2` | Federico Soler «Angry E» + Sounds Great «Orc… attack_7» | Sonniss GDC 2019 y 2020 | Efectos · −4 · 4 |
| `carga_jefe` | El jefe carga su golpe devastador | `combate/carga_jefe` | Gamemaster «casting_charge_matter_grow_04» | Sonniss GDC 2018 | Efectos · −8 · 3 |
| `embuir` | Garon usa Embuir (habilidad nueva) | `combate/embuir` | Sound Spark «Ice_Spell_Ice_Spell_Buff_Positive_02» | Sonniss GDC 2019 | Efectos · −8 · 2 |
| `victoria` | Victoria | `combate/victoria` | `01_ui_interface/victory_…_2.67s_03_s29` | CC0 (s29) | Efectos · −5 · 4 |
| `derrota` | Derrota | `combate/derrota` | InspectorJ «Failure_01-10_Ensemble-Small_DRY» | Sonniss GDC 2023 | Efectos · −5 · 4 |
| `nivel` | Un héroe sube de nivel | `combate/nivel` | CB Sound Design «Harp_Glissando_10b» (2,6 s) | Sonniss GDC 2023 | Efectos · −7 · 3 |
| `monedas` | Monedas al vencer; compras de la tienda | `combate/monedas_1…3` | Effectsworks «Coins_Pouch_Leather_Drop_Into_Takes_3» (tres tomas) | Sonniss GDC 2018 | Efectos · −9 · 3 |
| `pocion` | Poción (y Éter, un 12 % más agudo) en combate y en el menú | `combate/pocion` | `12_items_inventory/bottle_uncork_…_s32` + `bottle_…_s35` | CC0 (s32, s35) | Efectos · −8 · 2 |
| `cofre` | Se abre un cofre (Pastos Verdes 3D, zonas 2D, el cofre raro de la Garganta) | `mundo/cofre_1…3` | `11_doors_locks/creak_…_s14` (Kenney) | CC0 (s14) | Efectos · −7 · 3 |
| `tesoro` | El premio del cofre (0,3 s después) y la mecha de Tilo (PV-14) | `mundo/tesoro` | Gamemaster «collect_item_14» | Sonniss GDC 2017 | Efectos · −8 · 3 |
| `union` | Lya (PV-03) y Garon (PV-05) se unen al grupo | `mundo/union` | CB Sound Design «Harp_Glissando_10b» (1,8 s) | Sonniss GDC 2023 | Efectos · −10 · 3 |
| `examinar` | Examinar la estela y los detalles de lore | `mundo/examinar` | 3maze «marimba_tone_007» | Sonniss GDC 2019 | Efectos · −11 · 1 |
| `pagina` | Nueva página en el Diario; abrir el Diario | `mundo/pagina` | The Soundcatcher «Paper_Pergament_Pages_Turn_Flip_20» | Sonniss GDC 2017 | Efectos · −8 · 2 |
| `misterio` | Nueva página en el Diario (0,2 s después de la página) | `mundo/misterio` | InspectorJ «Mystery_01-11_Ensemble-Large_WET» (4,5 s) | Sonniss GDC 2023 | Efectos · −10 · 3 |
| `palanca` | La palanca de la Garganta | `mundo/palanca` | Bluezone «BC0302_industrial_lever_switch_014» | Sonniss GDC 2024 | Efectos · −6 · 3 |
| `atascado` | El ascensor de la Garganta sin fuerza | `mundo/atascado` | Bluezone «BC0302_industrial_lever_switch_small_003» | Sonniss GDC 2024 | Efectos · −9 · 2 |
| `puente_baja` | El puente que baja a lo lejos (0,5 s tras la palanca) | `mundo/puente_baja` | Conor Bradley «Heavy_Chain-Foley_On_Wood» (con paso bajo: lejos) | Sonniss GDC 2020 | Efectos · −9 · 3 |
| `ascensor` | Viajar en el ascensor de la Garganta | `mundo/ascensor` | Conor Bradley «Jingle_Chain-Sustained_Foley» | Sonniss GDC 2020 | Efectos · −6 · 2 |
| `cerrada` | La puerta sellada no cede | `mundo/cerrada` | 344 Audio «Dungeon Door Open, Close, Locked» (la parte «locked») | Sonniss GDC 2020 | Efectos · −8 · 2 |
| `guardado` | Punto de guardado de la Garganta | `mundo/guardado` | CB Sound Design «Enchanting_Bells_4» (2,6 s) | Sonniss GDC 2023 | Efectos · −9 · 3 |
| `posada` | Descansar en la posada | `mundo/posada` | CB Sound Design «Enchanting_Bells_4» (otros 3,3 s) | Sonniss GDC 2023 | Efectos · −9 · 3 |
| `portal` | Cruzar el portal a la ciudad flotante y bajar de ella (cruza la escena) | `mundo/portal` | David Dumais «Magic_Transformation03» | Sonniss GDC 2020 | Efectos · −6 · 3 |
| `entrar` | Entrar en un lugar desde el mapa (cruza la escena) | `mundo/entrar` | SoundBits «Whoosh_Rod_Pole_022» | Sonniss GDC 2016 | Efectos · −12 · 2 |
| `ui_tic` · `ui_confirmar` · `ui_clac` · `ui_mejora` | Pestañas y héroe del menú del grupo y de la tienda, botones del mapa; incienso; subir un atributo (confirmar más agudo) | Hechos por código (`menu_combate.gd`, `sonidos_ui`) | — | Propia | Interfaz · −6 · 1 |
| `ui_abrir` · `ui_cerrar` | Abrir y cerrar el menú del grupo y la tienda | `interfaz/abrir`, `interfaz/cerrar` | `01_ui_interface/open_…_s13`, `close_…_s13` (Kenney) | CC0 (s13) | Interfaz · −14 · 1 |
| `ui_atras` | Atrás en la tienda (al elegir quién aprende una magia) | `interfaz/atras` | `back_…_03_s13` (Kenney) | CC0 (s13) | Interfaz · −12 · 1 |
| `ui_error` | Opción apagada del menú de combate; compra o posada sin dinero | `interfaz/error` | `error_…_01_s13` (Kenney) | CC0 (s13) | Interfaz · −13 · 1 |
| `ui_equipar` · `ui_equipar_arma` | Cambiar armadura o accesorio · cambiar de arma (menú del grupo) | `interfaz/equipar`, `interfaz/equipar_arma` | Double Trouble «LeatherArmor_Rustle_03» · David Dumais «Metal Sword Sheath 04» | Sonniss GDC 2017 y 2023 | Interfaz · −12 · 1 |
| `rio` | Río de Pastos Verdes 3D: emisor a lo largo del cauce, en el punto más cercano a quien escucha | `ambiente/rio` (30 s, bucle) | Ivo Vicic «74 River_mid field_LOOP 2» | Sonniss GDC 2020 | Ambiente · −3 · 3D (4 m de referencia, hasta 32 m) |
| `cascada` | Cascada de Pastos Verdes 3D | `ambiente/cascada` (30 s, bucle) | Bluezone «BC0259_wilderness_flowing_water_waterfall_small_002» | Sonniss GDC 2020 | Ambiente · +3 · 3D (8 m, hasta 45 m) |
| `rafaga_hierba` | De vez en cuando en la pradera (9–20 s), las ciudades y los lugares de viento | `ambiente/rafaga_hierba_1…4` | Hzandbits «Wind,Ext,Gust,Grasslands,Rustle,Buffeting» (cuatro ráfagas) | Sonniss GDC 2017 | Ambiente · −14 · 0 |
| `rafaga_arbol` | De vez en cuando en el bosque | `ambiente/rafaga_arbol_1…4` | Pole Position «Wind - Aspen - Gusts - Close - Inside Canopy» | Sonniss GDC 2024 | Ambiente · −14 · 0 |
| `pajaro` | De vez en cuando en la pradera y las ciudades | `ambiente/pajaro` | `15_nature_weather/birds_…_3s_01_s58` | CC0 (s58) | Ambiente · −18 · 0 |
| `hojas` | De vez en cuando en el bosque | `ambiente/hojas_1…2` | `15_nature_weather/leaves_…_s40` | CC0 (s40) | Ambiente · −16 · 0 |
| `gota` | De vez en cuando en la Garganta | `ambiente/gota_1…3` | `14_water_mud_slime/water_drop_…_s32` | CC0 (s32) | Ambiente · −16 · 0 |

El cofre de Pastos Verdes sonaba con un sonido hecho por código; ahora suenan `cofre` y `tesoro`. El de código
(`sonido_cofre()`) se queda para compararlo (`prueba_region3d_fotos` lo guarda en WAV) y para `prueba_cofre3d`.

## Efectos de la tanda 2 (T-083, 2026-11-09)

Hechos igual que los de la primera tanda (`prueba_efectos_preparar.gd`, ahora con `solo=` para rehacer solo unas
recetas sin tocar las demás ni sus `.import`, y con `tono` para remuestrear: más agudo y corto en una criatura más
pequeña, más grave y lento en una más grande). **37 derivados nuevos** (137 en total) de 30 originales principales
más sus capas; las huellas, en [`efectos_procedencia.csv`](efectos_procedencia.csv) («comprobar»: 88 de 88
originales intactos el 09/11).

**Licencias nuevas de la colección CC0**, comprobadas en la página de OpenGameArt de cada fuente el **2026-11-09**
(navegador integrado; todas dicen «License(s): CC0»): s06 Independent.nu «8 wet squish, slurp impacts», s34
artisticdude «Goblins Sound Pack», s51 rubberduck «25 CC0 mud sfx», s53 rubberduck «40 CC0 water / splash / slime
SFX», s57 rubberduck «80 CC0 creature SFX» (y, para la propuesta de magias, s09 JaggedStone «Magic Spell SFX» y s10
Julien Matthey «Fireball»; también se comprobaron s24, s33, s52 y s56, que no se usan). Los paquetes de Sonniss son
de los años ya comprobados (2016-2024; el de 2015 sigue sin usarse).

### Voces de los enemigos (bus Efectos; grupo «voz»: dos a la vez como mucho)

Una sola vez por evento real, desde `combate.gd`: **ataque** cuando el enemigo llega y se lanza (`_anim_ataque_3d`,
`_anim_fisico_imagen`, `_anim_fisico_sprite`, `_anim_fisico`), **herido** o **caída** cuando un golpe *físico* ya le
ha quitado los PV (`Sonido.recibe` en el impacto de `_animar_golpe`, de Juicio y de cada vuelta del Giro). Una voz por
enemigo (la nueva corta la suya); la «espera» de cada voz hace que el Giro, que golpea a varios a la vez, dé una voz
por familia. Con **furia** (menos del 30 % de vida), el ataque suena 2 dB más fuerte y un poco más grave. Los héroes
no tienen voz. **Las magias no piden voces** (ni la quemadura del Fuego ni Érebo): su presentación está protegida y
las voces con magia van en la propuesta de abajo. Prioridades: ataque y herido 2 (bajan 8 dB durante la victoria),
caída 3.

| Efecto | Evento real (dónde) | Archivos del juego | Original (biblioteca) | Licencia | dB · p |
|---|---|---|---|---|---|
| `limo_ataque` | El slime se estira y se lanza (`_anim_fisico_sprite`) | `voces/limo_ataque_1…2` | `14_water_mud_slime/mud_…_01_s51` · Bluezone «synthetic-liquid-short-texture-057» | CC0 (s51) · Sonniss GDC 2017 | −6 · 2 |
| `limo_herido` | Golpe físico que no lo tumba | `voces/limo_herido_1…3` | `08_creatures_monsters/slime_…_01_s35`, `…_03_s35` · `mud_…_03_s51` | CC0 (s35, s51) | −6 · 2 |
| `limo_caida` | El golpe que lo tumba | `voces/limo_caida_1…2` | `impactsplat_…_05_s06` y `…_03_s06` con burbujas `bubbles_…_s53` debajo | CC0 (s06, s53) | −8 · 3 |
| `goblin_ataque` | Grimfang (y el Hollín de respaldo) llega y alza el hacha | `voces/goblin_ataque_1…3` | Phase 4 «MR - Orc Attack VO 04» · `goblin_…_02_s34` · Sounds Great «attack_7» (×1,15: más pequeño) | Sonniss GDC 2020 · CC0 (s34) | −13 · 2 |
| `goblin_herido` | Golpe físico que no lo tumba | `voces/goblin_herido_1…3` | Sounds Great «hit_injured_5» (×1,12) · `goblin_…_01_s34` · `creature_hurt_…_04_s57` | Sonniss GDC 2020 · CC0 (s34, s57) | −14 · 2 |
| `goblin_caida` | El golpe que lo tumba | `voces/goblin_caida_1…2` | Sounds Great «pain_scream_5» (×1,1) · MatiasMacSD «Creature_Monster_Pain_01» | Sonniss GDC 2020 y 2017 | −11 · 3 |
| `gorthor_ataque` | Gorthor llega y alza el hacha | `voces/gorthor_ataque_1…2` | Sounds Great «attack_7» (×0,85: más grande) · David Dumais «LargeMonster11_Roar03» | Sonniss GDC 2020 y 2023 | −10 · 3 |
| `gorthor_herido` | Golpe físico (también el que lo deja de rodillas) | `voces/gorthor_herido_1…2` | Gamemaster «troll_monster_hurt_pain_01» (×0,88) · Sounds Great «surprise_2» (×0,85) | Sonniss GDC 2017 y 2020 | −13 · 2 |
| `gorthor_caida` | Cae de rodillas (último aliento, `_decidir`) | `voces/gorthor_caida` | David Dumais «Monster9_Death10» + las rodillas: Bluezone «creature_wood_footstep_medium_004» | Sonniss GDC 2020 | −8 · 3 |
| `gorthor_muerte` | «Acabar» (`_acabar`, con el golpe crítico) | `voces/gorthor_muerte` | Gamemaster «troll_monster_death_01» (×0,9) | Sonniss GDC 2017 | −9 · 3 |
| `gorthor_devorar` | El mordisco de Devorar (segunda fase), en el impacto | `voces/gorthor_devorar` | Olivier Girardot «Monster Bite 3» | Sonniss GDC 2018 | −10 · 3 |
| `piedra_ataque` | El Guardián de piedra se lanza (`_anim_fisico_imagen`) | `voces/piedra_ataque_1…2` | Gregor Quendel «Designed Rocks - ELEM017 - Melodic 4» con un arrastre de roca de Wav Junction («0119…» y «0093…») | Sonniss GDC 2018 y 2020 | −11 · 2 |
| `piedra_herido` | Golpe físico | `voces/piedra_herido_1…3` | BluezoneCorp «stone_impact_hammer_015» y «stone_impact_015» · Soundrangers «boulder_impact_on_stones_14» | Sonniss GDC 2024 y 2018 | −8 · 2 |
| `piedra_caida` | Se derrumba | `voces/piedra_caida_1…2` | Mechanical Wave «Crumbling Rock Slide_RBDII 07» con el pedrusco debajo · Soundrangers «dirt_collapse_05» con «stone_impact_041» | Sonniss GDC 2017, 2018 y 2024 | −5 · 3 |
| `ambar_ataque` | El Gólem de ámbar se lanza | los de `piedra_ataque`, un 12 % más agudos (`tono_fijo`) | (los de la piedra) | (los de la piedra) | −11 · 2 |
| `ambar_herido` | Golpe físico | `voces/ambar_herido_1…2` | la piedra con cristal debajo: Stuart Duffield «Ice_impact_lite_02» y «Ice_smash_light_02» | Sonniss GDC 2024 y 2016 | −8 · 2 |
| `ambar_caida` | Se derrumba | `voces/ambar_caida` | el derrumbe con BluezoneCorp «glass_impact_break_falling_debris_004» | Sonniss GDC 2017 y 2023 | −5 · 3 |

**El segundo tajo del doble ataque** (Grimfang y Gorthor, `atacar_hacha`): se ve y tiembla, pero no hace daño (el
daño va en el primero). **Decisión del especialista (09/11): suena, 6 dB más bajo** (el mismo golpe o, si el héroe se
defiende, el del escudo), en `_anim_ataque_3d`. Un tajo que se ve y no se oye parece un fallo; más bajo, no parece un
segundo daño. Lo comprueba `prueba_efectos` (dos tajos que suenan, separados 0,62 s como la animación).

### Más combate, mundo e interfaz

| Efecto | Evento real (dónde) | Archivo del juego | Original | Licencia | Bus · dB · p |
|---|---|---|---|---|---|
| `congelar` | Un enemigo se congela (Frostfang o Embuir de hielo; `_congelar`, solo la primera vez) | `combate/congelar` | BluezoneCorp «ice_crack_break_078» | Sonniss GDC 2023 | Efectos · −9 · 2 |
| `puerta_abre` | La puerta sellada de P3 se abre a lo lejos, 1,3 s tras la palanca (`garganta.gd`, `_tirar_palanca`) | `mundo/puerta_abre` | 344 Audio «Dungeon Door Open, Close, Locked» (la parte «open», con paso bajo: lejos; la misma puerta que suena «cerrada») | Sonniss GDC 2020 | Efectos · −9 · 3 |
| `brazalete` | El brazalete de Kael brilla junto a un detalle sin ver (`zona.gd`, `_brazalete`; una vez por detalle) | `mundo/brazalete` | CB Sound Design «Enchanting_Bells_4» (0,6-1,9 s: el principio, suave) | Sonniss GDC 2023 | Efectos · −17 · 1 |
| `libro_hoja` | Cambiar de pestaña en el Diario (solo si cambia; `diario.gd`) | `interfaz/libro_hoja` | `13_paper_books/book_flip_…_02_s14` | CC0 (s14, Kenney) | Interfaz · −8 · 1 |
| `libro_cerrar` | Cerrar el Diario | `interfaz/libro_cerrar` | `13_paper_books/book_close_…_01_s14` | CC0 (s14, Kenney) | Interfaz · −11 · 1 |
| `examinar` (el de siempre) | Examinar el altar o monumento de una zona (antes solo sonaba el texto) | `mundo/examinar` | (tanda 1) | (tanda 1) | Efectos · −11 · 1 |
| `rio_2d` | El río de las zonas 2D, por cercanía (abajo) | `ambiente/rio` (el bucle del río 3D) | (tanda 1) | (tanda 1) | Ambiente · −5 |

**El agua de las zonas 2D** (`Sonido.agua_zona`, desde `zona.gd`): un emisor 2D (suena a la izquierda o a la
derecha) se pone en el punto del **río** más cercano a Kael; el río es el agua que cruza la zona de lado a lado (las
charcas, quietas, no suenan a corriente: `mascara_rio`). Volumen: todo a 1,5 casillas de la orilla o menos, la mitad
del nivel cada vez que se dobla la distancia, y se apaga del todo hacia las 9 casillas, donde deja de sonar (no ocupa
nada). Los cambios van con un fundido de 0,8 s; al salir de la zona (combate o mapa) se funde a cero. Solo agua de
verdad: el hielo, el abismo de la Garganta, la lava y el veneno no suenan (de momento). Medido a la salida (09/11):
RMS −33,1 dBFS en la orilla, −38,7 a 3 casillas y −45,3 a 6, frente al ambiente de la pradera (−29 dBFS): no lo
tapa; juntos dan −29,8 dBFS.

**La Garganta 2D, evento por evento** (`garganta.gd`; la Garganta 3D es de otro especialista y no se ha tocado):
guardar (`guardado`), la puerta sellada que no cede (`cerrada`), la palanca (`palanca`), el puente que baja a lo
lejos (`puente_baja`, 0,5 s después), **la puerta que se abre a lo lejos (`puerta_abre`, 1,3 s después: nuevo)**, el
ascensor sin fuerza (`atascado`) y ya con fuerza (`ascensor`), el cofre raro del nido (`cofre` y `tesoro`), el
combate del nido y el de Gorthor (`emboscada`; en el combate, las voces), las gotas de la mazmorra (`gota`) y los pasos
(grava, losas y tablas de los puentes colgantes). `prueba_efectos` los recorre todos.

**Interfaz sin duplicar «tic»:** el Diario no tenía sonido al cambiar de pestaña ni al cerrar; abrirlo ya sonaba
(`pagina`, en `mapa.gd`). No se ha añadido ningún «tic» donde ya había uno. En archivos de otros (propuesto en el
informe): `mapa.gd` (gráficos, mapamundi nuevo) no tiene huecos en lo que hay hoy (botones con «tic», Diario,
emboscada, entrar y portal ya suenan), pero lo nuevo que pinte (por ejemplo, un lugar que se descubre) necesitará su
línea; Pastos Verdes 3D no hace brillar el brazalete (si algún día lo hace, `Sonido.efecto("brazalete")`).

### Magias: PROPUESTA de sonido, **no integrada** (D-048)

El catálogo mágico no cambia: Fuego, Llamarada, Infierno, Agua, Torrente, Maremoto, Rayo, Tormenta, Cólera del
Cielo, Cura, Bendición y Gracia Divina **siguen sin sonar** (lo comprueba `prueba_efectos`: una magia no pide ningún
efecto, tampoco voces). Darles sonido añade una capa a su presentación protegida: es una decisión del usuario. Esta es
la propuesta, con **un candidato por magia y nivel**; las muestras para escucharlas están en
`D:\REBELUM_diagnostico\sonido_muestras\2026-11-09\magias\` (archivos tal cual quedarían, a −1/−2 dBFS de pico, con su
CSV de procedencia; no están en el proyecto). Se harían con `prueba_efectos_preparar.gd` (`RECETAS_MAGIAS`, que hoy
solo escribe fuera, con «magias=»).

| Magia | Nivel | Candidato (archivo y tramo) | Licencia | Cómo se engancharía (una línea, sin cambiar tiempos ni dibujo) |
|---|---|---|---|---|
| Fuego | I | `07_magic_spells/fireball_…_01_s10` (0,15-1,6 s), Julien Matthey «Fireball» | CC0 (s10, comprobada el 09/11) | En el impacto de la magia (`_animar_golpe`, `impacto`, si `magia == "Fuego"`) |
| Llamarada | II | Sound Spark «Fire_Spell_Dragon_Trap_03» (0,15-1,9 s) | Sonniss GDC 2019 | Al empezar el efecto de grupo (`_magia_grupal`, Fuego II) |
| Infierno | III | David Dumais «MagicPack2_Earth_MeteorShower003» (1,4-6 s: una lluvia de meteoros, como su dibujo) | Sonniss GDC 2023 | Al empezar `_lluvia_meteoros` |
| Agua | I | Gamemaster «water_blast_projectile_spell_03» (0-1 s) | Sonniss GDC 2018 | En el impacto (`magia == "Agua"`) |
| Torrente | II | David Dumais «Magic_Spells_CastShort_Water_General07» (0,05-1,85 s) | Sonniss GDC 2020 | Al empezar `_magia_grupal` (Agua II) |
| Maremoto | III | David Dumais «MagicPack2_WaterExplosions_Explosion2-004» (0-2,4 s) con «WaterCombo02» debajo (−8 dB) | Sonniss GDC 2023 y 2020 | Al empezar `_maremoto` |
| Rayo | I | Gamemaster «electric_surge_blast_04» (0-1,4 s) | Sonniss GDC 2018 | En el impacto (`magia == "Rayo"`) |
| Tormenta | II | David Dumais «MagicPack2_ElectricitySpells_Spell2-002» (0,15-2,2 s) | Sonniss GDC 2023 | Al empezar `_tormenta` (nivel II) |
| Cólera del Cielo | III | Soundrangers «thunder_strike_03» (0,3-4,4 s: un trueno cercano) | Sonniss GDC 2018 | Al empezar `_tormenta` (nivel III) |
| Cura | I | `07_magic_spells/magic_…_03_s09`, JaggedStone «Magic Spell SFX» | CC0 (s09, comprobada el 09/11) | En `_lanzar_cura` (nivel I), al llegar la luz |
| Bendición | II | `07_magic_spells/magic_…_08_s29`, Pixel-boy | CC0 (s29, comprobada el 08/11) | En `_lanzar_cura` (nivel II) |
| Gracia Divina | III | InspectorJ «Discovery_01-03_Organ-A_WET» (0-4 s, órgano y coro) con las campanas de «Enchanting_Bells_4» debajo (−10 dB) | Sonniss GDC 2023 | En `_lanzar_cura` (nivel III) |

Si se aprueba: un efecto por magia en el catálogo (prioridad 3, una vez por lanzamiento), las voces de herido y caída
también con las magias, la quemadura del Fuego con un chisporroteo corto, y escucharlo todo con la música de combate.
Érebo sigue con sus 7 sonidos de licencia pendiente (no se han tocado).

## Efectos de la tanda 3 (T-083, 2026-11-09, mediodía)

Hechos igual (`prueba_efectos_preparar.gd`, con «solo=»): **23 derivados nuevos** (160 en total) de 20 originales
principales y 7 capas, con sus huellas en [`efectos_procedencia.csv`](efectos_procedencia.csv). **Licencias:** todos
de los paquetes GDC de Sonniss 2016, 2017, 2018, 2019, 2020, 2023 y 2024 (el PDF de licencia de cada paquete está en su
carpeta: comprobado otra vez el 09/11), salvo `esquiva_1`, de la colección CC0 (s32, Vehicle «Tinysized SFX»,
comprobada el 08/11). Ninguno es del paquete de 2015, de TomMusic, de «Helton Yan's Pixel Combat» ni de Suno.

### La Garganta del Diablo 3D (`zonas3d/garganta_3d.gd`, `_sonido_3d`)

- **Se escucha desde Kael** (`Sonido.oyente_3d`), mirando como la cámara.
- **Pasos según el suelo** (`suelo_de_pasos`): **tablas** (`paso_madera`) en los puentes colgantes, el levadizo y las
  estaciones del ascensor; **roca** (`paso_piedra`) en lo demás (cornisas, escaleras talladas, la arena y el nido).
  Lya y Garon llevan los suyos con el mismo suelo (`grupo.pasos_superficie`, una línea en `_crear_grupo`).
- **La cascada grande** (`cascada_grande`): un emisor a lo largo de su caída (x = 3,6, de y = 26 a −40): suena desde
  el punto a la altura de quien escucha. Se oye en toda la garganta: de lejos, solo el rumor grave (Godot quita los
  agudos con la distancia).
- **El viento del abismo** (`viento_abismo`, un aullido tonal): a lo largo del eje del abismo (y = −5) y, 6 dB más bajo,
  bajo los dos puentes colgantes (y = −2,5): al cruzarlos se está encima del vacío y el viento sube.
- **Las gotas en la roca:** la mazmorra (también la 2D) tiene ahora `gota` y `gota_cueva`; en la 3D cada una cae en la
  pared de roca más cercana a Kael (`Sonido.detalles_3d` con `_punto_gota`), algo por delante o detrás y por encima.
- **El eco de la garganta** (`Sonido.eco(self, "garganta")`, `ECO` en `sonido.gd`): una reverberación al final de los
  buses Efectos (0,45) y Ambiente (0,35), con lo directo a 0,92; nunca en la música ni en la interfaz. Se quita sola al
  salir (combate, mapa). Medido el 09/11 con el driver real (A/B, mismo sonido): un paso de roca deja una cola unos 26 dB
  por debajo del golpe entre 0,1 y 0,4 s y 36 dB entre 0,4 y 1 s; una gota, 16 y 25 dB (suena a cueva); la palanca sube
  2,3 dB de pico y la emboscada 1,5 (sin saturar); el bucle del viento no cambia de nivel (−0,3 dB). Con 0,16 de
  «húmedo» (la primera prueba) la cola quedaba a 36 y 48 dB: no se oía. **Coste:** dos efectos de bus solo en esa
  escena; sin medir en el Redmi.
- **Los efectos de la 2D, una vez cada uno** (comprobado pulsando dos veces): guardar, la puerta sellada, el ascensor
  sin fuerza y con fuerza, la palanca, el cofre raro (tapa y premio), examinar y la emboscada. **El puente que baja**
  suena desde el levadizo (a unos 14 m de la palanca, a la izquierda) y **la puerta que se abre** (nuevo en la 3D: en la
  2D ya sonaba) desde la puerta, a 1,3 s, como en la 2D. Lo que pasa junto a Kael (palanca, cofre, ascensor) suena sin
  posición, como siempre.

| Efecto | Dónde suena | Archivo del juego | Original (biblioteca) | Licencia | Bus · dB · 3D |
|---|---|---|---|---|---|
| `cascada_grande` | La cascada del muro del norte (bucle) | `ambiente/cascada_grande` (30 s) | Justsoundeffects «WATRFall_Waterfall Roaring Rumble_03» (Streams and Rivers) | Sonniss GDC 2023 | Ambiente · 0 · 10 m de referencia, hasta 120 m |
| `viento_abismo` | El eje del abismo y bajo los puentes (bucle) | `ambiente/viento_abismo` (30 s) | Hzandbits «Wind,Int,Howl,Tonal,Mumble» (Howling Winds - Interior) | Sonniss GDC 2016 | Ambiente · −2,5 (−8,5 bajo los puentes) · 8 m, hasta 70 m |
| `gota_cueva` | De vez en cuando en la mazmorra (2D y 3D) | `ambiente/gota_cueva_1…2` | InMotionAudio «WATRDrip_SingleDripDesign05» (Cave Design); la 2.ª, ×0,84 | Sonniss GDC 2024 | Ambiente · −14 · en la roca (3 m) |
| `puente_baja` · `puerta_abre` | En la Garganta 3D, desde el levadizo y desde la puerta | (los de la tanda 1 y 2) | (los mismos) | (los mismos) | Efectos · −9 · 14 m y 20 m de referencia, sin quitar agudos (ya vienen «lejos») |

**Niveles a la salida** (Master, todo al 100 %, en la escena de verdad con Lya y Garon, 09/11): ver la tabla de
muestras de la tanda 3 en el informe y en `D:\REBELUM_diagnostico\sonido_muestras\2026-11-09_tanda3\indice.md`.

### Los pasos de Lya y Garon (`sonido.gd`, `Pasos3D`)

- **Desde su pie, en el espacio:** con un oyente 3D (Pastos Verdes y la Garganta), los pasos de quien no es el que
  escucha suenan desde el hueso del pie que pisa (`PASO_3D`: a 2,5 m de la cabeza de Kael, a su volumen; más lejos, más
  bajos; lo agudo apenas cambia). Detrás de Kael (2-3 m) quedan unos 1-3 dB por debajo, a un lado o al otro según
  vayan; si se quedan atrás, más bajos. Los de Kael siguen sin posición (están en sus oídos).
- **Un volumen por personaje** (`DB_PASOS`, por el nombre del nodo que les da `grupo_3d.gd`): Lya −2 dB (pisa más
  ligera), Garon 0. Sin oyente 3D, 3 dB más bajos (`DB_COMPANERO_SIN_POSICION`).
- **Sin duplicar ni perder:** un nodo «Pasos» por personaje (lo comprueba `prueba_anim_pies`); la espera mínima entre
  dos pasos es ahora de cada cuerpo (antes, si dos pisaban a la vez el mismo suelo, se perdía uno: casi la mitad de los
  de los compañeros); hasta 3 pasos del mismo suelo a la vez (antes 2). En la Garganta, 9 de 9 pisadas de Kael, 9 de 9
  de Lya y 8 de 8 de Garon sonaron (`prueba_efectos`, 09/11).

### Las artes nuevas (T-091; las engancha combate en `combate.gd`)

No son las 12 magias de siempre (que siguen sin sonar): son Alba, Escarcha y Lumbre. `artes.gd` pide sus nombres
(`SONIDO_LANZAR`, `SONIDO_ESTADO`) y `combate.gd` solo los pide si existen en el catálogo (`_sonar`). Bus Efectos;
prioridad 3 los lanzamientos, 1 los toques (Aliento, la coraza que absorbe) y 2 la esquiva.

| Efecto | Evento (lo pide) | Archivo del juego | Original (biblioteca) | Licencia | dB · p |
|---|---|---|---|---|---|
| `arte_alba` | Compás del Alba (Alba I): una campanilla que sube y un tic de reloj | `combate/arte_alba` | The Chris Alan «Bell Guitar Gliss Up 01» + InspectorJ «CLOCKTick_InsJ_Clock-07_Ticking_Single-01» | Sonniss GDC 2019 y 2023 | −11 · 3 |
| `arte_ocaso` | Peso del Ocaso (Alba II): un tono que cae y un golpe sordo | `combate/arte_ocaso` | The Chris Alan «Marimba Gliss Down Fast 01» (×0,8) + 344 Audio «Explosive Hit 10 Filtered, Low End» | Sonniss GDC 2019 | −10 · 3 |
| `arte_hora_dorada` | Hora Dorada (Alba III): un acorde cálido que crece, con campanillas | `combate/arte_hora_dorada` | BluezoneCorp «BC0273_eternity_synth_chord_002_01» + «…_chimes_texture_001» | Sonniss GDC 2023 | −9 · 3 |
| `arte_escarcha` | Las tres de Escarcha: la coraza de hielo se forma y cruje | `combate/arte_escarcha` | David Dumais «Magic_Spells_CastShort_Ice_General24» + Soundrangers «ice_freeze_crack_04» | Sonniss GDC 2020 y 2018 | −9 · 3 |
| `barrera_absorbe` | La coraza absorbe un golpe (dos a la vez como mucho, cada 0,05 s) | `combate/barrera_absorbe_1…2` | George Karagioules «Wine Glass Hit Higher Pitch» (dos golpes) | Sonniss GDC 2016 | −8 · 1 |
| `barrera_rota` | La coraza se rompe | `combate/barrera_rota` | Chris Skyes «Glass,Shards,Smash,Medium Impact,Lots of Large Shards» + David Dumais «Magic_Spells_Impact_Ice13» | Sonniss GDC 2017 y 2020 | −9 · 3 |
| `arte_lumbre` | Segundo Aliento y Última Brasa (Lumbre II y III): una subida cálida con una campana suave | `combate/arte_lumbre` | Gregor Quendel «Designed Fire - Winds - Binaural, swoosh, waves 02» + CB Sounddesign «Bell_10_b» | Sonniss GDC 2018 | −9 · 3 |
| `renacer` | Lumbre de Retorno (Lumbre I): un soplo que se levanta, con brasas | `combate/renacer` | Airborne Sound «Whoosh, Sound Design, Airy, Full, Soft, Shudder, Very Slow, Aftershock» + Gregor Quendel «Designed Fire - Swooshes - Burst, evolving 34» | Sonniss GDC 2019 y 2018 | −9 · 3 |
| `aliento` | Aliento: cura al empezar el turno (muy suave, uno a la vez) | `combate/aliento` | Eiravaein Works «Helinä, windchimes, Pacific, obsidian, beads…» | Sonniss GDC 2019 | −13 · 1 |
| `brasa` | Brasa: el aliado que cae se levanta (chisporroteo y campana) | `combate/brasa` | The Sound Keeper «sm-fire-firewood-small-03» + «Bell_10_b» + Gregor Quendel (la llamarada) | Sonniss GDC 2018 | −11 · 3 |
| `esquiva` | Esquiva (Pluma de arpía): un silbido de aire | `combate/esquiva_1…2` | `04_combat_melee/tin_whistle_whoosh_…_s32` · Airborne Sound «Whoosh, Sound Design, Airy, Full, Forceful, Soft» | CC0 (s32) · Sonniss GDC 2019 | −9 · 2 |

**Niveles a la salida** (cada una sola, Master al 100 %, 09/11): los lanzamientos, RMS −24 a −26 dBFS (como Embuir y
la unión al grupo; el golpe de siempre, −27,7); Aliento −36,9; la coraza que absorbe −33 (pico −12); esquiva −24 (un
silbido de 0,1 s).

### Oakhaven (T-089; los engancha narrativa en su escena)

| Efecto | Qué es | Archivo del juego | Original (biblioteca) | Licencia | Bus · dB |
|---|---|---|---|---|---|
| `campana` | La campana lejana de la Torre de la Campana (unas campanadas, con paso bajo: lejos) | `mundo/campana` (6,4 s) | Justsoundeffects «AMBRlgn_Church Bells Ringing Village» (Urban Ambiences) | Sonniss GDC 2023 | Ambiente · −12 |
| `taberna` | El bullicio de la Taberna del Cuervo Oxidado, oído desde la calle (bucle, por cercanía) | `ambiente/taberna` (30 s) | West Wolf «RA_06_Restaurant_Dinner_Int_Walla_Crowd_50-75 People» (paso bajo 2,6 kHz: a través de la puerta) | Sonniss GDC 2018 | Ambiente · −2 (a 2 casillas o menos; callado a 11) |
| `cuervo` | El letrero del cuervo de hierro que chirría con el viento (de vez en cuando, cada 4-11 s, por cercanía) | `mundo/cuervo_1…3` | SoundBits «Metal_Creak_13» (dos chirridos) · RZ Post «Creepy Door, Fast Metal Creak_02» | Sonniss GDC 2017 y 2018 | Ambiente · −12 (a 2 casillas o menos; nada a 12) |
| `farol` | Un farol que prende (una cerilla y la llama) | `mundo/farol` | InspectorJ «Party-Pack_Match_Ignite_02-03» (Party Pack) | Sonniss GDC 2020 | Efectos · −6 (tres a la vez como mucho) |

**Cómo pedirlos** (para `ciudad_oakhaven.gd`, que hereda de `zona.gd`: casillas de `T` = 64 px; `jugador`, el nodo de
quien anda):

```gdscript
# en _ready (las fuentes son hijas de la escena: se van con ella)
Sonido.fuente_2d(self, "taberna", Vector2(16, 25) * T, jugador)       # la puerta de la taberna: el bullicio, por cercanía
Sonido.fuente_2d(self, "cuervo", Vector2(13, 25.5) * T, jugador)      # el letrero: chirría de vez en cuando si estás cerca
# en los sucesos
Sonido.efecto("campana")                       # la campana lejana (al entrar, al subir a la torre, a una hora…)
Sonido.efecto("farol")                         # Kael enciende un farol de la ronda (oak:farol_1…3)
for i in 6:                                    # la ola de faroles de la vista desde las raíces (O7), cada vez más lejos
	Sonido.efecto("farol", {"retraso": 0.15 * i, "db": -2.0 * i})
```

`fuente_2d(padre, nombre, posición_px, quien, casilla := 64.0)`: el volumen sale de la distancia a `quien` (sin él, la
cámara 2D); suena a la izquierda o a la derecha según dónde esté en la pantalla; con la pausa, el silencio y el cambio
de escena de siempre. El ambiente de fondo de Oakhaven es el de las ciudades: `musica.gd` da a
`res://ciudad_oakhaven.tscn` el contexto «ciudad», como a la Oakhaven generada (así la escena ya no tiene que pedirlo;
lo comprueba `prueba_musica`).

### API nueva de `sonido.gd` (tanda 3)

- `Sonido.efecto(nombre, {"pos": Vector3})`: suena desde ese punto de la escena 3D (reproductores 3D de la escena,
  `VOCES_3D` = 8 como mucho, con las mismas reglas); `en_3d` del catálogo (o de la petición) da la distancia de
  referencia, el alcance y cuánto agudo se pierde; sin oyente ni cámara 3D, suena normal. `{"clave": …}`: la espera
  mínima por quien lo pide (los pasos de cada cuerpo).
- `Sonido.fuente_3d(padre, nombre, pos, db)` y `Sonido.fuente_linea(padre, nombre, a, b, db)`: con `db`, el mismo bucle
  más bajo en otro sitio.
- `Sonido.detalles_3d(escena, donde)`: los detalles de la naturaleza de esa escena suenan en un punto.
- `Sonido.eco(escena, "garganta")` / `Sonido.quitar_eco()` / `Sonido.eco_activo()`.
- `Sonido.fuente_2d(padre, nombre, pos, quien, casilla)`: fuentes del mundo en escenas 2D (bucle o de vez en cuando).

## Efectos de la tanda 4: las seis bestias del bestiario (T-097, 2026-11-09, tarde)

**Solo en el catálogo**: los engancha combate (empezando por Zarzalín) con estos nombres exactos. Hechos igual que las
tandas anteriores (`prueba_efectos_preparar.gd`, «solo=bestias/»): **51 derivados** en `audio/efectos/bestias/` (211 en
total) de 35 originales principales más sus capas, con sus huellas en [`efectos_procedencia.csv`](efectos_procedencia.csv).
**Licencias:** todos de los paquetes GDC de Sonniss 2016, 2017, 2018, 2019, 2020, 2023 y 2024 (PDF de licencia en la
carpeta de cada paquete; los de 2020 y 2024, releídos el 09/11: uso y modificación en juegos sin atribución, no
venderlos tal cual, no entrenar IA). Ninguna fuente CC0 nueva; nada de 2015, TomMusic, «Helton Yan's Pixel Combat» ni
Suno. Las fichas: `D:\REBELUM_diagnostico\entradas\2026-11-09_bestiario\REBELUM_Bestiario\Fichas_e_integracion.txt`.

**Reglas de todas:**
- `<bestia>_aviso_<ataque>`: la preparación del ataque. Suena **al empezar el ataque** (el principio de su clip) y acaba
  antes del impacto de la ficha (lo comprueba `prueba_efectos`, parte «bestias»). Prioridad 3: el jugador tiene que oírlo.
- `<bestia>_<ataque>`: el impacto, **en el instante del golpe** (el mismo en que el combate resuelve el daño, una vez),
  **junto al `Sonido.golpe(critico, defendido)` de siempre**, que dice si el héroe se defiende (escudo). Prioridad 2 (el
  Posadero, 3). La trama de eco golpea a todo el grupo: un solo impacto, como su resolución.
- `<bestia>_herido` / `<bestia>_caida`: su voz, **sola** con `Sonido.recibe(enemigo)` si su `clave` en `combate.gd` es la
  de `FAMILIAS` (`zarzalin`, `cencerrante`, `velaria`, `custodio_cal` o `custodio`, `hilandera_eco` o `hilandera`,
  `posadero_hueco` o `posadero`). Grupo «voz» (dos a la vez como mucho), herido 2 y caída 3, como la tanda 2.
- **No hay `_ataque`**: el aviso hace ese papel (`Sonido.voz(q, "ataque")` no suena para ellas).
- `<bestia>_entrada`: al presentarse en el combate (con la emboscada o tras ella).
- **El Posadero Hueco (jefe opcional) suena por encima**: unos 2-3 dB más y prioridad 3 en todo (su voz entra aunque
  suenen otras dos; una voz de herido de otra bestia no quita la suya).

| Efecto | Para quién y cuándo | Archivo(s) | Original (biblioteca) | Bus · dB · p | Salida (RMS, dBFS) |
|---|---|---|---|---|---|
| `zarzalin_aviso_embestida` | Zarzalín: señal `aviso` de `zarzalin_3d.gd` (el hocico ya está bajo, 0,267 s del clip `aviso_embestida`) | `bestias/zarzalin_aviso_embestida` | G4F «HORSES - Snort 03» (×0,9) + SoundBits «Pig_Grunt_09» | Efectos · −12 · 3 | −28,4 |
| `zarzalin_pezuna` | Zarzalín: cada señal `pezuna(n)` (0,467 y 0,733 s del aviso) | `bestias/zarzalin_pezuna_1…2` | Dramatic Cat «Draft Horse Walk On Grass And Dirt» + Kopeikin «soil and dirt debris heavy 13» | Efectos · −11 · 3 | −29,8 |
| `zarzalin_embestida` | Zarzalín: señal `impacto("embestida_espinosa")` (0,567 s; 0,167 s desde la carga) | `bestias/zarzalin_embestida` | Rock The Speakerbox «FLOG Leather Hit Smack 01» + Bluezone «wood_crushing_branches» + tierra + Red Libraries «bodyfall Dirt» (el aterrizaje, a 0,16 s) | Efectos · −10 · 2 | −25,3 |
| `zarzalin_aviso_colmillo` | Zarzalín: al llamar a `atacar("colmillo_lateral")` (gira la cabeza; barrido a 0,3-0,42 s) | `bestias/zarzalin_aviso_colmillo` | Bluezone «wood_creaking_tree_005» + el gruñido + Airborne «Whoosh Organic Fabric Glove» | Efectos · −3 · 3 | −27,9 |
| `zarzalin_colmillo` | Zarzalín: señal `impacto("colmillo_lateral")` (0,467 s) | `bestias/zarzalin_colmillo` | el cuero + InMotionAudio «WOODBrk_Snap09» + Bluezone «foliage impact short 012» | Efectos · −11 · 2 | −25,0 |
| `zarzalin_herido` | Zarzalín recibe un golpe físico (`Sonido.recibe`) | `bestias/zarzalin_herido_1…2` | Mechanical Wave «Pig Squeal and Snort-18» (×0,9) · Articulated «Pig, Grunt, Breathe, Single» (×0,88), con ramas | Efectos · −10 · 2 (voz) | −28,3 |
| `zarzalin_caida` | El golpe que lo tumba (`Sonido.recibe`) | `bestias/zarzalin_caida` | el chillido (×0,88) + Matt Script «wood breaking cracking» + Articulated «Pig Groan 03» | Efectos · −7 · 3 (voz) | −25,5 |
| `zarzalin_derrumbe` | Zarzalín: al empezar su clip `derrota` (`morir()`); el cuerpo toca la tierra a 0,60 s (fotograma 19) | `bestias/zarzalin_derrumbe` | follaje + «bodyfall Dirt» + ramas + tierra | Efectos · −7 · 2 | −28,9 |
| `zarzalin_entrada` | Zarzalín: al empezar su clip `entrada` (aterriza a 0,47 s, sacude la cabeza a 0,72, pisotón a 1 s y resopla) | `bestias/zarzalin_entrada` | follaje + «bodyfall Dirt» + crujido + casco + resoplido | Efectos · −6 · 3 | −27,8 |
| `cencerrante_aviso_alarma` | Cencerrante: al empezar `toque_de_alarma` (toma impulso hasta 0,6 s) | `bestias/cencerrante_aviso_alarma` | Rogue Waves «rope moving through metal» + «Cable Rope Stays, Percussive» | Efectos · −6 · 3 | −27,8 |
| `cencerrante_alarma` | Cencerrante: el repique de `toque_de_alarma` (0,73 s; refuerza, sin golpe) | `bestias/cencerrante_alarma` | Mechanical Wave «BELLHand Metallic Bell 22» (×0,75) + Ivo Vicic «Kukuljanski Bell ringers» (cencerros) + el cable | Efectos · −7 · 2 | −25,8 |
| `cencerrante_aviso_campanada` | Cencerrante: al empezar `campanada_baja` (carga de lado con el marco) | `bestias/cencerrante_aviso_campanada` | Matt Script «Old wood floor creak» + SoundBits «Whoosh_Source_Rope_03» | Efectos · −10 · 3 | −27,7 |
| `cencerrante_campanada` | Cencerrante: impacto de `campanada_baja` (0,53 s) | `bestias/cencerrante_campanada` | The Chris Alan «LP Bell Cowbell Straight Muted Stick Hits» (×0,62) + Double Trouble «Single Plank Drop» | Efectos · −4 · 2 | −25,2 |
| `cencerrante_herido` | Recibe un golpe físico | `bestias/cencerrante_herido_1…2` | el cencerro (×0,8 / ×0,85) con el cable o la cuerda | Efectos · −6 · 2 (voz) | −27,7 |
| `cencerrante_caida` | El golpe que lo tumba | `bestias/cencerrante_caida` | los cencerros + la campanilla + un golpe apagado del cencerro (el badajo agrietado) + la tabla (×0,7) | Efectos · −4 · 3 (voz) | −25,0 |
| `cencerrante_entrada` | Al presentarse: un toque lejano | `bestias/cencerrante_entrada` | la campanilla (×0,6) + la cuerda | Efectos · −7 · 3 | −27,6 |
| `velaria_aviso_destello` | Velaria: al empezar `destello_de_velo` (repliega las alas) | `bestias/velaria_aviso_destello` | Sergey Eybog «Umbrella 2 Close Slide Fold Snap 04» + MatiasMacSD «TextureWindChimeKeys_003» | Efectos · −2,5 · 3 | −28,1 |
| `velaria_destello` | Velaria: abre las alas y expulsa el destello (0,70 s) | `bestias/velaria_destello` | Gladestock «GS sail impact 004» + «Cane Umbrella Large Pop Open» + tintineo + Airborne «Whip By Airy» | Efectos · −11 · 2 | −25,3 |
| `velaria_aviso_corte` | Velaria: al empezar `corte_de_ala` (se eleva) | `bestias/velaria_aviso_corte` | Systematic Sound «Soft Shell Whoosh Flutter» (dos aleteos) | Efectos · −11 · 3 | −27,2 |
| `velaria_corte` | Velaria: impacto de `corte_de_ala` (0,50 s) | `bestias/velaria_corte` | Airborne «Whoosh Organic Fabric Glove Punchy» + la vela | Efectos · −13 · 2 | −25,9 |
| `velaria_herido` | Recibe un golpe físico | `bestias/velaria_herido_1…2` | la vela (×1,15) · el soplo de tela (×1,1), con tintineo | Efectos · −9,5 · 2 (voz) | −28,0 |
| `velaria_caida` | El golpe que la tumba | `bestias/velaria_caida` | «Umbrella 2 Shake Out» + tintineo + Eiravaein «windbell porcelain» + un golpe blando (Bluezone «creature footstep damp») | Efectos · −8 · 3 (voz) | −25,7 |
| `velaria_entrada` | Llega aleteando | `bestias/velaria_entrada` | el aleteo + tintineo | Efectos · −8 · 3 | −27,9 |
| `custodio_aviso_portazo` | Custodio de Cal: al empezar `portazo_de_cal` (recoge el brazo, gira los hombros) | `bestias/custodio_aviso_portazo` | SoundMorph «Door - Stone Long 02» (roce de losas) | Efectos · −13 · 3 | −28,0 |
| `custodio_portazo` | Custodio: impacto de `portazo_de_cal` (0,83 s) | `bestias/custodio_portazo` | SoundMorph «Rupture - Marble Impacts 06» + «Concrete Impact B02» + Bluezone «demolisher robot footsteps rusty creak» | Efectos · −10 · 2 | −25,2 |
| `custodio_aviso_martillo` | Custodio: al empezar `martillo_de_piedra` (carga el peso atrás) | `bestias/custodio_aviso_martillo` | la losa (×0,85) + Gregor Quendel «Designed Rocks EVO19» | Efectos · −13 · 3 | −27,6 |
| `custodio_martillo` | Custodio: impacto de `martillo_de_piedra` (0,83 s; más fuerte que el portazo) | `bestias/custodio_martillo` | PMSFX «Rocks Impact Hit Big LFE Heavy Designed 19» + Mattia Cellotto «Collapsed Stone House» + Bluezone «debris falling rock dust» | Efectos · −8 · 2 | −24,4 |
| `custodio_herido` | Recibe un golpe físico | `bestias/custodio_herido_1…2` | PMSFX «Rocks Impact Hit Single Stone 92» con la llave (BluezoneCorp «stone impact steel bar») · «… 53» con Tatak | Efectos · −9 · 2 (voz) | −27,4 |
| `custodio_caida` | Se derrumba (y cae su llave a 1,25 s) | `bestias/custodio_caida` | BluezoneCorp «building collapse rubble 008» + la piedra grande + la llave | Efectos · −8 · 3 (voz) | −25,2 |
| `custodio_entrada` | Despierta: la piedra se arrastra y da un paso (1,2 s) | `bestias/custodio_entrada` | la losa + el paso del autómata | Efectos · −13 · 3 | −27,6 |
| `hilandera_aviso_mordida` | Hilandera del Eco: al empezar `mordida_resonante` (alza el frente) | `bestias/hilandera_aviso_mordida` | Phase 4 «Insect Creature Attack VO 02» + TheWorkRoom «Animal Footsteps Insects ANF036» | Efectos · −10 · 3 | −27,4 |
| `hilandera_mordida` | Hilandera: impacto de `mordida_resonante` (0,73 s) | `bestias/hilandera_mordida` | Bluezone «crab organic texture attack impact 009» + Submerged Tapes «PD39 Snap» + 344 Audio «Trailer Hit Cavernous 10» | Efectos · −7 · 2 | −25,9 |
| `hilandera_aviso_trama` | Hilandera: al empezar `trama_de_eco` (alza las placas) | `bestias/hilandera_aviso_trama` | Hzandbits «Small Species A Voices Skitter Squeak» + Bluezone «organic texture insect» + Articulated «Seashell Pututo» | Efectos · −12 · 3 | −28,2 |
| `hilandera_trama` | Hilandera: el pulso de `trama_de_eco` (0,83 s), **una vez** aunque golpee a todo el grupo | `bestias/hilandera_trama` | la caracola (×0,8) + 2496 «echo hit pan subsonic» + el caparazón + la caverna | Efectos · −12 · 2 | −25,2 |
| `hilandera_herido` | Recibe un golpe físico | `bestias/hilandera_herido_1…2` | Bluezone «crab carapace crack squishy 003» · la voz de insecto (×1,12) | Efectos · −9 · 2 (voz) | −28,0 |
| `hilandera_caida` | El golpe que la tumba | `bestias/hilandera_caida` | el caparazón + Bluezone «crab texture underwater» + «creature footstep damp» + la caracola, lejos | Efectos · −6 · 3 (voz) | −25,2 |
| `hilandera_entrada` | Llega correteando | `bestias/hilandera_entrada` | las patas de insecto + el chirrido + el golpe húmedo | Efectos · −6 · 3 | −28,6 |
| `posadero_aviso_cierre` | Posadero Hueco: al empezar `cierre_de_posada` (alza los brazos como un dintel) | `bestias/posadero_aviso_cierre` | BluezoneCorp «forest tree wood texture creaking 016» (vigas) + Badlands «Set of Car Keys» | Efectos · −1,5 · 3 | −26,5 |
| `posadero_cierre` | Posadero: impacto de `cierre_de_posada` (0,97 s) | `bestias/posadero_cierre` | Rogue Waves «Wooden Door, Door Slams, Impacts 3» (×0,9) + Rock The Speakerbox «BEAM Wood Ceiling Drop» + Alex Lane «Resonant Rusty Door impact» + llaves | Efectos · −5 · 3 | −22,3 |
| `posadero_aviso_llave` | Posadero: al empezar `llave_del_umbral` (retuerce el torso, enseña la mano) | `bestias/posadero_aviso_llave` | Double Trouble «Old Lock Fiddling» + llaves | Efectos · −1,5 · 3 | −26,4 |
| `posadero_llave` | Posadero: impacto de `llave_del_umbral` (0,87 s) | `bestias/posadero_llave` | Federico Soler «Warlock D» (×0,85) + Alexander Ahura «Lock03 outdoor opening solid» + un portazo lejano | Efectos · −9 · 3 | −22,9 |
| `posadero_herido` | Recibe un golpe físico | `bestias/posadero_herido_1…2` | el crujido de viga con llaves · las vigas con llaves | Efectos · −2 · 3 (voz) | −24,8 |
| `posadero_caida` | Se derrumba: vigas, llaves y la puerta que se cierra (a 0,9 s) | `bestias/posadero_caida` | la viga que cae (×0,9) + PMSFX «HAUNTED DOORS Door Close Long Creak» + llaves + crujido | Efectos · −9 · 3 (voz) | −22,2 |
| `posadero_entrada` | Al presentarse (con `jefe`, si se quiere): la puerta de la posada se abre | `bestias/posadero_entrada` | SoundMorph «Door - Medieval Open 16» + llaves + Wav Junction «Door Thick Open Close» | Efectos · −3 · 3 | −25,9 |

Salida: medida el 09/11 con el driver real (`prueba_efectos_senal`, «efectos=zarzalin_,…» y «mezclas=4»), cada efecto
solo, Master al 100 % (el golpe de siempre sale a −27,7; las voces de la tanda 2, de −23 a −31). Muestras y una mezcla
por ataque con los tiempos de su ficha: `D:\REBELUM_diagnostico\sonido_muestras\2026-11-09_bestiario\indice.md`.

**Cómo pedirlos** (para `combate.gd`; Zarzalín ya emite las señales en `enemigos/zarzalin/zarzalin_3d.gd`):

```gdscript
# Zarzalín (z = su nodo zarzalin_3d; q = su diccionario de combate, con clave "zarzalin")
z.aviso.connect(func(_a): Sonido.efecto("zarzalin_aviso_embestida"))      # el hocico ya está bajo
z.pezuna.connect(func(_n): Sonido.efecto("zarzalin_pezuna"))              # cada golpe de pezuña
Sonido.efecto("zarzalin_aviso_colmillo")                                 # justo al llamar a atacar("colmillo_lateral")
z.impacto.connect(func(a): Sonido.efecto("zarzalin_embestida" if a == "embestida_espinosa" else "zarzalin_colmillo"))
# en el mismo impacto, como siempre: Sonido.golpe(critico, defendido)
# al recibir un golpe físico: Sonido.recibe(q)  (herido o caída, por su clave)
Sonido.efecto("zarzalin_derrumbe")                                       # al llamar a morir()/derrota()
Sonido.efecto("zarzalin_entrada")                                        # al llamar a entrada()
# Las demás bestias, igual: Sonido.efecto("<bestia>_aviso_<ataque>") al empezar el clip del ataque y
# Sonido.efecto("<bestia>_<ataque>") en su impacto (velaria_destello, custodio_martillo, hilandera_trama…).
```

Sonido.BESTIAS lista, por familia, [avisos], [impactos] y los demás. **Pendiente**: oírlo (nadie lo ha escuchado),
engancharlo en combate y oírlo en el Redmi (**pendiente en Redmi**: sobre todo lo grave de la trama de eco y del
portazo del Posadero, que un altavoz de móvil casi no da).

### Los héroes quietos en la exploración 3D (tanda 4, pedido del coordinador)

Muy discretos y sin tocar ninguna escena: el nodo de pasos de cada personaje (`Pasos3D`, el que ya crean
`pastos_verdes_3d.gd`, `garganta_3d.gd` y `grupo_3d.gd` con `pasos_3d`) cuenta el tiempo parado. A los 7-14 s suena el
gesto de su personaje y, mientras siga parado, otro cada 22-40 s; al andar se reinicia. **Uno a la vez entre los tres**
(grupo «quieto»), por Efectos, prioridad 0 (lo primero que cede), con la pausa, el silencio y el cambio de escena de
siempre; los de Lya y Garon suenan desde su sitio (como sus pasos). Kael es el que escucha (o el nodo «Kael»); Lya y
Garon, por el nombre de su nodo. Comprobado sin ventana (`prueba_efectos`, parte «quietos», 09/11): parados 45 s, 3/2/2
gestos y nunca dos a la vez; andando, ninguno.

| Efecto | Quién | Archivos | Original (biblioteca) | Licencia | Bus · dB · p | Salida (RMS) |
|---|---|---|---|---|---|---|
| `quieto_kael` | Kael se recoloca el cuero y suelta el aire | `heroes/kael_quieto_1…2` | Systematic Sound «Jacket Leather Rough Movement Slow Rustle» + Articulated «Human Male Breathe … Long Exhale_F» | Sonniss GDC 2020 | Efectos · −12 · 0 | −36,4 |
| `quieto_lya` | Lya sorbe por la nariz y se ajusta la tela | `heroes/lya_quieto_1…2` | UberDuo «Inhale – Tanja: Sniff, Nose 7» + Systematic Sound «Soft Shell Whoosh Flutter» | Sonniss GDC 2024 y 2020 | Efectos · −18 · 0 | −36,9 |
| `quieto_garon` | Garon mueve el equipo (metal y correas) y respira hondo | `heroes/garon_quieto_1…2` | Gamemaster «foley soldier gear equipment metal cloth heavy movement light 08» (×0,94) + la respiración + el cuero | Sonniss GDC 2018 y 2020 | Efectos · −10,5 · 0 | ≈ −36 |

Muestras: `D:\REBELUM_diagnostico\sonido_muestras\2026-11-09_bestiario\heroes_quietos\`. Pasos de la tanda 1 para
comparar: −32 a −39 dBFS. Si molestan en un diálogo o una cinemática, se pueden callar subiendo `QUIETO` o quitando
su nombre de `QUIETO_DE` (sonido.gd).
## Efectos de la tanda 5: las voces de los héroes en combate (2026-11-09, noche)

Voces **no verbales** (sin palabras): **Kael**, joven e impulsivo (un hombre joven, un 3-4 % más agudo); **Lya**, cálida
y ligera (una mujer); **Garon**, grave y veterano (otro hombre, un 8-12 % más grave). 30 derivados en
`audio/efectos/heroes/`, con variantes y una variación leve de tono y volumen. **Licencias:** todos de los paquetes
GDC de Sonniss 2016-2024 (los mismos PDF de siempre); ninguna fuente CC0 nueva; nada de Suno.

**Reglas:** bus Efectos; **prioridad 1** (por debajo de los golpes, 2, y de las voces de los enemigos): si faltan voces,
son lo primero que cede, y nunca quitan un golpe; **una a la vez entre los tres** (grupo «voz_heroe»: la nueva corta la
anterior). La victoria, prioridad 3 (no baja 8 dB con la fanfarria), un momento después de ella. A la salida, todas
entre −28 y −34 dBFS de RMS (el golpe de siempre, −27,7; las voces de los enemigos, −23 a −31).

| Efecto | Cuándo | Archivos | Original (biblioteca) | dB · p | Salida (RMS) |
|---|---|---|---|---|---|
| `kael_esfuerzo` | Kael se lanza al ataque | `heroes/kael_esfuerzo_1…3` | Pole Position «The Grunts Library, Male 2 - Grunt - Battle Cry» (el arranque de tres gritos, ×1,04) | −16,5 · 1 | −29,9 |
| `kael_herido` | Kael recibe un golpe físico (o cae) | `heroes/kael_herido_1…2` | Bottle Rocket «Grunt_Pain_Male_BB_10» · 344 Audio «British Soldier Voices, Grunts 16» | −14 · 1 | −30,0 |
| `kael_jadeo` | Kael queda con poca vida (menos del 30 %) | `heroes/kael_jadeo_1…2` | Pole Position «Male 1 - Breathing - Gasping» | −10,5 · 1 | −33,6 |
| `kael_alivio` | Kael se cura | `heroes/kael_alivio_1…2` | 344 Audio «Ahh, Relief, Drink, Soda, Exhale, Male» · el jadeo (un suspiro) | −12,5 · 1 | −31,7 |
| `kael_victoria` | Kael celebra la victoria | `heroes/kael_victoria_1…2` | SoundBits «Male_Grunt-Shout_317» · el grito, corto | −8,5 · 3 | −29,2 |
| `lya_esfuerzo` | Lya se lanza al ataque | `heroes/lya_esfuerzo_1…3` | Pole Position «Female 3 - Grunt - Jumping and Landing» | −14,5 · 1 | −29,9 |
| `lya_herido` | Lya recibe un golpe físico (o cae) | `heroes/lya_herido_1…3` | Pole Position «Female 1 - Grunt - Getting Hit - Medium Intensity» | −17 · 1 | −30,7 |
| `lya_jadeo` | Lya queda con poca vida | `heroes/lya_jadeo_1…2` | UberDuo «Inhale – Tanja: Panting, Nose» | −19 · 1 | −33,2 |
| `lya_alivio` | Lya se cura | `heroes/lya_alivio_1` | Eiravaein «Kieuk, laughter, female, inhales, titter» | −13 · 1 | −30,4 |
| `lya_victoria` | Lya celebra la victoria (una risa breve) | `heroes/lya_victoria_1` | AudioDesire «Voice Pack One - Emma, Female_Laugh_03» | −12 · 3 | −28,9 |
| `garon_esfuerzo` | Garon se lanza al ataque | `heroes/garon_esfuerzo_1…3` | Articulated «Fight Vocalizations, David, Anger Fight Grunt Special Power» · Gamemaster «voice_male_b_battle_shout_short_09» · The Chris Alan «Vocal Excursion - Male - Powering Up 14» (×0,88-0,92) | −16 · 1 | −30,3 |
| `garon_herido` | Garon recibe un golpe físico (o cae) | `heroes/garon_herido_1…2` | Articulated «Joshua, Pain Hurt Grunt Big 03» · Gamemaster «voice_male_b_death_low_09» (el principio) | −13,5 · 1 | −30,3 |
| `garon_jadeo` | Garon queda con poca vida | `heroes/garon_jadeo_1…2` | el jadeo de Kael, ×0,85 (más grave y lento) | −15 · 1 | −30,8 |
| `garon_alivio` | Garon se cura | `heroes/garon_alivio_1` | Articulated «Human Male Breathe, Deep Opened Mouth Breath … Long Exhale» (×0,9) | −12,5 · 1 | −31,1 |
| `garon_victoria` | Garon celebra la victoria (una risa contenida) | `heroes/garon_victoria_1` | Eiravaein «Kieuk, laughter, male, 60s, restrained, chuckle» | −9 · 3 | −28,1 |

**Lo que ya suena sin tocar `combate.gd`** (las llamadas que ya hay): `Sonido.recibe(objetivo)` en el impacto de un golpe
físico de un enemigo (`_animar_golpe`, si `magia == ""`) da el quejido del héroe y, si le deja con menos del 30 % de su
vida, un jadeo 0,7 s después (una vez hasta que se cure); y `Sonido.voz(o, "ataque")` en los ataques genéricos da su
esfuerzo cuando el que ataca es un héroe. Comprobado en un combate de verdad (`prueba_efectos`, parte «heroes»): el golpe
del limo hace quejarse a Kael; la magia sigue sin pedir voces.

**La Guardia de Garon** (`guardia`, nuevo; combate lo pide por este nombre y hasta ahora sonaba `defensa`): se planta
tras el escudo, metálico, firme y breve. `combate/guardia` (0,63 s): Double Trouble «Medieval Armor and Impacts,
Plate_Impact_Hard_02» (×0,95) con «Weapon_Impact_Parry_01» (−8 dB) y SmartSoundFX «Medieval, ARMOR Body Drop Chain
Leather Short 02» (−10 dB): Sonniss GDC 2017 y 2020. Efectos · −14 dB · prioridad 2 (como la defensa) · uno a la vez.
Salida: −25 dBFS de RMS aprox. (medido −23,3 a −12 dB; la defensa, −26,9). En combate: `_sonar("guardia")` donde hoy
dice `_sonar("defensa")` al ponerse en guardia.

**Líneas para combate** (`combate.gd`; no lo he tocado, combate lo está editando):

```gdscript
# _anim_salto_3d (Kael 3D), justo después de Sonido.efecto("salto"):
Sonido.voz(o, "ataque")                            # su esfuerzo al saltar (hoy su ataque no tiene voz)
# _anim_fisico_3d (Lya y otros 3D con preparar_golpe), justo después de maga.preparar_golpe():
Sonido.voz(o, "ataque")
# _usar_objeto, tras Sonido.efecto("pocion"…), si cura PV:
if campo == "hp" and cura > 0:
	Sonido.voz(quien, "alivio")
# _comprobar_fin, tras Sonido.efecto("victoria" if ganan else "derrota"):
if ganan:
	Sonido.victoria_heroes(heroes)                 # uno de los que siguen en pie, 0,8 s después
# (opcional) las artes que curan o levantan (Aliento, Lumbre de Retorno, Brasa): Sonido.voz(h, "alivio")
```

Las 12 magias de siempre (también Cura, Bendición y Gracia Divina) **no** piden el alivio: añadir una voz a su
presentación es la decisión aparte de D-048. Muestras: `D:\REBELUM_diagnostico\sonido_muestras\2026-11-09_heroes_combate\indice.md`
(cada voz sola, un combate seguido con golpes, poción y victoria, y las tres victorias).
### La entrada, la cornisa y los puentes de la Garganta 3D (tanda 5, para quien lleve `garganta_3d.gd`)

Dos efectos nuevos (gráficos los engancha en `garganta_3d.gd`) que **no son bucles**: suenan de vez en cuando (`"cada"` en su `tres_d`) en el punto de su línea más
cercano a quien escucha, y nada si está más lejos que `max` (`Sonido.fuente_linea` los reconoce solo). Bus Ambiente,
prioridad 0, con el eco de la garganta que ya hay. Sin tocar `zonas3d/**` (lo pule gráficos en `area-garganta3d`).

| Efecto | Qué | Archivos | Original (biblioteca) | Licencia | dB · cada · 3D | Salida (RMS) |
|---|---|---|---|---|---|---|
| `puente_cruje` | Los puentes colgantes crujen: las cuerdas (1-3) y las tablas de madera (4-5) | `ambiente/puente_cruje_1…5` | Rogue Waves «AMBNaut_Atmos, EXT Marina, boats, rope creaking» (+ un gozne de Jake Fielding en la 3.ª) · Matt Script «Old wood floor creak» · Coll Anderson «EFX CTM Floor Board Creak 03 A» (con una cuerda debajo) | Sonniss GDC 2024 y 2019 | −14 · cada 3-8 s · 4 m de referencia, hasta 25 m | −35,1 (a 4 m) |
| `viento_cuerdas` | El viento silba en las cuerdas de la cornisa y los puentes (ráfagas de 5,5 s) | `ambiente/viento_cuerdas_1…2` | Ivo Vicic «Bora wind: 38 Wind_hurricane_wires_whistle» | Sonniss GDC 2018 | −8 · cada 9-18 s · 6 m, hasta 40 m | −31,9 |

**Líneas propuestas** para `_sonido_3d()` de `zonas3d/garganta_3d.gd` (trazado.gd: `X_CAMINO_O`, `X_BORDE_O`, `ALTO`,
`PUENTES`; la entrada está hacia z = 37-40):

```gdscript
for p in T.PUENTES:                                    # las cuerdas de cada puente colgante, a la altura de la mano
	Sonido.fuente_linea(self, "puente_cruje", Vector3(T.X_CAMINO_O, T.ALTO + 0.8, p[0]), Vector3(T.X_CAMINO_O, T.ALTO + 0.8, p[1]))
# el viento en las cuerdas, por el borde de la cornisa desde la entrada hasta el último puente
Sonido.fuente_linea(self, "viento_cuerdas", Vector3(T.X_BORDE_O, T.ALTO - 1.0, 40.0), Vector3(T.X_BORDE_O, T.ALTO - 1.0, T.PUENTES[1][1]))
```

Comprobado sin la escena de verdad (`prueba_efectos`, parte «cuerdas»: en 40 s, las cuerdas 8 veces y el viento al menos
una, siempre en el punto de su línea más cercano y por Ambiente; a 80 m, nada). Con ventana, cada uno solo:
`D:\REBELUM_diagnostico\sonido_muestras\2026-11-09_heroes_combate\garganta_cuerdas\`.
## Tanda 6 (2026-11-09, noche): dos voces más claras, Oakhaven vivo y la mezcla por buses

### Las dos voces que marqué como dudosas

- **El esfuerzo de Kael** (`kael_esfuerzo_1…3`): ahora son tres esfuerzos cortos y enteros, de 0,26 a 0,36 s (The Chris
  Alan, «Little Fighter Guy - Vocalizations: Punch Kick Chop_19, Jump Lift Push_09, Crash Bump Fall_01», Sonniss GDC
  2018). Antes eran el arranque recortado de un grito largo. Salida: −30 dBFS de RMS.
- **El jadeo de Lya** (`lya_jadeo_1…2`): ahora son respiraciones de la misma actriz que sus esfuerzos (Pole Position, «The
  Grunts Library: Female 3 - Jumping and Landing», GDC 2023), con unos 8 dB de ganancia. Antes era una respiración nasal
  con unos 36 dB de ganancia. Suelo de ruido medido entre respiraciones: −53,5 dBFS (antes, −30). Salida: −34,6.

### Oakhaven vivo (2D ahora; las mismas fuentes valen en 3D, T-103)

| Efecto | Qué | Archivos | Original (biblioteca) | Licencia | Bus · dB · cercanía |
|---|---|---|---|---|---|
| `plaza_murmullo` | El murmullo de la Plaza del Tapiz: un pueblo con voces y caballos, con paso bajo para que no se entiendan las palabras | `ambiente/plaza_murmullo` (bucle, 30 s) | Charlie Atanasyan, «Village medium in a canyon voices activity and horses» | Sonniss GDC 2017 | Ambiente · −5 · todo a 4 casillas, nada a 16 (3D: 8 m, hasta 50) |
| `mercado_murmullo` | El mercado: voces tranquilas y pasos en tierra | `ambiente/mercado_murmullo` (bucle) | Charlie Atanasyan, «CHIL Market Village calm with voices…» | Sonniss GDC 2018 | Ambiente · −1 · 3 / 12 casillas (3D: 6 m, hasta 40) |
| `fuente_plaza` | La fuente de la plaza | `ambiente/fuente_plaza` (bucle) | Articulated, «100 Fountains: FOUNTAIN Medium, Invigorating Network of Dribbles, Close» | Sonniss GDC 2017 | Ambiente · −10 · 1,5 / 8 casillas (3D: 3 m, hasta 25) |
| `pajaro_ciudad` | Un pájaro de ciudad, de día | `ambiente/pajaro_ciudad_1…2` | Discover Oregon, «Robins 2015 Medlock Dawn Robins» | Sonniss GDC 2018 | Ambiente · −16 · detalle |
| `grillo` | Un grillo, al atardecer y de noche | `ambiente/grillo` | justsoundeffects, «Single Cricket Night Countryside Italy» | Sonniss GDC 2020 | Ambiente · −14 · detalle |
| `mochuelo` | Un mochuelo lejano, de noche | `ambiente/mochuelo_1…2` | Ivo Vicic, «Little owl, river, night, distant» | Sonniss GDC 2019 | Ambiente · −20 · detalle |

- **La hora:** `Sonido.fijar_momento(escena, "dia" | "tarde" | "noche")`. Mientras esa escena sea la actual, los detalles
  de su contexto son los de `DETALLES["ciudad_<momento>"]`:
  - de día, pájaros y ráfagas;
  - al atardecer, un pájaro, el grillo y ráfagas;
  - de noche, el grillo y el mochuelo.
  - En los tres, la campana lejana marca la hora de vez en cuando (cada 110-200 s; de noche, cada 180-300).
  - Se olvida al cambiar de escena. Sin hora fijada, las ciudades suenan como siempre, ahora con algún pájaro de ciudad
    más.
- **Pasos sobre empedrado:** el camino de Oakhaven es «empedrado» y ya suena `paso_piedra`. En la biblioteca no hay
  pasos sobre adoquines (busqué «cobble»), así que no he hecho uno nuevo.

**Líneas para `ciudad_oakhaven.gd`**, en `_ready`, junto a la taberna y el cuervo (casillas de `T` = 64 px; las
posiciones salen de `ciudades/oakhaven.gd`):

```gdscript
var pz := _rect("plaza")                                           # la Plaza del Tapiz y su fuente
Sonido.fuente_2d(self, "plaza_murmullo", pz.get_center() * T, jugador)
Sonido.fuente_2d(self, "fuente_plaza", pz.get_center() * T, jugador)   # si la fuente está en otro punto, ese
Sonido.fuente_2d(self, "mercado_murmullo", _rect("mercado").get_center() * T, jugador)
Sonido.fijar_momento(self, "tarde")                                # la hora azul del arte (con un reloj, la hora real)
```

**En 3D (T-103)**, las mismas fuentes como emisores en bucle: `Sonido.fuente_3d(self, "plaza_murmullo", pos)`, y lo
mismo con la fuente y el mercado. También `Sonido.oyente_3d(kael, cam)` y `Sonido.fijar_momento(self, …)`.

Comprobado sin ventana (`prueba_efectos`, parte «ciudad»):
- al lado, la plaza suena a −2 dB y la fuente a −8 (los valores de esa pasada; hoy, −5 y −10);
- lejos, se callan y dejan de sonar;
- de noche, el grillo y el mochuelo, sin pájaros de día;
- la campana suena una vez;
- la hora se olvida al cambiar de escena;
- la fuente vale como emisor 3D.

### La mezcla por buses (combate y ciudad)

`prueba_efectos_senal`, «mezclas=6», con ventana y el driver real, 09/11: se graban a la vez el Master y cada bus
(Musica, Ambiente, Efectos e Interfaz). Primero, un combate de 15 s con su música (`musica_combate_normal.mp3` a −6 dB,
como `combate.gd`), golpes, voces de héroes y enemigos, Zarzalín, poción y victoria. Después, 10 s en la Plaza del Tapiz,
a 3 casillas de la fuente, con el ambiente de las ciudades, el murmullo, el mercado lejos, pasos, un farol, la campana y
la interfaz. «Sobre el fondo»: cuánto quedan los efectos por encima de la música o del ambiente, en las ventanas de 0,1 s
en que suenan.

| Escena | Música | Ambiente | Efectos | Interfaz | Efectos sobre el fondo | Interfaz sobre el fondo | Pico del Master |
|---|---|---|---|---|---|---|---|
| Combate, hoy (música −6 dB) | −19,2 | — | −23,6 | −30,7 | mediana **−8,9 dB** (peor −26,9) | −12,7 dB | **−0,3 a −2,6 dBFS** (tres pasadas) |
| B: música −10 dB | −23,9 | — | −23,1 | −31,5 | mediana −2,3 dB (peor −19,6) | −6,4 dB | −3,2 a −3,8 |
| C: música −6 dB que se aparta | −25,6 | — | −23,3 | −32,2 | mediana **+7,4 dB** (peor −17,8) | −10,6 dB | −2,0 a −2,5 |
| Plaza, primera medida (murmullo −2, fuente −8) | — | −29,6 | −34,4 | −31,0 | −4,2 dB | −1,0 dB | −7,5 |
| Plaza, hoy (murmullo −5, fuente −10: **aplicado**) | — | −30,7 | −34,2 | −31,0 | −0,6 dB | +2,2 dB | −6,2 |

C: la música se aparta con un compresor en el bus Musica que escucha al bus Efectos (umbral −32 dB, 4:1, ataque 8 ms,
suelta 300 ms).

**Lo que dice la medida:** en el combate, la música va por encima de los golpes y de las voces. Los efectos quedan, en
la mediana, 9 dB por debajo de ella, y la interfaz, 13. Cuando coinciden un crítico, una voz y la música, el Master
llega a −0,3 dBFS: casi satura. En la plaza, con los niveles de la primera medida, los pasos quedaban unos 4 dB por
debajo del ambiente; con el murmullo y la fuente más bajos, quedan a la par.

**Propuestas** (la de la plaza, aplicada; las demás, para decidir al escucharlas):
1. **Combate, música −6 → −10 dB** (`combate.gd`, `musica.volume_db`, el archivo de combate). Es lo más sencillo: los
   efectos ganan 6-7 dB respecto a la música y el pico baja a −3 dBFS. La música sigue sonando entera.
2. **O, mejor para oír los golpes, la música que se aparta** (C):
   - un `AudioEffectCompressor` con sidechain «Efectos» en el bus Musica (`default_bus_layout.tres`, o puesto por
     `sonido.gd` solo en combate);
   - los efectos pasan a quedar 7 dB por encima;
   - la música baja sola unos 6 dB mientras hay golpes y vuelve en 0,3 s;
   - hay que oírlo: si «bombea», ataque y suelta más lentos o ratio 3:1.
3. **Una protección en el Master** (un `AudioEffectLimiter` a −1 dBFS) para que una suma rara no sature nunca. Es
   prudente con 1 o 2, pero no necesaria con ellas (picos de −2 a −4).
4. **Interfaz**: en el combate queda 13 dB bajo la música (6 dB con la propuesta 1). Son tonos agudos y cortos, que se
   oyen más de lo que dice el RMS. Si al escucharlo se pierden, +3 dB a `ui_tic` y `ui_confirmar` solo en combate.
5. **Plaza** (aplicado en `sonido.gd`): murmullo −2 → −5 dB y fuente −8 → −10 dB.

Muestras (cada bus por separado, para escucharlo): `D:\REBELUM_diagnostico\sonido_muestras\2026-11-09_tanda6\indice.md`
y los WAV `buses_*_<bus>.wav` en `D:\REBELUM_diagnostico\pruebas\2026-11-09_185932\prueba_efectos_senal\`.
**Límite:** la medida es por nivel (RMS), no por bandas de frecuencia. Un efecto agudo se oye sobre una música grave
aunque tengan el mismo RMS. Por eso las propuestas 1 y 2 hay que escucharlas.
## Candidatos aún sin usar

- **Alternativas para escuchar y elegir:** `victory_…_01_s29` y `…_02_s29` (otra victoria), InspectorJ
  «Discovery_01-03_Organ-A_WET» (descubrimiento) y «Failure_05-01_Piano-A_DRY» (derrota más triste); Ivo Vicic
  «07 Waterfall near field 7_LOOP» y Sound Sower «01 SPRING WATERFALLS, fall, continuous…» (otra cascada).
- **Voces de los enemigos, otras tomas** (tanda 2, por si alguna no convence al escucharla): Lukas Tvrdon
  «6Monsters_BlackBoss_Scream_04» (un grito enorme, para un jefe más adelante), SmartSoundFX «BEAST 01 Attack 08»,
  David Dumais «Monster06_Attack13» y «Monster09_Death02», Gamemaster «troll_monster_growl_long_05» (para la furia),
  Bluezone «mountain_dweller_creature_orc_grunt_003», y de la colección CC0 `08_creatures_monsters` (s24, s35 «ogre» y
  «giant», s36 «zombie», s56 «roar»: CC0 comprobado el 09/11).
- **Pasos de los enemigos en la exploración 3D** (cuando los haya): la misma API (`Sonido.pasos_3d(nodo, superficie)`)
  los pondría en el espacio como los de Lya y Garon (tanda 3).
- **Otras cascadas y vientos para la Garganta 3D** (por si no convencen al escucharlos): Sound Sower «01 SPRING
  WATERFALLS, fall, continuous…» y Ivo Vicic «07 Waterfall near field 7_LOOP» (Sonniss 2020); Sound of Essen
  «TonalWind_Atmo_SealLikeHowling_Mono» y Articulated Sounds «WEATHER WIND Synth… Howling, Whistling, Eerie» (2020).
- **Otra campana para Oakhaven:** Kenney «impact_bell_heavy» (colección CC0, s12; su página de kenney.nl está sin
  comprobar), más grave con «tono» 0,5.
- **Charcas, lava y veneno de las zonas 2D**: hoy solo suena el río de agua. Candidatos: `14_water_mud_slime`
  «loop_bubbles» (s53) para el veneno y «water_boiling_loop» (s52) para la lava, ambos CC0 (comprobado el 09/11).
- **Paquete GDC 2015 de Sonniss:** su carpeta no trae el PDF de licencia (solo «ROYALTY-FREE SINGLE LICENSE» en el
  léeme); la página pública dice que todos los paquetes tienen la misma licencia, pero en esta tanda no se usa.
- **Sonidos de 8 bits** de la colección (s30, s55): no encajan con la dirección del juego.
- **«Free Fantasy SFX Pack» de TomMusic:** su léeme no dice la licencia. **No se usa** hasta comprobarla.
