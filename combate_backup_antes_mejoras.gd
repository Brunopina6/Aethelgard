extends Node2D
# Combate ATB de Aethelgard (Godot 4.x)
# Personajes articulados, menú estilo FFIX, magias Agua y Fuego (con quemadura) y vida sobre los enemigos.
# Se adjunta al nodo raíz de combate.tscn (Nodo 2D). Crea toda la interfaz por código.

const ATB_MAX := 100.0
const ESC := 0.8
const CANVAS := Vector2(320, 480)
const DANO_QUEMADURA := 5
# Música de los combates normales (los jefes y súper jefes tendrán la suya).
const MUSICA_NORMAL := "res://musica_combate_normal.mp3"
const RONDAS_QUEMADURA := 2

# Magias: cambia aquí el coste, el daño y los colores.
const MAGIAS := {
	"Agua": {"coste": 6, "dano": 35, "color": Color(0.35, 0.65, 1.0)},
	"Fuego": {"coste": 8, "dano": 50, "color": Color(1.0, 0.5, 0.15), "quemadura": true},
}

const MODELOS := {
	"kael": {
		"cadera": Vector2(320, 494),
		"esc": 0.4,
		"cerrada": "res://kael2_cara_cerrados.png",
		"partes": [
			{"n": "piernas", "r": "res://kael2_piernas.png", "p": Vector2(0, 0), "padre": "root", "detras": false},
			{"n": "cadera", "r": "res://kael2_cadera.png", "p": Vector2(0, 0), "padre": "root", "detras": false},
			{"n": "torso", "r": "res://kael2_torso.png", "p": Vector2(0, 0), "padre": "cuerpo", "detras": false},
			{"n": "brazo_a", "r": "res://kael2_brazo_a.png", "p": Vector2(231, 316), "padre": "cuerpo", "detras": false},
			{"n": "antebrazo_a", "r": "res://kael2_antebrazo_a_1.png", "p": Vector2(206, 426), "padre": "brazo_a", "detras": false},
			{"n": "cabeza", "r": "res://kael2_cara_normal.png", "p": Vector2(320, 277), "padre": "cuerpo", "detras": false},
			{"n": "brazo_f", "r": "res://kael2_brazo_f.png", "p": Vector2(409, 316), "padre": "cuerpo", "detras": false},
			{"n": "antebrazo_f", "r": "res://kael2_antebrazo_f.png", "p": Vector2(432, 426), "padre": "brazo_f", "detras": false},
			{"n": "arma", "r": "res://kael2_espada_h.png", "p": Vector2(419, 600), "padre": "antebrazo_f", "detras": true}
		]},
	"nyx": {
		"cadera": Vector2(160, 215),
		"cerrada": "res://nyx_cabeza_cerrada.png",
		"partes": [
			{"n": "falda", "r": "res://nyx_falda.png", "p": Vector2(0, 0), "padre": "root", "detras": false},
			{"n": "pelo", "r": "res://nyx_pelo.png", "p": Vector2(0, 0), "padre": "cuerpo", "detras": false},
			{"n": "torso", "r": "res://nyx_torso.png", "p": Vector2(0, 0), "padre": "cuerpo", "detras": false},
			{"n": "brazo_a", "r": "res://nyx_brazo_a.png", "p": Vector2(120, 108), "padre": "cuerpo", "detras": false},
			{"n": "cabeza", "r": "res://nyx_cabeza.png", "p": Vector2(160, 88), "padre": "cuerpo", "detras": false},
			{"n": "brazo_f", "r": "res://nyx_brazo_f.png", "p": Vector2(200, 108), "padre": "cuerpo", "detras": false},
			{"n": "arma", "r": "res://nyx_baston.png", "p": Vector2(222, 234), "padre": "brazo_f", "detras": true}
		]},
	"hollin_a": {
		"cadera": Vector2(160, 240),
		"partes": [
			{"n": "piernas", "r": "res://hollin_a_piernas.png", "p": Vector2(0, 0), "padre": "root", "detras": false},
			{"n": "torso", "r": "res://hollin_a_torso.png", "p": Vector2(0, 0), "padre": "cuerpo", "detras": false},
			{"n": "brazo_f", "r": "res://hollin_a_brazo_f.png", "p": Vector2(222, 142), "padre": "cuerpo", "detras": false},
			{"n": "brazo_a", "r": "res://hollin_a_brazo_a.png", "p": Vector2(112, 150), "padre": "cuerpo", "detras": false},
			{"n": "cabeza", "r": "res://hollin_a_cabeza.png", "p": Vector2(130, 130), "padre": "cuerpo", "detras": false}
		]},
	"hollin_b": {
		"cadera": Vector2(160, 240),
		"partes": [
			{"n": "piernas", "r": "res://hollin_b_piernas.png", "p": Vector2(0, 0), "padre": "root", "detras": false},
			{"n": "torso", "r": "res://hollin_b_torso.png", "p": Vector2(0, 0), "padre": "cuerpo", "detras": false},
			{"n": "brazo_f", "r": "res://hollin_b_brazo_f.png", "p": Vector2(222, 142), "padre": "cuerpo", "detras": false},
			{"n": "arma", "r": "res://hollin_b_cuchilla.png", "p": Vector2(246, 380), "padre": "brazo_f", "detras": true},
			{"n": "brazo_a", "r": "res://hollin_b_brazo_a.png", "p": Vector2(112, 150), "padre": "cuerpo", "detras": false},
			{"n": "cabeza", "r": "res://hollin_b_cabeza.png", "p": Vector2(130, 130), "padre": "cuerpo", "detras": false}
		]},
	"aventurero": {
		"tipo": "frames", "cadera": Vector2(295.0, 640.0), "esc": 0.45, "fps": 10,
		"frames": ["res://aventurero_idle_00.png", "res://aventurero_idle_01.png", "res://aventurero_idle_02.png", "res://aventurero_idle_03.png", "res://aventurero_idle_04.png", "res://aventurero_idle_05.png", "res://aventurero_idle_06.png", "res://aventurero_idle_07.png", "res://aventurero_idle_08.png", "res://aventurero_idle_09.png", "res://aventurero_idle_10.png", "res://aventurero_idle_11.png"],
		"espada": "res://aventurero_espada.png", "piv": Vector2(124.9, 651.0),
		"agarres": [Vector2(144.8, 619.2), Vector2(142.1, 613.9), Vector2(140.0, 608.4), Vector2(138.3, 610.0), Vector2(138.0, 606.2), Vector2(139.7, 609.9), Vector2(141.1, 613.2), Vector2(145.1, 618.5), Vector2(144.5, 620.1), Vector2(146.3, 623.5), Vector2(145.4, 620.9), Vector2(143.1, 620.1)],
		"angs": [-46.0, -45.5, -45.0, -43.5, -43.0, -44.0, -45.0, -46.0, -47.0, -48.0, -47.5, -46.5]},
}


