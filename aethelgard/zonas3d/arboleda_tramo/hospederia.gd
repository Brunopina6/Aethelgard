extends Node2D
# Arboleda Mítica, tramo «La escalera de la Hospedería» (EXPERIMENTAL, 16/11): el INTERIOR de la Hospedería del
# Peregrino [P] (docs/diseno/ciudades_y_lugares.md §2.3). Es un nodo de la misma escena (arboleda_tramo.gd), lejos de la
# isla (ORIGEN), con su fondo pintado (interior/color.png), su máscara de paso, su suelo, su tapa y su luz, hechos con las
# mismas herramientas que la isla (fuente/crear_hospederia.py → render_isla.gd → preparar_isla.gd → preparar_tramo.gd).
#
# Dentro: Yedra [P] tras el mostrador; dormir (PRECIO [D], 20) cobra, cura y cuenta la escena de descanso en avisos
# encadenados (sin Dialogic: pasarla a Dialogic es un cambio aparte); el dibujo de Lumi aparece en la pared cuando se le
# ha llevado la flor (lumi_flor.gd). Por las ventanas se ven el cielo y unas nubes que pasan (detrás del fondo, que tiene
# las ventanas transparentes): sin capas transparentes a pantalla completa.

const DIR := "res://zonas3d/arboleda_tramo/interior/"
const ORIGEN := Vector2(4400, 0)             # lejos de la isla (3072 × 3348): nunca se ven a la vez
const PRECIO := 20                           # [D] 20 monedas (la hospitalidad de los peregrinos); sin tocar zona.gd
const RADIO_PUERTA := 60.0
const RADIO_YEDRA := 110.0
const RADIO_CAMA := 90.0
const RADIO_DIBUJO := 120.0
const YEDRA := {"nombre": "Yedra", "imagen": "res://zonas3d/arboleda_tramo/piezas/yedra.png",
	"frases": ["Hace años que no subía nadie a dormir. Te he guardado la mejor cama.",       # [P] ciudades_y_lugares §2.3
		"Firma en el libro de la ermita, como los peregrinos. Aquí arriba, lo escrito se queda.",
		"Veinte monedas. Los peregrinos pagaban con una historia. Tú pareces de pagar."],
	"con_dibujo": "Lumi me ha traído su dibujo. Dice que así los que suban sabrán que abajo hay colores."}   # [P] nueva
# La escena de descanso [P] (ciudades_y_lugares §2.3), en avisos: quién habla y qué. Solo los que están en el grupo.
const DESCANSO := [["Yedra", "Hacía años que no subía nadie a dormir."], ["Kael", "¿Y eso?"],
	["Yedra", "No había por dónde subir. Ahora hay un portal. Y vosotros."],
	["Lya", "Se duerme bien aquí. Demasiado bien."], ["Garon", "Yo hago la primera guardia."],
	["Yedra", "¿Guardia? Aquí arriba no pasa nada. Ese es el problema."]]
const SHADER_NUBE_VENTANA := """
shader_type canvas_item;
render_mode blend_mix;
void fragment() {
	COLOR = texture(TEXTURE, UV) * COLOR;
}
"""

var tramo                                    # arboleda_tramo.gd (la escena)
var paso_img: Image
var suelo_img: Image
var luz_img: Image
var anclas := {}
var tam := Vector2.ZERO
var mats: Array = []
var yedra: Sprite2D
var dibujo: Sprite2D
var nubes: CPUParticles2D
var fondo: Node2D
var descansando := false
var tapa_tex: Texture2D


func preparar(t) -> void:
	tramo = t
	position = ORIGEN
	visible = false
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "anclas.json"))
	tam = Vector2(d["tam"][0], d["tam"][1])
	for k in d["anclas"]:
		anclas[k] = Vector2(d["anclas"][k][0], d["anclas"][k][1])
	paso_img = tramo._tex(DIR + "paso.png").get_image()
	suelo_img = tramo._tex(DIR + "suelo.png").get_image()
	luz_img = tramo._tex(DIR + "luz.png").get_image()
	_crear_cielo_ventanas()
	var color: Texture2D = tramo._tex(DIR + "color.png")
	var tapa: Texture2D = tramo._tex(DIR + "tapa.png")
	tapa_tex = tapa
	fondo = Node2D.new()
	add_child(fondo)
	var base := Sprite2D.new()
	base.texture = color
	base.centered = false
	base.z_index = 0
	fondo.add_child(base)
	var encima := Sprite2D.new()                  # la misma técnica que la isla: lo que está delante tapa a Kael
	encima.texture = color
	encima.centered = false
	encima.z_index = 3
	var m := ShaderMaterial.new()
	m.shader = Shader.new()
	m.shader.code = tramo.SHADER_TAPA
	m.set_shader_parameter("tapa", tapa)
	m.set_shader_parameter("uv_ini", Vector2.ZERO)
	m.set_shader_parameter("uv_tam", Vector2.ONE)
	m.set_shader_parameter("z_kael", tramo.z_kael)
	encima.material = m
	fondo.add_child(encima)
	mats.append(m)
	_crear_dibujo()
	_crear_yedra()


