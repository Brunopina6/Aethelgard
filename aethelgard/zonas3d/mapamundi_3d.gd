extends "res://prototipos/vista3d.gd"
# V12, mapamundi 3D (15/11/2026): MAPAMUNDI 3D EXPLORABLE, primera región «Tierras de Oakhaven» (Norte).
# EXPERIMENTAL DE AUDITORÍA, APAGADO POR DEFECTO: solo con la exploración 3D activa y la opción «Mapamundi 3D (en
# pruebas)» de Ajustes (Auditoría o editor; [regiones] mapamundi3d en user://ajustes.cfg) o el argumento «mapamundi3d»
# (modo3d.gd, mapamundi_activo). Apagado, nada cambia: se sale de Oakhaven y de Pastos Verdes al mapa de siempre.
#
# Encendido, al salir de Oakhaven 3D o de Pastos Verdes 3D se llega aquí, junto a su entrada (modo3d.salida_al_mapa):
#   - cámara elevada (vista3d.gd) sobre una maqueta a escala reducida: la costa, las praderas y los bosques del mapa 2D
#     (terreno.gd, con su misma máscara), el camino principal, la bifurcación hacia la cueva, la senda casi borrada del
#     secreto y las maquetas (maquetas.gd) de Oakhaven, Pastos Verdes, el Portal del Vacío, el campamento y la cueva;
#   - SOLO KAEL: el grupo no camina detrás (no se crea grupo_3d.gd), pero sigue en la partida con sus datos intactos; la
#     formación de dentro de las ciudades y regiones no cambia;
#   - pisar el círculo dorado de una entrada (o «Entrar» / Intro / A cerca de ella) carga esa ubicación a escala del
#     personaje: Oakhaven 3D, Pastos Verdes 3D, la cueva provisional, la ciudad flotante por el Portal (como en el mapa
#     2D) o, por el camino del sureste, el mapa de siempre junto al Gran Bosque Verde;
#   - al volver, Kael aparece fuera del círculo y la entrada no se arma hasta alejarse (sin reentradas automáticas);
#   - encuentros por el camino como en el mapa 2D (progreso.gd), nunca junto a los sitios; el combate vuelve aquí;
#   - descubrimientos (datos.gd, en mazmorras["mapamundi"] de la partida): el campamento, la cueva y el secreto al
#     acercarse; Oakhaven y Pastos al visitarlos;
#   - VIAJE RÁPIDO (menu_viaje.gd): botón «VIAJE RÁPIDO», Tab / Esc / Start, o el mojón del campamento; solo destinos
#     descubiertos; bloqueado y explicado durante un combate, una escena o antes de terminar el prólogo;
#   - guardado al llegar, tras cada descubrimiento y viaje, y al pausar o cerrar (guardar_posicion: también deja la
#     posición equivalente del mapa 2D, por si se apaga la opción);
#   - si una carga falla (carga_fallida, la llama recursos.gd), se vuelve a ver el mapamundi con el control, sin negro.

const D := preload("res://zonas3d/mapamundi/datos.gd")
const T := preload("res://zonas3d/mapamundi/terreno.gd")
const Veg := preload("res://zonas3d/mapamundi/vegetacion.gd")
const Maq := preload("res://zonas3d/mapamundi/maquetas.gd")
const MenuViaje := preload("res://zonas3d/mapamundi/menu_viaje.gd")
const AGUA := preload("res://zonas3d/mapamundi/agua_mapamundi.gdshader")
const Progreso := preload("res://progreso.gd")
const Estilo := preload("res://estilo.gd")

const RADIO_ENTRADA := 1.3                # pisar el círculo
const ARMAR := 2.6                        # una entrada solo funciona tras alejarse de ella esto
const CERCA := 4.2                        # a esta distancia sale el botón «Entrar»
const MOJON_CERCA := 3.2                  # el mojón de viaje del campamento
const CAMARA := [55.0, 27.0, 16.0, 34.0]  # inclinación, distancia de partida, mínima y máxima (rueda y pellizco)
const ESCALA_KAEL := 1.45                 # Kael, más grande que la maqueta (se lee en el móvil); dentro, a su escala
const SIEMPRE_CON_NOMBRE := ["oakhaven", "pastos", "portal", "gran_bosque"]   # los demás, al descubrirlos
const ALTO_ROTULO := {"oakhaven": 8.6, "pastos": 4.2, "portal": 3.8, "campamento": 3.2, "cueva": 5.6, "secreto": 2.6,
	"gran_bosque": 3.0}
