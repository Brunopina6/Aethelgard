extends "res://prototipos/vista3d.gd"
# El Mar de Cristal en 3D (V12; docs/v12/DISENO_V12.md): el primer sector, «La Orilla de Vidrio», del corazón
# vitrificado del Mar de Arena de Calid (lugar 4 del mapa). Dunas con relieve, el campamento de la cartógrafa, los restos
# de la caravana, el oasis, el cañón con su cobijo, las ruinas enterradas, la arena que tiembla (el gusano), un espejismo
# y un esqueleto con su nota. Mecánicas: el buscador de metales de Kael (buscador.gd, buscador_hud.gd), el viento y la
# tormenta de arena (clima.gd), la misión «La caravana perdida» (mision.gd) y las vibraciones del gusano (gusano.gd).
# Contrato de región (como la Garganta y Oakhaven 3D): guardado al entrar y al pausar (guardar_posicion), encuentros por
# pasos con progreso.gd, combate con vuelta, Dialogic, grupo detrás de Kael y salida al mapa por el camino del sur.
# En pruebas hasta que esté entera: con la exploración 3D y «mardecristal» (argumento o Ajustes; modo3d.gd EN_PRUEBAS).

const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const Terreno := preload("res://zonas3d/mar_cristal/terreno.gd")
const Clima := preload("res://zonas3d/mar_cristal/clima.gd")
const Mision := preload("res://zonas3d/mar_cristal/mision.gd")
const Hud := preload("res://zonas3d/mar_cristal/buscador_hud.gd")
const Gusano := preload("res://zonas3d/mar_cristal/gusano.gd")
const Buscador := preload("res://buscador.gd")
const Progreso := preload("res://progreso.gd")

const INDICE := 4                          # lugar del mapa (mapa.gd: Mar de Arena de Calid; modo3d.MAR_CRISTAL)
const NOMBRE := "mar_cristal"              # progreso.gd: mazmorras[...] y encuentros
const ZONA := "desierto"                   # combate: fondo y nivel (mapa.gd ZONA_LUGAR[4])
const REGION_BUSCADOR := "mar_de_cristal_1"   # buscador.gd REGIONES
const SEMILLA := 4207                      # el reparto de lo enterrado en este sector (fijo: igual en todas las partidas)
const LONG_PASO := 0.5
const PASOS_MIN := 40
const PROB_ENCUENTRO := 0.010
const RADIO_SALIDA := 1.4
const ARMAR_SALIDA := 3.0
const RADIO_ACCION := 2.2
const CAMARA := [48.0, 13.0, 22.0]         # [inclinación, distancia mínima, máxima]

var perfil: Dictionary = {}
var nombre_perfil := "alto"
var terreno
var clima
var mision
var hud
var gusano
var grupo: Node3D
var capa_ui: CanvasLayer
var fundido: ColorRect
var aviso: Label
var boton_accion: Button
var cartografa: Node3D
var cerca := ""
var saliendo := false
var pasos := 0
var _recorrido := 0.0
var _ultima := Vector3.ZERO
var _bloqueo := 0.0
var _t := 0.0
var salida := {"armada": false}
var _dist_jugador := 17.0
var _dist_puesta := 17.0
var dialogo_actual := ""


func _ready() -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	super()
	info.visible = false
	_crear_interfaz()
	mision = Mision.new()
	clima = Clima.new(self, perfil)
	clima.construir()
	hud = Hud.new(self, capa_ui)
	hud.construir()
	gusano = Gusano.new(self)
	Mision.registrar_dialogic()
	_crear_cartografa()
	poner_oren(Progreso.hito("mc_superviviente"))
	terreno.poner_ruinas(mision.ruinas_reveladas())
	if Progreso.hito("mc_superviviente"):
		terreno.abrir_trampilla()
	Sonido.fuente_3d(self, "fogata_bucle", Vector3(T.FOGATA.x, 0.4, T.FOGATA.y))   # sonido_v12_desierto.md §2
	Sonido.fuente_3d(self, "oasis_bucle", Vector3(T.OASIS.x, 0.2, T.OASIS.y))
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and Engine.get_meta("pos_3d_lugar", -1) == INDICE \
		and Engine.get_meta("pos_3d", null) is Vector3
	_colocar_kael(Engine.get_meta("pos_3d") if vuelve else T.ENTRADA)
	_ultima = kael.global_position
	_crear_grupo()
	salida["armada"] = _dist_plana(kael.global_position, T.SALIDA) > ARMAR_SALIDA
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.timeline_ended.connect(_al_terminar_dialogo)
		if not dg.signal_event.is_connected(_senal_dialogo):
			dg.signal_event.connect(_senal_dialogo)
	Engine.set_meta("zona", ZONA)
	Sonido.oyente_3d(kael, cam)
	Sonido.pasos_3d(kael, suelo_de_pasos)
	clima.empezar_sonido()
	_titulo_zona("El Mar de Cristal")
	if not en_banco():
		Progreso.guardar(scene_file_path)