const ANIM := {
	"kael": {"distancia": 150.0, "punta": Vector2(419, 131),
		"tex": {"esp_g": "res://kael2_espada_g.png", "esp_h": "res://kael2_espada_h.png",
			"esp_2": "res://kael2_espada_2.png", "ma_1": "res://kael2_antebrazo_a_1.png",
			"ma_2": "res://kael2_antebrazo_a_2.png"},
		"caras": {"normal": "res://kael2_cara_normal.png", "grito": "res://kael2_cara_grito.png",
			"dolor": "res://kael2_cara_dolor.png", "cerrados": "res://kael2_cara_cerrados.png",
			"sonrisa": "res://kael2_cara_sonrisa.png", "cansado": "res://kael2_cara_cansado.png"},
		"poses": {
			"guardia": {"f": -52.1, "codo_f": 72.7, "arma": 119.4, "a": 4.0, "codo_a": -6.0, "lean": -3.0, "z": 0, "esp": "g", "ma": 1},
			"ini": {"f": 20.8, "codo_f": 183.2, "arma": 76.0, "a": 4.0, "codo_a": -6.0, "lean": 0.0, "z": -1, "esp": "h", "ma": 1},
			"alto": {"f": -130.2, "codo_f": -97.9, "arma": 263.1, "a": 135.2, "codo_a": 112.6, "lean": 8.0, "z": 0, "esp": "2", "ma": 2},
			"golpe": {"f": 2.8, "codo_f": -268.1, "arma": 150.3, "a": 53.3, "codo_a": 226.2, "lean": -12.0, "z": 0, "esp": "2", "ma": 2},
			"magia": {"f": -50.1, "codo_f": 192.8, "arma": 217.3, "a": 178.4, "codo_a": 118.9, "lean": 3.0, "z": 0, "esp": "2", "ma": 2},
		}},
	"aventurero": {"distancia": 140.0, "prep": -20.0, "golpe": -115.0, "lean_prep": 6.0, "lean_golpe": -10.0,
		"m_arma": -12.0, "m_lean": 4.0, "punta": Vector2(192.0, 4.7)},
	"nyx": {"distancia": 100.0, "prep": -100.0, "arma_prep": 150.0, "golpe": -260.0, "arma_golpe": 140.0,
		"ret": -360.0, "lean_prep": 6.0, "lean_golpe": -10.0,
		"m_brazo": -120.0, "m_arma": 90.0, "m_brazo_a": 30.0, "m_lean": 4.0, "punta": Vector2(223, 36)},
	"hollin_a": {"distancia": 90.0, "prep": -120.0, "golpe": -290.0, "ret": -360.0,
		"a_prep": -100.0, "a_golpe": -270.0, "a_ret": -360.0, "lean_prep": 10.0, "lean_golpe": -18.0},
	"hollin_b": {"distancia": 110.0, "prep": -150.0, "arma_prep": 175.0, "golpe": -310.0, "arma_golpe": 160.0,
		"ret": -360.0, "lean_prep": 12.0, "lean_golpe": -20.0},
}

var heroes: Array = [
	{"nombre": "Kael", "modelo": "aventurero", "hero": true, "hp": 120, "hp_max": 120, "mp": 16, "mp_max": 16,
		"atk": 18, "vel": 22.0, "atb": 0.0, "pos": Vector2(830, 160)},
	{"nombre": "Nyx", "modelo": "nyx", "hero": true, "hp": 80, "hp_max": 80, "mp": 40, "mp_max": 40,
		"atk": 8, "vel": 26.0, "atb": 0.0, "pos": Vector2(990, 140)},
]

var enemigos: Array = [
	{"nombre": "Hollín (garras)", "modelo": "hollin_a", "hero": false, "hp": 90, "hp_max": 90,
		"atk": 12, "vel": 13.0, "atb": 0.0, "pos": Vector2(400, 120)},
	{"nombre": "Hollín (cuchilla)", "modelo": "hollin_b", "hero": false, "hp": 90, "hp_max": 90,
		"atk": 14, "vel": 12.0, "atb": 0.0, "pos": Vector2(230, 150)},
]

var pociones := 3
var cola: Array = []
var actor = null
var estado := "esperando"     # esperando, menu, objetivo, enemigo, accion, fin
var accion := ""
var magia_sel := ""
var objetivo_apuntado = null

var capa: CanvasLayer
var registro: Label
var lista: VBoxContainer
var mano: Control
var mano_obj: Control
var glow_tex: GradientTexture2D
var ventana_tex: GradientTexture2D
var mat_aditivo: CanvasItemMaterial
var musica: AudioStreamPlayer


func _ready() -> void:
	randomize()
	_crear_texturas()
	_crear_interfaz()
	_iniciar_musica()
	_actualizar()


func _iniciar_musica() -> void:
	var tipo: String = Engine.get_meta("tipo_combate", "normal")
	if tipo != "normal" or not ResourceLoader.exists(MUSICA_NORMAL):
		return
	var pista = load(MUSICA_NORMAL)
	if pista is AudioStreamMP3:
		pista.loop = true
	musica = AudioStreamPlayer.new()
	musica.stream = pista
	musica.volume_db = -6.0
	add_child(musica)
	musica.play()


func _bajar_musica() -> void:
	if musica != null:
		create_tween().tween_property(musica, "volume_db", -40.0, 1.8)


# ================================================================= interfaz

func _crear_texturas() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	glow_tex = GradientTexture2D.new()
	glow_tex.gradient = g
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(1.0, 0.5)
	glow_tex.width = 256
	glow_tex.height = 256
	var gv := Gradient.new()
	gv.offsets = PackedFloat32Array([0.0, 1.0])
	gv.colors = PackedColorArray([Color(0.33, 0.40, 0.86), Color(0.08, 0.10, 0.36)])
	ventana_tex = GradientTexture2D.new()
	ventana_tex.gradient = gv
	ventana_tex.fill_from = Vector2(0, 0)
	ventana_tex.fill_to = Vector2(0, 1)
	ventana_tex.width = 8
	ventana_tex.height = 64
	mat_aditivo = CanvasItemMaterial.new()
	mat_aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


