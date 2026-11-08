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
# Después hay que importar: Godot --headless --path aethelgard --import

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

# [derivado, fuente, desde (s), hasta (s, -1 = el final), opciones]
# opciones: norm ("pico" o "rms"), db (objetivo en dBFS), techo (pico máximo con «rms»), fi / fo (fundidos en s),
# capas ([[fuente, desde, hasta, en (s), dB], ...] que se suman a la principal), pb (paso bajo en Hz: «lejos»),
# bucle (s de fundido final→principio: hace un bucle sin corte)
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
]

var base := ""
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
		if a != "comprobar":
			partes.append(a)
	base = " ".join(partes).replace("\\", "/").trim_suffix("/") + "/"
	if "comprobar" in args:
		quit(_comprobar())
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SALIDA))
	var filas := PackedStringArray(["derivado;fuente;desde_s;hasta_s;capas;sha256_fuente;duracion_s;pico_dbfs;rms_dbfs"])
	var fallos := 0
	for r in RECETAS:
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


func _ruta(fuente: String) -> String:
	var i := fuente.find("/")
	return base + CARPETAS[fuente.substr(0, i)] + fuente.substr(i + 1)


func _preparar(r: Array) -> String:
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
	var ruta := "%s/%s.wav" % [SALIDA, nombre]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ruta.get_base_dir()))
	var err := w.save_to_wav(ruta)
	if err != OK:
		print("FALLO: no se pudo guardar %s (%s)" % [ruta, error_string(err)])
		return ""
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
static func _import(ruta: String, bucle: bool) -> void:
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