func en_banco() -> bool:
	return Engine.has_meta("banco_proto")


# ================================================================= mundo

func _crear_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR                 # un cielo de desierto: azul pálido, casi blanco abajo
	env.background_color = Color(0.70, 0.80, 0.90)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.82, 0.66)          # el rebote cálido de la arena
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_light_color = Color(0.96, 0.84, 0.66)              # bruma cálida
	env.fog_density = 0.006
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.10
	env.adjustment_contrast = 1.06
	env.tonemap_exposure = 1.0
	if nombre_perfil == "alto":
		env.glow_enabled = true
		env.glow_intensity = 0.35
		env.glow_bloom = 0.04
		env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	we.name = "Ambiente"
	add_child(we)
	var sol := DirectionalLight3D.new()                        # sol alto de la tarde, cálido, desde el suroeste
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-52.0, -138.0, 0.0)
	sol.light_color = Color(1.0, 0.90, 0.74)
	sol.light_energy = perfil.get("luz_sol", 1.0) * 1.15
	sol.shadow_enabled = perfil.get("sombras", false)
	sol.directional_shadow_max_distance = perfil.get("dist_sombras", 40.0)
	sol.shadow_blur = 1.2
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sol)


func _crear_escenario() -> void:
	terreno = Terreno.new(self, perfil)
	terreno.construir()


func _prohibido(p: Vector3) -> bool:
	return T.prohibido(p.x, p.z)


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func suelo_de_pasos(p: Vector3) -> String:
	return "arena" if not T.en_camino(p.x, p.z) else "tierra"


# ================================================================= Kael, cámara y grupo

func _colocar_kael(p: Vector3) -> void:
	p.y = T.altura(p.x, p.z)
	kael.global_position = p
	seguro = p
	foco = p
	destino = null
	inclinacion = CAMARA[0]
	distancia = clampf(_dist_jugador, CAMARA[1], CAMARA[2])
	_dist_puesta = distancia
	_colocar_camara(1.0)


func _camara_zona(delta: float) -> void:
	if absf(distancia - _dist_puesta) > 0.0001:
		_dist_jugador = clampf(_dist_jugador + distancia - _dist_puesta, DIST_MIN, DIST_MAX)
	var k := 1.0 - exp(-2.2 * delta)
	inclinacion = lerpf(inclinacion, CAMARA[0], k)
	distancia = lerpf(distancia, clampf(_dist_jugador, CAMARA[1], CAMARA[2]), k)
	_dist_puesta = distancia


func _crear_grupo() -> void:
	if not perfil.get("grupo", true):
		return
	var G = load("res://grupo.gd")
	var activos: Array = G.activos()
	var nombres: Array = []
	for n in G.EN_EL_GRUPO:
		if n != "Kael" and n in activos:
			nombres.append(n)
	grupo = load("res://zonas3d/grupo_3d.gd").new()
	grupo.name = "Grupo"
	add_child(grupo)
	grupo.pasos_superficie = suelo_de_pasos
	grupo.preparar(self, kael, nombres)
	grupo.colocar(Vector3.BACK)


func _parar_kael() -> void:
	destino = null
	if movimiento != "":
		movimiento = ""
		kael.reposo()


func ocupado() -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	return (dg != null and dg.current_timeline != null) or (hud != null and hud.ocupado())


func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:
			n.queue_free()


func _cambiar_perfil() -> void:
	guardar_posicion()
	super()


# ================================================================= cada fotograma

func _process(delta: float) -> void:
	_t += delta
	_bloqueo = maxf(0.0, _bloqueo - delta)
	if kael == null:
		return
	if terreno != null:
		terreno.animar(_t, clima.viento() if clima != null else 0.2)
	if clima != null:
		clima.actualizar(delta, kael.global_position, ocupado())
	if en_banco():
		super(delta)
		return
	if ocupado():
		_parar_kael()
		boton_accion.visible = false
		_colocar_camara(1.0 - exp(-suavizado * delta))
		_oclusion()
		return
	_camara_zona(delta)
	super(delta)
	if saliendo:
		return
	var p := kael.global_position
	var d := _dist_plana(p, _ultima)
	_ultima = p
	if d < 2.0:
		_recorrido += d
		while _recorrido >= LONG_PASO and not saliendo:
			_recorrido -= LONG_PASO
			_paso()
	if saliendo:
		return
	var ds := _dist_plana(p, T.SALIDA)
	if not salida["armada"]:
		salida["armada"] = ds > ARMAR_SALIDA
	elif ds < RADIO_SALIDA:
		_salir()
		return
	hud.actualizar(delta, p, clima.buscador_estorbado())
	gusano.actualizar(delta, p)
	mision.vigilar(self, p)
	_comprobar_cerca()


