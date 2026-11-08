# Inventario de sonidos de AETHELGARD / REBELUM

**Actualizado el 2026-11-08 por la noche** (T-030, D-064, D-067 y **T-083**, primera tanda de efectos; rama
`area-sonido`). Criterio: de cada sonido, el original, el recurso que usa el juego, el evento, la licencia y la
evidencia. Tres comprobaciones **por separado**:

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

### Magias: sin sonido nuevo (decisión aparte)

El catálogo mágico no cambia: Fuego, Llamarada, Infierno, Agua, Torrente, Maremoto, Rayo, Tormenta, Cólera del
Cielo, Cura, Bendición y Gracia Divina **no suenan** (lo comprueba `prueba_efectos`: una magia no pide ningún
efecto). Darles sonido añade una capa a su presentación protegida, así que queda para una decisión del usuario.
Candidatos con licencia comprobada para entonces: Gamemaster «Magic and Spell Sounds» (2018), Sound Spark «Magic
Spells, Buffs and Attacks» (2019), David Dumais «Magic Sound FX Pack 1 y 2», «Spells Magic 1», «Water Magic 1»,
«Electricity Magic 1» e «Ice & Frost Magic 1» (2020 y 2023), Articulated Sounds «Magic Elements vol. 1 y 2», Rogue
Waves «Druid Magic» (2023), y de la colección CC0, `07_magic_spells` (s09, s10, s29, s35, s56). Érebo sigue con sus
7 sonidos de licencia pendiente (no se han tocado).

## Candidatos aún sin usar

- **Alternativas para escuchar y elegir:** `victory_…_01_s29` y `…_02_s29` (otra victoria), InspectorJ
  «Discovery_01-03_Organ-A_WET» (descubrimiento) y «Failure_05-01_Piano-A_DRY» (derrota más triste); Ivo Vicic
  «07 Waterfall near field 7_LOOP» y Sound Sower «01 SPRING WATERFALLS, fall, continuous…» (otra cascada).
- **Rugidos para la furia de los enemigos** (Phase 4 «Monster Roars», Sounds Great «Orc Creature Library», Bluezone
  «Mountain Dweller»): hace falta decidir qué voz tiene cada enemigo (un limo no ruge como un orco).
- **Pasos de Lya, Garon y los enemigos**, y **el agua de las zonas 2D** cerca de los ríos: siguiente tanda.
- **Paquete GDC 2015 de Sonniss:** su carpeta no trae el PDF de licencia (solo «ROYALTY-FREE SINGLE LICENSE» en el
  léeme); la página pública dice que todos los paquetes tienen la misma licencia, pero en esta tanda no se usa.
- **Sonidos de 8 bits** de la colección (s30, s55): no encajan con la dirección del juego.
- **«Free Fantasy SFX Pack» de TomMusic:** su léeme no dice la licencia. **No se usa** hasta comprobarla.
