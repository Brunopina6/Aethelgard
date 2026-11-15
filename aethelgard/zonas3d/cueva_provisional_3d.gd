extends "res://prototipos/vista3d.gd"
# V12, mapamundi 3D (15/11/2026): CUEVA DE LOS HELECHOS, ESCENA PROVISIONAL (PROPUESTA, no canon). No había una cueva
# jugable adecuada en la región (la Gruta del Velo va dentro de Pastos Verdes y no existe aún; INVENTARIO_MUNDO.md §5):
# esta es una cueva pequeña y explorable para que la entrada del mapamundi lleve a algún sitio. Solo se llega desde el
# mapamundi 3D (en pruebas, apagado por defecto).
#   - Un túnel con helechos y luz del día, una sala con estalagmitas y hongos que brillan, una poza y, al fondo, un
#     rincón con cristales donde hay un frasco olvidado (1 Éter, una sola vez: cofres_abiertos, como un cofre).
#   - Kael con su grupo (grupo_3d.gd, como en las demás ubicaciones: la formación de dentro no cambia).
#   - Sin encuentros. Guardado al entrar, tras el hallazgo y al pausar (pos_3d con pos_3d_lugar = 101).
#   - Salida: el círculo dorado de la boca (o «Salir» / Intro): al mapamundi, junto a la entrada de la cueva. Si el
#     mapamundi se apagó mientras tanto, al mapa de siempre (en el sitio que dejó el mapamundi).
# Arte provisional, hecho por código (zonas3d/mapamundi/kit.gd).

const D := preload("res://zonas3d/mapamundi/datos.gd")
const Kit := preload("res://zonas3d/mapamundi/kit.gd")
const Maq := preload("res://zonas3d/mapamundi/maquetas.gd")
const Progreso := preload("res://progreso.gd")

const INDICE := D.INDICE_CUEVA
const INICIO := Vector3(0.0, 0.0, 7.0)
const SALIDA := Vector3(0.0, 0.0, 9.2)
const RADIO_SALIDA := 1.2
const ARMAR_SALIDA := 2.4
const HALLAZGO := Vector3(5.6, 0.0, -5.4)
const RADIO_HALLAZGO := 1.9
# El contorno de lo andable (x, z), en el sentido de las agujas del reloj desde la boca.
const CONTORNO := [Vector2(-1.4, 10.2), Vector2(-1.5, 4.6), Vector2(-4.6, 2.6), Vector2(-7.2, -0.6), Vector2(-7.0, -4.6),
	Vector2(-4.2, -7.6), Vector2(0.2, -8.4), Vector2(4.0, -8.0), Vector2(7.4, -6.8), Vector2(7.6, -3.6),
	Vector2(5.0, -1.6), Vector2(4.8, 1.8), Vector2(1.5, 4.6), Vector2(1.4, 10.2)]
const POZA := Vector2(-4.2, -2.6)
const RADIO_POZA := 1.7
const ESTALAGMITAS := [Vector2(-1.8, -3.4), Vector2(1.6, -5.6), Vector2(2.4, -1.4), Vector2(-3.4, -6.2), Vector2(4.4, -3.2)]

var perfil: Dictionary
var nombre_perfil := ""
var saliendo := false
var salida_armada := false
var grupo: Node3D
var capa_ui: CanvasLayer
var boton: Button
var aviso: Label
var fundido: ColorRect
var cerca := ""
var brillo: MeshInstance3D
var _t := 0.0
var luces: Array = []
var _tween_aviso: Tween


func _ready() -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	inclinacion = 56.0
	distancia = 15.0
	super()
	info.visible = false
	_crear_interfaz()
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and int(Engine.get_meta("pos_3d_lugar", -1)) == INDICE \
		and Engine.get_meta("pos_3d", null) is Vector3
	var p: Vector3 = Engine.get_meta("pos_3d") if vuelve else INICIO
	if _prohibido(p):
		p = INICIO
	kael.global_position = Vector3(p.x, 0.0, p.z)
	seguro = kael.global_position
	foco = kael.global_position
	kael.mirar(Vector3(0, 0, -1), 0.05)
	_colocar_camara(1.0)
	salida_armada = _dist_plana(kael.global_position, SALIDA) > ARMAR_SALIDA
	_crear_grupo()
	Engine.set_meta("zona", "cueva")
	Sonido.oyente_3d(kael, cam)
	Sonido.pasos_3d(kael, func(_q): return "piedra")
	_mostrar_aviso("Cueva de los Helechos", 1.8)
	if not Engine.has_meta("banco_proto"):
		guardar_posicion()
		Progreso.guardar(D.CUEVA)