# ================================================================= encuentros

func _paso() -> void:
	pasos += 1
	if Progreso.paso_incienso():
		_mostrar_aviso("El Incienso de Ceniza se ha consumido.")
	var k := T.ritmo(kael.global_position.x, kael.global_position.z)
	if clima.tormenta_fuerte():
		k *= 1.4                                                 # con tormenta se oye menos y se ve menos: más emboscadas
	if k > 0.0 and randf() < Progreso.prob_encuentro(PROB_ENCUENTRO * k, pasos, PASOS_MIN, NOMBRE):
		encuentro()


func encuentro(fijo := "", grupo_combate := -1, tipo := "normal", texto := "¡Emboscada!") -> void:
	if saliendo:
		return
	saliendo = true
	guardar_posicion()
	Engine.set_meta("zona", ZONA)
	Engine.set_meta("desde_mapa", true)
	Engine.set_meta("tipo_combate", tipo)
	Engine.set_meta("escena_retorno", scene_file_path)
	if fijo != "":
		Engine.set_meta("grupo_combate", grupo_combate)
		Engine.set_meta("combate_fijo", fijo)
	Sonido.efecto("emboscada")
	_mostrar_aviso(texto)
	_parar_kael()
	boton_accion.visible = false
	fundido.color = Color(1, 1, 1, 0)
	var t := create_tween()
	for i in 3:
		t.tween_property(fundido, "color:a", 0.85, 0.07)
		t.tween_property(fundido, "color:a", 0.0, 0.07)
	t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.45)
	await t.finished
	Recursos.cambiar_escena("res://combate.tscn")


# ================================================================= lo que se usa

# [id, sitio, radio, texto del botón]. La misión decide qué sale (mision.gd).
func _piezas_al_alcance() -> Array:
	var r: Array = [["cartografa", Vector3(T.CARTOGRAFA.x, 0, T.CARTOGRAFA.y), 2.4, "Hablar con la cartógrafa"],
		["esqueleto", Vector3(T.ESQUELETO.x, 0, T.ESQUELETO.y), 2.4, "Examinar"],
		["espejismo", Vector3(T.ESPEJISMO.x, 0, T.ESPEJISMO.y), 3.2, "Mirar el espejismo"]]
	r.append_array(mision.piezas())
	return r


func _comprobar_cerca() -> void:
	cerca = ""
	var mejor := INF
	for pz in _piezas_al_alcance():
		var d := _dist_plana(kael.global_position, pz[1])
		if d < pz[2] and d < mejor:
			mejor = d
			cerca = pz[0]
			boton_accion.text = pz[3]
	boton_accion.visible = cerca != ""


func _unhandled_input(ev: InputEvent) -> void:
	if ocupado():
		return
	if ev.is_action_pressed("ui_accept") and boton_accion.visible:
		_accion()
		get_viewport().set_input_as_handled()
		return
	super(ev)


func _accion() -> void:
	if _bloqueo > 0.0 or ocupado():
		return
	_bloqueo = 0.4
	mision.accion(self, cerca)


func dialogo(nombre: String) -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	var ruta := "res://dialogos/mar_cristal/%s.dtl" % nombre
	if dg == null or not ResourceLoader.exists(ruta) or dg.current_timeline != null:
		return false
	_parar_kael()
	boton_accion.visible = false
	dialogo_actual = nombre
	dg.start(ruta)
	return true


func _senal_dialogo(arg) -> void:
	if mision != null:
		mision.senal(self, str(arg))


func _al_terminar_dialogo() -> void:
	var fue := dialogo_actual
	dialogo_actual = ""
	_bloqueo = 0.4
	if mision != null and fue != "":
		mision.dialogo_terminado(self, fue)


# ================================================================= la cartógrafa