# El cielo de las ventanas: el degradado del cielo de la isla ya está detrás de todo (CanvasLayer -10); aquí solo unas
# nubes pequeñas que pasan por detrás de las tres ventanas (el fondo es opaco fuera de ellas).
func _crear_cielo_ventanas() -> void:
	var xs: Array = []
	for k in anclas:
		if k.begins_with("ventana"):
			xs.append(anclas[k].x)
	if xs.is_empty():
		return
	xs.sort()
	nubes = CPUParticles2D.new()
	nubes.texture = tramo.luz_tex
	nubes.amount = 6
	nubes.lifetime = 26.0
	nubes.preprocess = 26.0
	nubes.local_coords = false
	nubes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	nubes.emission_rect_extents = Vector2(10, 40)
	nubes.position = Vector2(xs[0] - 160, anclas.get("ventana_0", Vector2(0, 150)).y)
	nubes.direction = Vector2(1, 0)
	nubes.spread = 0.0
	nubes.gravity = Vector2.ZERO
	nubes.initial_velocity_min = 22.0
	nubes.initial_velocity_max = 34.0
	nubes.scale_amount_min = 0.9
	nubes.scale_amount_max = 1.6
	nubes.color = Color(1, 1, 1, 0.75)
	nubes.z_index = -1
	add_child(nubes)


func _crear_dibujo() -> void:
	var ruta := "res://zonas3d/arboleda_tramo/piezas/dibujo_lumi.png"
	if not ResourceLoader.exists(ruta) or not anclas.has("dibujo"):
		return
	dibujo = Sprite2D.new()
	dibujo.texture = tramo._tex(ruta)
	dibujo.position = anclas["dibujo"]
	dibujo.rotation = deg_to_rad(-4.0)
	dibujo.scale = Vector2.ONE * 0.62
	dibujo.z_index = 1                        # sobre la pared y bajo lo que tapa
	dibujo.visible = false
	add_child(dibujo)