var brillo_sin_sombras := 1.12            # vista3d.gd: el perfil bajo (sin sombras) se ve igual de claro

var perfil: Dictionary
var nombre_perfil := ""
var veg = null
var maq = null
var maquetas := {}
var entradas := {}                        # id → {"pos": Vector3, "armada": bool, "aro": MeshInstance3D}
var rotulos := {}                         # id → Label3D
var obstaculos: Array = []                # [centro (x, z), radio]
var saliendo := false
var en_encuentro := false
var cinematica := false                   # (para datos.motivo_bloqueo; hoy no hay cinemáticas aquí)
var menu_abierto: Control = null
var pasos := 0
var viajes := 0                           # viajes rápidos hechos en esta escena (las pruebas lo miran)
var llegada_id := ""                      # junto a qué entrada se apareció ("" si no)
var cerca_id := ""                        # la entrada o el mojón que ofrece el botón
var ultimo_fallo := ""
var sol: DirectionalLight3D
var _recorrido := 0.0
var _ultima := Vector3.ZERO
var _t := 0.0
var t_preparar_ms := 0                    # lo que tarda _ready (medidas)
var tiempos := {}                         # ms de cada parte del escenario (medidas: pruebas/medir_mapamundi3d.gd)

var capa_ui: CanvasLayer
var titulo: Label
var aviso: Label
var boton_entrar: Button
var boton_viaje: Button
var boton_grupo: Button
var fundido: ColorRect
var _tween_aviso: Tween


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	inclinacion = CAMARA[0]
	distancia = CAMARA[1]
	super()                                              # ambiente, escenario, Kael, cámara, perfil y panel RND
	info.visible = false
	kael.scale = Vector3.ONE * ESCALA_KAEL
	cam.far = 240.0
	_crear_interfaz()
	_colocar_inicio()
	_crear_entradas()
	_actualizar_rotulos()
	_ultima = kael.global_position
	Engine.set_meta("zona", T.zona(kael.global_position.x, kael.global_position.z))
	Sonido.oyente_3d(kael, cam)
	Sonido.pasos_3d(kael, suelo_de_pasos)
	_descubrir_cerca(true)
	_titulo_zona()
	t_preparar_ms = Time.get_ticks_msec() - t0
	if not en_banco():
		guardar_posicion()
		Progreso.guardar(D.ESCENA)                       # guardado automático al llegar (como las regiones)


func en_banco() -> bool:
	return Engine.has_meta("banco_proto")


# ================================================================= mundo

func _crear_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.44, 0.62, 0.74)       # el mar lejano entre la bruma
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.70, 0.86)    # relleno azul suave (biblia de arte)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color(0.70, 0.80, 0.90)
	env.fog_density = 0.003
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0 if perfil.get("sombras", false) else 1.05
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.04
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = env
	add_child(we)
	sol = DirectionalLight3D.new()                       # luz dorada desde arriba a la izquierda
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-50.0, -38.0, 0.0)
	sol.light_color = Color(1.0, 0.93, 0.80)
	sol.light_energy = 1.05
	sol.shadow_enabled = perfil.get("sombras", false)
	sol.directional_shadow_max_distance = maxf(float(perfil.get("dist_sombras", 30.0)), 40.0)
	sol.shadow_blur = 1.2
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if int(perfil.get("sombra_tramos", 1)) <= 1 \
		else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	if perfil.get("sombras", false):
		RenderingServer.directional_shadow_atlas_set_size(int(perfil.get("sombra_res", 2048)), true)
	add_child(sol)