func _crear_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.46, 0.52)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var luz := DirectionalLight3D.new()                  # la poca luz que baja de las grietas
	luz.rotation_degrees = Vector3(-62.0, -25.0, 0.0)
	luz.light_color = Color(0.70, 0.78, 0.86)
	luz.light_energy = 0.35
	luz.shadow_enabled = false
	add_child(luz)


func _crear_escenario() -> void:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	var k := Kit.new()
	# el suelo de la cueva (un poco más claro en lo andable) y su física
	k.caja(Vector3(0, -0.3, 0), Vector3(30, 0.3, 30), Color(0.20, 0.18, 0.17))
	var poli := PackedVector2Array(CONTORNO)
	var tri := Geometry2D.triangulate_polygon(poli)
	for i in range(0, tri.size(), 3):
		var a := poli[tri[i]]
		var b := poli[tri[i + 1]]
		var c := poli[tri[i + 2]]
		k.tri(Vector3(a.x, 0.01, a.y), Vector3(b.x, 0.01, b.y), Vector3(c.x, 0.01, c.y), Vector3.UP, Color(0.38, 0.34, 0.30))
	var cuerpo := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(30, 1, 30)
	col.shape = caja
	col.position = Vector3(0, -0.5, 0)
	cuerpo.add_child(col)
	add_child(cuerpo)
	# las paredes: peñascos alrededor del contorno, más altos al fondo
	var rng := RandomNumberGenerator.new()
	rng.seed = 2610
	for i in CONTORNO.size():
		var a: Vector2 = CONTORNO[i]
		var b: Vector2 = CONTORNO[(i + 1) % CONTORNO.size()]
		if i == CONTORNO.size() - 1:
			continue                                     # la boca queda abierta
		var largo := a.distance_to(b)
		var n := maxi(1, int(largo / 1.3))
		var fuera := Vector2((b - a).y, -(b - a).x).normalized()   # hacia fuera del contorno (horario en pantalla)
		for j in n:
			var p := a.lerp(b, (j + 0.5) / n) + fuera * 0.9
			var alto := rng.randf_range(2.2, 3.6) * (1.25 if p.y < 0.0 else 1.0)
			var tono := Color(0.33, 0.30, 0.28).lightened(rng.randf_range(-0.05, 0.08))
			k.bola(Vector3(p.x, alto * 0.45, p.y), rng.randf_range(1.1, 1.5), tono, alto / 2.6, 3, 6, rng.randf() * TAU)
	# estalagmitas
	for e in ESTALAGMITAS:
		k.cono(Vector3(e.x, 0, e.y), 0.42, rng.randf_range(1.1, 1.8), 6, Color(0.46, 0.42, 0.37))
	# la poza (el borde de piedra; el agua va aparte)
	k.cilindro(Vector3(POZA.x, -0.05, POZA.y), RADIO_POZA + 0.25, RADIO_POZA + 0.2, 0.12, 12, Color(0.30, 0.28, 0.27))
	# helechos en la boca
	for s in [-1.0, 1.0]:
		for f in 4:
			k.cono(Vector3(s * (1.0 + rng.randf() * 0.3), 0, 9.6 - f * 1.4), 0.38, 0.6, 5, Color(0.30, 0.56, 0.26).lightened(f * 0.04))
	# cristales del fondo (emisión aparte) y hongos
	k.instancia(self, "Cueva", mat, false)
	var cristal := StandardMaterial3D.new()
	cristal.vertex_color_use_as_albedo = true
	cristal.emission_enabled = true
	cristal.emission = Color(0.35, 0.8, 0.95)
	cristal.emission_energy_multiplier = 1.4
	var kc := Kit.new()
	for c in 7:
		var a := TAU * c / 7.0
		var p := HALLAZGO + Vector3(cos(a) * 1.15, 0, sin(a) * 0.9) + Vector3(0.6, 0, -0.6)
		kc.cono(p, 0.18, rng.randf_range(0.6, 1.2), 5, Color(0.55, 0.88, 0.98))
	for h in [Vector3(-5.6, 0, -0.8), Vector3(-5.9, 0, -1.6), Vector3(3.6, 0, 0.6), Vector3(-1.2, 0, -7.2), Vector3(2.8, 0, -7.4)]:
		kc.cilindro(h, 0.04, 0.04, 0.22, 4, Color(0.80, 0.86, 0.70))
		kc.bola(h + Vector3(0, 0.26, 0), 0.16, Color(0.55, 0.95, 0.62), 0.55, 2, 6)
	kc.instancia(self, "Cristales", cristal, false)
	# el agua de la poza (quieta, oscura) y la luz del día que entra por la boca
	var agua := Maq.mat_efecto(0, Color(0.06, 0.16, 0.20), Color(0.20, 0.42, 0.48), 1.0, 0.25)
	var poza := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = RADIO_POZA
	disco.bottom_radius = RADIO_POZA
	disco.height = 0.02
	poza.mesh = disco
	poza.material_override = agua
	poza.position = Vector3(POZA.x, 0.04, POZA.y)
	add_child(poza)
	Maq.plano(self, "LuzDelDia", Vector3(0, 1.4, 9.0), Vector2(3.4, 3.2), Maq.mat_efecto(4, Color(1.0, 0.95, 0.80), Color.WHITE, 0.35), false)
	# el frasco olvidado (si sigue ahí): un destello
	if not _hallazgo_cogido():
		brillo = MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.32
		brillo.mesh = sm
		brillo.material_override = Maq.mat_efecto(4, Color(0.75, 0.95, 1.0), Color.WHITE, 0.9)
		brillo.position = HALLAZGO + Vector3(0, 0.35, 0)
		add_child(brillo)
	# luces: la boca (día), los cristales y los hongos
	for l in [[Vector3(0, 2.2, 8.4), Color(1.0, 0.92, 0.78), 1.6, 7.5], [HALLAZGO + Vector3(0.5, 1.2, -0.4), Color(0.4, 0.85, 1.0), 1.3, 6.0],
			[Vector3(-5.0, 1.0, -1.2), Color(0.5, 1.0, 0.6), 0.8, 4.5]]:
		var o := OmniLight3D.new()
		o.position = l[0]
		o.light_color = l[1]
		o.light_energy = l[2]
		o.omni_range = l[3]
		add_child(o)
		luces.append(o)
	# la salida
	var aro := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = RADIO_SALIDA
	dm.bottom_radius = RADIO_SALIDA
	dm.height = 0.03
	aro.mesh = dm
	var ma := StandardMaterial3D.new()
	ma.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ma.albedo_color = Color(1.0, 0.86, 0.45, 0.42)
	aro.material_override = ma
	aro.position = SALIDA + Vector3(0, 0.05, 0)
	add_child(aro)
	var letrero := Label3D.new()
	letrero.text = "Mapamundi"
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.font_size = 44
	letrero.outline_size = 12
	letrero.pixel_size = 0.012
	letrero.position = SALIDA + Vector3(2.4, 1.2, 0.4)
	add_child(letrero)


