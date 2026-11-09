extends SceneTree
# HERRAMIENTA (T-083, no es una prueba de regresión): prepara los efectos del juego a partir de la biblioteca del
# usuario (D:\qtorrent\sound effect), que es de solo lectura y no se importa entera.
#   - Colección CC0 «500 GAME SOUND EFFECTS» (la fuente de cada archivo, sNN, está en su LICENSES.txt).
#   - Paquetes GDC de Sonniss (2016-2024): su licencia (Licensing.pdf / License.pdf en cada carpeta) permite usarlos y
#     editarlos en juegos comerciales sin atribución; no se pueden vender tal cual. Solo entran derivados.
# Para cada receta: lee el original, se queda con un tramo (y a veces le suma otra capa), lo pasa a mono, filtra lo
# que no cabe al bajar de 96/192 kHz (media banda) y lo deja a 48 kHz, funde la entrada y la salida, lo normaliza
# (pico o RMS con un pico máximo) y lo guarda en res://audio/efectos/<ruta>.wav con su .import (QOA; bucle si toca).
# Los originales no se tocan: se apunta su SHA-256 en docs/audio/efectos_procedencia.csv.
# Uso (con los datos aislados, como las pruebas):
#   Godot --headless --path aethelgard --script res://pruebas/prueba_efectos_preparar.gd -- "D:/qtorrent/sound effect"
#   ... -- "D:/qtorrent/sound effect" comprobar      (solo vuelve a calcular las huellas: «originales intactos»)
#   ... -- "D:/qtorrent/sound effect" solo=voces/,mundo/puerta   (solo esas recetas; las demás filas del CSV se quedan)
#   ... -- "D:/qtorrent/sound effect" magias=D:/carpeta   (las MUESTRAS de la propuesta de magias, fuera del proyecto:
#        no entran en res:// ni en el CSV del proyecto; se apuntan en <carpeta>/magias_procedencia.csv)
# Después hay que importar: Godot --headless --path aethelgard --import
# El .import de un derivado que ya existe no se reescribe (conserva su uid); solo se crea para los nuevos.

const SALIDA := "res://audio/efectos"
const HZ := 48000
const PROCEDENCIA := "docs/audio/efectos_procedencia.csv"      # relativo a la raíz del repositorio

const CARPETAS := {
	"C": "",                                                   # la colección CC0: carpetas 01_… a 20_… en la raíz
	"S16": "Sonniss.com - GDC 2016- Game Audio Bundle/",
	"S17": "Sonniss.com - GDC 2017 - Game Audio Bundle/",
	"S18": "Sonniss.com - GDC 2018 - Game Audio Bundle/",
	"S19": "Sonniss.com - GDC 2019 - Game Audio Bundle/",
	"S20": "Sonniss.com - GDC 2020 - Game Audio Bundle/",
	"S23": "Sonniss.com - GDC 2023 - Game Audio Bundle/",
	"S24": "Sonniss.com - GDC 2024 - Game Audio Bundle/",
}

const F_HIERBA := "S17/Tovusound - Edward – Foleyart Collection Add-On Extended Footsteps/169_Foley_Footsteps_Grass_Sneaker_Walk_Fast_Run_Jog_Close.wav"
const F_PIEDRA := "S17/Tovusound - Edward – Foleyart Collection Add-On Extended Footsteps/015_Foley_Footsteps_Asphalt_Boot_Walk_Fast_Run_Jog_Close.wav"
const F_HOJAS := "S18/Sounds Visual - Footsteps on Leaves/FX3280 Walking Faster Leaves Foley Foosteps.wav"
const F_NIEVE := "S19/Studio 23 - Ultimate Footstep Collection/S23_SFX_Footsteps_Snow_Singles_Sequence.wav"
const F_GRAVA := "S19/Studio 23 - Ultimate Footstep Collection/S23_SFX_Footsteps_Gravel_Loafers_Loops_Walk_Normal.wav"
const F_MADERA := "S23/RYK-Sounds - Footstep/wooden floor 1 loop.wav"
const F_HACHA := "S24/Justsoundeffects - Melee Weapons/WEAPAxe_Long Two-Handed Axe Flesh Hit_JSE_MW.wav"
const F_ESCUDO := "S24/Justsoundeffects - Melee Weapons/WEAPArmr_Metal Shield Block Hits_JSE_MW.wav"
const F_TAJO := "S23/David Dumais Audio - Melee Weapons Sound Effects Pack 1/SWSH_Sword Slash Impact V2 Assorted 18_DDUMAIS_NONE.wav"
const F_GOLPE_SORDO := "S20/Shapeforms - Hit & Punch/IMPACT_LOW_THUD_10.wav"
const F_VAINA := "S23/David Dumais Audio - Melee Weapons Sound Effects Pack 1/METLFric_Designed Metal Sword Sheath 04_DDUMAIS_NONE.wav"
const F_CUERO := "S17/Double Trouble Audio - Medieval Armor and Impacts/LeatherArmor_Rustle_03.wav"
const F_MONEDAS := "S18/Effectsworks - COINAGE/Coins_Pouch_Leather_Drop_Into_Takes_3.wav"
const F_PUERTA := "S20/344 Audio - Practical Doors/Dungeon Door Open, Close, Locked.wav"
const F_CAMPANAS := "S23/CB Sound Design - Dreamcatcher - The Sound of Dreams & Magic/Enchanting_Bells_4.wav"
const F_ARPA := "S23/CB Sound Design - Dreamcatcher - The Sound of Dreams & Magic/Harp_Glissando_10b.wav"
const F_RAFAGA_HIERBA := "S17/Hzandbits - Wind In Trees/Wind,Ext,Gust,Grasslands,Rustle,Buffeting.wav"
const F_RAFAGA_ARBOL := "S24/Pole Position - Wind In Trees/Wind - Aspen - Gusts - Close - Inside Canopy - XY - MKH8060.wav"

# T-083, tanda 2: voces de los enemigos, la puerta de la Garganta, el brazalete, el Diario y la congelación
const F_ORCO := "S20/Sounds Great - Orc Creature Library/"
const F_PIEDRA_HUM := "S18/Gregor Quendel - Designed Rocks/Designed Rocks - ELEM017 - Melodic 4.wav"
const F_PIEDRA_MARTILLO := "S24/BluezoneCorp - Stone Impact/Bluezone_BC0297_stone_impact_hammer_015.wav"
const F_PIEDRA_GOLPE := "S24/BluezoneCorp - Stone Impact/Bluezone_BC0297_stone_impact_015.wav"
const F_PEDRUSCO := "S18/Soundrangers - Foley Elements Rocks, Dirt And Stone/boulder_impact_on_stones_14.wav"
const F_DERRUMBE := "S17/Mechanical Wave - Rock,Brick and Dirt - Part 02/Crumbling Rock Slide_RBDII 07.wav"
const F_SLIME := "C/08_creatures_monsters/slime_48kHz_16bit_"
const F_AGUA_CC0 := "C/14_water_mud_slime/"

# T-083, tanda 3: la Garganta 3D, las artes nuevas (T-091) y Oakhaven
const F_CASCADA_GRANDE := "S23/Justsoundeffects - Streams and Rivers/WATRFall_Waterfall Roaring Rumble_03_JSE_SR.wav"
const F_AULLIDO := "S16/Hzandbits - Howling Winds - Interior/Wind,Int,Howl,Tonal,Mumble.wav"
const F_GOTA_CUEVA := "S24/InMotionAudio - Cave Design/WATRDrip_SingleDripDesign05_InMotionAudio_CaveDesign.wav"
const F_ETERNIDAD := "S23/BluezoneCorp - Eternity - Ethereal Ambient/"
const F_HIELO_DD := "S20/David Dumais Audio - Ice & Frost Magic 1/"
const F_COPA := "S16/George Karagioules - The Source Collection SFX Pack/Wine Glass Hit Higher Pitch.wav"
const F_FUEGO_GQ := "S18/Gregor Quendel – Designed Fire/"
const F_CAMPANA_SUAVE := "S18/CB_Sounddesign – ACTIVATION UI & HUD Sound Effects Library/Bell_10_b.wav"
const F_CHIRRIDO := "S17/SoundBits - Unsettling Creaks and Squeaks/Metal_Creak_13.wav"