func _crear_cartografa() -> void:
	cartografa = Node3D.new()
	cartografa.name = "Cartografa"
	cartografa.position = Vector3(T.CARTOGRAFA.x, T.altura(T.CARTOGRAFA.x, T.CARTOGRAFA.y), T.CARTOGRAFA.y)
	add_child(cartografa)
	if terreno.poner_modelo("cartografa", Vector3.ZERO, 1.0, null, cartografa):
		return
	var cuerpo := MeshInstance3D.new()                         # sencilla: túnica, pañuelo y sombrero de ala ancha
	var c := CapsuleMesh.new()
	c.radius = 0.32
	c.height = 1.55
	cuerpo.mesh = c
	cuerpo.material_override = terreno._liso(Color(0.30, 0.48, 0.58))
	cuerpo.position.y = 0.78
	cartografa.add_child(cuerpo)
	var cabeza := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.2
	s.height = 0.4
	cabeza.mesh = s
	cabeza.material_override = terreno._liso(Color(0.86, 0.66, 0.50))
	cabeza.position.y = 1.68
	cartografa.add_child(cabeza)
	var ala := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.18
	cil.bottom_radius = 0.42
	cil.height = 0.16
	ala.mesh = cil
	ala.material_override = terreno._liso(Color(0.80, 0.62, 0.38))
	ala.position.y = 1.86
	cartografa.add_child(ala)


# Oren, de vuelta en el campamento junto a su hermana (desde mc_superviviente): sencillo, como ella, en otros colores.
var oren: Node3D


func poner_oren(si: bool) -> void:
	if not si or oren != null:
		return
	oren = Node3D.new()
	oren.name = "Oren"
	var p := Vector2(T.CARTOGRAFA.x - 1.6, T.CARTOGRAFA.y + 0.4)
	oren.position = Vector3(p.x, T.altura(p.x, p.y), p.y)
	add_child(oren)
	if terreno.poner_modelo("oren", Vector3.ZERO, 1.0, null, oren):
		return
	for parte in [[CapsuleMesh, 0.30, 1.45, 0.73, Color(0.62, 0.36, 0.22)], [SphereMesh, 0.19, 0.38, 1.58, Color(0.84, 0.64, 0.48)]]:
		var mi := MeshInstance3D.new()
		var m = parte[0].new()
		m.radius = parte[1]
		m.height = parte[2]
		mi.mesh = m
		mi.material_override = terreno._liso(parte[4])
		mi.position.y = parte[3]
		oren.add_child(mi)
	var panuelo := MeshInstance3D.new()                        # el pañuelo rojo del toldo de su carro
	var c := CylinderMesh.new()
	c.top_radius = 0.2
	c.bottom_radius = 0.24
	c.height = 0.14
	panuelo.mesh = c
	panuelo.material_override = terreno._liso(Color(0.80, 0.24, 0.20))
	panuelo.position.y = 1.72
	oren.add_child(panuelo)


# ================================================================= guardado y salida

func guardar_posicion() -> void:
	Engine.set_meta("pos_3d", kael.global_position)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", INDICE)


func _salir() -> void:
	if saliendo:
		return
	saliendo = true
	Engine.set_meta("pos_3d_ok", false)
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.5)
	await t.finished
	Recursos.cambiar_escena(Progreso.MAPA)


func _exit_tree() -> void:
	if clima != null:
		clima.parar_sonido()
	super()


# ================================================================= interfaz

func _crear_interfaz() -> void:
	capa_ui = CanvasLayer.new()
	capa_ui.layer = 50
	add_child(capa_ui)
	boton_accion = Button.new()
	boton_accion.position = Vector2(960, 600)
	boton_accion.custom_minimum_size = Vector2(290, 84)
	boton_accion.add_theme_font_size_override("font_size", 28)
	boton_accion.focus_mode = Control.FOCUS_NONE
	boton_accion.visible = false
	boton_accion.pressed.connect(_accion)
	capa_ui.add_child(boton_accion)
	aviso = Label.new()
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.size = Vector2(1000, 120)
	aviso.position = Vector2(140, 470)
	aviso.add_theme_font_size_override("font_size", 28)
	aviso.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	aviso.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.06, 0.9))
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.modulate.a = 0.0
	capa_ui.add_child(aviso)
	fundido = ColorRect.new()
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_ui.add_child(fundido)


var _tween_aviso: Tween


func _mostrar_aviso(texto: String, segundos := 1.8) -> void:
	aviso.text = texto
	if _tween_aviso != null and _tween_aviso.is_valid():
		_tween_aviso.kill()
	_tween_aviso = create_tween()
	_tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	_tween_aviso.tween_interval(segundos)
	_tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)


func _titulo_zona(nombre: String) -> void:
	var l := Label.new()
	l.text = nombre
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(1280, 80)
	l.position = Vector2(0, 110)
	l.add_theme_font_size_override("font_size", 52)
	l.add_theme_color_override("font_color", Color(1.0, 0.94, 0.80))
	l.add_theme_color_override("font_outline_color", Color(0.20, 0.12, 0.06, 0.9))
	l.add_theme_constant_override("outline_size", 10)
	l.modulate.a = 0.0
	capa_ui.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.6)
	t.tween_interval(1.6)
	t.tween_property(l, "modulate:a", 0.0, 0.8)
	t.tween_callback(l.queue_free)
