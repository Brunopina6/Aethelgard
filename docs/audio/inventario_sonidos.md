# Inventario de sonidos de AETHELGARD / REBELUM

**Actualizado el 2026-11-09 por la mañana** (T-030, D-064, D-067 y **T-083**: primera tanda de efectos el 08/11 y
**segunda tanda** el 09/11: voces de los enemigos, agua de las zonas 2D, la Garganta, el Diario, el brazalete y la
propuesta de sonido de las magias; rama `area-sonido`). Criterio: de cada sonido, el original, el recurso que usa el
juego, el evento, la licencia y la evidencia. Tres comprobaciones **por separado**:

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

## Candidatos aún sin usar

- **Alternativas para escuchar y elegir:** `victory_…_01_s29` y `…_02_s29` (otra victoria), InspectorJ
  «Discovery_01-03_Organ-A_WET» (descubrimiento) y «Failure_05-01_Piano-A_DRY» (derrota más triste); Ivo Vicic
  «07 Waterfall near field 7_LOOP» y Sound Sower «01 SPRING WATERFALLS, fall, continuous…» (otra cascada).
- **Voces de los enemigos, otras tomas** (tanda 2, por si alguna no convence al escucharla): Lukas Tvrdon
  «6Monsters_BlackBoss_Scream_04» (un grito enorme, para un jefe más adelante), SmartSoundFX «BEAST 01 Attack 08»,
  David Dumais «Monster06_Attack13» y «Monster09_Death02», Gamemaster «troll_monster_growl_long_05» (para la furia),
  Bluezone «mountain_dweller_creature_orc_grunt_003», y de la colección CC0 `08_creatures_monsters` (s24, s35 «ogre» y
  «giant», s36 «zombie», s56 «roar»: CC0 comprobado el 09/11).
- **Pasos de Lya, Garon y los enemigos**: la API admite varios cuerpos a la vez (`Sonido.pasos_3d(nodo, superficie)`,
  un nodo «Pasos» por personaje, cada uno con su espera entre pasos); los engancha animaciones en su tanda 2.
- **Charcas, lava y veneno de las zonas 2D**: hoy solo suena el río de agua. Candidatos: `14_water_mud_slime`
  «loop_bubbles» (s53) para el veneno y «water_boiling_loop» (s52) para la lava, ambos CC0 (comprobado el 09/11).
- **Paquete GDC 2015 de Sonniss:** su carpeta no trae el PDF de licencia (solo «ROYALTY-FREE SINGLE LICENSE» en el
  léeme); la página pública dice que todos los paquetes tienen la misma licencia, pero en esta tanda no se usa.
- **Sonidos de 8 bits** de la colección (s30, s55): no encajan con la dirección del juego.
- **«Free Fantasy SFX Pack» de TomMusic:** su léeme no dice la licencia. **No se usa** hasta comprobarla.
