extends "res://isla.gd"
# Arboleda Mítica, tramo «La escalera de la Hospedería» (V12, 16/11, EXPERIMENTAL; docs/v12/SUNKEN_ARBOLEDA_PLAN.md §3
# y docs/v12/ARBOLEDA_HOSPEDERIA.md). La MISMA isla 2D pintada (isla.gd, que no se toca: se hereda) con:
#   - la escalera de piedra de la derecha del cristal unida a la escalera de madera y la terraza de la casa de la cúpula
#     verde (tramo/paso_extra.png: isla_paso.png no cambia);
#   - la puerta de la terraza, que lleva a la Hospedería del Peregrino [P] (hospederia.gd: interior pintado con la misma
#     técnica, en la misma escena, lejos de la isla, con fundido; al salir se vuelve a la terraza);
#   - «Una flor para Lumi» [P] (lumi_flor.gd) y la abuela Nívea [P] en la plaza;
#   - atrezo de la terraza (piezas renderizadas con render_isla.gd y la misma luz, tapadas por lo que la isla tenga
#     delante), «sondas» 2D (la luz del suelo tiñe a Kael y a los vecinos) y una sombra larga coherente con el sol;
#   - pasos de madera dentro.
# SOLO desde el banco de pruebas (Auditoría o editor): ninguna escena del juego la enlaza, ni el mapa ni el mapamundi;
# no se crea ninguna clave de partida (el hito isla_flor_lumi, solo en la partida aislada del banco) y pos_isla se usa
# como en la isla (guardar dentro deja la puerta de la terraza). Las APK sin banco no llevan la carpeta.

const DIR_TRAMO := "res://zonas3d/arboleda_tramo/"
const PUERTA_HOSPEDERIA := Vector2(2396, 2056)   # los pies de Kael en lo alto de la escalera de madera
const RADIO_PUERTA_H := 64.0
const CRISTAL := Vector2(1373, 1800)              # el cristal de la plaza (late despacio)
const ALTO_FIGURA := 112.0                         # px en pantalla de las figuras nuevas (los NPC antiguos: 120)
# Atrezo de la terraza (fuente/crear_terraza.py → render_isla.gd → preparar_tramo.gd): imagen, pies en la isla (en lo
# andable de la terraza, comprobado en la máscara), radio que no se atraviesa, si ondea (el lino) y su escala. El lino y
# el banco, en la cornisa de detrás del árbol (se asoma a las nubes); el farol, al pie de la escalera de madera. Las
# macetas, junto a la puerta pero FUERA del paso a la cornisa (el único: de la terraza sube en diagonal entre la pared
# y el árbol, y=2024-2048): en (2462, 2046) con radio 20 lo cerraban (revisión del 16/11; prueba_arboleda_tramo, BFS).
const PIEZAS := [
	{"imagen": "piezas/lino.png", "pies": Vector2(2672, 1990), "bloquea": 0.0, "ondea": true, "escala": 0.8},
	{"imagen": "piezas/banco.png", "pies": Vector2(2522, 1950), "bloquea": 26.0, "ondea": false, "escala": 0.9},
	{"imagen": "piezas/farol.png", "pies": Vector2(2298, 2158), "bloquea": 10.0, "ondea": false},
	{"imagen": "piezas/macetas.png", "pies": Vector2(2450, 2064), "bloquea": 16.0, "ondea": false},
	{"imagen": "piezas/cantaro.png", "pies": Vector2(2402, 2150), "bloquea": 16.0, "ondea": false},
]
const SHADER_PIEZA := """
shader_type canvas_item;
// Una pieza o figura nueva sobre un fondo pintado (la isla o el interior): lo que el fondo tiene DELANTE de ella (su
// tapa, más cerca que sus pies) la tapa. Es la misma prueba de profundidad que SHADER_TAPA, al revés.
uniform sampler2D tapa : filter_nearest;
uniform vec2 origen = vec2(0.0);
uniform vec2 tam_fondo = vec2(3072.0, 3348.0);
uniform float z_pieza;
uniform float ondea = 0.0;
varying vec2 mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec2 uv = UV;
	// el lino tendido: los paños ondean más abajo (lejos de la cuerda) y nada en los postes de los lados
	float w = ondea * smoothstep(0.08, 0.2, UV.x) * smoothstep(0.92, 0.8, UV.x) * clamp((UV.y - 0.25) / 0.6, 0.0, 1.0);
	uv.x += w * (sin(TIME * 1.7 + UV.y * 7.0 + UV.x * 4.0) * 0.010 + sin(TIME * 2.9 + UV.y * 13.0) * 0.004);
	float d = texture(tapa, (mundo - origen) / tam_fondo).r;
	if (d > z_pieza + 0.012) {
		discard;
	}
	COLOR = texture(TEXTURE, uv) * COLOR;
}
"""
var extra_img: Image
var luz_img: Image
var hosp
var flor
var dentro := false
var puerta_cerca := false
var accion_interior := ""
var en_transicion := false
var exterior: Array = []                  # lo que se oculta dentro (trozos de la isla, nubes, motas, brillos, vecinos)
var mats_piezas: Array = []
var piezas: Array = []                    # los Sprite2D del atrezo
var sombra_larga: Sprite2D
var lumi = null                           # [sprite, datos, frase] de Lumi en npcs