func _prohibido(p: Vector3) -> bool:
	var q := Vector2(p.x, p.z)
	if not Geometry2D.is_point_in_polygon(q, PackedVector2Array(CONTORNO)):
		return true
	if q.distance_to(POZA) < RADIO_POZA + 0.2:
		return true
	for e in ESTALAGMITAS:
		if q.distance_to(e) < 0.55:
			return true
	if q.distance_to(Vector2(HALLAZGO.x + 0.6, HALLAZGO.z - 0.6)) < 0.9:
		return true                                      # los cristales
	return false


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _crear_grupo() -> void:
	if not perfil.get("grupo", true):
		return
	var G = load("res://grupo.gd")
	var activos: Array = G.activos()
	var nombres: Array = []
	for n in G.EN_EL_GRUPO:
		if n != "Kael" and n in activos:
			nombres.append(n)
	if nombres.is_empty():
		return
	grupo = load("res://zonas3d/grupo_3d.gd").new()
	grupo.name = "Grupo"
	add_child(grupo)
	grupo.pasos_superficie = func(_q): return "piedra"
	grupo.preparar(self, kael, nombres)
	grupo.colocar(Vector3.BACK)


func _hallazgo_cogido() -> bool:
	return Engine.get_meta("cofres_abiertos", {}).has(D.ID_CUEVA)