func _crear_interfaz() -> void:
	capa = CanvasLayer.new()
	add_child(capa)
	_crear_fondo()
	for f in enemigos + heroes:
		_crear_rig(f)
	for e in enemigos:
		_crear_vida_enemigo(e)

	# cartel superior
	var cartel := _ventana(Vector2(380, 12), Vector2(520, 52))
	registro = Label.new()
	registro.size = Vector2(520, 52)
	registro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	registro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	registro.add_theme_font_size_override("font_size", 26)
	registro.text = "¡Combate!"
	cartel.add_child(registro)

	# ventana de comandos
	var vc := _ventana(Vector2(20, 530), Vector2(470, 178))
	lista = VBoxContainer.new()
	lista.position = Vector2(46, 12)
	lista.add_theme_constant_override("separation", 0)
	vc.add_child(lista)

	# ventana del grupo
	var vg := _ventana(Vector2(510, 530), Vector2(750, 178))
	var cab := [["NOMBRE", 34], ["PV", 300], ["PM", 450], ["ATB", 585]]
	for c in cab:
		var l := _etiqueta(c[0], 18, Color(0.75, 0.82, 1.0))
		l.position = Vector2(c[1], 10)
		vg.add_child(l)
	for i in heroes.size():
		var h: Dictionary = heroes[i]
		var y := 44.0 + i * 58.0
		h["lbl_nombre"] = _etiqueta(h["nombre"], 30, Color.WHITE)
		h["lbl_nombre"].position = Vector2(34, y)
		h["lbl_pv"] = _etiqueta("", 30, Color.WHITE)
		h["lbl_pv"].position = Vector2(300, y)
		h["lbl_pm"] = _etiqueta("", 30, Color.WHITE)
		h["lbl_pm"].position = Vector2(450, y)
		h["barra"] = _barra(Vector2(140, 16), Color(1.0, 0.86, 0.25))
		h["barra"].position = Vector2(585, y + 14)
		for n in ["lbl_nombre", "lbl_pv", "lbl_pm", "barra"]:
			vg.add_child(h[n])

	# cursores con forma de mano
	mano = _cursor(false)
	mano_obj = _cursor(true)


func _ventana(pos: Vector2, tam: Vector2) -> Control:
	var raiz := Control.new()
	raiz.position = pos
	raiz.size = tam
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo := TextureRect.new()
	fondo.texture = ventana_tex
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.position = Vector2(3, 3)
	fondo.size = tam - Vector2(6, 6)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(fondo)
	var marco := Panel.new()
	marco.size = tam
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0)
	e.border_color = Color(0.92, 0.94, 1.0)
	e.set_border_width_all(3)
	e.set_corner_radius_all(8)
	marco.add_theme_stylebox_override("panel", e)
	raiz.add_child(marco)
	capa.add_child(raiz)
	return raiz


func _etiqueta(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.1))
	l.add_theme_constant_override("outline_size", 5)
	return l


func _barra(tam: Vector2, color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = tam
	b.size = tam
	b.show_percentage = false
	b.max_value = 100.0
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = color
	relleno.set_corner_radius_all(3)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.05, 0.05, 0.15, 0.85)
	fondo.border_color = Color(0.85, 0.88, 1.0, 0.8)
	fondo.set_border_width_all(1)
	fondo.set_corner_radius_all(3)
	b.add_theme_stylebox_override("fill", relleno)
	b.add_theme_stylebox_override("background", fondo)
	return b


func _cursor(hacia_abajo: bool) -> Control:
	var c := Control.new()
	c.size = Vector2(36, 24)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.visible = false
	c.draw.connect(_dibujar_cursor.bind(c))
	if hacia_abajo:
		c.pivot_offset = Vector2(18, 12)
		c.rotation_degrees = 90.0
	capa.add_child(c)
	return c


func _dibujar_cursor(c: Control) -> void:
	var pts := PackedVector2Array([Vector2(0, 7), Vector2(18, 7), Vector2(18, 0), Vector2(34, 12),
		Vector2(18, 24), Vector2(18, 17), Vector2(0, 17)])
	c.draw_colored_polygon(pts, Color.WHITE)
	pts.append(pts[0])
	c.draw_polyline(pts, Color(0.1, 0.1, 0.2), 2.0)


func _crear_fondo() -> void:
	if ResourceLoader.exists("res://fondo.png"):
		var fondo := TextureRect.new()
		fondo.texture = load("res://fondo.png")
		fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fondo.stretch_mode = TextureRect.STRETCH_SCALE
		fondo.size = Vector2(1280, 720)
		fondo.z_index = -100
		capa.add_child(fondo)
	else:
		var plano := ColorRect.new()
		plano.color = Color(0.08, 0.08, 0.12)
		plano.size = Vector2(1280, 720)
		plano.z_index = -100
		capa.add_child(plano)


func _crear_vida_enemigo(e: Dictionary) -> void:
	var l := _etiqueta("", 20, Color.WHITE)
	l.position = e["pos"] + Vector2(48, -8)
	capa.add_child(l)
	var b := _barra(Vector2(160, 10), Color(0.9, 0.25, 0.2))
	b.position = e["pos"] + Vector2(48, 22)
	capa.add_child(b)
	e["lbl_hp"] = l
	e["barra_hp"] = b


# ================================================================= personajes articulados