func _crear_escenario() -> void:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	var us := Time.get_ticks_usec()
	T.crear_suelo(self, mat)
	T.crear_fisica(self)
	tiempos["suelo"] = (Time.get_ticks_usec() - us) / 1000.0
	us = Time.get_ticks_usec()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	T.cinta_camino(st, D.CAMINO, 1.3)
	T.cinta_camino(st, D.SENDA_CUEVA, 0.9)
	var camino := MeshInstance3D.new()
	camino.name = "Camino"
	camino.mesh = st.commit()
	camino.material_override = mat
	camino.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(camino)
	var agua := ShaderMaterial.new()
	agua.shader = AGUA
	T.crear_agua(self, agua)
	tiempos["camino_agua"] = (Time.get_ticks_usec() - us) / 1000.0
	us = Time.get_ticks_usec()
	veg = Veg.new()
	veg.crear(self, mat, nombre_perfil)
	tiempos["vegetacion"] = (Time.get_ticks_usec() - us) / 1000.0
	us = Time.get_ticks_usec()
	maq = Maq.new()
	maquetas = maq.crear(self, mat, nombre_perfil)
	tiempos["maquetas"] = (Time.get_ticks_usec() - us) / 1000.0
	# lo que no se pisa (además del mar, los troncos y lo empinado): las maquetas
	obstaculos = [[D.SITIOS["oakhaven"]["centro"], 7.9], [D.SITIOS["pastos"]["centro"] + Vector2(0.6, -0.8), 3.8],
		[D.SITIOS["portal"]["centro"], 1.7], [D.SITIOS["campamento"]["centro"] + Vector2(-1.6, 1.2), 0.95],
		[D.SITIOS["campamento"]["centro"] + Vector2(1.3, 1.7), 0.95], [D.SITIOS["campamento"]["centro"], 0.6],
		[D.SITIOS["campamento"]["centro"] + Vector2(2.3, -1.4), 0.4], [D.SITIOS["secreto"]["centro"], 0.4]]
	var c: Vector2 = D.SITIOS["cueva"]["centro"]
	var e: Vector2 = D.SITIOS["cueva"]["entrada"]
	obstaculos.append([c - (e - c).normalized() * 0.6, 2.4])
	_crear_rotulos()


func _crear_rotulos() -> void:
	for id in ALTO_ROTULO:
		var s: Dictionary = D.SITIOS[id]
		var c: Vector2 = s["centro"]
		var l := Label3D.new()
		l.name = "Rotulo_" + id
		l.text = s["nombre"]
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true                           # nunca lo tapa una montaña: se lee siempre
		l.render_priority = 10
		l.font_size = 52 if id in ["oakhaven", "pastos"] else 40
		l.outline_size = 14
		l.modulate = Color(1.0, 0.95, 0.82)
		l.outline_modulate = Color(0.10, 0.07, 0.05, 0.85)
		l.pixel_size = 0.02
		l.font = Estilo.cursiva()
		l.position = Vector3(c.x, T.altura(c.x, c.y) + ALTO_ROTULO[id], c.y)
		add_child(l)
		rotulos[id] = l


func _actualizar_rotulos() -> void:
	for id in rotulos:
		rotulos[id].visible = id in SIEMPRE_CON_NOMBRE or D.descubierto(id)


func _crear_entradas() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.86, 0.45, 0.42)
	var disco := CylinderMesh.new()
	disco.top_radius = RADIO_ENTRADA
	disco.bottom_radius = RADIO_ENTRADA
	disco.height = 0.03
	disco.radial_segments = 28
	disco.rings = 1
	for id in D.SITIOS:
		var s: Dictionary = D.SITIOS[id]
		if s["entrada"] == Vector2.INF:
			continue
		var p: Vector2 = s["entrada"]
		var pos := Vector3(p.x, T.altura(p.x, p.y), p.y)
		var aro := MeshInstance3D.new()
		aro.name = "Entrada_" + id
		aro.mesh = disco
		aro.material_override = mat
		aro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		aro.position = pos + Vector3(0, 0.1, 0)
		add_child(aro)
		entradas[id] = {"pos": pos, "armada": _dist_plana(kael.global_position, pos) > ARMAR, "aro": aro}


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func suelo_de_pasos(p: Vector3) -> String:
	return "piedra" if T.campo("camino", p.x, p.z) < 0.9 else "hierba"