# [derivado, fuente, desde (s), hasta (s, -1 = el final), opciones]
# opciones: norm ("pico" o "rms"), db (objetivo en dBFS), techo (pico máximo con «rms»), fi / fo (fundidos en s),
# capas ([[fuente, desde, hasta, en (s), dB], ...] que se suman a la principal), pb (paso bajo en Hz: «lejos»),
# bucle (s de fundido final→principio: hace un bucle sin corte), tono (lo acelera o lo frena al remuestrear, como
# una cinta: 1,12 = más agudo y corto, criatura más pequeña; 0,85 = más grave y lento, más grande)
const RECETAS := [
	# ---------------------------------------------------------------- pasos (un paso por archivo)
	["pasos/hierba_1", F_HIERBA, 2.295, 2.62, {"norm": "rms", "db": -20.0}],
	["pasos/hierba_2", F_HIERBA, 3.275, 3.60, {"norm": "rms", "db": -20.0}],
	["pasos/hierba_3", F_HIERBA, 4.985, 5.31, {"norm": "rms", "db": -20.0}],
	["pasos/hierba_4", F_HIERBA, 7.635, 7.96, {"norm": "rms", "db": -20.0}],
	["pasos/hierba_5", F_HIERBA, 8.605, 8.93, {"norm": "rms", "db": -20.0}],
	["pasos/hierba_6", F_HIERBA, 12.295, 12.62, {"norm": "rms", "db": -20.0}],
	["pasos/piedra_1", F_PIEDRA, 2.835, 3.13, {"norm": "rms", "db": -20.0}],
	["pasos/piedra_2", F_PIEDRA, 3.755, 4.05, {"norm": "rms", "db": -20.0}],
	["pasos/piedra_3", F_PIEDRA, 10.275, 10.55, {"norm": "rms", "db": -20.0}],
	["pasos/piedra_4", F_PIEDRA, 11.485, 11.76, {"norm": "rms", "db": -20.0}],
	["pasos/piedra_5", F_PIEDRA, 13.335, 13.61, {"norm": "rms", "db": -20.0}],
	["pasos/piedra_6", F_PIEDRA, 17.915, 18.19, {"norm": "rms", "db": -20.0}],
	["pasos/hojas_1", F_HOJAS, 3.90, 4.24, {"norm": "rms", "db": -21.0}],
	["pasos/hojas_2", F_HOJAS, 21.12, 21.46, {"norm": "rms", "db": -21.0}],
	["pasos/hojas_3", F_HOJAS, 28.34, 28.68, {"norm": "rms", "db": -21.0}],
	["pasos/hojas_4", F_HOJAS, 30.98, 31.32, {"norm": "rms", "db": -21.0}],
	["pasos/hojas_5", F_HOJAS, 32.25, 32.59, {"norm": "rms", "db": -21.0}],
	["pasos/nieve_1", F_NIEVE, 1.60, 2.02, {"norm": "rms", "db": -21.0}],
	["pasos/nieve_2", F_NIEVE, 2.58, 3.00, {"norm": "rms", "db": -21.0}],
	["pasos/nieve_3", F_NIEVE, 3.57, 3.99, {"norm": "rms", "db": -21.0}],
	["pasos/nieve_4", F_NIEVE, 4.56, 4.98, {"norm": "rms", "db": -21.0}],
	["pasos/nieve_5", F_NIEVE, 5.54, 5.96, {"norm": "rms", "db": -21.0}],
	["pasos/grava_1", F_GRAVA, 5.00, 5.40, {"norm": "rms", "db": -21.0}],
	["pasos/grava_2", F_GRAVA, 6.10, 6.50, {"norm": "rms", "db": -21.0}],
	["pasos/grava_3", F_GRAVA, 9.28, 9.68, {"norm": "rms", "db": -21.0}],
	["pasos/grava_4", F_GRAVA, 9.80, 10.20, {"norm": "rms", "db": -21.0}],
	["pasos/grava_5", F_GRAVA, 10.32, 10.72, {"norm": "rms", "db": -21.0}],
	["pasos/arena_1", "C/02_footsteps/sand_48kHz_16bit_0.44s_01_s03.wav", 0.0, -1, {"norm": "rms", "db": -21.0}],
	["pasos/arena_2", "C/02_footsteps/sand_48kHz_16bit_0.32s_02_s03.wav", 0.0, -1, {"norm": "rms", "db": -21.0}],
	["pasos/arena_3", "C/02_footsteps/sand_48kHz_16bit_0.3s_03_s03.wav", 0.0, -1, {"norm": "rms", "db": -21.0}],
	["pasos/arena_4", "C/02_footsteps/sand_48kHz_16bit_0.41s_04_s03.wav", 0.0, -1, {"norm": "rms", "db": -21.0}],
	["pasos/madera_1", F_MADERA, 0.01, 0.42, {"norm": "rms", "db": -21.0}],
	["pasos/madera_2", F_MADERA, 0.52, 0.93, {"norm": "rms", "db": -21.0}],
	["pasos/madera_3", F_MADERA, 1.06, 1.47, {"norm": "rms", "db": -21.0}],
	["pasos/madera_4", F_MADERA, 1.55, 1.96, {"norm": "rms", "db": -21.0}],
	# ---------------------------------------------------------------- combate (ataques físicos, impactos y defensa)
	["combate/golpe_1", F_HACHA, 2.67, 3.30, {"norm": "pico", "db": -1.0, "fo": 0.18}],
	["combate/golpe_2", F_HACHA, 5.01, 5.64, {"norm": "pico", "db": -1.0, "fo": 0.18}],
	["combate/golpe_3", F_HACHA, 7.42, 8.05, {"norm": "pico", "db": -1.0, "fo": 0.18}],
	["combate/golpe_4", F_HACHA, 9.81, 10.44, {"norm": "pico", "db": -1.0, "fo": 0.18}],
	["combate/critico_1", F_TAJO, 0.17, 0.86, {"norm": "pico", "db": -1.0, "fo": 0.2,
		"capas": [[F_GOLPE_SORDO, 0.0, 0.2, 0.025, -3.0]]}],
	["combate/critico_2", F_HACHA, 9.81, 10.50, {"norm": "pico", "db": -1.0, "fo": 0.2,
		"capas": [[F_GOLPE_SORDO, 0.0, 0.2, 0.025, -4.0]]}],
	["combate/defendido_1", F_ESCUDO, 0.0, 0.62, {"norm": "pico", "db": -1.0, "fo": 0.2}],
	["combate/defendido_2", F_ESCUDO, 2.59, 3.21, {"norm": "pico", "db": -1.0, "fo": 0.2}],
	["combate/defendido_3", F_ESCUDO, 7.34, 7.96, {"norm": "pico", "db": -1.0, "fo": 0.2}],
	["combate/defensa", F_CUERO, 0.05, 0.85, {"norm": "pico", "db": -2.0, "fo": 0.15,
		"capas": [[F_VAINA, 0.0, 0.55, 0.10, -7.0]]}],
	["combate/salto_1", "S20/David Dumais Audio - Weapon Sounds - Weapon Swings/MeleeSwingsPack_96khz_Stereo_HighSwings15.wav", 0.0, 0.43, {"norm": "pico", "db": -2.0, "fo": 0.08}],
	["combate/salto_2", "S20/David Dumais Audio - Weapon Sounds - Weapon Swings/MeleeSwingsPack_96khz_Stereo_NormalSwings39.wav", 0.05, 0.75, {"norm": "pico", "db": -2.0, "fo": 0.15}],
	["combate/salto_3", "S23/David Dumais Audio - Melee Weapons Sound Effects Pack 1/SWSH_Swing 3 Large 03_DDUMAIS_NONE.wav", 0.07, 0.62, {"norm": "pico", "db": -2.0, "fo": 0.12}],
	["combate/huida", "S16/SoundBits -  Just Whoosh 3 _ Whoosh Essentials/Whoosh_Cloth_Leather_Fight_174.wav", 0.10, 0.80, {"norm": "pico", "db": -2.0, "fo": 0.15}],
	["combate/emboscada", "S17/Bluezone Corporation - Cinematic Trailer Sound Effects/Bluezone-BC0226-whoosh-impact-012.wav", 0.85, 2.85, {"norm": "pico", "db": -1.0, "fi": 0.05, "fo": 0.6}],
	["combate/jefe", "S19/Federico Soler Fernández - Effective Trailer Hits & Impacts/Dramatic E.wav", 0.0, 3.6, {"norm": "pico", "db": -1.0, "fo": 1.2}],
	["combate/fase2", "S19/Federico Soler Fernández - Effective Trailer Hits & Impacts/Angry E.wav", 0.0, 3.2, {"norm": "pico", "db": -1.0, "fo": 1.0,
		"capas": [["S20/Sounds Great - Orc Creature Library/attack_7.WAV", 0.03, 0.85, 0.15, -4.0]]}],
	["combate/carga_jefe", "S18/Gamemaster Audio - Magic and Spell Sounds/casting_charge_matter_grow_04.wav", 0.0, -1, {"norm": "pico", "db": -2.0, "fo": 0.1}],
	["combate/embuir", "S19/Sound Spark LLC – Magic Spells, Buffs and Attacks/Ice_Spell_Ice_Spell_Buff_Positive_02.wav", 0.0, 1.25, {"norm": "pico", "db": -2.0, "fo": 0.35}],
	["combate/victoria", "C/01_ui_interface/victory_48kHz_16bit_2.67s_03_s29.wav", 0.0, -1, {"norm": "pico", "db": -1.0, "fo": 0.2}],
	["combate/derrota", "S23/InspectorJ - RPG Orchestral Essentials (Music FX)/Failure_01-10_Ensemble-Small_DRY.wav", 0.0, 1.35, {"norm": "pico", "db": -1.0, "fo": 0.35}],
	["combate/nivel", F_ARPA, 0.0, 2.6, {"norm": "pico", "db": -1.0, "fo": 0.9}],
	["combate/monedas_1", F_MONEDAS, 0.45, 1.75, {"norm": "pico", "db": -2.0, "fo": 0.25}],
	["combate/monedas_2", F_MONEDAS, 2.15, 3.62, {"norm": "pico", "db": -2.0, "fo": 0.25}],
	["combate/monedas_3", F_MONEDAS, 4.15, 5.25, {"norm": "pico", "db": -2.0, "fo": 0.25}],
	["combate/pocion", "C/12_items_inventory/bottle_uncork_48kHz_16bit_0.48s_01_s32.wav", 0.0, 0.42, {"norm": "pico", "db": -2.0, "fo": 0.1,
		"capas": [["C/12_items_inventory/bottle_48kHz_16bit_0.43s_01_s35.wav", 0.0, 0.43, 0.14, -5.0]]}],
	# ---------------------------------------------------------------- cofres, puertas, objetos y mundo
	["mundo/cofre_1", "C/11_doors_locks/creak_48kHz_16bit_0.65s_01_s14.wav", 0.0, -1, {"norm": "pico", "db": -2.0, "fo": 0.08}],
	["mundo/cofre_2", "C/11_doors_locks/creak_48kHz_16bit_0.83s_02_s14.wav", 0.0, -1, {"norm": "pico", "db": -2.0, "fo": 0.08}],
	["mundo/cofre_3", "C/11_doors_locks/creak_48kHz_16bit_0.34s_03_s14.wav", 0.0, -1, {"norm": "pico", "db": -2.0, "fo": 0.06}],
	["mundo/tesoro", "S17/Gamemaster Audio -  Fun Casual Sounds/collect_item_14.wav", 0.0, 1.0, {"norm": "pico", "db": -1.0, "fo": 0.3}],
	["mundo/union", F_ARPA, 0.0, 1.8, {"norm": "pico", "db": -1.0, "fo": 0.7}],
	["mundo/examinar", "S19/3maze - UI FX/marimba_tone_007.wav", 0.0, 0.6, {"norm": "pico", "db": -2.0, "fo": 0.25}],
	["mundo/pagina", "S17/The Soundcatcher - Paperlife/Paper_Pergament_Pages_Turn_Flip_20.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.1}],
	["mundo/misterio", "S23/InspectorJ - RPG Orchestral Essentials (Music FX)/Mystery_01-11_Ensemble-Large_WET.wav", 0.0, 4.5, {"norm": "pico", "db": -1.0, "fo": 1.8}],
	["mundo/palanca", "S24/BluezoneCorp - Industrial Lever Switch/Bluezone_BC0302_industrial_lever_switch_014.wav", 0.0, 1.55, {"norm": "pico", "db": -1.0, "fo": 0.15}],
	["mundo/atascado", "S24/BluezoneCorp - Industrial Lever Switch/Bluezone_BC0302_industrial_lever_switch_small_003.wav", 0.0, -1, {"norm": "pico", "db": -2.0, "fo": 0.05}],
	["mundo/puente_baja", "S20/Conor Bradley - Metal Chains/Heavy_Chain-Foley_On_Wood.wav", 0.0, 2.6, {"norm": "pico", "db": -2.0, "fo": 0.8, "pb": 3200.0}],
	["mundo/ascensor", "S20/Conor Bradley - Metal Chains/Jingle_Chain-Sustained_Foley.wav", 0.0, 1.3, {"norm": "pico", "db": -2.0, "fi": 0.05, "fo": 0.4}],
	["mundo/cerrada", F_PUERTA, 5.05, 5.90, {"norm": "pico", "db": -2.0, "fo": 0.2}],
	["mundo/guardado", F_CAMPANAS, 2.2, 4.8, {"norm": "pico", "db": -2.0, "fi": 0.2, "fo": 1.0}],
	["mundo/posada", F_CAMPANAS, 6.3, 9.6, {"norm": "pico", "db": -2.0, "fi": 0.3, "fo": 1.2}],
	["mundo/portal", "S20/David Dumais Audio - Magic Sound FX Pack 1/Magic_Transformation03.wav", 0.0, 2.4, {"norm": "pico", "db": -1.0, "fo": 0.6}],
	["mundo/entrar", "S16/SoundBits -  Just Whoosh 3 _ Whoosh Essentials/Whoosh_Rod_Pole_022.wav", 0.03, 0.63, {"norm": "pico", "db": -3.0, "fo": 0.15}],
	# ---------------------------------------------------------------- interfaz (los «tic», «confirmar» y «clac» siguen hechos por código)
	["interfaz/abrir", "C/01_ui_interface/open_48kHz_16bit_0.15s_01_s13.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.03}],
	["interfaz/cerrar", "C/01_ui_interface/close_48kHz_16bit_0.15s_01_s13.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.03}],
	["interfaz/atras", "C/01_ui_interface/back_48kHz_16bit_0.09s_03_s13.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.02}],
	["interfaz/error", "C/01_ui_interface/error_48kHz_16bit_0.16s_01_s13.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.03}],
	["interfaz/equipar", F_CUERO, 0.05, 0.60, {"norm": "pico", "db": -3.0, "fo": 0.15}],
	["interfaz/equipar_arma", F_VAINA, 0.0, 0.60, {"norm": "pico", "db": -3.0, "fo": 0.15}],
	# ---------------------------------------------------------------- ambiente: río y cascada (bucles para sonido 3D)
	["ambiente/rio", "S20/Ivo Vicic - Mountain rivers and streams/74 River_mid  field_LOOP 2.WAV", 20.0, 52.0, {"norm": "rms", "db": -22.0, "techo": -2.0, "bucle": 2.0}],
	["ambiente/cascada", "S20/Bluezone - Wilderness - Flowing Water/Bluezone_BC0259_wilderness_flowing_water_waterfall_small_002.wav", 5.0, 37.0, {"norm": "rms", "db": -21.0, "techo": -2.0, "bucle": 2.0}],
	# ---------------------------------------------------------------- ambiente: detalles sueltos de la naturaleza
	["ambiente/rafaga_hierba_1", F_RAFAGA_HIERBA, 15.5, 21.5, {"norm": "rms", "db": -24.0, "techo": -3.0, "fi": 1.5, "fo": 1.8}],
	["ambiente/rafaga_hierba_2", F_RAFAGA_HIERBA, 23.5, 28.5, {"norm": "rms", "db": -24.0, "techo": -3.0, "fi": 1.5, "fo": 1.8}],
	["ambiente/rafaga_hierba_3", F_RAFAGA_HIERBA, 105.5, 110.5, {"norm": "rms", "db": -24.0, "techo": -3.0, "fi": 1.5, "fo": 1.8}],
	["ambiente/rafaga_hierba_4", F_RAFAGA_HIERBA, 135.5, 142.5, {"norm": "rms", "db": -24.0, "techo": -3.0, "fi": 1.5, "fo": 1.8}],
	["ambiente/rafaga_arbol_1", F_RAFAGA_ARBOL, 5.5, 11.5, {"norm": "rms", "db": -24.0, "techo": -3.0, "fi": 1.5, "fo": 1.8}],
	["ambiente/rafaga_arbol_2", F_RAFAGA_ARBOL, 27.5, 34.0, {"norm": "rms", "db": -24.0, "techo": -3.0, "fi": 1.5, "fo": 1.8}],
	["ambiente/rafaga_arbol_3", F_RAFAGA_ARBOL, 99.0, 105.5, {"norm": "rms", "db": -24.0, "techo": -3.0, "fi": 1.5, "fo": 1.8}],
	["ambiente/rafaga_arbol_4", F_RAFAGA_ARBOL, 123.5, 130.0, {"norm": "rms", "db": -24.0, "techo": -3.0, "fi": 1.5, "fo": 1.8}],
	["ambiente/pajaro", "C/15_nature_weather/birds_48kHz_16bit_3s_01_s58.wav", 0.0, -1, {"norm": "rms", "db": -24.0, "techo": -3.0, "fi": 0.05, "fo": 0.4}],
	["ambiente/hojas_1", "C/15_nature_weather/leaves_48kHz_16bit_0.85s_02_s40.wav", 0.0, -1, {"norm": "rms", "db": -24.0, "techo": -3.0, "fo": 0.2}],
	["ambiente/hojas_2", "C/15_nature_weather/leaves_48kHz_16bit_1.58s_01_s40.wav", 0.0, -1, {"norm": "rms", "db": -24.0, "techo": -3.0, "fo": 0.3}],
	["ambiente/gota_1", "C/14_water_mud_slime/water_drop_48kHz_16bit_0.35s_01_s32.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.08}],
	["ambiente/gota_2", "C/14_water_mud_slime/water_drop_48kHz_16bit_0.39s_02_s32.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.08}],
	["ambiente/gota_3", "C/14_water_mud_slime/water_drop_48kHz_16bit_0.59s_03_s32.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.1}],
	# ---------------------------------------------------------------- voces de los enemigos (tanda 2)
	# el limo (slime): no tiene voz, suena a materia húmeda que se estira, se aplasta y se deshace
	["voces/limo_ataque_1", F_AGUA_CC0 + "mud_48kHz_16bit_0.44s_01_s51.wav", 0.05, 0.42, {"norm": "pico", "db": -3.0, "fo": 0.1}],
	["voces/limo_ataque_2", "S17/Bluezone Corporation - Synthetic Liquid Textures/Bluezone-BC0227-synthetic-liquid-short-texture-057.wav", 0.0, 0.75, {"norm": "pico", "db": -3.0, "fo": 0.2}],
	["voces/limo_herido_1", F_SLIME + "0.35s_01_s35.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.06}],
	["voces/limo_herido_2", F_SLIME + "0.31s_03_s35.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.06}],
	["voces/limo_herido_3", F_AGUA_CC0 + "mud_48kHz_16bit_0.31s_03_s51.wav", 0.0, 0.28, {"norm": "pico", "db": -3.0, "fo": 0.08}],
	["voces/limo_caida_1", F_AGUA_CC0 + "impactsplat_48kHz_16bit_1.78s_05_s06.wav", 0.03, 0.75, {"norm": "pico", "db": -2.0, "fo": 0.25,
		"capas": [[F_AGUA_CC0 + "bubbles_48kHz_16bit_0.6s_01_s53.wav", 0.02, 0.45, 0.30, -6.0]]}],
	["voces/limo_caida_2", F_AGUA_CC0 + "impactsplat_48kHz_16bit_0.83s_03_s06.wav", 0.0, 0.6, {"norm": "pico", "db": -2.0, "fo": 0.2,
		"capas": [[F_AGUA_CC0 + "bubbles_48kHz_16bit_0.32s_02_s53.wav", 0.0, 0.30, 0.25, -6.0]]}],
	# Grimfang, el goblin: voz rasposa y algo aguda (el orco, un poco acelerado: una criatura más pequeña)
	["voces/goblin_ataque_1", "S20/Phase 4 Libraries - Monster Roars/MR - Orc Attack VO 04.wav", 0.02, 0.50, {"norm": "pico", "db": -2.0, "fo": 0.1}],
	["voces/goblin_ataque_2", "C/08_creatures_monsters/goblin_48kHz_16bit_0.29s_02_s34.wav", 0.0, -1, {"norm": "pico", "db": -2.0, "fo": 0.05}],
	["voces/goblin_ataque_3", F_ORCO + "attack_7.WAV", 0.04, 0.75, {"norm": "pico", "db": -2.0, "fo": 0.15, "tono": 1.15}],
	["voces/goblin_herido_1", F_ORCO + "hit_injured_5.WAV", 0.06, 0.60, {"norm": "pico", "db": -2.0, "fo": 0.12, "tono": 1.12}],
	["voces/goblin_herido_2", "C/08_creatures_monsters/goblin_48kHz_16bit_0.18s_01_s34.wav", 0.0, -1, {"norm": "pico", "db": -2.0, "fo": 0.04}],
	["voces/goblin_herido_3", "C/08_creatures_monsters/creature_hurt_48kHz_16bit_0.47s_04_s57.wav", 0.0, 0.32, {"norm": "pico", "db": -2.0, "fo": 0.08}],
	["voces/goblin_caida_1", F_ORCO + "pain_scream_5.WAV", 0.08, 1.25, {"norm": "pico", "db": -2.0, "fo": 0.4, "tono": 1.1}],
	["voces/goblin_caida_2", "S17/MatiasMacSD - CREATURES ZONE/Creature_Monster_Pain_01.wav", 0.02, 0.90, {"norm": "pico", "db": -2.0, "fo": 0.3}],
	# Gorthor el Devorador (el mismo goblin, el doble de grande): grave y lento; cae de rodillas, muerde y muere
	["voces/gorthor_ataque_1", F_ORCO + "attack_7.WAV", 0.04, 0.80, {"norm": "pico", "db": -1.0, "fo": 0.2, "tono": 0.85}],
	["voces/gorthor_ataque_2", "S23/David Dumais Audio - Monster Sound FX Pack 2/MonsterPack2_LargeMonster11_Roar03.wav", 0.02, 0.75, {"norm": "pico", "db": -1.0, "fo": 0.2}],
	["voces/gorthor_herido_1", "S17/Gamemaster Audio - Troll Monster Vocalizations/troll_monster_hurt_pain_01.wav", 0.0, 0.62, {"norm": "pico", "db": -1.0, "fo": 0.15, "tono": 0.88}],
	["voces/gorthor_herido_2", F_ORCO + "surprise_2.WAV", 0.05, 0.50, {"norm": "pico", "db": -1.0, "fo": 0.12, "tono": 0.85}],
	["voces/gorthor_caida", "S20/David Dumais Audio - Monster Sound FX Pack 1/Monster9_Death10.wav", 0.04, 1.0, {"norm": "pico", "db": -1.0, "fo": 0.35,
		"capas": [["S20/Bluezone - Forest Creature Sound Effects/Bluezone_BC0269_creature_wood_footstep_medium_004.wav", 0.0, 0.9, 0.35, -4.0]]}],
	["voces/gorthor_muerte", "S17/Gamemaster Audio - Troll Monster Vocalizations/troll_monster_death_01.wav", 0.0, 2.0, {"norm": "pico", "db": -1.0, "fo": 0.8, "tono": 0.9}],
	["voces/gorthor_devorar", "S18/Olivier Girardot - Monsters/Monster Bite 3.wav", 0.0, 0.72, {"norm": "pico", "db": -1.0, "fo": 0.15}],
	# el Guardián de piedra: no tiene boca; su «voz» es roca que gruñe y arrastra, golpes de piedra y un derrumbe
	["voces/piedra_ataque_1", F_PIEDRA_HUM, 1.5, 2.6, {"norm": "pico", "db": -2.0, "fi": 0.08, "fo": 0.35,
		"capas": [["S20/Wav Junction Sound Effects - Rocks/0119_Rock_Quick_Drag_On_Rock_029.wav", 0.7, 1.0, 0.05, -2.0]]}],
	["voces/piedra_ataque_2", F_PIEDRA_HUM, 0.0, 1.05, {"norm": "pico", "db": -2.0, "fi": 0.05, "fo": 0.3,
		"capas": [["S20/Wav Junction Sound Effects - Rocks/0093_Rock_Quick_Drag_On_Rock_003.wav", 0.55, 0.8, 0.1, -2.0]]}],
	["voces/piedra_herido_1", F_PIEDRA_MARTILLO, 0.0, 0.35, {"norm": "pico", "db": -2.0, "fo": 0.12}],
	["voces/piedra_herido_2", F_PIEDRA_GOLPE, 0.0, 0.40, {"norm": "pico", "db": -2.0, "fo": 0.15}],
	["voces/piedra_herido_3", F_PEDRUSCO, 0.0, 0.60, {"norm": "pico", "db": -2.0, "fo": 0.2}],
	["voces/piedra_caida_1", F_DERRUMBE, 0.08, 1.9, {"norm": "pico", "db": -1.0, "fo": 0.6, "capas": [[F_PEDRUSCO, 0.0, 0.5, 0.0, -3.0]]}],
	["voces/piedra_caida_2", "S18/Soundrangers - Foley Elements Rocks, Dirt And Stone/dirt_collapse_05.wav", 0.2, 2.0, {"norm": "pico", "db": -1.0, "fo": 0.6,
		"capas": [["S24/BluezoneCorp - Stone Impact/Bluezone_BC0297_stone_impact_041.wav", 0.0, 0.5, 0.0, -3.0]]}],
	# el Gólem de ámbar: la piedra con un brillo de cristal (su ataque es el de la piedra, más agudo: sonido.gd)
	["voces/ambar_herido_1", F_PIEDRA_MARTILLO, 0.0, 0.35, {"norm": "pico", "db": -2.0, "fo": 0.15,
		"capas": [["S16/Stuart Duffield - Ice SFX/Ice_impact_lite_02.wav", 0.0, 0.4, 0.0, -3.0]]}],
	["voces/ambar_herido_2", F_PIEDRA_GOLPE, 0.0, 0.40, {"norm": "pico", "db": -2.0, "fo": 0.15,
		"capas": [["S16/Stuart Duffield - Ice SFX/Ice_smash_light_02.wav", 0.0, 0.5, 0.01, -6.0]]}],
	["voces/ambar_caida", F_DERRUMBE, 0.08, 1.6, {"norm": "pico", "db": -1.0, "fo": 0.5,
		"capas": [["S23/BluezoneCorp - Broken Glass/Bluezone_BC0274_glass_impact_break_falling_debris_004.wav", 0.0, 1.0, 0.05, -5.0]]}],
	# ---------------------------------------------------------------- más combate, la Garganta, el brazalete y el Diario (tanda 2)
	["combate/congelar", "S23/BluezoneCorp - Ice Cracking/Bluezone_BC0278_ice_crack_break_078.wav", 0.02, 0.66, {"norm": "pico", "db": -2.0, "fo": 0.15}],
	["mundo/puerta_abre", F_PUERTA, 0.0, 1.35, {"norm": "pico", "db": -2.0, "fo": 0.3, "pb": 2400.0}],
	["mundo/brazalete", F_CAMPANAS, 0.6, 1.9, {"norm": "pico", "db": -3.0, "fi": 0.15, "fo": 0.6}],
	["interfaz/libro_hoja", "C/13_paper_books/book_flip_48kHz_16bit_0.23s_02_s14.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.04}],
	["interfaz/libro_cerrar", "C/13_paper_books/book_close_48kHz_16bit_0.23s_01_s14.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.04}],
	# ---------------------------------------------------------------- tanda 3: la Garganta 3D (bucles para sonido 3D y gotas)
	# la cascada grande que cae del muro del norte al abismo: un rugido grave y ancho (no el chorro pequeño de Pastos Verdes)
	["ambiente/cascada_grande", F_CASCADA_GRANDE, 20.0, 52.0, {"norm": "rms", "db": -21.0, "techo": -2.0, "bucle": 2.0}],
	# el viento del abismo: un aullido grave y tonal, como el aire que pasa por una rendija
	["ambiente/viento_abismo", F_AULLIDO, 0.5, 32.5, {"norm": "rms", "db": -24.0, "techo": -3.0, "bucle": 2.0}],
	# una gota de cueva con su cola de eco (la segunda, más grave: otra gota más grande)
	["ambiente/gota_cueva_1", F_GOTA_CUEVA, 0.0, 2.2, {"norm": "pico", "db": -3.0, "fo": 1.2}],
	["ambiente/gota_cueva_2", F_GOTA_CUEVA, 0.0, 2.2, {"norm": "pico", "db": -3.0, "fo": 1.2, "tono": 0.84}],
	# ---------------------------------------------------------------- tanda 3: las artes (T-091; NO son las 12 magias de siempre)
	# Alba: una campanilla que sube y un tic de reloj suave (el turno llega antes)
	["combate/arte_alba", "S19/The Chris Alan - Gliss Bliss/Bell Guitar Gliss Up 01.wav", 0.0, 0.85, {"norm": "pico", "db": -2.0, "fo": 0.3,
		"capas": [["S23/InspectorJ - Essentials 02 Clocks/CLOCKTick_InsJ_Clock-07_Ticking_Single-01.wav", 0.0, 0.25, 0.5, -8.0]]}],
	# Ocaso: un tono que cae (marimba, más grave) y un golpe sordo (los enemigos pierden su turno)
	["combate/arte_ocaso", "S19/The Chris Alan - Gliss Bliss/Marimba Gliss Down Fast 01.wav", 0.0, 0.8, {"norm": "pico", "db": -2.0, "fo": 0.35, "tono": 0.8,
		"capas": [["S19/344 Audio - Low Frequency Elements/Explosive Hit 10 Filtered, Low End.wav", 0.0, 0.5, 0.6, -2.0]]}],
	# Hora Dorada: un acorde cálido que crece, con campanillas
	["combate/arte_hora_dorada", F_ETERNIDAD + "Bluezone_BC0273_eternity_synth_chord_002_01.wav", 0.0, 2.2, {"norm": "pico", "db": -2.0, "fi": 0.05, "fo": 0.9,
		"capas": [[F_ETERNIDAD + "Bluezone_BC0273_eternity_synth_chimes_texture_001.wav", 2.8, 4.4, 0.25, -5.0]]}],
	# Escarcha: la coraza de hielo se forma y cruje
	["combate/arte_escarcha", F_HIELO_DD + "Magic_Spells_CastShort_Ice_General24.wav", 0.12, 1.25, {"norm": "pico", "db": -2.0, "fo": 0.4,
		"capas": [["S18/Soundrangers - Foley Elements Ice and Snow/ice_freeze_crack_04.wav", 0.78, 1.05, 0.3, -5.0]]}],
	# la coraza absorbe un golpe: un tintineo de cristal corto (dos golpes distintos de la misma copa)
	["combate/barrera_absorbe_1", F_COPA, 1.06, 1.42, {"norm": "pico", "db": -3.0, "fo": 0.15}],
	["combate/barrera_absorbe_2", F_COPA, 4.79, 5.15, {"norm": "pico", "db": -3.0, "fo": 0.15}],
	# la coraza se rompe: cristal que estalla con hielo debajo
	["combate/barrera_rota", "S17/Chris Skyes - Shards Broken Glass/Glass,Shards,Smash,Medium Impact,Lots of Large Shards.wav", 0.0, 0.85, {"norm": "pico", "db": -1.0, "fo": 0.2,
		"capas": [[F_HIELO_DD + "Magic_Spells_Impact_Ice13.wav", 0.12, 0.9, 0.0, -4.0]]}],
	# Lumbre (Segundo Aliento y Última Brasa): una subida cálida de fuego con una campana suave
	["combate/arte_lumbre", F_FUEGO_GQ + "Designed Fire - Winds - Binaural, swoosh, waves 02.wav", 0.2, 2.3, {"norm": "pico", "db": -2.0, "fi": 0.1, "fo": 0.6,
		"capas": [[F_CAMPANA_SUAVE, 0.0, 1.2, 1.25, -5.0]]}],
	# Lumbre de Retorno: un soplo que se levanta, con brasas
	["combate/renacer", "S19/Airborne Sound - Airy Whooshes/Whoosh,Sound Design,Airy,Full,Soft,Shudder,Very Slow,Aftershock.wav", 1.0, 2.9, {"norm": "pico", "db": -2.0, "fi": 0.2, "fo": 0.5,
		"capas": [[F_FUEGO_GQ + "Designed Fire - Swooshes - Burst, evolving 34.wav", 1.9, 3.3, 0.35, -6.0]]}],
	# Aliento (cura al empezar el turno): unas cuentas que tintinean con un soplo, muy suave
	["combate/aliento", "S19/Eiravaein Works - Helina/Helinä,windchimes,Pacific,obsidian,beads,kelppods,noclapper,nowindcatcher,twine,release,gentle,shorttail,MidSide.wav", 0.05, 1.3, {"norm": "pico", "db": -4.0, "fi": 0.05, "fo": 0.5}],
	# Brasa (el aliado caído se levanta): chisporroteo, una campana y una llamarada corta
	["combate/brasa", "S18/The Sound Keeper - Small Fire/sm-fire-firewood-small-03-DPAmono.wav", 8.0, 9.3, {"norm": "pico", "db": -2.0, "fi": 0.05, "fo": 0.5,
		"capas": [[F_CAMPANA_SUAVE, 0.0, 1.2, 0.12, -3.0], [F_FUEGO_GQ + "Designed Fire - Swooshes - Burst, evolving 34.wav", 2.0, 2.8, 0.0, -8.0]]}],
	# esquiva (la Pluma de arpía): un silbido de aire
	["combate/esquiva_1", "C/04_combat_melee/tin_whistle_whoosh_48kHz_16bit_0.37s_01_s32.wav", 0.0, -1, {"norm": "pico", "db": -3.0, "fo": 0.08}],
	["combate/esquiva_2", "S19/Airborne Sound - Airy Whooshes/Whoosh,Sound Design,Airy,Full,Forceful,Soft.wav", 0.18, 0.62, {"norm": "pico", "db": -3.0, "fi": 0.02, "fo": 0.12}],
	# ---------------------------------------------------------------- tanda 3: Oakhaven (los engancha narrativa en su escena)
	# la campana lejana de la torre (unas campanadas de pueblo, con paso bajo: lejos)
	["mundo/campana", "S23/Justsoundeffects - Urban Ambiences/AMBRlgn_Church Bells Ringing Village_JSE_UAG.wav", 7.2, 13.6, {"norm": "pico", "db": -3.0, "fi": 0.02, "fo": 1.6, "pb": 3500.0}],
	# el bullicio de la taberna, oído desde la calle (con paso bajo: a través de la puerta y las paredes)
	["ambiente/taberna", "S18/West Wolf - Restaurant Ambiences/RA_06_Restaurant_Dinner_Int_Walla_Crowd_50-75 People_Germany_Zoom H4.wav", 20.0, 52.0, {"norm": "rms", "db": -22.0, "techo": -3.0, "bucle": 2.0, "pb": 2600.0}],
	# el letrero del cuervo de hierro oxidado que chirría con el viento (tres chirridos)
	["mundo/cuervo_1", F_CHIRRIDO, 0.1, 1.1, {"norm": "pico", "db": -3.0, "fi": 0.08, "fo": 0.3}],
	["mundo/cuervo_2", F_CHIRRIDO, 2.85, 3.95, {"norm": "pico", "db": -3.0, "fi": 0.08, "fo": 0.3}],
	["mundo/cuervo_3", "S18/RZ Post - The Creepy Door/Creepy Door, Fast Metal Creak_02.wav", 0.05, 0.95, {"norm": "pico", "db": -3.0, "fi": 0.05, "fo": 0.3}],
	# un farol que prende (una cerilla que se enciende y la llama que agarra)
	["mundo/farol", "S20/InspectorJ - Party Pack/Party-Pack_Match_Ignite_02-03.wav", 0.0, 1.5, {"norm": "pico", "db": -2.0, "fo": 0.6}],
]

# PROPUESTA de sonido para las 12 magias (T-083, tanda 2): NO se integran (D-048: su presentación está protegida). Solo
# se hacen muestras para escucharlas fuera del proyecto («magias=<carpeta>»); la tabla y el enganche que tendrían están
# en docs/audio/inventario_sonidos.md. Un candidato por magia y nivel.
const RECETAS_MAGIAS := [
	["magia_1_fuego", "C/07_magic_spells/fireball_48kHz_16bit_1.96s_01_s10.wav", 0.15, 1.6, {"norm": "pico", "db": -1.0, "fo": 0.4}],
	["magia_2_llamarada", "S19/Sound Spark LLC – Magic Spells, Buffs and Attacks/Fire_Spell_Dragon_Trap_03.wav", 0.15, 1.9, {"norm": "pico", "db": -1.0, "fo": 0.5}],
	["magia_3_infierno", "S23/David Dumais Audio - Magic Sound FX Pack 2/MagicPack2_Earth_MeteorShower003.wav", 1.4, 6.0, {"norm": "pico", "db": -1.0, "fi": 0.1, "fo": 1.2}],
	["magia_1_agua", "S18/Gamemaster Audio - Magic and Spell Sounds/water_blast_projectile_spell_03.wav", 0.0, 1.0, {"norm": "pico", "db": -1.0, "fo": 0.3}],
	["magia_2_torrente", "S20/David Dumais Audio - Water Magic 1/Magic_Spells_CastShort_Water_General07.wav", 0.05, 1.85, {"norm": "pico", "db": -1.0, "fo": 0.5}],
	["magia_3_maremoto", "S23/David Dumais Audio - Magic Sound FX Pack 2/MagicPack2_WaterExplosions_Explosion2-004.wav", 0.0, 2.4, {"norm": "pico", "db": -1.0, "fo": 0.8,
		"capas": [["S20/David Dumais Audio - Water Magic 1/Magic_Spells_CastLong_Combo_WaterCombo02.wav", 0.0, 2.4, 0.0, -8.0]]}],
	["magia_1_rayo", "S18/Gamemaster Audio - Magic and Spell Sounds/electric_surge_blast_04.wav", 0.0, 1.4, {"norm": "pico", "db": -1.0, "fo": 0.4}],
	["magia_2_tormenta", "S23/David Dumais Audio - Magic Sound FX Pack 2/MagicPack2_ElectricitySpells_Spell2-002.wav", 0.15, 2.2, {"norm": "pico", "db": -1.0, "fo": 0.5}],
	["magia_3_colera_del_cielo", "S18/Soundrangers – Thunder/thunder_strike_03.wav", 0.3, 4.4, {"norm": "pico", "db": -1.0, "fo": 1.2}],
	["magia_1_cura", "C/07_magic_spells/magic_48kHz_16bit_1.82s_03_s09.wav", 0.0, -1, {"norm": "pico", "db": -2.0, "fo": 0.4}],
	["magia_2_bendicion", "C/07_magic_spells/magic_48kHz_16bit_2.67s_08_s29.wav", 0.0, -1, {"norm": "pico", "db": -2.0, "fo": 0.6}],
	["magia_3_gracia_divina", "S23/InspectorJ - RPG Orchestral Essentials (Music FX)/Discovery_01-03_Organ-A_WET.wav", 0.0, 4.0, {"norm": "pico", "db": -2.0, "fo": 1.5,
		"capas": [[F_CAMPANAS, 11.6, 14.0, 0.2, -10.0]]}],
]

var base := ""
var solo := PackedStringArray()                        # «solo=a/,b»: solo las recetas que empiezan así
var salida_magias := ""                                # «magias=<carpeta>»: las muestras de la propuesta de magias
var _huellas := {}                                     # ruta de la fuente → SHA-256 (se calcula una vez)
var _cache := {}                                       # ruta de la fuente → [muestras mono a 48 kHz, hz original]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("FALLO: falta la carpeta de la biblioteca (-- \"D:/qtorrent/sound effect\")")
		quit(1)
		return
	# la ruta lleva un espacio: si llega partida en dos argumentos, se vuelve a juntar
	var partes := PackedStringArray()
	for a in args:
		if a == "comprobar":
			continue
		if a.begins_with("solo="):
			solo = a.substr(5).split(",", false)
		elif a.begins_with("magias="):
			salida_magias = a.substr(7).replace("\\", "/").trim_suffix("/")
		else:
			partes.append(a)
	base = " ".join(partes).replace("\\", "/").trim_suffix("/") + "/"
	if "comprobar" in args:
		quit(_comprobar())
		return
	if salida_magias != "":
		quit(_magias())
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SALIDA))
	var filas := PackedStringArray(["derivado;fuente;desde_s;hasta_s;capas;sha256_fuente;duracion_s;pico_dbfs;rms_dbfs"])
	var fallos := 0
	var previas := _filas_previas()                    # las recetas que no se rehacen conservan su fila
	for r in RECETAS:
		if not _toca(r[0]):
			var vieja: String = previas.get(r[0] + ".wav", "")
			if vieja == "":
				print("FALLO: %s no se rehace (solo=) y no está en %s" % [r[0], PROCEDENCIA])
				fallos += 1
			else:
				filas.append(vieja)
			continue
		var fila := _preparar(r)
		if fila == "":
			fallos += 1
		else:
			filas.append(fila)
	var csv := ProjectSettings.globalize_path("res://").path_join("../" + PROCEDENCIA).simplify_path()
	var f := FileAccess.open(csv, FileAccess.WRITE)
	if f == null:
		print("FALLO: no se puede escribir %s" % csv)
		fallos += 1
	else:
		f.store_string("\n".join(filas) + "\n")
		f.close()
	print("PROCEDENCIA %s (%d derivados)" % [csv, filas.size() - 1])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _toca(nombre: String) -> bool:
	if solo.is_empty():
		return true
	for s in solo:
		if nombre.begins_with(s):
			return true
	return false


# Filas del CSV de procedencia que ya había: derivado (con .wav) → fila entera.
func _filas_previas() -> Dictionary:
	var r := {}
	var csv := ProjectSettings.globalize_path("res://").path_join("../" + PROCEDENCIA).simplify_path()
	var f := FileAccess.open(csv, FileAccess.READ)
	if f == null:
		return r
	f.get_line()
	while not f.eof_reached():
		var l := f.get_line()
		if l.strip_edges() != "":
			r[l.get_slice(";", 0)] = l
	return r


# Muestras de la propuesta de magias: fuera del proyecto, sin .import, con su propio CSV de procedencia.
func _magias() -> int:
	DirAccess.make_dir_recursive_absolute(salida_magias)
	var filas := PackedStringArray(["muestra;fuente;desde_s;hasta_s;capas;sha256_fuente;duracion_s;pico_dbfs;rms_dbfs"])
	var fallos := 0
	for r in RECETAS_MAGIAS:
		var fila := _preparar(r, salida_magias)
		if fila == "":
			fallos += 1
		else:
			filas.append(fila)
	var f := FileAccess.open(salida_magias + "/magias_procedencia.csv", FileAccess.WRITE)
	if f == null:
		print("FALLO: no se puede escribir en %s" % salida_magias)
		fallos += 1
	else:
		f.store_string("\n".join(filas) + "\n")
		f.close()
	print("MAGIAS %s (%d muestras)" % [salida_magias, filas.size() - 1])
	print("FALLOS: %d" % fallos)
	return 1 if fallos > 0 else 0


func _ruta(fuente: String) -> String:
	var i := fuente.find("/")
	return base + CARPETAS[fuente.substr(0, i)] + fuente.substr(i + 1)


# carpeta: "" = res://audio/efectos (con su .import); una carpeta absoluta = fuera del proyecto (muestras).
func _preparar(r: Array, carpeta := "") -> String:
	var nombre: String = r[0]
	var op: Dictionary = r[4]
	var m := _tramo(r[1], r[2], r[3])
	if m.is_empty():
		print("FALLO: %s: no se puede leer %s" % [nombre, r[1]])
		return ""
	var capas_txt := PackedStringArray()
	for c in op.get("capas", []):
		var mc := _tramo(c[0], c[1], c[2])
		if mc.is_empty():
			print("FALLO: %s: no se puede leer la capa %s" % [nombre, c[0]])
			return ""
		var desde := int(float(c[3]) * HZ)
		var g := db_to_linear(float(c[4]))
		if desde + mc.size() > m.size():
			m.resize(desde + mc.size())
		for i in mc.size():
			m[desde + i] += mc[i] * g
		capas_txt.append("%s [%.2f-%.2f] en %.2f s a %+.0f dB (%s)" % [_corta(c[0]), c[1], c[2], c[3], c[4], _huella(c[0]).substr(0, 12)])
	if op.has("tono"):                                  # remuestreo (como una cinta): cambia el tono y la duración
		var k := float(op["tono"])
		if k > 1.0:                                     # al acelerar, lo de arriba no debe doblarse hacia abajo
			m = _paso_bajo(m, 0.45 * HZ / k)
		m = _cubica(m, k)
		capas_txt.append("tono ×%.2f" % k)
	if op.has("pb"):
		m = _paso_bajo(m, float(op["pb"]))
	if op.has("bucle"):
		m = _bucle(m, int(float(op["bucle"]) * HZ))
	else:
		_fundir(m, float(op.get("fi", 0.003)), float(op.get("fo", 0.03)))
	var pico := _pico(m)
	var rms := _rms(m)
	var ganancia := 1.0
	if op.get("norm", "pico") == "rms":
		ganancia = minf(db_to_linear(float(op["db"])) / maxf(rms, 1e-6), db_to_linear(float(op.get("techo", -1.0))) / maxf(pico, 1e-6))
	else:
		ganancia = db_to_linear(float(op["db"])) / maxf(pico, 1e-6)
	for i in m.size():
		m[i] *= ganancia
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = HZ
	w.stereo = false
	w.data = _pcm(m)
	var ruta := "%s/%s.wav" % [SALIDA if carpeta == "" else carpeta, nombre]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ruta.get_base_dir()))
	var err := w.save_to_wav(ruta)
	if err != OK:
		print("FALLO: no se pudo guardar %s (%s)" % [ruta, error_string(err)])
		return ""
	if carpeta == "":
		_import(ruta, op.has("bucle"))
	var dur := m.size() / float(HZ)
	var p_db := linear_to_db(_pico(m))
	var r_db := linear_to_db(maxf(_rms(m), 1e-6))
	print("EFECTO %-28s %5.2f s  pico %6.1f dBFS  RMS %6.1f dBFS  ← %s" % [nombre, dur, p_db, r_db, _corta(r[1])])
	return "%s.wav;%s;%.3f;%.3f;%s;%s;%.3f;%.1f;%.1f" % [nombre, r[1], r[2], r[3], " + ".join(capas_txt), _huella(r[1]),
		dur, p_db, r_db]


func _corta(fuente: String) -> String:
	return fuente.get_file()


func _huella(fuente: String) -> String:
	if not _huellas.has(fuente):
		_huellas[fuente] = FileAccess.get_sha256(_ruta(fuente))
	return _huellas[fuente]


# Tramo [desde, hasta] de una fuente, en mono y a 48 kHz (flotantes de -1 a 1). hasta < 0: hasta el final.
func _tramo(fuente: String, desde: float, hasta: float) -> PackedFloat32Array:
	var todo: PackedFloat32Array
	if _cache.has(fuente):
		todo = _cache[fuente]
	else:
		var w := AudioStreamWAV.load_from_file(_ruta(fuente))   # sin opciones: tal cual (16 bits; 24 bits se pasan a 16)
		if w == null or w.format != AudioStreamWAV.FORMAT_16_BITS:
			return PackedFloat32Array()
		todo = _a_48k(_mono(w), w.mix_rate)
		_cache[fuente] = todo
		_huella(fuente)
	var a := clampi(int(desde * HZ), 0, todo.size())
	var b := todo.size() if hasta < 0.0 else clampi(int(hasta * HZ), a, todo.size())
	return todo.slice(a, b)


static func _mono(w: AudioStreamWAV) -> PackedFloat32Array:
	var b: PackedByteArray = w.data
	var canales := 2 if w.stereo else 1
	var n := b.size() / (2 * canales)
	var m := PackedFloat32Array()
	m.resize(n)
	for i in n:
		var s := 0.0
		for c in canales:
			s += b.decode_s16((i * canales + c) * 2)
		m[i] = s / (32768.0 * canales)
	return m


# Baja a 48 kHz sin que lo de arriba se cuele como ruido: media banda y diezmado por 2 mientras haga falta
# (192 → 96 → 48; 88,2 → 44,1) y, si queda otra frecuencia, interpolación cúbica (44,1 → 48 sube, no hay pliegue).
static func _a_48k(m: PackedFloat32Array, hz: int) -> PackedFloat32Array:
	while hz >= 72000:
		m = _media_banda(m)
		hz /= 2
	if hz == HZ:
		return m
	return _cubica(m, float(hz) / HZ)


# Filtro de media banda de 11 coeficientes (0,0084 · −0,0558 · 0,2974 · 0,5 · simétrico; los pares son 0) y diezmado
# por 2. Los bordes se rellenan con ceros.
static func _media_banda(m: PackedFloat32Array) -> PackedFloat32Array:
	var n := m.size()
	var e := PackedFloat32Array()
	e.resize(n + 10)
	for i in n:
		e[i + 5] = m[i]
	var r := PackedFloat32Array()
	r.resize(n / 2)
	for j in r.size():
		var c := j * 2 + 5
		r[j] = 0.5 * e[c] + 0.2974 * (e[c - 1] + e[c + 1]) - 0.0558 * (e[c - 3] + e[c + 3]) + 0.0084 * (e[c - 5] + e[c + 5])
	return r


static func _cubica(m: PackedFloat32Array, paso: float) -> PackedFloat32Array:
	var n := m.size()
	var r := PackedFloat32Array()
	r.resize(int(n / paso))
	for j in r.size():
		var x := j * paso
		var i := int(x)
		var t := x - i
		var y0 := m[maxi(i - 1, 0)]
		var y1 := m[mini(i, n - 1)]
		var y2 := m[mini(i + 1, n - 1)]
		var y3 := m[mini(i + 2, n - 1)]
		r[j] = cubic_interpolate(y1, y2, y0, y3, t)
	return r


# Paso bajo de dos polos (Butterworth, RBJ), dos veces: suena «lejos».
static func _paso_bajo(m: PackedFloat32Array, corte: float) -> PackedFloat32Array:
	var w0 := TAU * corte / HZ
	var alfa := sin(w0) / (2.0 * 0.7071)
	var c := cos(w0)
	var a0 := 1.0 + alfa
	var b0 := (1.0 - c) * 0.5 / a0
	var b1 := (1.0 - c) / a0
	var a1 := -2.0 * c / a0
	var a2 := (1.0 - alfa) / a0
	for vuelta in 2:
		var x1 := 0.0
		var x2 := 0.0
		var y1 := 0.0
		var y2 := 0.0
		for i in m.size():
			var x := m[i]
			var y := b0 * x + b1 * x1 + b0 * x2 - a1 * y1 - a2 * y2
			x2 = x1
			x1 = x
			y2 = y1
			y1 = y
			m[i] = y
	return m


static func _fundir(m: PackedFloat32Array, fi: float, fo: float) -> void:
	var ni := mini(int(fi * HZ), m.size())
	for i in ni:
		m[i] *= float(i) / ni
	var no := mini(int(fo * HZ), m.size())
	for i in no:
		var k := m.size() - 1 - i
		m[k] *= sin(float(i) / no * PI * 0.5)             # cae suave, sin chasquido


# Bucle sin corte (como preparar_ambientes.gd): el principio se funde con lo que había justo antes del final.
static func _bucle(m: PackedFloat32Array, f: int) -> PackedFloat32Array:
	f = mini(f, m.size() / 3)
	var largo := m.size() - f
	var r := PackedFloat32Array()
	r.resize(largo)
	for i in largo:
		var v := m[i]
		if i < f:
			var t := float(i) / f
			v = v * sin(t * PI / 2.0) + m[largo + i] * cos(t * PI / 2.0)
		r[i] = v
	return r


static func _pcm(m: PackedFloat32Array) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(m.size() * 2)
	for i in m.size():
		b.encode_s16(i * 2, int(clampf(m[i], -1.0, 1.0) * 32767.0))
	return b


static func _rms(m: PackedFloat32Array) -> float:
	var s := 0.0
	for v in m:
		s += v * v
	return sqrt(s / maxf(1.0, m.size()))


static func _pico(m: PackedFloat32Array) -> float:
	var p := 0.0
	for v in m:
		p = maxf(p, absf(v))
	return p


# .import: QOA (ligero en el móvil), mono, sin recortar ni normalizar (ya está hecho) y bucle solo en los ambientes.
# Si ya existe (Godot lo completa al importar con su uid), se deja como está: rehacer un derivado no cambia su uid.
static func _import(ruta: String, bucle: bool) -> void:
	if FileAccess.file_exists(ruta + ".import"):
		return
	var c := ConfigFile.new()
	c.set_value("remap", "importer", "wav")
	c.set_value("remap", "type", "AudioStreamWAV")
	c.set_value("deps", "source_file", ruta)
	c.set_value("params", "force/8_bit", false)
	c.set_value("params", "force/mono", false)
	c.set_value("params", "force/max_rate", false)
	c.set_value("params", "force/max_rate_hz", 44100)
	c.set_value("params", "edit/trim", false)
	c.set_value("params", "edit/normalize", false)
	c.set_value("params", "edit/loop_mode", 2 if bucle else 1)
	c.set_value("params", "edit/loop_begin", 0)
	c.set_value("params", "edit/loop_end", -1)
	c.set_value("params", "compress/mode", 2)
	c.save(ruta + ".import")


# Vuelve a calcular la huella de cada original y la compara con la apuntada: los originales siguen intactos.
func _comprobar() -> int:
	var csv := ProjectSettings.globalize_path("res://").path_join("../" + PROCEDENCIA).simplify_path()
	var f := FileAccess.open(csv, FileAccess.READ)
	if f == null:
		print("FALLO: no hay %s" % csv)
		return 1
	f.get_line()
	var vistas := {}
	var malas := 0
	while not f.eof_reached():
		var l := f.get_line()
		if l.strip_edges() == "":
			continue
		var c := l.split(";")
		if vistas.has(c[1]):
			continue
		vistas[c[1]] = true
		if FileAccess.get_sha256(_ruta(c[1])) != c[5]:
			print("FALLO: el original cambió o falta: %s" % c[1])
			malas += 1
	print("ORIGINALES %d de %d intactos" % [vistas.size() - malas, vistas.size()])
	print("FALLOS: %d" % malas)
	return 1 if malas > 0 else 0