func _crear_yedra() -> void:
	if not anclas.has("yedra"):
		return
	var tex: Texture2D = tramo.figura(YEDRA["imagen"])
	yedra = Sprite2D.new()
	yedra.texture = tex
	yedra.centered = false
	yedra.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	yedra.scale = Vector2.ONE * tramo.escala_figura(tex)
	yedra.position = ORIGEN + anclas["yedra"]
	yedra.visible = false
	var m := ShaderMaterial.new()                  # el mostrador, que está delante, la tapa de cintura abajo
	m.shader = Shader.new()
	m.shader.code = tramo.SHADER_PIEZA
	m.set_shader_parameter("tapa", tapa_tex)
	m.set_shader_parameter("origen", ORIGEN)
	m.set_shader_parameter("tam_fondo", tam)
	m.set_shader_parameter("z_pieza", suelo_en(yedra.position))
	yedra.material = m
	tramo.mundo_y.add_child(yedra)
	var t := create_tween().set_loops()
	var s: float = yedra.scale.y
	t.tween_property(yedra, "scale:y", s * 1.02, 1.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(yedra, "scale:y", s, 1.5).set_trans(Tween.TRANS_SINE)


# ---------------------------------------------------------------- consultas (en coordenadas de la escena)

func local(p: Vector2) -> Vector2:
	return p - ORIGEN


func se_anda(p: Vector2) -> bool:
	var q := local(p) / 4.0
	var x := int(q.x)
	var y := int(q.y)
	if q.x < 0 or q.y < 0 or x >= paso_img.get_width() or y >= paso_img.get_height():
		return false
	if paso_img.get_pixel(x, y).r < 0.5:
		return false
	return yedra == null or p.distance_to(yedra.position) >= 26.0


func suelo_en(p: Vector2) -> float:
	var q := local(p) / 4.0
	return suelo_img.get_pixel(clampi(int(q.x), 0, suelo_img.get_width() - 1),
		clampi(int(q.y), 0, suelo_img.get_height() - 1)).r


func luz_en(p: Vector2) -> float:
	var q := local(p) / 4.0
	return luz_img.get_pixel(clampi(int(q.x), 0, luz_img.get_width() - 1),
		clampi(int(q.y), 0, luz_img.get_height() - 1)).r


func entrada() -> Vector2:
	return ORIGEN + anclas.get("entrada", Vector2(550, 713))


func puerta() -> Vector2:
	return ORIGEN + anclas.get("puerta", Vector2(550, 754))


func limites() -> Rect2:
	return Rect2(ORIGEN, tam)


func poner_z(z: float) -> void:
	for m in mats:
		m.set_shader_parameter("z_kael", z)


func mostrar(si: bool) -> void:
	visible = si
	if yedra != null:
		yedra.visible = si
	if dibujo != null:
		dibujo.visible = si and tramo.flor.entregada()


# ---------------------------------------------------------------- qué hay cerca y acciones

# Devuelve [texto del botón, acción] o [] si no hay nada.
func cerca(p: Vector2) -> Array:
	if p.distance_to(puerta()) < RADIO_PUERTA:
		return ["Salir a la terraza", "salir"]
	if yedra != null and p.distance_to(ORIGEN + anclas.get("mostrador", Vector2.ZERO)) < RADIO_YEDRA:
		return ["Hablar con Yedra", "yedra"]
	if anclas.has("cama") and p.distance_to(ORIGEN + anclas["cama"]) < RADIO_CAMA:
		return ["Dormir (%d monedas)" % PRECIO, "dormir"]
	if dibujo != null and dibujo.visible and p.distance_to(ORIGEN + anclas["dibujo"] + Vector2(0, 115)) < RADIO_DIBUJO:
		return ["Mirar el dibujo", "dibujo"]
	return []


var _frase_yedra := 0


func accion(que: String) -> void:
	match que:
		"salir":
			tramo.salir_hospederia()
		"yedra":
			var frases: Array = YEDRA["frases"].duplicate()
			if tramo.flor.entregada():
				frases.insert(0, YEDRA["con_dibujo"])
			tramo._mostrar_aviso("Yedra: «%s»" % frases[_frase_yedra % frases.size()])
			_frase_yedra += 1
		"dormir":
			dormir()
		"dibujo":
			tramo._mostrar_aviso("Un sol, una flor morada y dos figuras. La nube gris, tachada.")


# Dormir: cobra PRECIO, cura al grupo (grupo.gd) y suena la posada; la noche pasa en un fundido y la escena de
# descanso sale en avisos encadenados (solo los del grupo). Sin monedas: el sonido de error y un aviso.
func dormir() -> bool:
	if descansando:
		return false
	if not load("res://inventario.gd").gastar_oro(PRECIO):
		Sonido.efecto("ui_error")
		tramo._mostrar_aviso("No tienes monedas suficientes (la Hospedería cuesta %d)." % PRECIO)
		return false
	descansando = true
	Sonido.efecto("posada")
	load("res://grupo.gd").curar_todos()
	var en_grupo: Array = load("res://grupo.gd").activos()
	var lineas: Array = []
	for l in DESCANSO:
		if l[0] == "Yedra" or l[0] in en_grupo:
			lineas.append(l)
	if not "Garon" in en_grupo:                  # sin Garon, la respuesta a su guardia no tiene sentido
		lineas = lineas.filter(func(l): return not str(l[1]).begins_with("¿Guardia?"))
	var t := create_tween()
	t.tween_property(tramo.fundido, "color", Color(0.02, 0.02, 0.06, 0.92), 0.5)
	t.tween_interval(0.7)
	t.tween_property(tramo.fundido, "color:a", 0.0, 0.7)
	tramo._mostrar_aviso("Descansáis en la Hospedería. PV y PM recuperados.")
	var espera := 2.6
	for l in lineas:
		t.tween_interval(espera)
		t.tween_callback(tramo._mostrar_aviso.bind("%s: «%s»" % [l[0], l[1]]))
		espera = 3.2
	t.tween_callback(func(): descansando = false)
	return true