# Lo que no se pisa: fuera de la región, el mar, los troncos de los árboles y las maquetas. Lo empinado (la sierra, los
# acantilados) ya lo para vista3d.gd (_altura_suelo).
func _prohibido(p: Vector3) -> bool:
	if not D.ANDABLE.has_point(Vector2(p.x, p.z)):
		return true
	if T.altura(p.x, p.z) < 0.14:
		return true
	if veg != null and veg.hay_tronco(p.x, p.z):
		return true
	for o in obstaculos:
		if Vector2(p.x, p.z).distance_to(o[0]) < o[1]:
			return true
	return false


# ================================================================= llegada y posición

func _colocar_inicio() -> void:
	llegada_id = String(Engine.get_meta(D.LLEGADA, ""))
	if Engine.has_meta(D.LLEGADA):
		Engine.remove_meta(D.LLEGADA)
	var p := Vector2.INF
	if llegada_id != "" and D.SITIOS.has(llegada_id):
		p = D.SITIOS[llegada_id]["llegada"]
		if llegada_id in ["oakhaven", "pastos", "cueva"]:
			D.descubrir(llegada_id)                       # se vuelve de visitarlo: queda descubierto
	elif Engine.get_meta("pos_3d_ok", false) and int(Engine.get_meta("pos_3d_lugar", -1)) == D.INDICE \
			and Engine.get_meta("pos_3d", null) is Vector3:
		var v: Vector3 = Engine.get_meta("pos_3d")      # vuelve de un combate o de una partida guardada aquí
		p = Vector2(v.x, v.z)
	elif Engine.get_meta("pos_mapa_ok", false) and Engine.get_meta("pos_mapa", null) is Vector2:
		var q := D.a_3d(Engine.get_meta("pos_mapa"))     # la misma posición del mapa 2D, si cae en la región
		if D.ANDABLE.has_point(q) and not _prohibido(Vector3(q.x, 0, q.y)):
			p = q
	if p == Vector2.INF or _prohibido(Vector3(p.x, 0, p.y)):
		p = D.SITIOS["oakhaven"]["llegada"]
	_colocar_kael(Vector3(p.x, T.altura(p.x, p.y), p.y))
	if llegada_id != "" and D.SITIOS.has(llegada_id):    # mirando hacia fuera de la maqueta de la que sale
		var desde: Vector2 = D.SITIOS[llegada_id]["centro"]
		var dir := (p - desde).normalized()
		if dir.length() > 0.1:
			kael.mirar(Vector3(dir.x, 0, dir.y), 0.05)


func _colocar_kael(p: Vector3) -> void:
	kael.global_position = p
	seguro = p
	foco = p
	destino = null
	_colocar_camara(1.0)


# Recursos la llama al pausar o cerrar la app (y antes de guardar). Deja también la posición del mapa 2D equivalente.
func guardar_posicion() -> void:
	Engine.set_meta("pos_3d", kael.global_position)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", D.INDICE)
	Engine.set_meta("pos_mapa", D.a_2d(Vector2(kael.global_position.x, kael.global_position.z)))
	Engine.set_meta("pos_mapa_ok", true)


# ================================================================= cada fotograma

func ocupado() -> bool:
	if menu_abierto != null:
		return true
	var dg = get_node_or_null("/root/Dialogic")
	return dg != null and dg.current_timeline != null


func _parar_kael() -> void:
	destino = null
	if movimiento != "":
		movimiento = ""
		if kael.has_method("parar_marcha"):
			kael.parar_marcha()
		else:
			kael.reposo()


func _process(delta: float) -> void:
	_t += delta
	if maq != null:
		maq.animar(_t)
	if kael == null:
		return
	if en_banco():
		super(delta)
		return
	if saliendo or ocupado():
		_parar_kael()
		boton_entrar.visible = false
		_colocar_camara(1.0 - exp(-suavizado * delta))
		return
	super(delta)
	if saliendo:
		return
	var p := kael.global_position
	var d := _dist_plana(p, _ultima)
	_ultima = p
	if d < 2.0:                                          # un salto (viaje, recolocación) no cuenta como andar
		_recorrido += d
		while _recorrido >= D.LONG_PASO and not saliendo:
			_recorrido -= D.LONG_PASO
			_paso()
	if saliendo:
		return
	for id in entradas:
		var e: Dictionary = entradas[id]
		var de := _dist_plana(p, e["pos"])
		if not e["armada"]:
			e["armada"] = de > ARMAR
		elif de < RADIO_ENTRADA:
			_entrar(id)
			return
	_descubrir_cerca(false)
	_comprobar_cerca()


