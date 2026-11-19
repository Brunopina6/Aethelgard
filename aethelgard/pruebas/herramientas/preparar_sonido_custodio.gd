extends SceneTree
# HERRAMIENTA (19/11, C-9 / PC-5; no es una prueba de regresión): los sonidos propios del Custodio de Porcelana
# (meshy_e01, combate_meshy_e01.gd; APAGADO tras su interruptor «meshy_e01»), derivados de la biblioteca del usuario
# (D:\qtorrent\sound effect, de solo lectura) con el mismo método que pruebas/prueba_efectos_preparar.gd (tramo, capas,
# mono, 48 kHz, tono por remuestreo, paso bajo, fundidos y normalización; QOA al importar): se usan sus funciones.
# Fuentes: paquetes GDC de Sonniss 2017-2020 (#GameAudioGDC; Licensing.pdf / License.pdf en cada paquete: uso en juegos
# comerciales sin atribución, editarlos como parte de la producción; no venderlos tal cual).
# A diferencia de la herramienta general, SOLO toca las filas «meshy_e01/…» de docs/audio/efectos_procedencia.csv (las
# demás se quedan como están: la general reescribe el CSV con sus recetas y perdería las de otras ramas).
# Uso (con los datos aislados, como las pruebas):
#   Godot --headless --path aethelgard --script res://pruebas/herramientas/preparar_sonido_custodio.gd -- "D:/qtorrent/sound effect"
# Después: Godot --headless --path aethelgard --import
#
# Qué pide la ficha del paquete (ataques_propuestos.json, «vfx_audio») y dónde suena (combate.gd y combate_meshy_e01.gd):
#   meshy_e01_entrada   la alerta al empezar el combate (e01__alert: se yergue 0,22, guardia baja 0,60): placas de porcelana
#                       que se recolocan y un apoyo pétreo grave
#   meshy_e01_ataque    Prensa del Umbral, en el IMPACTO (0,90): «golpe pétreo grave» y «astillas de cerámica»
#   meshy_e01_aviso_porton  Avance del Portón, desde el aviso (0,00) hasta antes del impacto: «sonido mecánico creciente»
#   meshy_e01_porton    Avance del Portón, en el IMPACTO (1,30): «impacto metálico amortiguado»
#   meshy_e01_aviso_sello   Sello de Clausura, desde el aviso (0,20): «sonido de llave girando…»
#   meshy_e01_sello     Sello de Clausura, en el IMPACTO (1,30): «…seguido de golpe corto»

const PREP := "res://pruebas/prueba_efectos_preparar.gd"
const PROCEDENCIA := "docs/audio/efectos_procedencia.csv"
const PREFIJO := "meshy_e01/"

const F_ROCA_GRAVE := "S20/PMSFX - Rocky Impacts/PM_RI_Designed_7 Rocks Impact Hit Big LFE Heavy Designed.wav"
const F_ROCA_53 := "S20/PMSFX - Rocky Impacts/PM_RI_Source_53 Rocks Impact Hit Single Stone.wav"
const F_ROCA_92 := "S20/PMSFX - Rocky Impacts/PM_RI_Source_92 Rocks Impact Hit Single Stone.wav"
const F_TAZA_ROTA := "S17/Griffin Sound Design - Mugs/MUG_Tile_Floor_Drop_and_Break.wav"
const F_TARRO := "S18/Eiravaein Works - Vaeyan IV/CookieJar,ceramic,glazed,irregularshape,hollowbase,hollowtop,rough,resonant,tonal,jostle,long,strong,2.wav"
const F_PLACA := "S17/Double Trouble Audio - Medieval Armor and Impacts/Plate_Impact_Hard_02.wav"
const F_SORDO := "S20/Shapeforms - Hit & Punch/IMPACT_LOW_THUD_10.wav"
const F_ENGRANAJE := "S17/Mindful Audio - Elements - Gears/large gear 03 metal slow 8040.wav"
const F_CERRADURA := "S17/Alexander Ahura - Locks & Keys/Lock01_outdoor_opening_lite03.wav"
const F_PESTILLO := "S19/3maze - Doors/door_lock_007.wav"