func _process(delta: float) -> void:
	_t += delta
	if brillo != null:
		brillo.scale = Vector3.ONE * (1.0 + sin(_t * 3.0) * 0.18)
	if saliendo:
		destino = null
		_colocar_camara(1.0 - exp(-suavizado * delta))
		return
	super(delta)
	if saliendo:
		return
	var p := kael.global_position
	var ds := _dist_plana(p, SALIDA)
	if not salida_armada:
		salida_armada = ds > ARMAR_SALIDA
	elif ds < RADIO_SALIDA:
		_salir()
		return
	var nuevo := ""
	if ds < 3.0:
		nuevo = "salir"
	elif brillo != null and _dist_plana(p, HALLAZGO) < RADIO_HALLAZGO:
		nuevo = "hallazgo"
	if nuevo != cerca:
		cerca = nuevo
		boton.visible = nuevo != ""
		boton.text = "Salir al mapamundi" if nuevo == "salir" else "Examinar"


func _unhandled_input(ev: InputEvent) -> void:
	if saliendo:
		return
	if ev.is_action_pressed("ui_accept") and boton.visible:
		get_viewport().set_input_as_handled()
		_pulsar()
		return
	super(ev)


func _pulsar() -> void:
	if cerca == "salir":
		_salir()
	elif cerca == "hallazgo":
		_coger()


func _coger() -> void:
	if _hallazgo_cogido():
		return
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	abiertos[D.ID_CUEVA] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	load("res://inventario.gd").agregar_objeto("Éter", 1)
	if brillo != null:
		brillo.queue_free()
		brillo = null
	cerca = ""
	boton.visible = false
	Sonido.efecto("tesoro")
	_mostrar_aviso("Entre los cristales, un frasco olvidado: 1 Éter.", 2.6)
	guardar_posicion()
	Progreso.guardar(D.CUEVA)


func guardar_posicion() -> void:
	Engine.set_meta("pos_3d", kael.global_position)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", INDICE)


func _salir() -> void:
	if saliendo:
		return
	saliendo = true
	Engine.set_meta("pos_3d_ok", false)
	var ruta := D.MAPA
	if load("res://modo3d.gd").mapamundi_activo() and ResourceLoader.exists(D.ESCENA):
		Engine.set_meta(D.LLEGADA, "cueva")
		ruta = D.ESCENA
	Sonido.efecto("entrar")
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.45)
	await t.finished
	Recursos.cambiar_escena(ruta)


# recursos.gd la llama si no pudo cambiar de escena: se vuelve a ver la cueva con el control.
func carga_fallida(_ruta: String) -> void:
	saliendo = false
	salida_armada = false
	fundido.color = Color(0, 0, 0, 0)
	get_tree().root.gui_disable_input = false
	_mostrar_aviso("No se pudo salir. Inténtalo de nuevo.", 2.4)


func _crear_interfaz() -> void:
	capa_ui = CanvasLayer.new()
	capa_ui.layer = 50
	add_child(capa_ui)
	boton = Button.new()
	boton.position = Vector2(470, 600)
	boton.custom_minimum_size = Vector2(340, 56)
	boton.add_theme_font_size_override("font_size", 22)
	boton.focus_mode = Control.FOCUS_NONE
	boton.visible = false
	boton.pressed.connect(_pulsar)
	capa_ui.add_child(boton)
	aviso = Label.new()
	aviso.position = Vector2(140, 96)
	aviso.size = Vector2(1000, 90)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.add_theme_font_override("font", load("res://estilo.gd").cursiva())
	aviso.add_theme_font_size_override("font_size", 30)
	aviso.add_theme_constant_override("outline_size", 9)
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aviso.modulate.a = 0.0
	capa_ui.add_child(aviso)
	fundido = ColorRect.new()
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_ui.add_child(fundido)


func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:
			n.queue_free()


func _cambiar_perfil() -> void:
	guardar_posicion()
	super()


func _mostrar_aviso(texto: String, segundos := 1.8) -> void:
	aviso.text = texto
	if _tween_aviso != null and _tween_aviso.is_valid():
		_tween_aviso.kill()
	_tween_aviso = create_tween()
	_tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	_tween_aviso.tween_interval(segundos)
	_tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)