func _ready() -> void:
	var R = get_node_or_null("/root/Recursos")
	if R != null and not load("res://banco_pruebas.gd").permitido():
		R.cambiar_escena.call_deferred("res://isla.tscn")       # (fuera de Auditoría y del editor no existe)
		return
	flor = load(DIR_TRAMO + "lumi_flor.gd").new()
	extra_img = _tex(DIR_TRAMO + "tramo/paso_extra.png").get_image()
	luz_img = _tex(DIR_TRAMO + "tramo/luz_tramo.png").get_image()
	super()
	for c in get_children():
		if c is CanvasItem and c != mundo_y:
			exterior.append(c)
	for c in mundo_y.get_children():
		if c != jugador:
			exterior.append(c)
	_preparar_lumi()
	_crear_nivea()
	_crear_piezas()
	_crear_brillo_cristal()
	_crear_sombra_larga()
	hosp = load(DIR_TRAMO + "hospederia.gd").new()
	add_child(hosp)
	hosp.preparar(self)
	for n in npcs:
		n[0].modulate = _tinte(_luz_en(n[1]["pos"]))
	_tintar_kael()


# Kael pisa piedra fuera y madera dentro: se cambian los pasos de isla.gd (sonido.gd, pasos_2d) por los del tramo.
func _crear_jugador() -> void:
	super()
	for con in sprite.frame_changed.get_connections():
		sprite.frame_changed.disconnect(con["callable"])
	Sonido.pasos_2d(sprite, func(): return "madera" if dentro else "piedra")


# ================================================================= figuras y piezas

# Una figura nueva (Nívea, Yedra): su sprite si existe; si no, un respaldo provisional (y se avisa en la consola).
func figura(ruta: String) -> Texture2D:
	if ResourceLoader.exists(ruta):
		return _tex(ruta)
	push_warning("arboleda_tramo: falta %s (figura provisional)" % ruta)
	return load("res://personajes/npc/aldeana.png")


func escala_figura(tex: Texture2D) -> float:
	return 1.0 if tex.get_height() < 150 else ALTO_FIGURA / float(tex.get_height())   # (las nuevas ya salen a su altura)


func _preparar_lumi() -> void:
	for n in npcs:
		if n[1]["nombre"] == "Niña Lumi":
			var d: Dictionary = n[1].duplicate(true)
			d["canon"] = n[1]["frases"].duplicate()
			d["frases"] = flor.frases_lumi(d["canon"]) if not flor.entregada() else d["canon"] + [flor.DESPUES]
			n[1] = d
			lumi = n


func _crear_nivea() -> void:
	var d: Dictionary = flor.NIVEA.duplicate(true)
	var tex := figura(d["imagen"])
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	s.scale = Vector2.ONE * escala_figura(tex)
	s.position = d["pos"]
	mundo_y.add_child(s)
	var sombra := Sprite2D.new()
	sombra.texture = luz_tex
	sombra.modulate = Color(0.04, 0.07, 0.13, 0.4)
	sombra.scale = Vector2(0.45, 0.15) / s.scale
	sombra.show_behind_parent = true
	s.add_child(sombra)
	var t := create_tween().set_loops()
	var e: float = s.scale.y
	t.tween_property(s, "scale:y", e * 1.02, 1.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "scale:y", e, 1.6).set_trans(Tween.TRANS_SINE)
	npcs.append([s, d, 0])
	exterior.append(s)