func _unhandled_input(ev: InputEvent) -> void:
	if saliendo or ocupado():
		return
	if ev.is_action_pressed("ui_accept") and boton_entrar.visible:
		get_viewport().set_input_as_handled()
		_pulsar_entrar()
		return
	if ev.is_action_pressed("menu_juego") or (ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_V):
		get_viewport().set_input_as_handled()
		abrir_viaje()
		return
	super(ev)


# El botón de abajo: «Entrar: …» junto a una entrada, o «Viaje rápido» junto al mojón del campamento.
func _comprobar_cerca() -> void:
	var p := kael.global_position
	var mejor := ""
	var dmin := CERCA
	for id in entradas:
		var de := _dist_plana(p, entradas[id]["pos"])
		if de < dmin:
			dmin = de
			mejor = id
	if mejor == "" and D.descubierto("campamento"):
		var c: Vector2 = D.SITIOS["campamento"]["centro"]
		if Vector2(p.x, p.z).distance_to(c) < MOJON_CERCA + 1.5:
			mejor = "mojon"
	if mejor != cerca_id:
		cerca_id = mejor
		if mejor == "":
			boton_entrar.visible = false
		else:
			boton_entrar.visible = true
			match mejor:
				"mojon":
					boton_entrar.text = "Viaje rápido"
				"portal":
					boton_entrar.text = "Cruzar el portal"
				"gran_bosque":
					boton_entrar.text = "Hacia el Gran Bosque Verde"
				_:
					boton_entrar.text = "Entrar: %s" % D.SITIOS[mejor]["nombre"]


func _pulsar_entrar() -> void:
	if cerca_id == "mojon":
		abrir_viaje()
	elif cerca_id != "":
		_entrar(cerca_id)


# ================================================================= descubrimientos

func _descubrir_cerca(silencioso: bool) -> void:
	var p := Vector2(kael.global_position.x, kael.global_position.z)
	for id in D.SITIOS:
		var s: Dictionary = D.SITIOS[id]
		var radio: float = s["radio_descubrir"]
		if radio <= 0.0 or p.distance_to(s["centro"]) > radio:
			continue
		if not D.descubrir(id):
			continue
		var texto := ""
		match id:
			"campamento":
				texto = "Descubierto: Campamento de Pastos Verdes.\nDesde su mojón (o con «Viaje rápido») podrás volver aquí."
			"cueva":
				texto = "Descubierta: la Cueva de los Helechos."
			"secreto":
				texto = "Lugar secreto: el Corro de los Mirlos.\n" + _premio_secreto()
		_actualizar_rotulos()
		if not silencioso and texto != "":
			Sonido.efecto("tesoro" if id == "secreto" else "ui_tic")
			_mostrar_aviso(texto, 3.4)
		if not en_banco():
			guardar_posicion()
			Progreso.guardar(D.ESCENA)


# El hallazgo del corro (PROPUESTA): una sola vez en la partida (como un cofre: cofres_abiertos).
func _premio_secreto() -> String:
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	if abiertos.has(D.ID_SECRETO):
		return ""
	abiertos[D.ID_SECRETO] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	load("res://inventario.gd").agregar_objeto("Poción", 2)
	load("res://inventario.gd").agregar_objeto("Éter", 1)
	return "Junto al mojón, una ofrenda para los viajeros: 2 Pociones y 1 Éter."


# ================================================================= entrar en una ubicación