func _crear_rig(f: Dictionary) -> void:
	var m: Dictionary = MODELOS[f["modelo"]]
	var raiz := Node2D.new()
	var base: Vector2 = f["pos"]
	var esc: float = m.get("esc", ESC)
	if f["hero"]:
		raiz.scale = Vector2(esc, esc)
	else:
		raiz.scale = Vector2(-esc, esc)
		base += Vector2(CANVAS.x * ESC, 0)
	raiz.position = base
	capa.add_child(raiz)
	if m.get("tipo", "") == "frames":
		_crear_rig_frames(f, m, raiz, base, esc)
		return

	var cuerpo := Node2D.new()
	cuerpo.position = m["cadera"]
	var nodos := {"root": raiz, "cuerpo": cuerpo}
	var pivotes := {"root": Vector2.ZERO, "cuerpo": m["cadera"]}
	var partes := {}
	var cuerpo_puesto := false
	for d in m["partes"]:
		if d["padre"] == "cuerpo" and not cuerpo_puesto:
			raiz.add_child(cuerpo)
			cuerpo_puesto = true
		var s := Sprite2D.new()
		if ResourceLoader.exists(d["r"]):
			s.texture = load(d["r"])
		s.centered = false
		s.offset = -d["p"]
		s.position = d["p"] - pivotes[d["padre"]]
		s.show_behind_parent = d["detras"]
		nodos[d["padre"]].add_child(s)
		nodos[d["n"]] = s
		pivotes[d["n"]] = d["p"]
		partes[d["n"]] = s

	f["esc"] = esc
	f["rig"] = raiz
	f["rig_base"] = base
	f["cuerpo"] = cuerpo
	f["partes"] = partes
	f["pivotes"] = pivotes
	f["animando"] = false
	f["fase"] = randf() * 6.28
	f["quemadura"] = 0
	f["llama"] = null
	f["pose"] = "ini"
	f["cab_cerrada"] = null
	if m.has("cerrada") and ResourceLoader.exists(m["cerrada"]):
		f["cab_abierta"] = partes["cabeza"].texture
		f["cab_cerrada"] = load(m["cerrada"])
	var a: Dictionary = ANIM[f["modelo"]]
	if a.has("tex"):
		var tx := {}
		for k in a["tex"]:
			if ResourceLoader.exists(a["tex"][k]):
				tx[k] = load(a["tex"][k])
		f["tex"] = tx
	if a.has("caras"):
		var cs := {}
		for k in a["caras"]:
			if ResourceLoader.exists(a["caras"][k]):
				cs[k] = load(a["caras"][k])
		f["caras"] = cs
		_cara_reposo(f)
	if a.has("poses"):
		_fijar_pose(f, a["poses"]["ini"])


# Personaje animado por fotogramas (sprite completo) con la espada como pieza aparte.
func _crear_rig_frames(f: Dictionary, m: Dictionary, raiz: Node2D, base: Vector2, esc: float) -> void:
	var cuerpo := Node2D.new()
	cuerpo.position = m["cadera"]
	raiz.add_child(cuerpo)
	var espada := Sprite2D.new()                 # va detrás del cuerpo: la mano tapa la empuñadura
	if ResourceLoader.exists(m["espada"]):
		espada.texture = load(m["espada"])
	espada.centered = false
	espada.offset = -m["piv"]
	cuerpo.add_child(espada)
	var anim := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", m["fps"])
	sf.set_animation_loop("default", true)
	for r in m["frames"]:
		if ResourceLoader.exists(r):
			sf.add_frame("default", load(r))
	anim.sprite_frames = sf
	anim.centered = false
	anim.position = -m["cadera"]
	cuerpo.add_child(anim)
	anim.play("default")
	var nada := Node2D.new()
	cuerpo.add_child(nada)
	f["esc"] = esc
	f["rig"] = raiz
	f["rig_base"] = base
	f["cuerpo"] = cuerpo
	f["partes"] = {"arma": espada, "anim": anim, "brazo_a": nada}
	f["pivotes"] = {"arma": m["piv"]}
	f["animando"] = false
	f["fase"] = randf() * 6.28
	f["quemadura"] = 0
	f["llama"] = null
	f["pose"] = "ini"
	f["cab_cerrada"] = null
	_seguir_fotograma(f)
	anim.frame_changed.connect(_seguir_fotograma.bind(f))


# La espada sigue a la mano en cada fotograma del reposo.
func _seguir_fotograma(f: Dictionary) -> void:
	var m: Dictionary = MODELOS[f["modelo"]]
	var i: int = f["partes"]["anim"].frame
	var e: Sprite2D = f["partes"]["arma"]
	e.position = m["agarres"][i] - m["cadera"]
	if not f["animando"]:
		e.rotation_degrees = m["angs"][i]


func _ang_reposo(f: Dictionary) -> float:
	var m: Dictionary = MODELOS[f["modelo"]]
	return m["angs"][f["partes"]["anim"].frame]


func _es_frames(f: Dictionary) -> bool:
	return MODELOS[f["modelo"]].get("tipo", "") == "frames"


const HUESOS := {"f": "brazo_f", "codo_f": "antebrazo_f", "arma": "arma", "a": "brazo_a", "codo_a": "antebrazo_a"}


func _fijar_pose(o: Dictionary, v: Dictionary) -> void:
	var p: Dictionary = o["partes"]
	for k in HUESOS:
		if v.has(k) and p.has(HUESOS[k]):
			p[HUESOS[k]].rotation_degrees = v[k]
	o["cuerpo"].rotation_degrees = v.get("lean", 0.0)
	if p.has("arma"):
		p["arma"].z_index = int(v.get("z", 0))
	_manos(o, v)


# Cambia el dibujo de las manos según la pose: una mano o las dos en la empuñadura.
func _manos(o: Dictionary, v: Dictionary) -> void:
	if not o.has("tex"):
		return
	var p: Dictionary = o["partes"]
	var tx: Dictionary = o["tex"]
	var e: String = "esp_" + str(v.get("esp", "g"))
	if tx.has(e) and p.has("arma"):
		p["arma"].texture = tx[e]
	var m: String = "ma_%d" % int(v.get("ma", 1))
	if tx.has(m) and p.has("antebrazo_a"):
		p["antebrazo_a"].texture = tx[m]


# Mueve todas las articulaciones hacia una pose, siempre por el camino más corto.
func _tween_pose(o: Dictionary, v: Dictionary, dur: float, golpe := false) -> Tween:
	var p: Dictionary = o["partes"]
	if p.has("arma"):
		p["arma"].z_index = int(v.get("z", 0))
	var dos_manos: bool = int(v.get("ma", 1)) == 2
	if not dos_manos:
		_manos(o, v)
	var t := create_tween().set_parallel(true)
	for k in HUESOS:
		if v.has(k) and p.has(HUESOS[k]):
			var actual: float = p[HUESOS[k]].rotation_degrees
			var destino: float = actual + wrapf(v[k] - actual, -180.0, 180.0)
			var tw := t.tween_property(p[HUESOS[k]], "rotation_degrees", destino, dur)
			if golpe:
				tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			else:
				tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(o["cuerpo"], "rotation_degrees", v.get("lean", 0.0), dur)
	if dos_manos:
		t.finished.connect(_manos.bind(o, v))   # la segunda mano se cierra al llegar a la empuñadura
	return t


func _pose_a(o: Dictionary) -> float:
	var a: Dictionary = ANIM[o["modelo"]]
	if a.has("poses"):
		return a["poses"][o["pose"]].get("a", 0.0)
	return 0.0