func _crear_piezas() -> void:
	var tapa := _tex(CARPETA + "isla_tapa.png")
	for p in PIEZAS:
		var ruta: String = DIR_TRAMO + p["imagen"]
		if not ResourceLoader.exists(ruta):
			continue
		var tex := _tex(ruta)
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		s.position = p["pies"]
		s.scale = Vector2.ONE * float(p.get("escala", 1.0))
		var m := ShaderMaterial.new()
		m.shader = Shader.new()
		m.shader.code = SHADER_PIEZA
		m.set_shader_parameter("tapa", tapa)
		m.set_shader_parameter("z_pieza", _suelo_isla(p["pies"]))
		s.set_meta("bloquea", float(p["bloquea"]))
		m.set_shader_parameter("ondea", 1.0 if p["ondea"] else 0.0)
		s.material = m
		s.modulate = _tinte(_luz_en(p["pies"]))
		s.set_meta("pieza", p["imagen"])
		mundo_y.add_child(s)
		mats_piezas.append(m)
		piezas.append(s)
		exterior.append(s)


# El cristal de la plaza late despacio: un brillo aditivo pequeño (como el del portal), nunca a pantalla completa.
func _crear_brillo_cristal() -> void:
	var b := Sprite2D.new()
	b.texture = luz_tex
	b.material = aditivo
	b.modulate = Color("5FE0F0", 0.3)
	b.scale = Vector2(1.5, 2.3)
	b.position = CRISTAL
	b.z_index = 1
	add_child(b)
	exterior.append(b)
	var t := create_tween().set_loops()
	t.tween_property(b, "modulate:a", 0.12, 2.2).set_trans(Tween.TRANS_SINE)
	t.tween_property(b, "modulate:a", 0.3, 2.2).set_trans(Tween.TRANS_SINE)


# La sombra larga de Kael, hacia abajo a la derecha (el sol de la isla viene de arriba a la izquierda), bajo la mancha
# de contacto de isla.gd.
func _crear_sombra_larga() -> void:
	sombra_larga = Sprite2D.new()
	sombra_larga.texture = luz_tex
	sombra_larga.modulate = Color(0.04, 0.07, 0.13, 0.22)
	sombra_larga.scale = Vector2(0.62, 0.13)
	sombra_larga.rotation = 0.42
	sombra_larga.position = Vector2(26, 9)
	jugador.add_child(sombra_larga)
	jugador.move_child(sombra_larga, 0)


# ================================================================= suelo, luz y paso

func _en_extra(p: Vector2) -> bool:
	var x := int(p.x / 4.0)
	var y := int(p.y / 4.0)
	if x < 0 or y < 0 or x >= extra_img.get_width() or y >= extra_img.get_height():
		return false
	return extra_img.get_pixel(x, y).r > 0.5


func _choca_npc(p: Vector2) -> bool:
	for n in npcs:
		if n[0].visible and p.distance_to(n[0].position) < 22.0:
			return true
	return false


# Las piezas que están en lo andable (farol, macetas, banco, cántaro) no se atraviesan.
func _choca_pieza(p: Vector2) -> bool:
	for s in piezas:
		var r: float = s.get_meta("bloquea", 0.0)
		if r > 0.0 and p.distance_to(s.position) < r:
			return true
	return false


func _se_anda(p: Vector2) -> bool:
	if dentro:
		return hosp != null and hosp.se_anda(p)
	if _choca_pieza(p):
		return false
	if super(p):
		return true
	return extra_img != null and _en_extra(p) and not _choca_npc(p)


func _suelo_isla(p: Vector2) -> float:
	var x := clampi(int(p.x / 4.0), 0, suelo_img.get_width() - 1)
	var y := clampi(int(p.y / 4.0), 0, suelo_img.get_height() - 1)
	var z := suelo_img.get_pixel(x, y).r
	if z <= 0.0 and extra_img != null:
		z = extra_img.get_pixel(x, y).g             # (los escalones abiertos: la profundidad interpolada)
	return z


func _luz_en(p: Vector2) -> float:
	if dentro and hosp != null:
		return hosp.luz_en(p)
	if luz_img == null:
		return 0.5
	return luz_img.get_pixel(clampi(int(p.x / 4.0), 0, luz_img.get_width() - 1),
		clampi(int(p.y / 4.0), 0, luz_img.get_height() - 1)).r


# 0,5 = la luz media del suelo: tal cual. Menos: más frío y oscuro (aleros, árboles); más: un poco más cálido.
static func _tinte(l: float) -> Color:
	if l < 0.5:
		var k := clampf((0.5 - l) * 2.0, 0.0, 1.0)
		return Color(1, 1, 1).lerp(Color(0.66, 0.72, 0.86), k * 0.5)
	var c := clampf((l - 0.5) * 2.0, 0.0, 1.0)
	return Color(1, 1, 1).lerp(Color(1.08, 1.04, 0.95), c)