func _entrar(id: String) -> void:
	if saliendo:
		return
	var M = load("res://modo3d.gd")
	var mapa = load("res://mapa.gd")
	var ruta := ""
	var kp := Vector2(kael.global_position.x, kael.global_position.z)
	Engine.set_meta("pos_mapa", D.a_2d(kp))              # por si se apaga la opción: el mapa 2D, en el mismo sitio
	Engine.set_meta("pos_mapa_ok", true)
	Engine.set_meta("pos_3d_ok", false)                  # la ubicación se entra por su principio
	match id:
		"oakhaven", "pastos":
			var i: int = D.SITIOS[id]["lugar"]
			var l: Dictionary = mapa.LUGARES[i] if i < mapa.LUGARES.size() else mapa.LUGAR_PASTOS
			Engine.set_meta("lugar", {"indice": i, "nombre": l["nombre"], "tipo": l["tipo"],
				"zona": l.get("zona", mapa.ZONA_LUGAR[i] if i < mapa.ZONA_LUGAR.size() else "llanura"), "texto": l["texto"]})
			ruta = M.escena_de(i)
			if ruta == "" and i == 0:
				ruta = "res://ciudad_oakhaven.tscn"       # Oakhaven 2D elegida en Ajustes: la de siempre
			D.descubrir(id)
		"cueva":
			ruta = D.CUEVA
			D.descubrir("cueva")
		"portal":
			Engine.set_meta("pos_isla_ok", false)         # como el mapa 2D: la ciudad flotante vuelve al mapa de siempre
			ruta = mapa.ESCENA_PORTAL
		"gran_bosque":
			Engine.set_meta("pos_mapa", D.a_2d(D.SITIOS["gran_bosque"]["centro"] + Vector2(3.0, 2.0)))
			ruta = D.MAPA
	Sonido.efecto("portal" if id == "portal" else "entrar")
	ir_a(ruta, D.SITIOS[id]["nombre"])


# Funde a negro y cambia de escena. Si la ruta no existe o la carga falla, carga_fallida devuelve el control.
func ir_a(ruta: String, nombre := "") -> void:
	if saliendo:
		return
	saliendo = true
	_parar_kael()
	if ruta == "" or not ResourceLoader.exists(ruta):
		carga_fallida(ruta if ruta != "" else nombre)
		return
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.45)
	await t.finished
	if not saliendo:
		return
	Recursos.cambiar_escena(ruta)


# recursos.gd la llama si no pudo cambiar de escena (y ir_a, si la ruta no existe): se vuelve a ver el mapamundi, con
# control, y la entrada no se vuelve a disparar hasta alejarse.
func carga_fallida(ruta: String) -> void:
	ultimo_fallo = ruta
	saliendo = false
	en_encuentro = false
	if is_instance_valid(fundido):
		fundido.color = Color(0, 0, 0, 0)
	for id in entradas:
		entradas[id]["armada"] = false
	get_tree().root.gui_disable_input = false
	push_warning("Mapamundi 3D: no se pudo cargar «%s»; se sigue en el mapamundi" % ruta)
	_mostrar_aviso("No se pudo abrir ese lugar. Sigues en el mapamundi.", 3.0)


# ================================================================= encuentros

func _paso() -> void:
	pasos += 1
	var P = load("res://progreso.gd")
	if P.paso_incienso():
		_mostrar_aviso("El Incienso de Ceniza se ha consumido.")
	if Engine.has_meta("mm3d_sin_encuentros"):
		return
	var p := Vector2(kael.global_position.x, kael.global_position.z)
	for id in D.SITIOS:
		if p.distance_to(D.SITIOS[id]["centro"]) < D.SIN_ENCUENTROS_CERCA + 4.0:
			return                                      # junto a los sitios no hay (como en las ciudades del mapa 2D)
	var zona := T.zona(p.x, p.y)
	if randf() < P.prob_encuentro(D.PROB_ENCUENTRO, pasos, D.PASOS_MIN, zona):
		_encuentro(zona)


func _encuentro(zona := "llanura") -> void:
	if saliendo:
		return
	saliendo = true
	en_encuentro = true
	_parar_kael()
	guardar_posicion()                                   # el combate vuelve aquí, al mismo sitio
	Engine.set_meta("zona", zona)
	Engine.set_meta("desde_mapa", true)
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("escena_retorno", D.ESCENA)
	Sonido.efecto("emboscada")
	_mostrar_aviso("¡Emboscada!")
	fundido.color = Color(1, 1, 1, 0)
	var t := create_tween()
	for i in 3:
		t.tween_property(fundido, "color:a", 0.85, 0.07)
		t.tween_property(fundido, "color:a", 0.0, 0.07)
	t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.45)
	await t.finished
	Recursos.cambiar_escena("res://combate.tscn")