# ================================================================= bucle ATB

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for f in heroes + enemigos:
		if f["hp"] > 0:
			f["cuerpo"].scale = Vector2(1.0, 1.0 + 0.012 * sin(t * 1.9 + f["fase"]))
			if not f["animando"]:
				f["partes"]["brazo_a"].rotation_degrees = _pose_a(f) + sin(t * 1.6 + f["fase"] + 1.0) * 2.0
				if not ANIM[f["modelo"]].has("poses"):
					f["cuerpo"].rotation_degrees = sin(t * 1.3 + f["fase"]) * 0.8
	if mano_obj.visible and objetivo_apuntado != null:
		mano_obj.position = objetivo_apuntado["pos"] + Vector2(110, -48 + sin(t * 7.0) * 5.0)
	if estado == "fin":
		return
	for f in heroes + enemigos:
		if f["hp"] > 0 and f["atb"] < ATB_MAX:
			f["atb"] = min(ATB_MAX, f["atb"] + f["vel"] * delta)
			if f["atb"] >= ATB_MAX:
				cola.append(f)
	_siguiente_turno()
	_actualizar()


func _siguiente_turno() -> void:
	if estado != "esperando" or cola.is_empty():
		return
	var f = cola.pop_front()
	if f["hp"] <= 0:
		return
	if f["hero"]:
		actor = f
		_mostrar_menu()
	else:
		estado = "enemigo"
		_turno_enemigo(f)


func _turno_enemigo(f: Dictionary) -> void:
	if f["quemadura"] > 0:
		await _tic_quemadura(f)
		if f["hp"] <= 0:
			f["atb"] = 0.0
			if not _comprobar_fin():
				estado = "esperando"
			return
	var vivos := heroes.filter(func(h): return h["hp"] > 0)
	var objetivo = vivos.pick_random()
	var dano: int = f["atk"] + randi_range(-2, 3)
	registro.text = "%s ataca a %s" % [f["nombre"], objetivo["nombre"]]
	await _animar_golpe(f, objetivo, dano, "")
	f["atb"] = 0.0
	await get_tree().create_timer(0.3).timeout
	if not _comprobar_fin():
		estado = "esperando"


# ================================================================= menús del jugador

func _llenar_lista(items: Array) -> void:
	for hijo in lista.get_children():
		hijo.queue_free()
	var primero: Button = null
	var primero_extra = null
	for it in items:
		var b := Button.new()
		b.text = it[0]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(390, 48)
		b.add_theme_font_size_override("font_size", 28)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color(1, 0.92, 0.5))
		b.add_theme_color_override("font_disabled_color", Color(0.55, 0.58, 0.75))
		b.disabled = it[2]
		b.pressed.connect(it[1])
		var extra = it[3] if it.size() > 3 else null
		b.mouse_entered.connect(func(): _apuntar(b, extra))
		b.focus_entered.connect(func(): _apuntar(b, extra))
		lista.add_child(b)
		if primero == null and not b.disabled:
			primero = b
			primero_extra = extra
	lista.visible = true
	await get_tree().process_frame
	if primero != null and is_instance_valid(primero):
		_apuntar(primero, primero_extra)


func _apuntar(b: Button, enemigo) -> void:
	if not is_instance_valid(b):
		return
	mano.visible = true
	mano.position = b.global_position + Vector2(-40, b.size.y * 0.5 - 12)
	objetivo_apuntado = enemigo
	mano_obj.visible = enemigo != null


func _ocultar_menu() -> void:
	lista.visible = false
	mano.visible = false
	mano_obj.visible = false
	objetivo_apuntado = null


func _mostrar_menu() -> void:
	estado = "menu"
	registro.text = "Turno de %s" % actor["nombre"]
	var coste_min := 999
	for k in MAGIAS:
		coste_min = min(coste_min, MAGIAS[k]["coste"])
	_llenar_lista([
		["Atacar", func(): _menu_objetivo("atacar", ""), false],
		["Magia", _menu_magia, actor["mp"] < coste_min],
		["Poción   x%d" % pociones, _usar_pocion, pociones <= 0],
	])


func _menu_magia() -> void:
	estado = "magia"
	var items: Array = []
	for k in MAGIAS:
		var nombre: String = k
		var coste: int = MAGIAS[k]["coste"]
		items.append(["%s   %d PM" % [nombre, coste], func(): _menu_objetivo("magia", nombre), actor["mp"] < coste])
	items.append(["Atrás", _mostrar_menu, false])
	_llenar_lista(items)


func _menu_objetivo(a: String, magia: String) -> void:
	accion = a
	magia_sel = magia
	estado = "objetivo"
	var items: Array = []
	for e in enemigos:
		if e["hp"] > 0:
			var enemigo = e
			items.append([e["nombre"], func(): _aplicar(enemigo), false, enemigo])
	items.append(["Atrás", _mostrar_menu, false])
	_llenar_lista(items)


func _aplicar(objetivo: Dictionary) -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	if accion == "magia":
		var mg: Dictionary = MAGIAS[magia_sel]
		quien["mp"] -= mg["coste"]
		registro.text = "%s lanza %s" % [quien["nombre"], magia_sel]
		await _animar_golpe(quien, objetivo, mg["dano"], magia_sel)
	else:
		registro.text = "%s ataca a %s" % [quien["nombre"], objetivo["nombre"]]
		await _animar_golpe(quien, objetivo, quien["atk"] + randi_range(-2, 3), "")
	_terminar_turno()


func _usar_pocion() -> void:
	if pociones <= 0:
		return
	_ocultar_menu()
	pociones -= 1
	estado = "accion"
	var quien = actor
	quien["hp"] = min(quien["hp_max"], quien["hp"] + 50)
	registro.text = "%s usa una Poción (+50 PV)" % quien["nombre"]
	quien["rig"].modulate = Color(0.6, 1.5, 0.7)
	_numero_flotante(quien, "+50", Color(0.5, 1.0, 0.55))
	await get_tree().create_timer(0.5).timeout
	quien["rig"].modulate = Color(1, 1, 1)
	_cara_reposo(quien)
	_terminar_turno()


func _terminar_turno() -> void:
	estado = "accion"
	actor["atb"] = 0.0
	actor = null
	_actualizar()
	await get_tree().create_timer(0.3).timeout
	if not _comprobar_fin():
		estado = "esperando"


# ================================================================= animaciones

func _animar_golpe(origen: Dictionary, objetivo: Dictionary, dano: int, magia: String) -> void:
	var impacto: Callable = func():
		objetivo["hp"] = max(0, objetivo["hp"] - dano)
		_golpe_visual(objetivo, dano, magia)
	if magia != "":
		await _anim_magia(origen, objetivo, magia, impacto)
	elif ANIM[origen["modelo"]].has("poses"):
		await _anim_fisico_poses(origen, objetivo, impacto)
	elif _es_frames(origen):
		await _anim_fisico_frames(origen, objetivo, impacto)
	else:
		await _anim_fisico(origen, objetivo, impacto)