func _tintar_kael() -> void:
	if sprite != null and jugador != null:
		sprite.modulate = _tinte(_luz_en(jugador.position))


func _poner_z() -> void:
	var z: float = hosp.suelo_en(jugador.position) if dentro and hosp != null else _suelo_isla(jugador.position)
	if z > 0.0 and absf(z - z_kael) > 0.001:
		z_kael = z
		for m in mats_tapa:
			m.set_shader_parameter("z_kael", z_kael)
		if hosp != null:
			hosp.poner_z(z_kael)
	_tintar_kael()


# ================================================================= cerca y acciones

func _process(delta: float) -> void:
	if en_transicion:
		return
	super(delta)


func _unhandled_input(event: InputEvent) -> void:
	if en_transicion:
		return
	super(event)


func _comprobar_cerca() -> void:
	if dentro:
		portal_cerca = false
		npc_cerca = null
		puerta_cerca = false
		var c: Array = hosp.cerca(jugador.position)
		accion_interior = c[1] if not c.is_empty() else ""
		boton.text = c[0] if not c.is_empty() else ""
		boton.visible = not c.is_empty()
		return
	super()
	puerta_cerca = jugador.position.distance_to(PUERTA_HOSPEDERIA) < RADIO_PUERTA_H
	if puerta_cerca and npc_cerca == null:
		boton.text = "Entrar en la Hospedería"
		boton.visible = true


func _accion() -> void:
	if saliendo or en_transicion:
		return
	if dentro:
		hosp.accion(accion_interior)
		return
	if npc_cerca != null and npc_cerca == lumi:
		var avisos: Array = flor.dar(scene_file_path)
		if not avisos.is_empty():
			lumi[1]["frases"] = lumi[1]["canon"] + [flor.DESPUES]
			lumi[2] = lumi[1]["frases"].size() - 1       # la siguiente vez, lo del dibujo
			_avisos(avisos)
			return
	if npc_cerca == null and puerta_cerca and not portal_cerca:
		entrar_hospederia()
		return
	super()


func _avisos(lista: Array) -> void:
	_mostrar_aviso(lista[0])
	var t := create_tween()
	for k in range(1, lista.size()):
		t.tween_interval(3.0)
		t.tween_callback(_mostrar_aviso.bind(lista[k]))


# ================================================================= entrar y salir de la Hospedería

func entrar_hospederia(inmediato := false) -> void:
	await _cambiar_sala(true, inmediato)


func salir_hospederia(inmediato := false) -> void:
	await _cambiar_sala(false, inmediato)


func _cambiar_sala(entrar: bool, inmediato: bool) -> void:
	if en_transicion or saliendo or dentro == entrar:
		return
	en_transicion = true
	tiene_destino = false
	boton.visible = false
	if not inmediato:
		Sonido.efecto("puerta_abre")
		var t := create_tween()
		t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.3)
		await t.finished
	dentro = entrar
	for c in exterior:
		c.visible = not entrar
	hosp.mostrar(entrar)
	var lim: Rect2 = hosp.limites() if entrar else Rect2(0, 0, ANCHO, ALTO)
	camara.limit_left = int(lim.position.x)
	camara.limit_top = int(lim.position.y)
	camara.limit_right = int(lim.end.x)
	camara.limit_bottom = int(lim.end.y)
	jugador.position = hosp.entrada() if entrar else PUERTA_HOSPEDERIA + Vector2(0, 12)
	sprite.actualizar(Vector2.DOWN, 0.0, 0.016)
	camara.reset_smoothing()
	_poner_z()
	if not inmediato:
		var t2 := create_tween()
		t2.tween_property(fundido, "color:a", 0.0, 0.35)
	if entrar:
		_mostrar_aviso("La Hospedería del Peregrino. Huele a pan de higo.")
	en_transicion = false
	_comprobar_cerca()


# Recursos la llama al cerrar o pausar la app: dentro, se guarda la puerta de la terraza (al cargar se aparece fuera).
func guardar_posicion() -> void:
	if dentro:
		Engine.set_meta("pos_isla", PUERTA_HOSPEDERIA)
		Engine.set_meta("pos_isla_ok", true)
	else:
		super()