# ================================================================= viaje rápido

# Abre la ventana de destinos, o explica por qué no se puede viajar ahora. Devuelve si se abrió.
func abrir_viaje() -> bool:
	if menu_abierto != null:
		return false
	var motivo := D.motivo_bloqueo(self)
	if motivo != "":
		_mostrar_aviso(motivo, 2.6)
		return false
	_parar_kael()
	var m = MenuViaje.new()
	m.preparar(D.destinos_conocidos(), Vector2(kael.global_position.x, kael.global_position.z))
	m.elegido.connect(viajar)
	m.cerrado.connect(func(): menu_abierto = null)
	menu_abierto = m
	capa_ui.add_child(m)
	return true


# Viaja a un destino conocido: gratis, sin encuentros al llegar (pasos a cero) y fuera de la entrada (no se entra solo).
func viajar(id: String) -> bool:
	var motivo := D.motivo_bloqueo(self)
	if motivo == "":
		motivo = D.motivo_destino(id, Vector2(kael.global_position.x, kael.global_position.z))
	if motivo != "":
		if menu_abierto != null and menu_abierto.has_method("avisar"):
			menu_abierto.avisar(motivo)
		else:
			_mostrar_aviso(motivo, 2.6)
		return false
	if menu_abierto != null:
		menu_abierto.cerrar()
		menu_abierto = null
	saliendo = true
	_parar_kael()
	Sonido.efecto("portal")
	fundido.color = Color(1.0, 0.95, 0.82, 0.0)
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.5)
	await t.finished
	var p: Vector2 = D.SITIOS[id]["llegada"]
	_colocar_kael(Vector3(p.x, T.altura(p.x, p.y), p.y))
	for e in entradas:
		entradas[e]["armada"] = _dist_plana(kael.global_position, entradas[e]["pos"]) > ARMAR
	pasos = 0
	_recorrido = 0.0
	_ultima = kael.global_position
	viajes += 1
	Engine.set_meta("zona", T.zona(p.x, p.y))
	if not en_banco():
		guardar_posicion()
		Progreso.guardar(D.ESCENA)
	var t2 := create_tween()
	t2.tween_property(fundido, "color:a", 0.0, 0.5)
	await t2.finished
	fundido.color = Color(0, 0, 0, 0)
	saliendo = false
	_mostrar_aviso("Has llegado: %s." % D.SITIOS[id]["nombre"], 2.0)
	return true


# ================================================================= interfaz

func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:
			n.queue_free()


func _cambiar_perfil() -> void:
	guardar_posicion()
	super()