# Kael: levanta el espadón con las dos manos y lo baja en vertical.
func _anim_fisico_poses(o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var a: Dictionary = ANIM[o["modelo"]]
	var ps: Dictionary = a["poses"]
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var dx: float = obj["pos"].x - o["pos"].x + a["distancia"]
	var dy: float = (obj["pos"].y - o["pos"].y) * 0.8
	o["animando"] = true
	rig.z_index = 5
	_cara(o, "grito")
	var t1 := _tween_pose(o, ps["alto"], 0.45)
	t1.tween_property(rig, "position", base + Vector2(dx, dy), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	var t2 := _tween_pose(o, ps["golpe"], 0.16, true)
	await t2.finished
	impacto.call()
	await get_tree().create_timer(0.35).timeout
	var t3 := _tween_pose(o, ps["guardia"], 0.4)
	t3.tween_property(rig, "position", base, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	o["pose"] = "guardia"
	rig.z_index = 0
	o["animando"] = false
	_cara_reposo(o)


# Aventurero: se acerca, levanta la espada y da un tajo de arriba abajo por delante.
func _anim_fisico_frames(o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var a: Dictionary = ANIM[o["modelo"]]
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var e: Sprite2D = o["partes"]["arma"]
	var dx: float = obj["pos"].x - o["pos"].x + a["distancia"]
	var dy: float = (obj["pos"].y - o["pos"].y) * 0.8
	o["animando"] = true
	rig.z_index = 5
	var t1 := create_tween().set_parallel(true)
	t1.tween_property(rig, "position", base + Vector2(dx, dy), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(e, "rotation_degrees", a["prep"], 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t1.tween_property(o["cuerpo"], "rotation_degrees", a["lean_prep"], 0.45)
	await t1.finished
	var t2 := create_tween().set_parallel(true)
	t2.tween_property(e, "rotation_degrees", a["golpe"], 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t2.tween_property(o["cuerpo"], "rotation_degrees", a["lean_golpe"], 0.15)
	await t2.finished
	impacto.call()
	await get_tree().create_timer(0.3).timeout
	var t3 := create_tween().set_parallel(true)
	t3.tween_property(e, "rotation_degrees", _ang_reposo(o), 0.35)
	t3.tween_property(o["cuerpo"], "rotation_degrees", 0.0, 0.35)
	t3.tween_property(rig, "position", base, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	rig.z_index = 0
	o["animando"] = false


# Resto de personajes: avanza, prepara el golpe, golpea y vuelve.
func _anim_fisico(o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var p: Dictionary = o["partes"]
	var a: Dictionary = ANIM[o["modelo"]]
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var cuerpo: Node2D = o["cuerpo"]
	var heroe: bool = o["hero"]
	var dist: float = a["distancia"]
	var dx: float = obj["pos"].x - o["pos"].x + (dist if heroe else -dist)
	var dy: float = (obj["pos"].y - o["pos"].y) * 0.8
	o["animando"] = true
	rig.z_index = 5
	var t1 := create_tween().set_parallel(true)
	t1.tween_property(rig, "position", base + Vector2(dx, dy), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(p["brazo_f"], "rotation_degrees", a["prep"], 0.45)
	if p.has("arma"):
		t1.tween_property(p["arma"], "rotation_degrees", a["arma_prep"], 0.45)
	if a.has("a_prep"):
		t1.tween_property(p["brazo_a"], "rotation_degrees", a["a_prep"], 0.45)
	t1.tween_property(cuerpo, "rotation_degrees", a["lean_prep"], 0.45)
	await t1.finished
	var t2 := create_tween().set_parallel(true)
	t2.tween_property(p["brazo_f"], "rotation_degrees", a["golpe"], 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if p.has("arma"):
		t2.tween_property(p["arma"], "rotation_degrees", a["arma_golpe"], 0.17)
	if a.has("a_golpe"):
		t2.tween_property(p["brazo_a"], "rotation_degrees", a["a_golpe"], 0.17)
	t2.tween_property(cuerpo, "rotation_degrees", a["lean_golpe"], 0.17)
	await t2.finished
	impacto.call()
	await get_tree().create_timer(0.35).timeout
	var t3 := create_tween().set_parallel(true)
	t3.tween_property(p["brazo_f"], "rotation_degrees", a["ret"], 0.35)
	if p.has("arma"):
		t3.tween_property(p["arma"], "rotation_degrees", 0.0, 0.35)
	if a.has("a_ret"):
		t3.tween_property(p["brazo_a"], "rotation_degrees", a["a_ret"], 0.35)
	t3.tween_property(cuerpo, "rotation_degrees", 0.0, 0.35)
	t3.tween_property(rig, "position", base, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	p["brazo_f"].rotation_degrees = 0.0
	p["brazo_a"].rotation_degrees = 0.0
	rig.z_index = 0
	o["animando"] = false


# Magia: cierra los ojos, levanta el arma, carga luz en la punta y envuelve al enemigo.
func _anim_magia(o: Dictionary, obj: Dictionary, magia: String, impacto: Callable) -> void:
	var p: Dictionary = o["partes"]
	var a: Dictionary = ANIM[o["modelo"]]
	var color: Color = MAGIAS[magia]["color"]
	o["animando"] = true
	_set_ojos(o, true)
	var t1: Tween
	if a.has("poses"):
		t1 = _tween_pose(o, a["poses"]["magia"], 0.6)
	elif _es_frames(o):
		t1 = create_tween().set_parallel(true)
		t1.tween_property(p["arma"], "rotation_degrees", a["m_arma"], 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t1.tween_property(o["cuerpo"], "rotation_degrees", a["m_lean"], 0.5)
	else:
		t1 = create_tween().set_parallel(true)
		t1.tween_property(p["brazo_f"], "rotation_degrees", a["m_brazo"], 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t1.tween_property(p["arma"], "rotation_degrees", a["m_arma"], 0.6)
		t1.tween_property(p["brazo_a"], "rotation_degrees", a["m_brazo_a"], 0.6)
		t1.tween_property(o["cuerpo"], "rotation_degrees", a["m_lean"], 0.6)
	await t1.finished

	# luz que se concentra en la punta del arma
	var k: float = ESC / float(o["esc"])
	var halo := _brillo(color)
	halo.position = a["punta"] - o["pivotes"]["arma"]
	halo.scale = Vector2.ZERO
	p["arma"].add_child(halo)
	var t2 := create_tween()
	t2.tween_property(halo, "scale", Vector2(0.9, 0.9) * k, 0.5)
	t2.tween_property(halo, "scale", Vector2(0.6, 0.6) * k, 0.15)
	await t2.finished

	# la luz sale disparada hacia el enemigo
	var bola := _brillo(color)
	bola.position = halo.global_position
	bola.scale = Vector2(0.5, 0.5)
	capa.add_child(bola)
	halo.queue_free()
	var t3 := create_tween()
	t3.tween_property(bola, "position", _centro(obj), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t3.finished
	bola.queue_free()
	impacto.call()
	await get_tree().create_timer(0.8).timeout

	# volver a la guardia y abrir los ojos
	var t4: Tween
	if a.has("poses"):
		t4 = _tween_pose(o, a["poses"]["guardia"], 0.45)
		o["pose"] = "guardia"
	elif _es_frames(o):
		t4 = create_tween().set_parallel(true)
		t4.tween_property(p["arma"], "rotation_degrees", _ang_reposo(o), 0.4)
		t4.tween_property(o["cuerpo"], "rotation_degrees", 0.0, 0.4)
	else:
		t4 = create_tween().set_parallel(true)
		t4.tween_property(p["brazo_f"], "rotation_degrees", 0.0, 0.4)
		t4.tween_property(p["arma"], "rotation_degrees", 0.0, 0.4)
		t4.tween_property(p["brazo_a"], "rotation_degrees", 0.0, 0.4)
		t4.tween_property(o["cuerpo"], "rotation_degrees", 0.0, 0.4)
	await t4.finished
	_set_ojos(o, false)
	o["animando"] = false


# Expresiones de la cara (solo personajes que tienen caras).
func _cara(f: Dictionary, nombre: String) -> void:
	if f.has("caras") and f["caras"].has(nombre):
		f["partes"]["cabeza"].texture = f["caras"][nombre]


func _cara_reposo(f: Dictionary) -> void:
	if not f.has("caras"):
		return
	if f["hp"] <= 0:
		_cara(f, "cerrados")
	elif f["hp"] < f["hp_max"] * 0.3:
		_cara(f, "cansado")
	else:
		_cara(f, "normal")


func _set_ojos(f: Dictionary, cerrados: bool) -> void:
	if f.has("caras"):
		if cerrados:
			_cara(f, "cerrados")
		else:
			_cara_reposo(f)
		return
	if f["cab_cerrada"] != null:
		f["partes"]["cabeza"].texture = f["cab_cerrada"] if cerrados else f["cab_abierta"]


func _centro(f: Dictionary) -> Vector2:
	return f["pos"] + Vector2(CANVAS.x * ESC * 0.5, CANVAS.y * ESC * 0.45)


func _brillo(color: Color) -> Sprite2D:
	var g := Sprite2D.new()
	g.texture = glow_tex
	g.material = mat_aditivo
	g.modulate = color
	return g


# ================================================================= efectos

func _golpe_visual(objetivo: Dictionary, dano: int, magia: String) -> void:
	var rig: Node2D = objetivo["rig"]
	var base: Vector2 = objetivo["rig_base"]
	var centro := _centro(objetivo)
	match magia:
		"Agua":
			_efecto_agua(centro)
			rig.modulate = Color(0.6, 0.85, 1.6)
			_numero_flotante(objetivo, str(dano), Color(0.6, 0.85, 1.0))
		"Fuego":
			_efecto_fuego(centro)
			rig.modulate = Color(1.7, 0.7, 0.3)
			_numero_flotante(objetivo, str(dano), Color(1.0, 0.75, 0.3))
			if objetivo["hp"] > 0:
				objetivo["quemadura"] = RONDAS_QUEMADURA
				_encender_llama(objetivo)
		_:
			_destello(centro, Color(1.0, 0.95, 0.85), 1.0)
			rig.modulate = Color(1.6, 0.3, 0.3)
			_numero_flotante(objetivo, str(dano), Color.WHITE)
	_actualizar()
	if objetivo["hp"] > 0 and not objetivo["animando"]:
		_cara(objetivo, "dolor")
	if objetivo["animando"]:
		_restablecer_color(objetivo)
		return
	var t := create_tween()
	t.tween_property(rig, "position", base + Vector2(14, 0), 0.04)
	t.tween_property(rig, "position", base - Vector2(14, 0), 0.04)
	t.tween_property(rig, "position", base + Vector2(7, 0), 0.04)
	t.tween_property(rig, "position", base, 0.04)
	t.tween_interval(0.25)
	t.tween_callback(func(): _restablecer_color(objetivo))


func _particulas(pos: Vector2, c1: Color, c2: Color, cantidad: int, vida: float, vel: Vector2,
		radio: float, direccion: Vector2, apertura: float, gravedad: Vector2, escala: float, continuo := false) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = glow_tex
	p.material = mat_aditivo
	p.position = pos
	p.amount = cantidad
	p.lifetime = vida
	p.one_shot = not continuo
	p.explosiveness = 0.0 if continuo else 0.55
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radio
	p.direction = direccion
	p.spread = apertura
	p.gravity = gravedad
	p.initial_velocity_min = vel.x
	p.initial_velocity_max = vel.y
	p.scale_amount_min = escala * 0.5
	p.scale_amount_max = escala
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([c1, c2])
	p.color_ramp = g
	capa.add_child(p)
	p.emitting = true
	if not continuo:
		get_tree().create_timer(vida + 0.6).timeout.connect(p.queue_free)
	return p


# Agua: una burbuja envuelve al enemigo y las gotas giran a su alrededor.
func _efecto_agua(centro: Vector2) -> void:
	var burbuja := _brillo(Color(0.3, 0.6, 1.0, 0.0))
	burbuja.position = centro
	burbuja.scale = Vector2(0.3, 0.3)
	capa.add_child(burbuja)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(burbuja, "scale", Vector2(1.7, 2.0), 0.25)
	t.tween_property(burbuja, "modulate:a", 0.8, 0.25)
	t.chain().tween_interval(0.45)
	t.chain().tween_property(burbuja, "modulate:a", 0.0, 0.5)
	t.chain().tween_callback(burbuja.queue_free)
	_particulas(centro, Color(0.75, 0.9, 1.0, 1.0), Color(0.2, 0.5, 1.0, 0.0), 70, 0.9, Vector2(60, 160),
		90.0, Vector2(0, -1), 180.0, Vector2(0, 220), 0.12)
	_particulas(centro + Vector2(0, 80), Color(0.6, 0.85, 1.0, 1.0), Color(0.1, 0.3, 0.9, 0.0), 40, 0.7, Vector2(200, 380),
		50.0, Vector2(0, -1), 30.0, Vector2(0, 600), 0.1)


# Fuego: una llamarada envuelve al enemigo.
func _efecto_fuego(centro: Vector2) -> void:
	_destello(centro, Color(1.0, 0.5, 0.15), 2.0)
	_particulas(centro + Vector2(0, 90), Color(1.0, 0.9, 0.4, 1.0), Color(0.8, 0.1, 0.0, 0.0), 120, 0.9, Vector2(140, 320),
		80.0, Vector2(0, -1), 30.0, Vector2(0, -180), 0.35)
	_particulas(centro, Color(1.0, 0.6, 0.2, 1.0), Color(0.5, 0.05, 0.0, 0.0), 40, 0.6, Vector2(80, 220),
		60.0, Vector2(0, -1), 180.0, Vector2(0, -100), 0.2)


# Quemadura: una llama pequeña permanece encima del enemigo mientras dure.
func _encender_llama(f: Dictionary) -> void:
	if f["llama"] != null and is_instance_valid(f["llama"]):
		return
	f["llama"] = _particulas(_centro(f) + Vector2(0, -40), Color(1.0, 0.8, 0.3, 0.9), Color(0.8, 0.15, 0.0, 0.0), 16, 0.6,
		Vector2(30, 70), 18.0, Vector2(0, -1), 20.0, Vector2(0, -60), 0.12, true)


func _apagar_llama(f: Dictionary) -> void:
	if f["llama"] != null and is_instance_valid(f["llama"]):
		var ll: CPUParticles2D = f["llama"]
		ll.emitting = false
		get_tree().create_timer(1.0).timeout.connect(ll.queue_free)
	f["llama"] = null


func _tic_quemadura(f: Dictionary) -> void:
	registro.text = "%s sufre quemaduras" % f["nombre"]
	_particulas(_centro(f) + Vector2(0, 40), Color(1.0, 0.85, 0.35, 1.0), Color(0.8, 0.1, 0.0, 0.0), 40, 0.6,
		Vector2(90, 200), 50.0, Vector2(0, -1), 25.0, Vector2(0, -120), 0.2)
	f["hp"] = max(0, f["hp"] - DANO_QUEMADURA)
	f["quemadura"] -= 1
	f["rig"].modulate = Color(1.6, 0.7, 0.3)
	_numero_flotante(f, str(DANO_QUEMADURA), Color(1.0, 0.6, 0.2))
	_actualizar()
	await get_tree().create_timer(0.5).timeout
	if f["quemadura"] <= 0 or f["hp"] <= 0:
		_apagar_llama(f)
	_restablecer_color(f)
	await get_tree().create_timer(0.3).timeout


func _restablecer_color(f: Dictionary) -> void:
	var rig: Node2D = f["rig"]
	if not f["animando"]:
		_cara_reposo(f)
	if f["hp"] > 0:
		rig.modulate = Color(1, 1, 1)
	elif f["hero"]:
		rig.modulate = Color(0.35, 0.35, 0.4)
		f["cuerpo"].rotation_degrees = 25.0
		rig.position = f["rig_base"] + Vector2(0, 30)
	else:
		_apagar_llama(f)
		var t := create_tween()
		t.tween_property(rig, "modulate:a", 0.0, 0.5)


func _destello(centro: Vector2, color: Color, tam: float) -> void:
	var g := _brillo(color)
	g.position = centro
	g.scale = Vector2(0.2, 0.2) * tam
	capa.add_child(g)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(g, "scale", Vector2(1.5, 1.5) * tam, 0.35)
	t.tween_property(g, "modulate:a", 0.0, 0.35)
	t.chain().tween_callback(g.queue_free)


func _numero_flotante(f: Dictionary, texto: String, color: Color) -> void:
	var l := _etiqueta(texto, 38, color)
	l.add_theme_constant_override("outline_size", 8)
	l.position = f["pos"] + Vector2(100, 60)
	capa.add_child(l)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 60.0, 0.9)
	t.tween_property(l, "modulate:a", 0.0, 0.9)
	t.chain().tween_callback(l.queue_free)


# ================================================================= fin y textos

func _comprobar_fin() -> bool:
	var ganan := enemigos.all(func(e): return e["hp"] <= 0)
	var pierden := heroes.all(func(h): return h["hp"] <= 0)
	if ganan or pierden:
		estado = "fin"
		_ocultar_menu()
		registro.text = "¡Victoria!" if ganan else "Derrota..."
		if ganan:
			for h in heroes:
				if h["hp"] > 0:
					_cara(h, "sonrisa")
		_bajar_musica()
		_volver_al_mapa()
		return true
	return false


# Si el combate empezó en el mapa, tras un par de segundos se vuelve a él.
func _volver_al_mapa() -> void:
	if not Engine.get_meta("desde_mapa", false):
		return
	await get_tree().create_timer(2.0).timeout
	Engine.set_meta("desde_mapa", false)
	get_tree().change_scene_to_file("res://mapa.tscn")


func _actualizar() -> void:
	for h in heroes:
		var vivo: bool = h["hp"] > 0
		h["lbl_pv"].text = "%d/%d" % [h["hp"], h["hp_max"]]
		h["lbl_pm"].text = "%d/%d" % [h["mp"], h["mp_max"]]
		h["barra"].value = h["atb"]
		var c_nombre := Color.WHITE
		if not vivo:
			c_nombre = Color(0.5, 0.5, 0.6)
		elif actor != null and h == actor:
			c_nombre = Color(1, 0.88, 0.3)
		h["lbl_nombre"].add_theme_color_override("font_color", c_nombre)
		var c_pv := Color.WHITE
		if not vivo:
			c_pv = Color(0.9, 0.3, 0.3)
		elif h["hp"] < h["hp_max"] * 0.3:
			c_pv = Color(1, 0.85, 0.3)
		h["lbl_pv"].add_theme_color_override("font_color", c_pv)
	for e in enemigos:
		var vivo: bool = e["hp"] > 0
		e["lbl_hp"].visible = vivo
		e["barra_hp"].visible = vivo
		e["lbl_hp"].text = "PV %d/%d" % [e["hp"], e["hp_max"]]
		e["barra_hp"].value = 100.0 * e["hp"] / e["hp_max"]