# [derivado, fuente, desde, hasta, opciones] como en prueba_efectos_preparar.gd (capas: [fuente, desde, hasta, en_s, dB]).
const RECETAS := [
	# alerta: el tarro de cerámica que se recoloca (el golpe de 3,05 s cae a 0,29 s con el tono) y, a ~0,6 s, el apoyo pétreo
	["meshy_e01/entrada", F_TARRO, 2.80, 3.60, {"norm": "pico", "db": -1.0, "fi": 0.02, "fo": 0.45, "tono": 0.85,
		"capas": [[F_ROCA_92, 0.0, 0.55, 0.50, -3.0]]}],
	# Prensa: el primer golpe grave de la roca (sin los rebotes de 0,35 s) con la taza que se rompe en astillas encima
	["meshy_e01/prensa", F_ROCA_GRAVE, 0.0, 0.34, {"norm": "pico", "db": -1.0, "fo": 0.12, "tono": 0.9,
		"capas": [[F_TAZA_ROTA, 0.03, 0.70, 0.02, -7.0]]}],
	# Avance (aviso): el engranaje grande que gira despacio, entrando poco a poco (crece durante 1 s) y cortado antes del impacto
	["meshy_e01/aviso_porton", F_ENGRANAJE, 0.50, 1.58, {"norm": "pico", "db": -2.0, "fi": 1.0, "fo": 0.08, "tono": 0.85}],
	# Avance (impacto): placa metálica, apagada con un paso bajo, sobre un golpe sordo grave
	["meshy_e01/porton", F_PLACA, 0.03, 0.62, {"norm": "pico", "db": -1.0, "fo": 0.2, "tono": 0.85, "pb": 2600.0,
		"capas": [[F_SORDO, 0.0, 0.20, 0.0, -2.0]]}],
	# Sello (aviso): la llave que entra y gira (el chasquido de 2,90 s cae a ~0,8 s del aviso: el centro fijo, 0,80-0,95)
	["meshy_e01/aviso_sello", F_CERRADURA, 2.22, 3.35, {"norm": "pico", "db": -2.0, "fi": 0.02, "fo": 0.15, "tono": 0.85}],
	# Sello (impacto): golpe corto y seco, el pestillo que cae y una piedra pequeña por debajo
	["meshy_e01/sello", F_SORDO, 0.0, 0.205, {"norm": "pico", "db": -1.0, "fo": 0.08, "tono": 0.9,
		"capas": [[F_PESTILLO, 0.42, 0.62, 0.0, -3.0], [F_ROCA_53, 0.0, 0.30, 0.0, -9.0]]}],
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("FALLO: falta la carpeta de la biblioteca (-- \"D:/qtorrent/sound effect\")")
		quit(1)
		return
	var p = load(PREP).new()                            # (sus funciones: _preparar, _tramo, _huella…; no se ejecuta)
	p.base = " ".join(args).replace("\\", "/").trim_suffix("/") + "/"
	if not DirAccess.dir_exists_absolute(p.base):
		print("FALLO: no encuentro la biblioteca en «%s»" % p.base)
		p.free()
		quit(1)
		return
	var nuevas := PackedStringArray()
	var fallos := 0
	for r in RECETAS:
		var fila: String = p._preparar(r)
		if fila == "":
			fallos += 1
		else:
			nuevas.append(fila)
	p.free()
	# el CSV: las filas de antes, sin las «meshy_e01/…», y las nuevas al final
	var csv := ProjectSettings.globalize_path("res://").path_join("../" + PROCEDENCIA).simplify_path()
	var f := FileAccess.open(csv, FileAccess.READ)
	if f == null:
		print("FALLO: no hay %s" % csv)
		quit(1)
		return
	var filas := PackedStringArray()
	while not f.eof_reached():
		var l := f.get_line()
		if l.strip_edges() != "" and not l.begins_with(PREFIJO):
			filas.append(l)
	f.close()
	if fallos == 0:
		filas.append_array(nuevas)
		f = FileAccess.open(csv, FileAccess.WRITE)
		f.store_string("\n".join(filas) + "\n")
		f.close()
		print("PROCEDENCIA %s (%d filas, %d del Custodio)" % [csv, filas.size() - 1, nuevas.size()])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