func _crear_interfaz() -> void:
	capa_ui = CanvasLayer.new()
	capa_ui.layer = 50
	add_child(capa_ui)
	titulo = Label.new()
	titulo.position = Vector2(22, 12)
	titulo.add_theme_font_override("font", Estilo.cursiva())
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	titulo.add_theme_color_override("font_outline_color", Color(0.10, 0.07, 0.05, 0.9))
	titulo.add_theme_constant_override("outline_size", 9)
	titulo.text = D.REGION
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_ui.add_child(titulo)
	var sub := Label.new()
	sub.position = Vector2(24, 56)
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78, 0.9))
	sub.add_theme_color_override("font_outline_color", Color(0.10, 0.07, 0.05, 0.9))
	sub.add_theme_constant_override("outline_size", 6)
	sub.text = "Mapamundi 3D · en pruebas"
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_ui.add_child(sub)
	var barra := PanelContainer.new()
	barra.name = "Barra"
	var est: StyleBoxFlat = Estilo.ventana(0.72)
	est.set_content_margin_all(6)
	barra.add_theme_stylebox_override("panel", est)
	barra.position = Vector2(400, 642)
	capa_ui.add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	barra.add_child(fila)
	boton_grupo = _boton_barra("GRUPO", fila)
	boton_grupo.pressed.connect(_abrir_grupo)
	boton_viaje = _boton_barra("VIAJE RÁPIDO", fila)
	boton_viaje.pressed.connect(abrir_viaje)
	barra.reset_size()
	barra.position.x = (1280.0 - barra.get_combined_minimum_size().x) * 0.5
	boton_entrar = Button.new()
	boton_entrar.name = "Entrar"
	boton_entrar.position = Vector2(470, 572)
	boton_entrar.custom_minimum_size = Vector2(340, 56)
	boton_entrar.add_theme_font_size_override("font_size", 22)
	boton_entrar.focus_mode = Control.FOCUS_NONE         # con teclado o mando, Intro / A
	boton_entrar.visible = false
	boton_entrar.pressed.connect(_pulsar_entrar)
	capa_ui.add_child(boton_entrar)
	aviso = Label.new()
	aviso.position = Vector2(140, 96)
	aviso.size = Vector2(1000, 90)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.add_theme_font_override("font", Estilo.cursiva())
	aviso.add_theme_font_size_override("font_size", 30)
	aviso.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	aviso.add_theme_color_override("font_outline_color", Color(0.10, 0.07, 0.05, 0.9))
	aviso.add_theme_constant_override("outline_size", 9)
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aviso.modulate.a = 0.0
	capa_ui.add_child(aviso)
	fundido = ColorRect.new()                            # el último: lo tapa todo al fundir
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_ui.add_child(fundido)


func _boton_barra(texto: String, fila: HBoxContainer) -> Button:
	var b := Button.new()
	b.text = texto
	b.flat = true
	b.custom_minimum_size = Vector2(200, 52)
	b.add_theme_font_override("font", load("res://menu_combate.gd").fuente("res://fuentes/SairaCondensed-Medium.ttf", 3, 0))
	b.add_theme_font_size_override("font_size", 20)
	b.focus_mode = Control.FOCUS_NONE
	fila.add_child(b)
	return b


# El grupo completo, con sus datos (menus.gd): aquí solo camina Kael, pero nadie ha dejado el grupo.
func _abrir_grupo() -> void:
	if menu_abierto != null or saliendo:
		return
	_parar_kael()
	var m = load("res://menus.gd").new()
	m.pestana = "Grupo"
	m.cerrado.connect(func(): menu_abierto = null)
	menu_abierto = m
	capa_ui.add_child(m)


func _mostrar_aviso(texto: String, segundos := 1.8) -> void:
	aviso.text = texto
	if _tween_aviso != null and _tween_aviso.is_valid():
		_tween_aviso.kill()
	_tween_aviso = create_tween()
	_tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	_tween_aviso.tween_interval(segundos)
	_tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)


func _titulo_zona() -> void:
	if llegada_id != "":
		_mostrar_aviso("Mapamundi · %s" % D.REGION, 1.6)


# ================================================================= Ajustes (menus.gd, solo Auditoría o editor)

const CLAVE_AJUSTES := "mapamundi3d"


static func opcion_ajustes(m: Object, cuerpo: Control) -> void:
	if not load("res://prototipos/calidad_proto.gd").pruebas_permitidas():
		return
	var m3d = load("res://modo3d.gd")
	var si_ahora: bool = m3d.elegida(CLAVE_AJUSTES)
	cuerpo.add_child(m._texto("Mapamundi", 26, m.COLOR_TITULO))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	for op in [[false, "El de siempre"], [true, "Mapamundi 3D (en pruebas)"]]:
		var en_3d: bool = op[0]
		var b: Button = m._boton(("● " if en_3d == si_ahora else "○ ") + op[1], 18, Vector2(300, 34),
			"mapamundi:%s" % ("3d" if en_3d else "2d"))
		b.pressed.connect(func():
			m3d.elegir(CLAVE_AJUSTES, en_3d)
			var son = m.get_node_or_null("/root/Sonido")
			if son != null:
				son.efecto("ui_tic")
			m._pintar_de_nuevo())
		fila.add_child(b)
	cuerpo.add_child(fila)
	cuerpo.add_child(m._texto("Se nota al salir de Oakhaven o de Pastos Verdes. Primera región, PROPUESTA.", 16, m.COLOR_SUAVE))
